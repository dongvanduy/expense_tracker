import 'package:flutter/material.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const BentoCard({
    Key? key,
    required this.child,
    this.color,
    this.gradient,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24), // Bo góc lớn chuẩn Bento
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}