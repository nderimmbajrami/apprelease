import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  /// Shorthand for the generated strings: `context.l10n.signIn`.
  AppL10n get l10n => AppL10n.of(this);
}
