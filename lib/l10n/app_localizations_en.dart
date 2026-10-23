// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AppRelease';

  @override
  String get appTagline => 'Ship your Flutter app to both stores.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get noAccountYet => 'No account yet? Create one';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInExplain => 'Sign in to the release console.';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get signUpExplain =>
      'Free plan, no credit card. We email you a code to confirm the address.';

  @override
  String get demoHint => 'Demo: demo@apprelease.store / demo1234';

  @override
  String get fillDemo => 'Fill demo account';

  @override
  String get authPitch =>
      'Build, sign and publish Flutter apps to Google Play and the App Store from one apprelease.yaml.';

  @override
  String get authPoint1 => 'Managed code signing for Android and iOS';

  @override
  String get authPoint2 => 'Build numbers taken straight from the store';

  @override
  String get authPoint3 => 'Live logs, release history, email when it is done';

  @override
  String get authFooterNote => 'Flutter first. React Native next.';

  @override
  String get invalidCredentials => 'Wrong email or password';

  @override
  String get emailAlreadyUsed => 'This email is already registered';

  @override
  String get weakPassword => 'Choose a longer password';

  @override
  String get networkError => 'No connection. Check the network and try again.';

  @override
  String get unknownError => 'Something went wrong. Please try again.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'At least 8 characters';

  @override
  String get invalidRepoUrl => 'Enter a Git URL (https:// or git@)';

  @override
  String get invalidApplicationId =>
      'Use reverse-domain form, e.g. com.example.app';

  @override
  String get invalidVersion => 'Use the form 1.2.3';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get notFoundTitle => 'Nothing here';

  @override
  String get notFoundMessage =>
      'The address may have changed, or it never existed.';

  @override
  String get backHome => 'Back to the dashboard';

  @override
  String get openDocs => 'Docs';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navApps => 'Applications';

  @override
  String get navCredentials => 'Credentials';

  @override
  String get navSettings => 'Settings';

  @override
  String get sectionBuild => 'Build';

  @override
  String get sectionTeam => 'Team';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle =>
      'What shipped, what is shipping, what failed.';

  @override
  String get statApps => 'Applications';

  @override
  String get statReleasesMonth => 'Releases this month';

  @override
  String get statSuccessRate => 'Success rate';

  @override
  String get statRunning => 'Running now';

  @override
  String get recentReleases => 'Recent releases';

  @override
  String get viewAllApps => 'All applications';

  @override
  String get noReleasesYet => 'No releases yet';

  @override
  String get noReleasesYetMessage =>
      'Add an application and start a release. It takes about six minutes to reach the store.';

  @override
  String get gettingStarted => 'Getting started';

  @override
  String get stepAddApp => 'Add an application';

  @override
  String get stepAddAppBody =>
      'Connect the Git repository that holds the Flutter project.';

  @override
  String get stepAddCredentials => 'Add signing credentials';

  @override
  String get stepAddCredentialsBody =>
      'Upload the Android keystore and the App Store Connect API key.';

  @override
  String get stepRelease => 'Start a release';

  @override
  String get stepReleaseBody =>
      'Pick a platform, a track and a version. Watch the log live.';

  @override
  String get appsTitle => 'Applications';

  @override
  String appsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applications',
      one: '1 application',
      zero: 'No applications yet',
    );
    return '$_temp0';
  }

  @override
  String get addApplication => 'Add application';

  @override
  String get noAppsTitle => 'No applications yet';

  @override
  String get noAppsMessage =>
      'Connect the repository that holds your Flutter project. AppRelease scans it for apprelease.yaml.';

  @override
  String get lastRelease => 'Last release';

  @override
  String get never => 'never';

  @override
  String releasesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count releases',
      one: '1 release',
      zero: 'no releases',
    );
    return '$_temp0';
  }

  @override
  String get newAppTitle => 'Add application';

  @override
  String get newAppStepRepo => 'Repository';

  @override
  String get newAppStepDetails => 'Details';

  @override
  String get newAppStepPlatforms => 'Platforms';

  @override
  String get newAppRepoExplain =>
      'Enter the Git URL. A public HTTPS URL works as is; for a private repository add a deploy key to the repository afterwards.';

  @override
  String get repoUrl => 'Repository URL';

  @override
  String get repoUrlHint => 'https://github.com/acme/app.git';

  @override
  String get branch => 'Branch';

  @override
  String get appName => 'Application name';

  @override
  String get projectType => 'Project type';

  @override
  String get projectFlutter => 'Flutter';

  @override
  String get projectReactNative => 'React Native';

  @override
  String get projectReactNativeSoon => 'React Native (coming soon)';

  @override
  String get flutterVersion => 'Flutter version';

  @override
  String get flutterVersionHint => 'stable, beta, master, 3.41.2 or fvm';

  @override
  String get newAppPlatformsExplain =>
      'Which stores does this app ship to? You can change this later.';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get androidPackageName => 'Android package name';

  @override
  String get iosBundleId => 'iOS bundle identifier';

  @override
  String get finishAddApp => 'Finish: Add application';

  @override
  String get appAdded => 'Application added';

  @override
  String get pickAtLeastOnePlatform => 'Choose at least one platform';

  @override
  String get tabReleases => 'Releases';

  @override
  String get tabConfig => 'Config';

  @override
  String get tabSettings => 'Settings';

  @override
  String get startRelease => 'Start release';

  @override
  String get noReleasesForApp => 'This application has not been released yet.';

  @override
  String releaseNumber(int number) {
    return 'Release #$number';
  }

  @override
  String get configExplain =>
      'Commit this file as apprelease.yaml in the root of the repository. It is generated from the application\'s settings and the credentials you have added.';

  @override
  String get configMissingCredentials =>
      'Add credentials to fill in the signing and publishing sections.';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get appSettingsExplain =>
      'The runner reads these when a release starts.';

  @override
  String get deleteApp => 'Delete application';

  @override
  String deleteAppConfirm(String name) {
    return 'Delete $name? Its releases and logs are deleted with it. Credentials stay.';
  }

  @override
  String get appSaved => 'Saved';

  @override
  String get releaseTitle => 'Release';

  @override
  String get releaseTarget => 'Platform';

  @override
  String get releaseTrack => 'Track';

  @override
  String get releaseVersion => 'Version name';

  @override
  String get releaseBuildNumber => 'Build number';

  @override
  String get releaseBuildNumberHint =>
      'Left empty, the next number is taken from the store.';

  @override
  String releaseExplain(String branch) {
    return 'The runner checks out $branch, builds, signs and uploads. You can watch the log while it runs.';
  }

  @override
  String get releaseQueued => 'Release queued';

  @override
  String get cancelRelease => 'Cancel release';

  @override
  String get rerunRelease => 'Run again';

  @override
  String get releaseLog => 'Log';

  @override
  String get releaseSteps => 'Steps';

  @override
  String releaseStartedBy(String name) {
    return 'Started by $name';
  }

  @override
  String get releaseCommit => 'Commit';

  @override
  String get releaseDuration => 'Duration';

  @override
  String get releaseArtifacts => 'Artifacts';

  @override
  String get waitingForRunner => 'Waiting for a runner…';

  @override
  String get logEmpty => 'The log appears here as soon as the runner starts.';

  @override
  String get downloadLog => 'Download log';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusSucceeded => 'Published';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get stepPending => 'Pending';

  @override
  String get stepRunning => 'Running';

  @override
  String get stepSucceeded => 'Done';

  @override
  String get stepFailed => 'Failed';

  @override
  String get stepSkipped => 'Skipped';

  @override
  String get trackInternal => 'Internal testing';

  @override
  String get trackAlpha => 'Closed testing (alpha)';

  @override
  String get trackBeta => 'Open testing (beta)';

  @override
  String get trackProduction => 'Production';

  @override
  String get trackTestflight => 'TestFlight';

  @override
  String get trackAppStore => 'App Store review';

  @override
  String get credentialsTitle => 'Credentials';

  @override
  String get credentialsSubtitle =>
      'Signing keys and store access. Encrypted at rest, decrypted only on the runner.';

  @override
  String get addCredential => 'Add credential';

  @override
  String get noCredentialsTitle => 'No credentials yet';

  @override
  String get noCredentialsMessage =>
      'Add an Android keystore, a Google Play service account and an App Store Connect API key to publish.';

  @override
  String get kindAndroidKeystore => 'Android keystore';

  @override
  String get kindAndroidKeystoreBody =>
      'Signs the app bundle. Use the upload key.';

  @override
  String get kindGooglePlay => 'Google Play service account';

  @override
  String get kindGooglePlayBody =>
      'Uploads to Google Play and reads the latest build number.';

  @override
  String get kindAppStoreConnect => 'App Store Connect API key';

  @override
  String get kindAppStoreConnectBody =>
      'Signs iOS builds and uploads to TestFlight.';

  @override
  String get credentialName => 'Reference name';

  @override
  String get credentialNameHint =>
      'Used in apprelease.yaml, e.g. upload_keystore';

  @override
  String get chooseFile => 'Choose file';

  @override
  String fileChosen(String name, String size) {
    return '$name · $size';
  }

  @override
  String get keystorePassword => 'Keystore password';

  @override
  String get keyAlias => 'Key alias';

  @override
  String get keyPassword => 'Key password';

  @override
  String get serviceAccountJson => 'Service account JSON';

  @override
  String get serviceAccountJsonHint =>
      'Paste the contents of the JSON key file';

  @override
  String get issuerId => 'Issuer ID';

  @override
  String get keyId => 'Key ID';

  @override
  String get privateKeyP8 => 'Private key (.p8)';

  @override
  String get credentialAdded => 'Credential added';

  @override
  String get deleteCredential => 'Delete credential';

  @override
  String deleteCredentialConfirm(String name) {
    return 'Delete $name? Workflows that reference it will fail until it is replaced.';
  }

  @override
  String addedOn(String date) {
    return 'Added $date';
  }

  @override
  String get fileRequired => 'Choose a file';

  @override
  String get invalidJson => 'This is not valid JSON';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Your account and how the console looks.';

  @override
  String get profile => 'Profile';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountExplain =>
      'Deletes your account, applications, releases and credentials. This cannot be undone.';

  @override
  String get deleteAccountConfirm =>
      'Delete your account and everything in it?';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get backendLabel => 'Backend';

  @override
  String get backendLocal => 'Demo data (in memory)';

  @override
  String get backendSupabase => 'Supabase';

  @override
  String get enterCode => 'Enter the code';

  @override
  String codeSentTo(String email) {
    return 'We sent a six-digit code to $email. It is valid for one hour.';
  }

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Send a new code';

  @override
  String resendIn(int seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get changeEmail => 'Use a different email';

  @override
  String get codeResent => 'A new code is on its way';

  @override
  String get invalidCode => 'That code is not right';

  @override
  String get expiredCode => 'That code has expired. Request a new one.';

  @override
  String get demoCodeHint => 'Demo: the code is 123456';

  @override
  String get setupTitle => 'Set up your first release';

  @override
  String get setupSubtitle =>
      'Four things AppRelease needs before it can publish. Add them now or later; nothing here is lost.';

  @override
  String get setupItemApp => 'Your application';

  @override
  String get setupItemAppBody =>
      'The Git URL of the Flutter project, the branch to build, and the package name or bundle identifier.';

  @override
  String get setupItemKeystore => 'Android upload keystore';

  @override
  String get setupItemKeystoreBody =>
      'The .jks file plus its store password, key alias and key password. We never show it again, so keep your own copy.';

  @override
  String get setupItemPlay => 'Google Play service account';

  @override
  String get setupItemPlayBody =>
      'A JSON key from Google Cloud, invited in Play Console with release permissions. Needed to upload and to read the build number.';

  @override
  String get setupItemAsc => 'App Store Connect API key';

  @override
  String get setupItemAscBody =>
      'The .p8 file, its Key ID and the Issuer ID from App Store Connect → Users and Access → Integrations.';

  @override
  String get setupAdd => 'Add';

  @override
  String get setupDoneLabel => 'Done';

  @override
  String get setupFinish => 'Go to the dashboard';

  @override
  String get setupSkip => 'Skip for now';

  @override
  String get setupAllDone =>
      'Everything is in place. Open your application and start a release.';

  @override
  String setupProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get navSetup => 'Setup checklist';

  @override
  String get noRunnerTitle => 'No build machine is online';

  @override
  String get noRunnerBody =>
      'A release is built by a runner: a Mac (or, for Android only, a Linux machine) running the AppRelease runner. None has reported in during the last two minutes, so this release waits in the queue. To build on your own machine, open a terminal there and run:';

  @override
  String get noRunnerFoot =>
      'The runner picks the release up within a few seconds and streams the log here. Leave the window open while it builds.';

  @override
  String get runnerOnline => 'A runner is online';

  @override
  String get triggersTitle => 'Release on push';

  @override
  String get triggersExplain =>
      'Let GitHub start releases. Each rule says which branch goes where: for example develop to internal testing and TestFlight, main to production and App Store review. The version comes from pubspec.yaml.';

  @override
  String get triggerEnabled => 'Release automatically on push';

  @override
  String get triggerBranch => 'Branch';

  @override
  String get triggerPlatforms => 'Platforms to release';

  @override
  String get triggerTrackAndroid => 'Android track on push';

  @override
  String get triggerTrackIos => 'iOS destination on push';

  @override
  String get triggerTags => 'A tag like v1.2.0 releases to production';

  @override
  String get triggerTagsBody =>
      'Pushing a version tag queues a production release on Google Play and an App Store review submission, with the version from the tag.';

  @override
  String get webhookTitle => 'Connect GitHub';

  @override
  String get webhookHow =>
      'In the repository on GitHub open Settings → Webhooks → Add webhook. Payload URL and secret as below, content type application/json, event: just the push event.';

  @override
  String get webhookUrl => 'Payload URL';

  @override
  String get webhookSecret => 'Secret';

  @override
  String get webhookLocalNote =>
      'Webhooks need the live backend; in the demo nothing is posted.';

  @override
  String get versionAuto => 'from pubspec';

  @override
  String get playGuideTitle => 'How to get this file';

  @override
  String get playGuide1 =>
      'Create a service account in Google Cloud. Any project works; the name does not matter.';

  @override
  String get playGuide1Link => 'Open Google Cloud → Service accounts';

  @override
  String get playGuide2 =>
      'Open the account → Keys → Add key → Create new key → JSON. Pick that file below or paste its contents.';

  @override
  String get playGuide3 =>
      'Enable the Google Play Android Developer API in the same Cloud project.';

  @override
  String playGuide3Link(String project) {
    return 'Enable the API for project $project';
  }

  @override
  String get playGuide3LinkGeneric => 'Enable the API';

  @override
  String get playGuide4 =>
      'In Google Play Console → Users and permissions → Invite new users, invite this email with \"Release to production, exclude devices, and use Play App Signing\" and \"Release apps to testing tracks\" for your app.';

  @override
  String get playGuide4Link => 'Open Play Console → Users and permissions';

  @override
  String get playGuideEmail => 'Service account email';

  @override
  String get playGuideAfter =>
      'Press Check on the saved credential afterwards; it tells you if a step is still missing.';

  @override
  String get checkCredential => 'Check';

  @override
  String get checkingCredential => 'Checking with Google…';

  @override
  String get checkResultTitle => 'Google Play check';

  @override
  String get checkOk => 'Ready';

  @override
  String get checkFix => 'Open the page to fix it';

  @override
  String checkFailed(String error) {
    return 'The check could not run: $error';
  }

  @override
  String get ascGuideTitle => 'How to get this key';

  @override
  String get ascGuide1 =>
      'In App Store Connect open Users and Access → Integrations → App Store Connect API and press \"+\" next to Active keys. Needs the Account Holder or an Admin.';

  @override
  String get ascGuide1Link => 'Open App Store Connect → Integrations';

  @override
  String get ascGuide2 =>
      'Name it AppRelease, choose the App Manager role, Generate. Then Download API Key: the .p8 can be downloaded only once, keep it.';

  @override
  String get ascGuide3 =>
      'Copy the Issuer ID shown above the table and the Key ID from the key\'s row into the fields below, and pick the .p8 file.';

  @override
  String get ascGuide4 =>
      'The app itself must exist in App Store Connect with the same bundle identifier; AppRelease uploads builds, it does not create app records.';

  @override
  String get ascGuide4Link => 'Open App Store Connect → Apps';

  @override
  String get ascGuideAfter =>
      'Press Check on the saved credential afterwards; it tells you if Apple accepts the key for your apps.';

  @override
  String get checkResultTitleAsc => 'App Store Connect check';

  @override
  String pushRuleTitle(int n) {
    return 'Rule $n';
  }

  @override
  String get pushRuleBranchHelper =>
      'A branch name, or a prefix with * such as release/*';

  @override
  String get addPushRule => 'Add a branch';

  @override
  String get removePushRule => 'Remove rule';

  @override
  String get pushRuleNoPlatforms => 'Pick at least one platform for this rule.';

  @override
  String pushRuleDuplicate(String branch) {
    return 'Two rules use the branch $branch.';
  }

  @override
  String get credentialApp => 'App';

  @override
  String get credentialAppHelper =>
      'The app this key signs. Leave it shared if several apps use it.';

  @override
  String get credentialShared => 'Shared';

  @override
  String get credentialSharedKeys => 'Shared keys';

  @override
  String get linkToApp => 'Link to app';

  @override
  String get keystoresTitle => 'Android keystores';

  @override
  String appKeystores(String app) {
    return '$app';
  }

  @override
  String get noKeystoreForApp => 'No keystore yet for this app.';

  @override
  String appReleasesSummary(int count, String ago) {
    return '$count releases · last $ago';
  }

  @override
  String allReleasesOfApp(int count) {
    return 'All $count releases';
  }
}
