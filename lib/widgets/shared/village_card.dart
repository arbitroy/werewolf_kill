import 'package:flutter/material.dart';

class VillageCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  const VillageCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? EdgeInsets.all(8),
      color: color ?? Color(0xFF1A0F2E),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}