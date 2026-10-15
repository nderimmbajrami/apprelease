/// The AppRelease runner.
///
/// ```
/// Runner.loop()
///   └─ claim a queued release (claim_release RPC)
///        └─ Pipeline.run()
///             ├─ checkout            git clone --branch
///             ├─ toolchain           flutter version, doctor
///             ├─ packages            flutter pub get
///             ├─ signing             keystore / App Store Connect key → env
///             ├─ versioning          build number from the store
///             ├─ build               flutter build appbundle | ipa
///             └─ publish             Google Play | App Store Connect
/// ```
///
/// Every step writes to `release_steps` and streams lines into
/// `release_logs`, which is what the console shows live.
library;

export 'src/api.dart';
export 'src/config.dart';
export 'src/pipeline.dart';
export 'src/runner.dart';
export 'src/stores/app_store_connect.dart';
export 'src/stores/google_play.dart';
