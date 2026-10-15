import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/page_header.dart';
import '../../../routing/app_routes.dart';
import '../domain/app_project.dart';
import 'apps_controller.dart';

/// Three short steps: the repository, the details, the platforms.
class AddAppScreen extends ConsumerStatefulWidget {
  const AddAppScreen({super.key});

  @override
  ConsumerState<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends ConsumerState<AddAppScreen> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  final _repoUrl = TextEditingController();
  final _branch = TextEditingController(text: 'main');
  final _name = TextEditingController();
  final _flutterVersion = TextEditingController(text: 'stable');
  final _packageName = TextEditingController();
  final _bundleId = TextEditingController();
  var _step = 0;
  var _projectType = ProjectType.flutter;
  var _platforms = {Platform.android, Platform.ios};

  @override
  void dispose() {
    for (final c in [
      _repoUrl,
      _branch,
      _name,
      _flutterVersion,
      _packageName,
      _bundleId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_formKeys[_step].currentState!.validate()) return;
    if (_step == 0 && _name.text.trim().isEmpty) {
      // Guess a name from the repository: "shop-app" → "Shop App".
      final tail = _repoUrl.text
          .trim()
          .replaceAll(RegExp(r'\.git/?$'), '')
          .split(RegExp(r'[/:]'))
          .where((p) => p.isNotEmpty)
          .last;
      _name.text = tail
          .split(RegExp(r'[-_]'))
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    setState(() => _step += 1);
  }

  Future<void> _finish() async {
    if (!_formKeys[2].currentState!.validate()) return;
    if (_platforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pickAtLeastOnePlatform)),
      );
      return;
    }
    final id = await ref
        .read(appsControllerProvider.notifier)
        .addApp(
          name: _name.text,
          repoUrl: _repoUrl.text,
          branch: _branch.text,
          projectType: _projectType,
          platforms: _platforms,
          androidPackageName: _packageName.text,
          iosBundleId: _bundleId.text,
          flutterVersion: _flutterVersion.text,
        );
    if (id == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.appAdded)));
    context.goNamed(AppRoute.appDetail.name, pathParameters: {'appId': id});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final validators = Validators(l10n);
    final isBusy = ref.watch(appsControllerProvider).isLoading;
    final labels = [
      l10n.newAppStepRepo,
      l10n.newAppStepDetails,
      l10n.newAppStepPlatforms,
    ];

    return PageBody(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          PageHeader(
            onBack: () => context.goNamed(AppRoute.apps.name),
            title: Text(l10n.newAppTitle),
            subtitle: Text('${_step + 1} / 3 · ${labels[_step]}'),
          ),
          const SizedBox(height: Gap.xl),
          _Steps(labels: labels, current: _step),
          const SizedBox(height: Gap.xl),
          AppCard(
            padding: const EdgeInsets.all(Gap.xl),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: switch (_step) {
                0 => Form(
                  key: _formKeys[0],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.newAppRepoExplain,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: Gap.lg),
                      TextFormField(
                        controller: _repoUrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: l10n.repoUrl,
                          hintText: l10n.repoUrlHint,
                          prefixIcon: const Icon(Icons.link, size: 19),
                        ),
                        keyboardType: TextInputType.url,
                        validator: validators.repoUrl,
                        onFieldSubmitted: (_) => _next(),
                      ),
                      const SizedBox(height: Gap.md),
                      TextFormField(
                        controller: _branch,
                        decoration: InputDecoration(
                          labelText: l10n.branch,
                          prefixIcon: const Icon(
                            Icons.account_tree_outlined,
                            size: 19,
                          ),
                        ),
                        validator: validators.required,
                        onFieldSubmitted: (_) => _next(),
                      ),
                    ],
                  ),
                ),
                1 => Form(
                  key: _formKeys[1],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        autofocus: true,
                        decoration: InputDecoration(labelText: l10n.appName),
                        validator: validators.required,
                      ),
                      const SizedBox(height: Gap.lg),
                      Text(
                        l10n.projectType,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: Gap.sm),
                      SegmentedButton<ProjectType>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ProjectType.flutter,
                            label: Text(l10n.projectFlutter),
                          ),
                          ButtonSegment(
                            value: ProjectType.reactNative,
                            enabled: false,
                            label: Text(l10n.projectReactNativeSoon),
                          ),
                        ],
                        selected: {_projectType},
                        onSelectionChanged: (s) =>
                            setState(() => _projectType = s.first),
                      ),
                      const SizedBox(height: Gap.lg),
                      TextFormField(
                        controller: _flutterVersion,
                        decoration: InputDecoration(
                          labelText: l10n.flutterVersion,
                          helperText: l10n.flutterVersionHint,
                        ),
                        validator: validators.required,
                      ),
                    ],
                  ),
                ),
                _ => Form(
                  key: _formKeys[2],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.newAppPlatformsExplain,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: Gap.lg),
                      CheckboxListTile(
                        value: _platforms.contains(Platform.android),
                        onChanged: (on) => setState(() {
                          _platforms = {..._platforms};
                          on!
                              ? _platforms.add(Platform.android)
                              : _platforms.remove(Platform.android);
                        }),
                        secondary: const Icon(Icons.android),
                        title: Text(l10n.platformAndroid),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_platforms.contains(Platform.android))
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 56,
                            bottom: Gap.md,
                          ),
                          child: TextFormField(
                            controller: _packageName,
                            decoration: InputDecoration(
                              labelText: l10n.androidPackageName,
                              hintText: 'com.example.app',
                            ),
                            validator: validators.applicationId,
                          ),
                        ),
                      CheckboxListTile(
                        value: _platforms.contains(Platform.ios),
                        onChanged: (on) => setState(() {
                          _platforms = {..._platforms};
                          on!
                              ? _platforms.add(Platform.ios)
                              : _platforms.remove(Platform.ios);
                        }),
                        secondary: const Icon(Icons.apple),
                        title: Text(l10n.platformIos),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_platforms.contains(Platform.ios))
                        Padding(
                          padding: const EdgeInsets.only(left: 56),
                          child: TextFormField(
                            controller: _bundleId,
                            decoration: InputDecoration(
                              labelText: l10n.iosBundleId,
                              hintText: 'com.example.app',
                            ),
                            validator: validators.applicationId,
                          ),
                        ),
                    ],
                  ),
                ),
              },
            ),
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: isBusy ? null : () => setState(() => _step -= 1),
                  child: Text(l10n.back),
                ),
              const Spacer(),
              if (_step < 2)
                FilledButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(l10n.next),
                )
              else
                FilledButton.icon(
                  onPressed: isBusy ? null : _finish,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l10n.finishAddApp),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Numbered step bar.
class _Steps extends StatelessWidget {
  const _Steps({required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        for (final (index, label) in labels.indexed) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: index <= current ? scheme.primary : scheme.outline,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= current ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: index <= current ? scheme.primary : scheme.outline,
                  ),
                ),
                child: index < current
                    ? Icon(Icons.check, size: 13, color: scheme.onPrimary)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: index == current
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: index <= current
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
