import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/release.dart';

/// The live log: dark panel, mono text, a colour per level, scrolled to the
/// end while lines keep arriving.
class LogView extends StatefulWidget {
  const LogView({required this.lines, this.follow = true, super.key});

  final List<LogLine> lines;

  /// Keep the newest line in view as lines arrive.
  final bool follow;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final _controller = ScrollController();

  /// Whether the reader is at the end. Scrolled up to read something, new
  /// lines must not pull the view away.
  var _atEnd = true;

  @override
  void didUpdateWidget(LogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.follow &&
        _atEnd &&
        widget.lines.length != oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        // A jump, not an animation: lines can arrive faster than 200 ms.
        _controller.jumpTo(_controller.position.maxScrollExtent);
      });
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      final m = n.metrics;
      _atEnd = m.pixels >= m.maxScrollExtent - 48;
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('HH:mm:ss', 'en_US');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.lineDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Gap.xl),
                child: Text(
                  context.l10n.logEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedDark,
                  ),
                ),
              ),
            )
          : NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SelectionArea(
                child: ListView.builder(
                  controller: _controller,
                  padding: const EdgeInsets.all(Gap.md),
                  itemCount: widget.lines.length,
                  itemBuilder: (context, index) {
                    final line = widget.lines[index];
                    final color = switch (line.level) {
                      LogLevel.command => const Color(0xFFAFC3FF),
                      LogLevel.warning => AppColors.amberDark,
                      LogLevel.error => AppColors.dangerDark,
                      LogLevel.success => AppColors.mintDark,
                      LogLevel.info => AppColors.inkDark,
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time.format(line.at.toLocal()),
                            style: theme.textTheme.mono.copyWith(
                              fontSize: 12,
                              color: AppColors.mutedDark.withValues(alpha: .7),
                            ),
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Text(
                              (line.level == LogLevel.command ? '\$ ' : '') +
                                  line.text,
                              style: theme.textTheme.mono.copyWith(
                                fontSize: 12.5,
                                color: color,
                                fontWeight: line.level == LogLevel.success
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
