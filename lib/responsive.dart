import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double compact = 640;
  static const double medium = 900;
  static const double expanded = 1200;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => width(context) < compact;

  static bool isMedium(BuildContext context) =>
      width(context) >= compact && width(context) < expanded;

  static bool isDesktop(BuildContext context) => width(context) >= expanded;

  static int columns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final w = width(context);
    if (w >= expanded) return desktop;
    if (w >= medium) return tablet;
    return mobile;
  }

  static double maxContentWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1440) return 1360;
    if (w >= expanded) return 1240;
    if (w >= medium) return 1040;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final w = width(context);
    if (w >= expanded) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    if (w >= medium) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 18);
    }
    return const EdgeInsets.all(16);
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;

  const ResponsiveContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
