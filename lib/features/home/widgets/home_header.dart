import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../settings/providers/nickname_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(nicknameProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LogoWidget(),
          const Spacer(),
          Text(
            '$nickname 님',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE8E8E8),
            child: Icon(Icons.person, color: Color(0xFF9E9E9E), size: 20),
          ),
        ],
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AspectRatio(
        aspectRatio: 386 / 250,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          placeholderBuilder: (_) => const _TextLogo(),
        ),
      ),
    );
  }
}

class _TextLogo extends StatelessWidget {
  const _TextLogo();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'dh',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        fontStyle: FontStyle.italic,
        letterSpacing: -1,
      ),
    );
  }
}
