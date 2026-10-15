import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Every page sits on the same sheet with a comfortable maximum width.
class PageBody extends StatelessWidget {
  const PageBody({required this.child, this.maxWidth = 1180, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final side = isCompact ? Gap.lg : Gap.xxl;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(side, Gap.xl, side, 0),
            child: child,
          ),
        ),
      ),
    );
  }
}
