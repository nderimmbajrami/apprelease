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
      'Build, sign and publish Flutter apps to Google Play and the App Store straight from your Git repository. No pipeline to write.';

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
  String get invalidRepoUrl =>
      'Use the address of one repository, e.g. https://github.com/acme/shop-app';

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
      'Connect the repository that holds your Flutter project. No configuration file is needed; the settings here are the build.';

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
  String get startRelease => 'Publish';

  @override
  String get noReleasesForApp => 'This application has not been released yet.';

  @override
  String releaseNumber(int number) {
    return 'Release #$number';
  }

  @override
  String get configExplain =>
      'Optional. The runner builds with the settings of this application. Commit this file as apprelease.yaml in the root of the repository only if you want to change how it builds; it is generated from the settings and the credentials, so it is a correct starting point.';

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
      'Each step opens the form it needs and shows where to get the key. Do them now or later; nothing here is lost.';

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
  String get runnerOnline => 'A runner is online';

  @override
  String get triggersTitle => 'Release on push';

  @override
  String get triggersExplain =>
      'Let GitHub start releases. Each rule says which branch goes where: for example develop to internal testing and TestFlight, main to production and App Store review, ready-for-qa as a QA build to your testers in Slack. The version comes from pubspec.yaml.';

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
      'Open the account → Keys → Add key → Create new key → JSON. Pick that file below or paste its contents. If Google says key creation is disabled, your company organization blocks it: an admin turns off the \"Disable service account key creation\" policy, or you create the project from a personal Gmail account instead.';

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
      'In Google Play Console → Users and permissions → Invite new users, invite the service account\'s own email, the one ending in .iam.gserviceaccount.com from the JSON file, not your Google account. Give it \"Release to production, exclude devices, and use Play App Signing\" and \"Release apps to testing tracks\" for your app.';

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

  @override
  String get queueShort => 'Waiting in line…';

  @override
  String queueInLineTitle(int position) {
    return 'Number $position in line';
  }

  @override
  String queueInLineBody(int ahead, int minutes, String platform) {
    String _temp0 = intl.Intl.pluralLogic(
      ahead,
      locale: localeName,
      other: '$ahead releases go before yours.',
      one: 'One release goes before yours.',
      zero: 'The build machine is finishing another release.',
    );
    return '$_temp0 Your $platform build should start in about $minutes min. You can close this page; the release carries on without it.';
  }

  @override
  String get queueStartingTitle => 'Starting now';

  @override
  String get queueStartingBody =>
      'A build machine is free and picks this release up in a few seconds.';

  @override
  String get queueOfflineTitle => 'The build machines are offline for a moment';

  @override
  String get queueOfflineBody =>
      'Your release is safe in the queue and starts by itself as soon as a machine is back. Nothing to do on your side.';

  @override
  String get exampleApplicationId =>
      'com.example is Flutter\'s placeholder. Use your app\'s real id, as in Google Play or App Store Connect.';

  @override
  String get readyRepository => 'Repository';

  @override
  String get readyRepositoryOk => 'The runner can find the code.';

  @override
  String get readyRepositoryMissing =>
      'Set the address of one repository, e.g. https://github.com/acme/shop-app.';

  @override
  String get readyAndroidPackage => 'Android package name';

  @override
  String get readyAndroidPackageOk => 'Matches the app in Google Play.';

  @override
  String get readyAndroidPackageMissing =>
      'Use the package name of the app in Google Play, not com.example.';

  @override
  String get readyIosBundle => 'iOS bundle identifier';

  @override
  String get readyIosBundleOk => 'Matches the app in App Store Connect.';

  @override
  String get readyIosBundleMissing =>
      'Use the bundle identifier of the app in App Store Connect, not com.example.';

  @override
  String get readyKeystore => 'Android upload keystore';

  @override
  String get readyKeystoreOk => 'Signs the app bundle.';

  @override
  String get readyKeystoreMissing =>
      'Upload the .jks file the app is signed with.';

  @override
  String get readyGooglePlay => 'Google Play access';

  @override
  String get readyGooglePlayOk => 'A service account can upload for you.';

  @override
  String get readyGooglePlayMissing =>
      'Add a Google Play service account. The form shows each step.';

  @override
  String get readyAppStoreConnect => 'App Store Connect key';

  @override
  String get readyAppStoreConnectOk => 'Apple accepts uploads with this key.';

  @override
  String get readyAppStoreConnectMissing =>
      'Add an App Store Connect API key. The form shows each step.';

  @override
  String get readyFix => 'Fix';

  @override
  String get readyFixSettings => 'Open settings';

  @override
  String get readyAll => 'Everything this release needs is in place.';

  @override
  String readyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things to fix before this release can start',
      one: '1 thing to fix before this release can start',
    );
    return '$_temp0';
  }

  @override
  String get startReleaseChecks => 'What it needs';

  @override
  String get startReleaseWhere => 'Where it goes';

  @override
  String get invalidBuildNumber => 'A whole number above 0, or leave it empty.';

  @override
  String tourStepOf(int n, int total) {
    return '$n of $total';
  }

  @override
  String get tourSkip => 'Skip tour';

  @override
  String get tourBack => 'Back';

  @override
  String get tourNext => 'Next';

  @override
  String get tourDone => 'Got it';

  @override
  String get tourTake => 'Take the tour';

  @override
  String get tourChecklistTitle => 'Your launch checklist';

  @override
  String get tourChecklistBody =>
      'Everything between you and the first build in the stores, in order. Each row opens the form it needs and shows where to get the key.';

  @override
  String get tourAppsTitle => 'Applications';

  @override
  String get tourAppsBody =>
      'One app is one repository. Its settings hold the package name, the branches that release on push and the webhook for GitHub.';

  @override
  String get tourCredentialsTitle => 'Credentials';

  @override
  String get tourCredentialsBody =>
      'Your Android keystore and the access keys for Google Play and the App Store. Encrypted, and opened only on the build machine for one build.';

  @override
  String get tourAddAppTitle => 'Start here';

  @override
  String get tourAddAppBody =>
      'Paste the repository address of your Flutter app. We guess the name; you add the package name and bundle identifier.';

  @override
  String get tourReleasesTitle => 'Your releases, per app';

  @override
  String get tourReleasesBody =>
      'Where each store stands now and the last runs. Anything that would stop a release is listed here with a button to fix it.';

  @override
  String get launchTitle => 'Launch checklist';

  @override
  String launchSubtitle(int done, int total) {
    return '$done of $total done. Each step opens the form it needs and shows where to get the key.';
  }

  @override
  String get launchApp => 'Add your application';

  @override
  String get launchAppBody =>
      'Tell us where the code is. Nothing is built yet.';

  @override
  String launchAppFix(String app) {
    return '$app: the repository address or a package name needs fixing before it can build.';
  }

  @override
  String get launchKeystoreBody =>
      'The key your Android app is signed with. Google accepts updates only when they are signed with the same key as the first version.';

  @override
  String get launchPlayBody =>
      'Permission for AppRelease to upload to your Play Console, through a Google service account.';

  @override
  String get launchAscBody =>
      'Permission for AppRelease to upload to App Store Connect, through an API key.';

  @override
  String get launchFirstRelease => 'Publish your first release';

  @override
  String get launchFirstReleaseBody =>
      'Pick a platform and a track. You watch the build live.';

  @override
  String get launchFirstReleaseWaiting =>
      'Opens once an app has everything a release needs.';

  @override
  String get launchUpload => 'Upload';

  @override
  String get launchConnect => 'Connect';

  @override
  String get appNoReleasesYet => 'No releases yet';

  @override
  String appBlocked(String platform, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things to fix before it can release',
      one: '1 thing to fix before it can release',
    );
    return '$platform: $_temp0';
  }

  @override
  String get appReadyFirstRelease => 'Ready for its first release.';

  @override
  String get appFixFirst =>
      'Fix the items above, or open the release dialog to see them all.';

  @override
  String releaseLatestOn(String branch) {
    return 'Latest on $branch';
  }

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String queueWaiting(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n releases waiting',
      one: '1 release waiting',
    );
    return '$_temp0';
  }

  @override
  String queueOlder(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n of them are older pushes. The newest ones build the same branches, so they are not needed.',
      one:
          '1 of them is an older push. The newest one builds the same branch, so it is not needed.',
    );
    return '$_temp0';
  }

  @override
  String get queueAllLatest =>
      'Each one is the latest of its branch and platform.';

  @override
  String get queueKeepLatest => 'Keep latest only';

  @override
  String get queueClear => 'Clear queue';

  @override
  String get queueClearTitle => 'Clear the queue?';

  @override
  String queueClearBody(int n, String app) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'All $n waiting releases of $app are removed.',
      one: 'The waiting release of $app is removed.',
    );
    return '$_temp0 A build already running carries on.';
  }

  @override
  String queueRemoved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Removed $n releases from the queue',
      one: 'Removed 1 release from the queue',
    );
    return '$_temp0';
  }

  @override
  String usageLine(int used, int limit) {
    return '$used of $limit releases used this month';
  }

  @override
  String usageExhausted(int limit, String date) {
    return 'All $limit releases of this month are used. More on $date, or ask us for a bigger plan.';
  }

  @override
  String get releaseStartFailed =>
      'The release could not be queued. Check your connection and try again.';

  @override
  String get guideTitle => 'How to get it';

  @override
  String guideMinutes(int n) {
    return 'about $n min';
  }

  @override
  String get guideFull => 'Full guide';

  @override
  String get guideVideo => 'Watch a video';

  @override
  String get guideWithUs => 'Set it up with us';

  @override
  String get guideKeystore1 =>
      'Already on Google Play? Use the same upload keystore (.jks) you used before. Google accepts only that key.';

  @override
  String get guideKeystore2 =>
      'New app? Create one in a terminal: keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload';

  @override
  String get guideKeystore3 =>
      'Write down the keystore password, the key alias (upload) and the key password.';

  @override
  String get guideKeystore4 =>
      'Drop the .jks file below and type the three values. We check them against the file before saving.';

  @override
  String get guideKeystoreNote =>
      'Keep a copy of the file somewhere safe. Losing it means asking Google to reset your upload key.';

  @override
  String get guidePlay1 =>
      'In Google Cloud Console, pick or create a project and enable the Google Play Android Developer API.';

  @override
  String get guidePlay2 =>
      'IAM & Admin → Service accounts → Create service account. It needs no roles there.';

  @override
  String get guidePlay3 =>
      'Open the new account → Keys → Add key → JSON. A .json file downloads.';

  @override
  String get guidePlay4 =>
      'In Play Console → Users and permissions → Invite new users: paste the service account\'s email (ends in .iam.gserviceaccount.com, from the JSON), not your own, and give it release permissions for your app.';

  @override
  String get guidePlay5 => 'Upload the .json file below.';

  @override
  String get guidePlayNote =>
      'The app must already exist in Play Console, with its first build uploaded by hand once. A new key can take a few hours before Google accepts it.';

  @override
  String get guideAsc1 =>
      'App Store Connect → Users and Access → Integrations → App Store Connect API.';

  @override
  String get guideAsc2 => 'Generate a key with the App Manager role.';

  @override
  String get guideAsc3 =>
      'Download the .p8 file. Apple lets you download it only once.';

  @override
  String get guideAsc4 =>
      'Copy the Key ID (next to the key) and the Issuer ID (top of the page).';

  @override
  String get guideAsc5 => 'Upload the .p8 file below with both IDs.';

  @override
  String get guideAscNote =>
      'The app must already exist in App Store Connect with the same bundle ID as your project.';

  @override
  String get setupHelpTitle => 'Stuck on the keys? We set it up with you.';

  @override
  String get setupHelpBody =>
      'A free 20-minute screen share: we create the keystore, the Google Play and App Store keys with you, and run your first release together.';

  @override
  String get credentialSecurityTitle => 'Encrypted and never shown again';

  @override
  String get credentialSecurityBody =>
      'Encrypted with AES before it is stored, with a key that is not in the database. Not even this console can read it back. Only the build machine decrypts it, for one release, then deletes it. Passwords never appear in logs.';

  @override
  String get credentialSecurityMore => 'How we protect it';

  @override
  String get playGuideEmailPending =>
      'The email to invite appears here once you pick the JSON file.';

  @override
  String get launchWhere => 'Where do you publish?';

  @override
  String get launchWhereHint =>
      'Pick the stores you use. The other one can be added any time.';

  @override
  String get storeGooglePlay => 'Google Play';

  @override
  String get storeAppStore => 'App Store';

  @override
  String get launchSectionApp => 'Your app';

  @override
  String get launchSectionPlay => 'Google Play';

  @override
  String get launchSectionAppStore => 'App Store';

  @override
  String get launchAppNeeds =>
      'You need: the Git address of your Flutter project, and the package name from Google Play or the bundle ID from App Store Connect.';

  @override
  String get launchKeystoreNeeds =>
      'You need: the .jks file, its password, the key alias and the key password. New app? The form shows how to create one.';

  @override
  String get launchPlayNeeds =>
      'You need: a Google account. The form walks you through Google Cloud and Play Console, click by click.';

  @override
  String get launchAscNeeds =>
      'You need: the Account Holder or an Admin of your Apple developer account; only they can create the key. The form has the message to send them.';

  @override
  String get launchPublishPlay => 'Publish to Google Play';

  @override
  String get launchPublishPlayBody =>
      'We download your code, build it, sign it with your key and upload it to Internal testing in Play Console. You watch every step; nothing reaches your users until you promote it.';

  @override
  String get launchPublishAppStore => 'Publish to App Store';

  @override
  String get launchPublishAppStoreBody =>
      'We build and sign your app and upload it to TestFlight. You watch every step; nothing reaches your users until you submit it for review.';

  @override
  String get launchPublishWaiting => 'Opens once the steps above are done.';

  @override
  String launchMinutes(int n) {
    return '~$n min';
  }

  @override
  String releaseWhatHappens(String where, int minutes) {
    return 'What happens next: we download your code, build it, sign it with your key and upload it to $where. About $minutes minutes; you can watch every step. Nothing reaches your users until you release it in the store.';
  }

  @override
  String get kindBuildFile => 'Build file (optional)';

  @override
  String get kindBuildFileBody =>
      'Optional. Only for a build that needs a file the repository leaves out, for example google-services.json if the app uses Firebase, GoogleService-Info.plist, or a .env. Kept encrypted; written into the checkout right before the build and deleted with it.';

  @override
  String get anyFile => 'Any file';

  @override
  String get buildFilePath => 'Where it goes in the repository';

  @override
  String get buildFilePathHelper =>
      'Relative to the repository root, as the build expects it.';

  @override
  String get buildFilePathInside =>
      'Use a path inside the repository, without a leading slash or ..';

  @override
  String get guideFile1 =>
      'Skip this if every file the build needs is in Git. Otherwise pick the file from your project, for example android/app/google-services.json if the app uses Firebase.';

  @override
  String get guideFile2 =>
      'Check the path: it is where the file sits in the repository, relative to its root. Common files are filled in for you.';

  @override
  String get guideFile3 =>
      'Choose the application it belongs to, or leave it shared, and save. Every build of that app gets the file.';

  @override
  String get guideFileNote =>
      'Apps without Firebase build fine without any file here. A build that fails with \'google-services.json is missing\' needs exactly this: the file is in your .gitignore, so the build machine never gets it from Git.';

  @override
  String logQuiet(String since) {
    return 'Still running. No output for $since: Gradle and Xcode print nothing while they compile, and this step usually takes 2 to 6 minutes.';
  }

  @override
  String get trackQa => 'QA build (APK to Slack)';

  @override
  String get trackQaTestflight => 'QA build (TestFlight + Slack)';

  @override
  String get qaWhatHappensAndroid =>
      'What happens next: we download your code, build a signed APK and post it to your Slack channel with the version and build number. The Jira tickets named in the last commit message (like DAMA-123) move to your QA status. Nothing goes to Google Play. About 10 minutes.';

  @override
  String get qaWhatHappensIos =>
      'What happens next: we download your code, build it and upload it to TestFlight, then tell your Slack channel the version and build number. The Jira tickets named in the last commit message (like DAMA-123) move to your QA status. Nothing is sent to App Store review. About 15 minutes.';

  @override
  String get readySlack => 'Slack channel for QA';

  @override
  String get readySlackOk => 'QA builds are posted to your channel.';

  @override
  String get readySlackMissing =>
      'Add a Slack connection: the bot token and the channel the build goes to.';

  @override
  String get kindSlack => 'Slack (QA builds)';

  @override
  String get kindSlackBody =>
      'Where QA builds are announced: the Android APK is posted to this channel, an iOS build is announced once it is on TestFlight.';

  @override
  String get kindJira => 'Jira (QA tickets)';

  @override
  String get kindJiraBody =>
      'Moves the tickets named in the last commit message (like DAMA-123) to your QA status once a QA build went out.';

  @override
  String get credentialAppHelperQa =>
      'The app whose QA builds use this. Leave it shared if every app goes to the same place.';

  @override
  String get slackToken => 'Bot User OAuth Token';

  @override
  String get slackTokenHelper =>
      'Slack app → OAuth & Permissions. Starts with xoxb-.';

  @override
  String get slackTokenInvalid => 'A bot token starts with xoxb-.';

  @override
  String get slackChannel => 'Channel ID';

  @override
  String get slackChannelHelper =>
      'In Slack, open the channel details: the ID is at the bottom. Not the #name.';

  @override
  String get slackChannelInvalid =>
      'The channel ID looks like C0123ABCDEF. It is at the bottom of the channel details.';

  @override
  String get jiraSite => 'Jira site';

  @override
  String get jiraSiteHelper =>
      'The start of the address in your browser when Jira is open, up to .atlassian.net.';

  @override
  String get jiraTokenHelper =>
      'From id.atlassian.com → Security → API tokens → Create API token (without scopes).';

  @override
  String get jiraSiteInvalid =>
      'The address of your Jira, like https://your-team.atlassian.net';

  @override
  String get jiraEmail => 'Atlassian account email';

  @override
  String get jiraEmailHelper =>
      'The email you sign in to Jira with, on the account that made the token. That account needs permission to move tickets.';

  @override
  String get jiraToken => 'API token';

  @override
  String get jiraStatus => 'Status to move tickets to';

  @override
  String get jiraStatusHelper =>
      'Open a ticket in Jira and click its status: type the name exactly as that list shows it.';

  @override
  String get jiraProjects => 'Project keys (optional)';

  @override
  String get jiraProjectsHelper =>
      'The letters before a ticket\'s number on your board: DAMA for DAMA-123. Only tickets of these projects are moved. Empty: any ticket named in a commit.';

  @override
  String get checkingConnection => 'Checking the connection…';

  @override
  String get checkResultTitleSlack => 'Slack check';

  @override
  String get checkResultTitleJira => 'Jira check';

  @override
  String get guideSlack1 =>
      'Open api.slack.com/apps. On the page Your Apps, click Create New App.';

  @override
  String get guideSlack2 =>
      'Window “Create new app”: under From scratch, click Paste a manifest, then Continue. Do not pick AI agent or Starter app: they add code this does not need.';

  @override
  String get guideSlack3 =>
      'Window “Create from a manifest”: on the JSON tab, select everything in the box and replace it with this text:';

  @override
  String get guideSlack4 =>
      'Same window: under Workspace, choose your workspace. Click Next, then Create.';

  @override
  String get guideSlack5 =>
      'Page “Allow AppRelease to access Slack”: it lists two actions, send messages and upload files. Click Allow.';

  @override
  String get guideSlack6 =>
      'Window “AppRelease is ready!”: click the copy icon next to Bot token (starts with xoxb-) and paste it below. Ignore the App token and the steps under it (Install Slack CLI and so on), then close the window.';

  @override
  String get guideSlack7 =>
      'In Slack, in the channel where QA should get builds: send /invite @AppRelease. The bot posts only in channels it is invited to and cannot read messages.';

  @override
  String get guideSlack8 =>
      'Same channel: click its name at the top. In the window that opens, the Channel ID is at the bottom (like C0123ABCDEF). Paste it below.';

  @override
  String get guideSlackNote =>
      'Then add a branch under the application\'s settings, for example ready-for-qa, and choose QA build for Android and iOS.';

  @override
  String get guideJira1 =>
      'Open id.atlassian.com/manage-profile/security/api-tokens. On the page API Tokens, click Create API token: the left button, not the one with scopes.';

  @override
  String get guideJira2 =>
      'Window “Create an API token”: as Name type AppRelease. As Expires on pick the latest date allowed, one year from today. Click Create.';

  @override
  String get guideJira3 =>
      'The next window shows the token. Copy it, Atlassian shows it only once, and paste it below under API token.';

  @override
  String get guideJira4 =>
      'Jira site: the start of the address in your browser when Jira is open, like https://your-team.atlassian.net.';

  @override
  String get guideJira5 =>
      'Atlassian account email: the email you sign in to Jira with. You can read it at id.atlassian.com/manage-profile/email.';

  @override
  String get guideJira6 =>
      'Status to move tickets to: open any ticket in Jira and click its status. Type the one QA tickets should get exactly as written there, for example Ready for QA.';

  @override
  String get guideJira7 =>
      'Project keys (optional): the letters before a ticket\'s number, DAMA for DAMA-123. Fill it in to move tickets of that project only. Empty: any ticket named in a commit is moved.';

  @override
  String get guideJira8 =>
      'Save, then click Check on the saved connection. It confirms the account and the status without moving a ticket.';

  @override
  String get guideJiraNote =>
      'To use it, put the ticket key in the commit you push to the QA branch, like \"DAMA-123 fix login\". The ticket moves once the build is in Slack. The token stops working on its expiry date: create a new one before then and save it here.';

  @override
  String get navPreview => 'On my phone';

  @override
  String get trackPreview => 'Preview on a phone';

  @override
  String get previewTitle => 'See your app on your phone';

  @override
  String previewNewVersionTitle(String name) {
    return 'New version of $name';
  }

  @override
  String get previewSubtitle =>
      'Upload your Flutter project as a zip. You get two QR codes back: one installs the app on an Android phone, one opens it on an iPhone.';

  @override
  String get previewHowTitle => 'How to make the zip';

  @override
  String get previewHow1 =>
      'Find your project folder on your computer: the one that has a file named pubspec.yaml in it.';

  @override
  String get previewHow2 =>
      'If there is a folder named build inside it, delete that folder. It is large and gets made again.';

  @override
  String get previewHow3 =>
      'Zip the project folder. On a Mac: right-click it and choose Compress. On Windows: right-click it, Send to, Compressed (zipped) folder.';

  @override
  String get previewHow4 =>
      'Choose the zip below and click Build my app. It takes about ten minutes; you can watch it happen.';

  @override
  String get previewName => 'Name of your app';

  @override
  String get previewNameHelper =>
      'Only for this console. Filled in from the zip\'s name.';

  @override
  String get previewChoose => 'Choose the zip';

  @override
  String get previewNoFile => 'No file chosen yet';

  @override
  String get previewBuild => 'Build my app';

  @override
  String get previewUploading => 'Uploading…';

  @override
  String get previewChooseFirst => 'Choose the zip of your project first.';

  @override
  String get previewNotZip =>
      'That is not a zip file. Compress the project folder and choose the file that ends in .zip.';

  @override
  String previewTooLarge(int mb) {
    return 'The zip is $mb MB; the limit is 50 MB. Delete the folder named build inside your project, zip it again and choose the new file.';
  }

  @override
  String get previewNotEnabled =>
      'Previews are switched on per account while they are new. Write to publish@apprelease.store and we switch yours on.';

  @override
  String get previewUploadFailed =>
      'The zip could not be uploaded. Check your connection and try again.';

  @override
  String get previewFailed =>
      'The build could not be started. Try again in a moment.';

  @override
  String get releaseLimitReached =>
      'You have used all of this month\'s builds.';

  @override
  String get previewNote =>
      'Flutter projects only. On Android the real app is installed. Apple does not allow installing an app outside the App Store, so on an iPhone the app opens in the browser; a few features that need the phone itself, like the camera or notifications, may not work there. Both links stay online for 7 days.';

  @override
  String get previewUploadNew => 'Upload a new version';

  @override
  String get previewUploadedProject => 'Uploaded project';

  @override
  String get previewReadyTitle => 'Your app is ready';

  @override
  String get previewReadyBody =>
      'Point your phone\'s camera at the code that matches your phone.';

  @override
  String get previewAndroidTitle => 'Android';

  @override
  String get previewAndroidBody =>
      'Scan, download the file and open it. Android asks once to allow installing from your browser: allow it, then tap Install.';

  @override
  String get previewIphoneTitle => 'iPhone';

  @override
  String get previewIphoneBody =>
      'Scan and the app opens in Safari. To keep it on the home screen: Share, then Add to Home Screen.';

  @override
  String get previewNoWeb =>
      'The iPhone link could not be made: this project uses something that does not run in a browser. The log says what.';

  @override
  String get previewCopyLink => 'Copy link';

  @override
  String get previewOpenLink => 'Open';
}
