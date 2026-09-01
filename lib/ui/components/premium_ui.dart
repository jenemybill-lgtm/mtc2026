import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isGlass;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAccent = accentColor != null;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isGlass 
            ? Colors.white.withValues(alpha: 0.8)
            : (hasAccent ? accentColor!.withValues(alpha: 0.08) : Colors.white),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: hasAccent ? accentColor!.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: hasAccent ? accentColor!.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const PremiumGlassCard({super.key, required this.child, this.padding, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: themeColor, size: 18),
              ),
              const SizedBox(width: 12),
            ] else ...[
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(2, 0))
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
            Flexible(
              fit: FlexFit.loose,
              flex: 0,
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: icon != null ? 38 : 16),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueGrey.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PremiumStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const PremiumStatRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isFullWidth;

  const PremiumButton({super.key, required this.label, required this.icon, required this.onTap, this.color, this.isFullWidth = true});

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: themeColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
