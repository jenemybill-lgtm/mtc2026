import 'package:flutter/material.dart';

class PremiumCard extends StatefulWidget {
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
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hasAccent = widget.accentColor != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use theme surface color if not glass, not accent, etc.
    final baseColor = widget.isGlass 
        ? (isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8))
        : (hasAccent ? widget.accentColor!.withValues(alpha: 0.08) : Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _isHovered && widget.onTap != null ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered && hasAccent
                ? widget.accentColor!.withValues(alpha: 0.5)
                : (hasAccent ? widget.accentColor!.withValues(alpha: 0.25) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))),
            width: _isHovered && hasAccent ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: hasAccent && _isHovered
                  ? widget.accentColor!.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.03),
              blurRadius: _isHovered ? 20 : 15,
              offset: Offset(0, _isHovered ? 10 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              splashColor: hasAccent ? widget.accentColor!.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(20.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: themeColor.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Icon(icon, size: 64, color: themeColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.blueGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
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
