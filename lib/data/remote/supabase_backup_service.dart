import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/id_generator.dart';
import '../local/hive_service.dart';
import '../models/task.dart';
import '../models/task_completion.dart';
import '../models/daily_record.dart';
import '../models/goal.dart';

class SupabaseBackupService {
  static const _table = 'backups';
  static const _deviceIdKey = 'device_uuid';

  static SupabaseClient get _client => Supabase.instance.client;

  /// 고유 디바이스 ID (UUID, 기기별 고유값)
  static String get _deviceId {
    var id = HiveService.settings.get(_deviceIdKey, defaultValue: '') as String;
    if (id.isEmpty) {
      id = IdGenerator.generate();
      HiveService.settings.put(_deviceIdKey, id);
    }
    return id;
  }

  /// 현재 디바이스 ID 조회 (복원 시 입력용으로 표시)
  static String get deviceId => _deviceId;

  /// Hive 전체 데이터를 JSON으로 직렬화
  static Map<String, dynamic> _serializeAll() {
    final tasks = HiveService.tasks.values.map((t) => {
          'id': t.id,
          'title': t.title,
          'memo': t.memo,
          'isRequired': t.isRequired,
          'isRoutine': t.isRoutine,
          'subItems': t.subItems,
          'createdAt': t.createdAt.toIso8601String(),
          'order': t.order,
        }).toList();

    final completions = HiveService.completions.values.map((c) => {
          'taskId': c.taskId,
          'date': c.date.toIso8601String(),
          'isCompleted': c.isCompleted,
          'completedAt': c.completedAt?.toIso8601String(),
        }).toList();

    final dailyRecords = HiveService.dailyRecords.values.map((r) => {
          'date': r.date.toIso8601String(),
          'totalTasks': r.totalTasks,
          'completedTasks': r.completedTasks,
        }).toList();

    final goals = HiveService.goals.values.map((g) => {
          'id': g.id,
          'title': g.title,
          'subtitle': g.subtitle,
          'isCompleted': g.isCompleted,
          'createdAt': g.createdAt.toIso8601String(),
        }).toList();

    final settings = <String, dynamic>{};
    for (final key in HiveService.settings.keys) {
      settings[key.toString()] = HiveService.settings.get(key);
    }

    return {
      'tasks': tasks,
      'completions': completions,
      'dailyRecords': dailyRecords,
      'goals': goals,
      'settings': settings,
    };
  }

  /// 백업 업로드 (기존 백업 덮어쓰기 + 3일 지난 데이터 삭제)
  static Future<bool> backup() async {
    try {
      // 3일 지난 백업 삭제
      await _deleteOldBackups();

      // 기존 내 백업 삭제 (최신 1개만 유지)
      await _client.from(_table).delete().eq('device_id', _deviceId);

      // 새 백업 저장
      await _client.from(_table).insert({
        'device_id': _deviceId,
        'data': _serializeAll(),
      });

      debugPrint('[Backup] 백업 완료: $_deviceId');
      return true;
    } catch (e) {
      debugPrint('[Backup] 백업 실패: $e');
      return false;
    }
  }

  /// 복원: 가장 최신 백업에서 Hive로 덮어쓰기
  /// [fromDeviceId]를 지정하면 해당 기기의 백업에서 복원
  static Future<bool> restore({String? fromDeviceId}) async {
    try {
      final targetId = fromDeviceId ?? _deviceId;
      final response = await _client
          .from(_table)
          .select()
          .eq('device_id', targetId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('[Backup] 복원할 백업이 없습니다');
        return false;
      }

      final data = response.first['data'] as Map<String, dynamic>;
      await _deserializeAll(data);

      debugPrint('[Backup] 복원 완료');
      return true;
    } catch (e) {
      debugPrint('[Backup] 복원 실패: $e');
      return false;
    }
  }

  /// JSON → Hive 복원
  static Future<void> _deserializeAll(Map<String, dynamic> data) async {
    // Tasks
    await HiveService.tasks.clear();
    final tasks = (data['tasks'] as List?) ?? [];
    for (final t in tasks) {
      final task = Task(
        id: t['id'],
        title: t['title'],
        memo: t['memo'],
        isRequired: t['isRequired'] ?? true,
        isRoutine: t['isRoutine'] ?? false,
        subItems: List<String>.from(t['subItems'] ?? []),
        createdAt: DateTime.parse(t['createdAt']),
        order: t['order'] ?? 0,
      );
      await HiveService.tasks.put(task.id, task);
    }

    // Completions
    await HiveService.completions.clear();
    final completions = (data['completions'] as List?) ?? [];
    for (final c in completions) {
      final comp = TaskCompletion(
        taskId: c['taskId'],
        date: DateTime.parse(c['date']),
        isCompleted: c['isCompleted'] ?? false,
        completedAt:
            c['completedAt'] != null ? DateTime.parse(c['completedAt']) : null,
      );
      await HiveService.completions.put(comp.compositeKey, comp);
    }

    // Daily Records
    await HiveService.dailyRecords.clear();
    final records = (data['dailyRecords'] as List?) ?? [];
    for (final r in records) {
      final record = DailyRecord(
        date: DateTime.parse(r['date']),
        totalTasks: r['totalTasks'] ?? 0,
        completedTasks: r['completedTasks'] ?? 0,
      );
      await HiveService.dailyRecords.put(record.dateKey, record);
    }

    // Goals
    await HiveService.goals.clear();
    final goals = (data['goals'] as List?) ?? [];
    for (final g in goals) {
      final goal = Goal(
        id: g['id'],
        title: g['title'],
        subtitle: g['subtitle'],
        isCompleted: g['isCompleted'] ?? false,
        createdAt: DateTime.parse(g['createdAt']),
      );
      await HiveService.goals.put(goal.id, goal);
    }

    // Settings
    final settings = (data['settings'] as Map<String, dynamic>?) ?? {};
    for (final entry in settings.entries) {
      await HiveService.settings.put(entry.key, entry.value);
    }
  }

  /// 3일 지난 백업 삭제
  static Future<void> _deleteOldBackups() async {
    try {
      final cutoff =
          DateTime.now().subtract(const Duration(days: 3)).toUtc().toIso8601String();
      await _client.from(_table).delete().lt('created_at', cutoff);
    } catch (e) {
      debugPrint('[Backup] 오래된 백업 삭제 실패: $e');
    }
  }

  /// 마지막 백업 시각 조회
  static Future<DateTime?> getLastBackupTime() async {
    try {
      final response = await _client
          .from(_table)
          .select('created_at')
          .eq('device_id', _deviceId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return DateTime.parse(response.first['created_at']);
    } catch (e) {
      return null;
    }
  }
}
