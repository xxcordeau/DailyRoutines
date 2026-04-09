import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 로고
          _LogoWidget(),
          const Spacer(),
          // 유저 정보
          Text(
            '정연 님',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8E8E8),
            child: const Icon(Icons.person, color: Color(0xFF9E9E9E), size: 20),
          ),
        ],
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // PNG 로고 시도 → 없으면 SVG → 없으면 텍스트 폴백
    return SizedBox(
      height: 36,
      child: AspectRatio(
        aspectRatio: 386 / 270,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          placeholderBuilder: (_) => _TextLogo(),
        ),
      ),
    );
  }
}

class _TextLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
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
