import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AppRelease'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Ship your Flutter app to both stores.'**
  String get appTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get noAccountYet;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInExplain.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the release console.'**
  String get signInExplain;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @signUpExplain.
  ///
  /// In en, this message translates to:
  /// **'Free plan, no credit card. We email you a code to confirm the address.'**
  String get signUpExplain;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo: demo@apprelease.store / demo1234'**
  String get demoHint;

  /// No description provided for @fillDemo.
  ///
  /// In en, this message translates to:
  /// **'Fill demo account'**
  String get fillDemo;

  /// No description provided for @authPitch.
  ///
  /// In en, this message translates to:
  /// **'Build, sign and publish Flutter apps to Google Play and the App Store from one apprelease.yaml.'**
  String get authPitch;

  /// No description provided for @authPoint1.
  ///
  /// In en, this message translates to:
  /// **'Managed code signing for Android and iOS'**
  String get authPoint1;

  /// No description provided for @authPoint2.
  ///
  /// In en, this message translates to:
  /// **'Build numbers taken straight from the store'**
  String get authPoint2;

  /// No description provided for @authPoint3.
  ///
  /// In en, this message translates to:
  /// **'Live logs, release history, email when it is done'**
  String get authPoint3;

  /// No description provided for @authFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Flutter first. React Native next.'**
  String get authFooterNote;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password'**
  String get invalidCredentials;

  /// No description provided for @emailAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailAlreadyUsed;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a longer password'**
  String get weakPassword;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check the network and try again.'**
  String get networkError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownError;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @invalidRepoUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a Git URL (https:// or git@)'**
  String get invalidRepoUrl;

  /// No description provided for @invalidApplicationId.
  ///
  /// In en, this message translates to:
  /// **'Use reverse-domain form, e.g. com.example.app'**
  String get invalidApplicationId;

  /// No description provided for @invalidVersion.
  ///
  /// In en, this message translates to:
  /// **'Use the form 1.2.3'**
  String get invalidVersion;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The address may have changed, or it never existed.'**
  String get notFoundMessage;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to the dashboard'**
  String get backHome;

  /// No description provided for @openDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get openDocs;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navApps.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get navApps;

  /// No description provided for @navCredentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get navCredentials;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @sectionBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get sectionBuild;

  /// No description provided for @sectionTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get sectionTeam;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What shipped, what is shipping, what failed.'**
  String get dashboardSubtitle;

  /// No description provided for @statApps.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get statApps;

  /// No description provided for @statReleasesMonth.
  ///
  /// In en, this message translates to:
  /// **'Releases this month'**
  String get statReleasesMonth;

  /// No description provided for @statSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get statSuccessRate;

  /// No description provided for @statRunning.
  ///
  /// In en, this message translates to:
  /// **'Running now'**
  String get statRunning;

  /// No description provided for @recentReleases.
  ///
  /// In en, this message translates to:
  /// **'Recent releases'**
  String get recentReleases;

  /// No description provided for @viewAllApps.
  ///
  /// In en, this message translates to:
  /// **'All applications'**
  String get viewAllApps;

  /// No description provided for @noReleasesYet.
  ///
  /// In en, this message translates to:
  /// **'No releases yet'**
  String get noReleasesYet;

  /// No description provided for @noReleasesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an application and start a release. It takes about six minutes to reach the store.'**
  String get noReleasesYetMessage;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get gettingStarted;

  /// No description provided for @stepAddApp.
  ///
  /// In en, this message translates to:
  /// **'Add an application'**
  String get stepAddApp;

  /// No description provided for @stepAddAppBody.
  ///
  /// In en, this message translates to:
  /// **'Connect the Git repository that holds the Flutter project.'**
  String get stepAddAppBody;

  /// No description provided for @stepAddCredentials.
  ///
  /// In en, this message translates to:
  /// **'Add signing credentials'**
  String get stepAddCredentials;

  /// No description provided for @stepAddCredentialsBody.
  ///
  /// In en, this message translates to:
  /// **'Upload the Android keystore and the App Store Connect API key.'**
  String get stepAddCredentialsBody;

  /// No description provided for @stepRelease.
  ///
  /// In en, this message translates to:
  /// **'Start a release'**
  String get stepRelease;

  /// No description provided for @stepReleaseBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a platform, a track and a version. Watch the log live.'**
  String get stepReleaseBody;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get appsTitle;

  /// No description provided for @appsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applications yet} =1{1 application} other{{count} applications}}'**
  String appsSubtitle(int count);

  /// No description provided for @addApplication.
  ///
  /// In en, this message translates to:
  /// **'Add application'**
  String get addApplication;

  /// No description provided for @noAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get noAppsTitle;

  /// No description provided for @noAppsMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect the repository that holds your Flutter project. AppRelease scans it for apprelease.yaml.'**
  String get noAppsMessage;

  /// No description provided for @lastRelease.
  ///
  /// In en, this message translates to:
  /// **'Last release'**
  String get lastRelease;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get never;

  /// No description provided for @releasesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no releases} =1{1 release} other{{count} releases}}'**
  String releasesCount(int count);

  /// No description provided for @newAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Add application'**
  String get newAppTitle;

  /// No description provided for @newAppStepRepo.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get newAppStepRepo;

  /// No description provided for @newAppStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get newAppStepDetails;

  /// No description provided for @newAppStepPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get newAppStepPlatforms;

  /// No description provided for @newAppRepoExplain.
  ///
  /// In en, this message translates to:
  /// **'Enter the Git URL. A public HTTPS URL works as is; for a private repository add a deploy key to the repository afterwards.'**
  String get newAppRepoExplain;

  /// No description provided for @repoUrl.
  ///
  /// In en, this message translates to:
  /// **'Repository URL'**
  String get repoUrl;

  /// No description provided for @repoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/acme/app.git'**
  String get repoUrlHint;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Application name'**
  String get appName;

  /// No description provided for @projectType.
  ///
  /// In en, this message translates to:
  /// **'Project type'**
  String get projectType;

  /// No description provided for @projectFlutter.
  ///
  /// In en, this message translates to:
  /// **'Flutter'**
  String get projectFlutter;

  /// No description provided for @projectReactNative.
  ///
  /// In en, this message translates to:
  /// **'React Native'**
  String get projectReactNative;

  /// No description provided for @projectReactNativeSoon.
  ///
  /// In en, this message translates to:
  /// **'React Native (coming soon)'**
  String get projectReactNativeSoon;

  /// No description provided for @flutterVersion.
  ///
  /// In en, this message translates to:
  /// **'Flutter version'**
  String get flutterVersion;

  /// No description provided for @flutterVersionHint.
  ///
  /// In en, this message translates to:
  /// **'stable, beta, master, 3.41.2 or fvm'**
  String get flutterVersionHint;

  /// No description provided for @newAppPlatformsExplain.
  ///
  /// In en, this message translates to:
  /// **'Which stores does this app ship to? You can change this later.'**
  String get newAppPlatformsExplain;

  /// No description provided for @platformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get platformAndroid;

  /// No description provided for @platformIos.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get platformIos;

  /// No description provided for @androidPackageName.
  ///
  /// In en, this message translates to:
  /// **'Android package name'**
  String get androidPackageName;

  /// No description provided for @iosBundleId.
  ///
  /// In en, this message translates to:
  /// **'iOS bundle identifier'**
  String get iosBundleId;

  /// No description provided for @finishAddApp.
  ///
  /// In en, this message translates to:
  /// **'Finish: Add application'**
  String get finishAddApp;

  /// No description provided for @appAdded.
  ///
  /// In en, this message translates to:
  /// **'Application added'**
  String get appAdded;

  /// No description provided for @pickAtLeastOnePlatform.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one platform'**
  String get pickAtLeastOnePlatform;

  /// No description provided for @tabReleases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get tabReleases;

  /// No description provided for @tabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get tabConfig;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @startRelease.
  ///
  /// In en, this message translates to:
  /// **'Start release'**
  String get startRelease;

  /// No description provided for @noReleasesForApp.
  ///
  /// In en, this message translates to:
  /// **'This application has not been released yet.'**
  String get noReleasesForApp;

  /// No description provided for @releaseNumber.
  ///
  /// In en, this message translates to:
  /// **'Release #{number}'**
  String releaseNumber(int number);

  /// No description provided for @configExplain.
  ///
  /// In en, this message translates to:
  /// **'Commit this file as apprelease.yaml in the root of the repository. It is generated from the application\'s settings and the credentials you have added.'**
  String get configExplain;

  /// No description provided for @configMissingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Add credentials to fill in the signing and publishing sections.'**
  String get configMissingCredentials;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @appSettingsExplain.
  ///
  /// In en, this message translates to:
  /// **'The runner reads these when a release starts.'**
  String get appSettingsExplain;

  /// No description provided for @deleteApp.
  ///
  /// In en, this message translates to:
  /// **'Delete application'**
  String get deleteApp;

  /// No description provided for @deleteAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Its releases and logs are deleted with it. Credentials stay.'**
  String deleteAppConfirm(String name);

  /// No description provided for @appSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get appSaved;

  /// No description provided for @releaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get releaseTitle;

  /// No description provided for @releaseTarget.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get releaseTarget;

  /// No description provided for @releaseTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get releaseTrack;

  /// No description provided for @releaseVersion.
  ///
  /// In en, this message translates to:
  /// **'Version name'**
  String get releaseVersion;

  /// No description provided for @releaseBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get releaseBuildNumber;

  /// No description provided for @releaseBuildNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Left empty, the next number is taken from the store.'**
  String get releaseBuildNumberHint;

  /// No description provided for @releaseExplain.
  ///
  /// In en, this message translates to:
  /// **'The runner checks out {branch}, builds, signs and uploads. You can watch the log while it runs.'**
  String releaseExplain(String branch);

  /// No description provided for @releaseQueued.
  ///
  /// In en, this message translates to:
  /// **'Release queued'**
  String get releaseQueued;

  /// No description provided for @cancelRelease.
  ///
  /// In en, this message translates to:
  /// **'Cancel release'**
  String get cancelRelease;

  /// No description provided for @rerunRelease.
  ///
  /// In en, this message translates to:
  /// **'Run again'**
  String get rerunRelease;

  /// No description provided for @releaseLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get releaseLog;

  /// No description provided for @releaseSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get releaseSteps;

  /// No description provided for @releaseStartedBy.
  ///
  /// In en, this message translates to:
  /// **'Started by {name}'**
  String releaseStartedBy(String name);

  /// No description provided for @releaseCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get releaseCommit;

  /// No description provided for @releaseDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get releaseDuration;

  /// No description provided for @releaseArtifacts.
  ///
  /// In en, this message translates to:
  /// **'Artifacts'**
  String get releaseArtifacts;

  /// No description provided for @waitingForRunner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a runner…'**
  String get waitingForRunner;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'The log appears here as soon as the runner starts.'**
  String get logEmpty;

  /// No description provided for @downloadLog.
  ///
  /// In en, this message translates to:
  /// **'Download log'**
  String get downloadLog;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusSucceeded;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @stepPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get stepPending;

  /// No description provided for @stepRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stepRunning;

  /// No description provided for @stepSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stepSucceeded;

  /// No description provided for @stepFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get stepFailed;

  /// No description provided for @stepSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get stepSkipped;

  /// No description provided for @trackInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal testing'**
  String get trackInternal;

  /// No description provided for @trackAlpha.
  ///
  /// In en, this message translates to:
  /// **'Closed testing (alpha)'**
  String get trackAlpha;

  /// No description provided for @trackBeta.
  ///
  /// In en, this message translates to:
  /// **'Open testing (beta)'**
  String get trackBeta;

  /// No description provided for @trackProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get trackProduction;

  /// No description provided for @trackTestflight.
  ///
  /// In en, this message translates to:
  /// **'TestFlight'**
  String get trackTestflight;

  /// No description provided for @trackAppStore.
  ///
  /// In en, this message translates to:
  /// **'App Store review'**
  String get trackAppStore;

  /// No description provided for @credentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentialsTitle;

  /// No description provided for @credentialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signing keys and store access. Encrypted at rest, decrypted only on the runner.'**
  String get credentialsSubtitle;

  /// No description provided for @addCredential.
  ///
  /// In en, this message translates to:
  /// **'Add credential'**
  String get addCredential;

  /// No description provided for @noCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'No credentials yet'**
  String get noCredentialsTitle;

  /// No description provided for @noCredentialsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an Android keystore, a Google Play service account and an App Store Connect API key to publish.'**
  String get noCredentialsMessage;

  /// No description provided for @kindAndroidKeystore.
  ///
  /// In en, this message translates to:
  /// **'Android keystore'**
  String get kindAndroidKeystore;

  /// No description provided for @kindAndroidKeystoreBody.
  ///
  /// In en, this message translates to:
  /// **'Signs the app bundle. Use the upload key.'**
  String get kindAndroidKeystoreBody;

  /// No description provided for @kindGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Google Play service account'**
  String get kindGooglePlay;

  /// No description provided for @kindGooglePlayBody.
  ///
  /// In en, this message translates to:
  /// **'Uploads to Google Play and reads the latest build number.'**
  String get kindGooglePlayBody;

  /// No description provided for @kindAppStoreConnect.
  ///
  /// In en, this message translates to:
  /// **'App Store Connect API key'**
  String get kindAppStoreConnect;

  /// No description provided for @kindAppStoreConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Signs iOS builds and uploads to TestFlight.'**
  String get kindAppStoreConnectBody;

  /// No description provided for @credentialName.
  ///
  /// In en, this message translates to:
  /// **'Reference name'**
  String get credentialName;

  /// No description provided for @credentialNameHint.
  ///
  /// In en, this message translates to:
  /// **'Used in apprelease.yaml, e.g. upload_keystore'**
  String get credentialNameHint;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @fileChosen.
  ///
  /// In en, this message translates to:
  /// **'{name} · {size}'**
  String fileChosen(String name, String size);

  /// No description provided for @keystorePassword.
  ///
  /// In en, this message translates to:
  /// **'Keystore password'**
  String get keystorePassword;

  /// No description provided for @keyAlias.
  ///
  /// In en, this message translates to:
  /// **'Key alias'**
  String get keyAlias;

  /// No description provided for @keyPassword.
  ///
  /// In en, this message translates to:
  /// **'Key password'**
  String get keyPassword;

  /// No description provided for @serviceAccountJson.
  ///
  /// In en, this message translates to:
  /// **'Service account JSON'**
  String get serviceAccountJson;

  /// No description provided for @serviceAccountJsonHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the contents of the JSON key file'**
  String get serviceAccountJsonHint;

  /// No description provided for @issuerId.
  ///
  /// In en, this message translates to:
  /// **'Issuer ID'**
  String get issuerId;

  /// No description provided for @keyId.
  ///
  /// In en, this message translates to:
  /// **'Key ID'**
  String get keyId;

  /// No description provided for @privateKeyP8.
  ///
  /// In en, this message translates to:
  /// **'Private key (.p8)'**
  String get privateKeyP8;

  /// No description provided for @credentialAdded.
  ///
  /// In en, this message translates to:
  /// **'Credential added'**
  String get credentialAdded;

  /// No description provided for @deleteCredential.
  ///
  /// In en, this message translates to:
  /// **'Delete credential'**
  String get deleteCredential;

  /// No description provided for @deleteCredentialConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Workflows that reference it will fail until it is replaced.'**
  String deleteCredentialConfirm(String name);

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String addedOn(String date);

  /// No description provided for @fileRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get fileRequired;

  /// No description provided for @invalidJson.
  ///
  /// In en, this message translates to:
  /// **'This is not valid JSON'**
  String get invalidJson;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account and how the console looks.'**
  String get settingsSubtitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountExplain.
  ///
  /// In en, this message translates to:
  /// **'Deletes your account, applications, releases and credentials. This cannot be undone.'**
  String get deleteAccountExplain;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your account and everything in it?'**
  String get deleteAccountConfirm;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @backendLabel.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backendLabel;

  /// No description provided for @backendLocal.
  ///
  /// In en, this message translates to:
  /// **'Demo data (in memory)'**
  String get backendLocal;

  /// No description provided for @backendSupabase.
  ///
  /// In en, this message translates to:
  /// **'Supabase'**
  String get backendSupabase;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get enterCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a six-digit code to {email}. It is valid for one hour.'**
  String codeSentTo(String email);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get changeEmail;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way'**
  String get codeResent;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not right'**
  String get invalidCode;

  /// No description provided for @expiredCode.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Request a new one.'**
  String get expiredCode;

  /// No description provided for @demoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Demo: the code is 123456'**
  String get demoCodeHint;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your first release'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Four things AppRelease needs before it can publish. Add them now or later; nothing here is lost.'**
  String get setupSubtitle;

  /// No description provided for @setupItemApp.
  ///
  /// In en, this message translates to:
  /// **'Your application'**
  String get setupItemApp;

  /// No description provided for @setupItemAppBody.
  ///
  /// In en, this message translates to:
  /// **'The Git URL of the Flutter project, the branch to build, and the package name or bundle identifier.'**
  String get setupItemAppBody;

  /// No description provided for @setupItemKeystore.
  ///
  /// In en, this message translates to:
  /// **'Android upload keystore'**
  String get setupItemKeystore;

  /// No description provided for @setupItemKeystoreBody.
  ///
  /// In en, this message translates to:
  /// **'The .jks file plus its store password, key alias and key password. We never show it again, so keep your own copy.'**
  String get setupItemKeystoreBody;

  /// No description provided for @setupItemPlay.
  ///
  /// In en, this message translates to:
  /// **'Google Play service account'**
  String get setupItemPlay;

  /// No description provided for @setupItemPlayBody.
  ///
  /// In en, this message translates to:
  /// **'A JSON key from Google Cloud, invited in Play Console with release permissions. Needed to upload and to read the build number.'**
  String get setupItemPlayBody;

  /// No description provided for @setupItemAsc.
  ///
  /// In en, this message translates to:
  /// **'App Store Connect API key'**
  String get setupItemAsc;

  /// No description provided for @setupItemAscBody.
  ///
  /// In en, this message translates to:
  /// **'The .p8 file, its Key ID and the Issuer ID from App Store Connect → Users and Access → Integrations.'**
  String get setupItemAscBody;

  /// No description provided for @setupAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get setupAdd;

  /// No description provided for @setupDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get setupDoneLabel;

  /// No description provided for @setupFinish.
  ///
  /// In en, this message translates to:
  /// **'Go to the dashboard'**
  String get setupFinish;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkip;

  /// No description provided for @setupAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everything is in place. Open your application and start a release.'**
  String get setupAllDone;

  /// No description provided for @setupProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String setupProgress(int done, int total);

  /// No description provided for @navSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup checklist'**
  String get navSetup;

  /// No description provided for @runnerOnline.
  ///
  /// In en, this message translates to:
  /// **'A runner is online'**
  String get runnerOnline;

  /// No description provided for @triggersTitle.
  ///
  /// In en, this message translates to:
  /// **'Release on push'**
  String get triggersTitle;

  /// No description provided for @triggersExplain.
  ///
  /// In en, this message translates to:
  /// **'Let GitHub start releases. Each rule says which branch goes where: for example develop to internal testing and TestFlight, main to production and App Store review. The version comes from pubspec.yaml.'**
  String get triggersExplain;

  /// No description provided for @triggerEnabled.
  ///
  /// In en, this message translates to:
  /// **'Release automatically on push'**
  String get triggerEnabled;

  /// No description provided for @triggerBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get triggerBranch;

  /// No description provided for @triggerPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms to release'**
  String get triggerPlatforms;

  /// No description provided for @triggerTrackAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android track on push'**
  String get triggerTrackAndroid;

  /// No description provided for @triggerTrackIos.
  ///
  /// In en, this message translates to:
  /// **'iOS destination on push'**
  String get triggerTrackIos;

  /// No description provided for @triggerTags.
  ///
  /// In en, this message translates to:
  /// **'A tag like v1.2.0 releases to production'**
  String get triggerTags;

  /// No description provided for @triggerTagsBody.
  ///
  /// In en, this message translates to:
  /// **'Pushing a version tag queues a production release on Google Play and an App Store review submission, with the version from the tag.'**
  String get triggerTagsBody;

  /// No description provided for @webhookTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub'**
  String get webhookTitle;

  /// No description provided for @webhookHow.
  ///
  /// In en, this message translates to:
  /// **'In the repository on GitHub open Settings → Webhooks → Add webhook. Payload URL and secret as below, content type application/json, event: just the push event.'**
  String get webhookHow;

  /// No description provided for @webhookUrl.
  ///
  /// In en, this message translates to:
  /// **'Payload URL'**
  String get webhookUrl;

  /// No description provided for @webhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get webhookSecret;

  /// No description provided for @webhookLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Webhooks need the live backend; in the demo nothing is posted.'**
  String get webhookLocalNote;

  /// No description provided for @versionAuto.
  ///
  /// In en, this message translates to:
  /// **'from pubspec'**
  String get versionAuto;

  /// No description provided for @playGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to get this file'**
  String get playGuideTitle;

  /// No description provided for @playGuide1.
  ///
  /// In en, this message translates to:
  /// **'Create a service account in Google Cloud. Any project works; the name does not matter.'**
  String get playGuide1;

  /// No description provided for @playGuide1Link.
  ///
  /// In en, this message translates to:
  /// **'Open Google Cloud → Service accounts'**
  String get playGuide1Link;

  /// No description provided for @playGuide2.
  ///
  /// In en, this message translates to:
  /// **'Open the account → Keys → Add key → Create new key → JSON. Pick that file below or paste its contents.'**
  String get playGuide2;

  /// No description provided for @playGuide3.
  ///
  /// In en, this message translates to:
  /// **'Enable the Google Play Android Developer API in the same Cloud project.'**
  String get playGuide3;

  /// No description provided for @playGuide3Link.
  ///
  /// In en, this message translates to:
  /// **'Enable the API for project {project}'**
  String playGuide3Link(String project);

  /// No description provided for @playGuide3LinkGeneric.
  ///
  /// In en, this message translates to:
  /// **'Enable the API'**
  String get playGuide3LinkGeneric;

  /// No description provided for @playGuide4.
  ///
  /// In en, this message translates to:
  /// **'In Google Play Console → Users and permissions → Invite new users, invite this email with \"Release to production, exclude devices, and use Play App Signing\" and \"Release apps to testing tracks\" for your app.'**
  String get playGuide4;

  /// No description provided for @playGuide4Link.
  ///
  /// In en, this message translates to:
  /// **'Open Play Console → Users and permissions'**
  String get playGuide4Link;

  /// No description provided for @playGuideEmail.
  ///
  /// In en, this message translates to:
  /// **'Service account email'**
  String get playGuideEmail;

  /// No description provided for @playGuideAfter.
  ///
  /// In en, this message translates to:
  /// **'Press Check on the saved credential afterwards; it tells you if a step is still missing.'**
  String get playGuideAfter;

  /// No description provided for @checkCredential.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkCredential;

  /// No description provided for @checkingCredential.
  ///
  /// In en, this message translates to:
  /// **'Checking with Google…'**
  String get checkingCredential;

  /// No description provided for @checkResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Play check'**
  String get checkResultTitle;

  /// No description provided for @checkOk.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get checkOk;

  /// No description provided for @checkFix.
  ///
  /// In en, this message translates to:
  /// **'Open the page to fix it'**
  String get checkFix;

  /// No description provided for @checkFailed.
  ///
  /// In en, this message translates to:
  /// **'The check could not run: {error}'**
  String checkFailed(String error);

  /// No description provided for @ascGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to get this key'**
  String get ascGuideTitle;

  /// No description provided for @ascGuide1.
  ///
  /// In en, this message translates to:
  /// **'In App Store Connect open Users and Access → Integrations → App Store Connect API and press \"+\" next to Active keys. Needs the Account Holder or an Admin.'**
  String get ascGuide1;

  /// No description provided for @ascGuide1Link.
  ///
  /// In en, this message translates to:
  /// **'Open App Store Connect → Integrations'**
  String get ascGuide1Link;

  /// No description provided for @ascGuide2.
  ///
  /// In en, this message translates to:
  /// **'Name it AppRelease, choose the App Manager role, Generate. Then Download API Key: the .p8 can be downloaded only once, keep it.'**
  String get ascGuide2;

  /// No description provided for @ascGuide3.
  ///
  /// In en, this message translates to:
  /// **'Copy the Issuer ID shown above the table and the Key ID from the key\'s row into the fields below, and pick the .p8 file.'**
  String get ascGuide3;

  /// No description provided for @ascGuide4.
  ///
  /// In en, this message translates to:
  /// **'The app itself must exist in App Store Connect with the same bundle identifier; AppRelease uploads builds, it does not create app records.'**
  String get ascGuide4;

  /// No description provided for @ascGuide4Link.
  ///
  /// In en, this message translates to:
  /// **'Open App Store Connect → Apps'**
  String get ascGuide4Link;

  /// No description provided for @ascGuideAfter.
  ///
  /// In en, this message translates to:
  /// **'Press Check on the saved credential afterwards; it tells you if Apple accepts the key for your apps.'**
  String get ascGuideAfter;

  /// No description provided for @checkResultTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'App Store Connect check'**
  String get checkResultTitleAsc;

  /// No description provided for @pushRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule {n}'**
  String pushRuleTitle(int n);

  /// No description provided for @pushRuleBranchHelper.
  ///
  /// In en, this message translates to:
  /// **'A branch name, or a prefix with * such as release/*'**
  String get pushRuleBranchHelper;

  /// No description provided for @addPushRule.
  ///
  /// In en, this message translates to:
  /// **'Add a branch'**
  String get addPushRule;

  /// No description provided for @removePushRule.
  ///
  /// In en, this message translates to:
  /// **'Remove rule'**
  String get removePushRule;

  /// No description provided for @pushRuleNoPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one platform for this rule.'**
  String get pushRuleNoPlatforms;

  /// No description provided for @pushRuleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Two rules use the branch {branch}.'**
  String pushRuleDuplicate(String branch);

  /// No description provided for @credentialApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get credentialApp;

  /// No description provided for @credentialAppHelper.
  ///
  /// In en, this message translates to:
  /// **'The app this key signs. Leave it shared if several apps use it.'**
  String get credentialAppHelper;

  /// No description provided for @credentialShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get credentialShared;

  /// No description provided for @credentialSharedKeys.
  ///
  /// In en, this message translates to:
  /// **'Shared keys'**
  String get credentialSharedKeys;

  /// No description provided for @linkToApp.
  ///
  /// In en, this message translates to:
  /// **'Link to app'**
  String get linkToApp;

  /// No description provided for @keystoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Android keystores'**
  String get keystoresTitle;

  /// No description provided for @appKeystores.
  ///
  /// In en, this message translates to:
  /// **'{app}'**
  String appKeystores(String app);

  /// No description provided for @noKeystoreForApp.
  ///
  /// In en, this message translates to:
  /// **'No keystore yet for this app.'**
  String get noKeystoreForApp;

  /// No description provided for @appReleasesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} releases · last {ago}'**
  String appReleasesSummary(int count, String ago);

  /// No description provided for @allReleasesOfApp.
  ///
  /// In en, this message translates to:
  /// **'All {count} releases'**
  String allReleasesOfApp(int count);

  /// No description provided for @queueShort.
  ///
  /// In en, this message translates to:
  /// **'Waiting in line…'**
  String get queueShort;

  /// No description provided for @queueInLineTitle.
  ///
  /// In en, this message translates to:
  /// **'Number {position} in line'**
  String queueInLineTitle(int position);

  /// No description provided for @queueInLineBody.
  ///
  /// In en, this message translates to:
  /// **'{ahead, plural, =0{The build machine is finishing another release.} =1{One release goes before yours.} other{{ahead} releases go before yours.}} Your {platform} build should start in about {minutes} min. You can close this page; the release carries on without it.'**
  String queueInLineBody(int ahead, int minutes, String platform);

  /// No description provided for @queueStartingTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting now'**
  String get queueStartingTitle;

  /// No description provided for @queueStartingBody.
  ///
  /// In en, this message translates to:
  /// **'A build machine is free and picks this release up in a few seconds.'**
  String get queueStartingBody;

  /// No description provided for @queueOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'The build machines are offline for a moment'**
  String get queueOfflineTitle;

  /// No description provided for @queueOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Your release is safe in the queue and starts by itself as soon as a machine is back. Nothing to do on your side.'**
  String get queueOfflineBody;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
