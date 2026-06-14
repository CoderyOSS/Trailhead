import 'package:flutter/material.dart';
import 'icons.dart';
import '../theme/tokens.dart';

class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: TrailheadIcon(
          icon: TrailheadIconData.x,
          size: 9,
          color: AppColors.fg2,
        ),
      ),
    );
  }
}
