import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/remote/supabase_backup_service.dart';
import '../../home/providers/tasks_provider.dart';
import '../../home/providers/completion_provider.dart';
import '../../history/providers/history_provider.dart';
import '../providers/nickname_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(nicknameProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '설정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // 프로필
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE8E8E8),
                    child:
                        Icon(Icons.person, color: Color(0xFF9E9E9E), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 닉네임 변경 + 데이터 초기화
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      iconColor: AppColors.primary,
                      title: '닉네임 변경',
                      onTap: () =>
                          _showNicknameDialog(context, ref, nickname),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: HugeIcons.strokeRoundedDelete02,
                      iconColor: Colors.redAccent,
                      title: '데이터 초기화',
                      subtitle: '모든 루틴 데이터를 삭제합니다',
                      onTap: () => _showResetDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 백업 + 복원 + 앱 정보
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: HugeIcons.strokeRoundedCloudUpload,
                      iconColor: AppColors.primary,
                      title: '데이터 백업',
                      subtitle: '클라우드 저장 (3일 보관)',
                      onTap: () => _doBackup(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: HugeIcons.strokeRoundedCloudDownload,
                      iconColor: AppColors.primary,
                      title: '데이터 복원',
                      subtitle: '클라우드에서 불러오기',
                      onTap: () => _showRestoreDialog(context, ref),
                    ),
                    const Divider(height: 1, indent: 56),
                    const _SettingsTile(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      iconColor: AppColors.primary,
                      title: '앱 정보',
                      subtitle: 'v1.0.0',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doBackup(BuildContext context) async {
    _showSnackBar(context, '백업 중...');
    final success = await SupabaseBackupService.backup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showSnackBar(
      context,
      success ? '백업 완료' : '백업 실패. 다시 시도해주세요',
      isError: !success,
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('데이터 복원'),
        content: const Text(
            '클라우드 백업에서 데이터를 불러옵니다.\n현재 데이터를 덮어씁니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _showSnackBar(context, '복원 중...');
              final success = await SupabaseBackupService.restore();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (success) {
                ref.read(tasksProvider.notifier).refresh();
                ref.read(todayCompletionsProvider.notifier).refresh();
                ref.read(historyProvider.notifier).refresh();
                ref.read(nicknameProvider.notifier).reload();
                _showSnackBar(context, '복원 완료');
              } else {
                _showSnackBar(context, '복원할 백업이 없습니다', isError: true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('복원'),
          ),
        ],
      ),
    );
  }

  void _showNicknameDialog(
      BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(nicknameProvider.notifier).setNickname(name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('데이터 초기화'),
        content: const Text(
            '모든 루틴 데이터를 초기화합니다.\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await HiveService.tasks.clear();
              await HiveService.completions.clear();
              await HiveService.dailyRecords.clear();
              await HiveService.goals.clear();
              ref.read(tasksProvider.notifier).refresh();
              ref.read(todayCompletionsProvider.notifier).refresh();
              ref.read(historyProvider.notifier).refresh();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                _showSnackBar(context, '초기화 완료');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}

// 재사용 설정 타일
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, size: 20, color: iconColor),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: onTap != null
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              color: AppColors.textSecondary,
            )
          : null,
      onTap: onTap,
      hoverColor: AppColors.border.withValues(alpha: 0.4),
      splashColor: AppColors.border.withValues(alpha: 0.3),
    );
  }
}
