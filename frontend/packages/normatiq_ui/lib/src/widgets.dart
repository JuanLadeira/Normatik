import 'package:flutter/material.dart';
import 'tokens.dart';

class NormatiqLogo extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool showText;

  const NormatiqLogo({
    super.key,
    this.size = 32,
    this.isDark = false,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : NormatiqColors.primary600;
    final iconBg = isDark ? NormatiqColors.accent500 : NormatiqColors.primary600;
    final barColor = isDark ? NormatiqColors.primary600 : NormatiqColors.accent500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.15),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(size * 0.4, barColor),
              const SizedBox(width: 2),
              _buildBar(size * 0.6, barColor),
              const SizedBox(width: 2),
              _buildBar(size * 0.25, Colors.white.withOpacity(0.6)),
              const SizedBox(width: 2),
              _buildBar(size * 0.15, Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            "Normatiq",
            style: TextStyle(
              color: primaryColor,
              fontSize: size * 0.6,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBar(double height, Color color) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class NormatiqStatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? sub;
  final Color? color;
  final VoidCallback? onTap;

  const NormatiqStatCard({
    super.key,
    required this.value,
    required this.label,
    this.sub,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NormatiqRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color ?? Theme.of(context).colorScheme.primary,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
