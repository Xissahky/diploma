import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Novel App'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @polish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get polish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// No description provided for @tabAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get tabAchievements;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @uploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload avatar'**
  String get uploadAvatar;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get loggedOut;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @noUserData.
  ///
  /// In en, this message translates to:
  /// **'No user data'**
  String get noUserData;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @minPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minPasswordLength;

  /// No description provided for @repeatNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get repeatNewPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @noAchievementsDefined.
  ///
  /// In en, this message translates to:
  /// **'No achievements defined'**
  String get noAchievementsDefined;

  /// No description provided for @achievementDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievementDefaultTitle;

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsShort;

  /// No description provided for @libStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libStatusAll;

  /// No description provided for @libStatusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get libStatusReading;

  /// No description provided for @libStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get libStatusPlanned;

  /// No description provided for @libStatusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get libStatusOnHold;

  /// No description provided for @libStatusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get libStatusDropped;

  /// No description provided for @libStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get libStatusCompleted;

  /// No description provided for @libStatusFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libStatusFavorites;

  /// No description provided for @noNovelsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No novels in this category'**
  String get noNovelsInCategory;

  /// No description provided for @untitledNovel.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledNovel;

  /// No description provided for @unknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get unknownAuthor;

  /// No description provided for @notificationsTitleUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications • Unread'**
  String get notificationsTitleUnread;

  /// No description provided for @notificationsTitleAll.
  ///
  /// In en, this message translates to:
  /// **'Notifications • All'**
  String get notificationsTitleAll;

  /// No description provided for @notificationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsFilterUnread;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsMarkAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllTooltip;

  /// No description provided for @notificationsAllReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'All read'**
  String get notificationsAllReadTooltip;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @notificationNewChapterPrefix.
  ///
  /// In en, this message translates to:
  /// **'New chapter'**
  String get notificationNewChapterPrefix;

  /// No description provided for @notificationDefaultNovelTitle.
  ///
  /// In en, this message translates to:
  /// **'Novel'**
  String get notificationDefaultNovelTitle;

  /// No description provided for @notificationDefaultChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'New chapter'**
  String get notificationDefaultChapterTitle;

  /// No description provided for @notificationReplySuffix.
  ///
  /// In en, this message translates to:
  /// **'replied'**
  String get notificationReplySuffix;

  /// No description provided for @notificationReplyDefaultText.
  ///
  /// In en, this message translates to:
  /// **'replied to your comment'**
  String get notificationReplyDefaultText;

  /// No description provided for @notificationAchievementUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get notificationAchievementUnlockedTitle;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @notificationReadButton.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationReadButton;

  /// No description provided for @notificationMarkAsReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationMarkAsReadButton;

  /// No description provided for @notificationMissingIds.
  ///
  /// In en, this message translates to:
  /// **'Missing novel/chapter id in notification'**
  String get notificationMissingIds;

  /// No description provided for @notificationFailedLoadNovel.
  ///
  /// In en, this message translates to:
  /// **'Failed to load novel'**
  String get notificationFailedLoadNovel;

  /// No description provided for @notificationChapterNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chapter not found in novel'**
  String get notificationChapterNotFound;

  /// No description provided for @failedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedPrefix;

  /// No description provided for @openErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Open error'**
  String get openErrorPrefix;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createTitle;

  /// No description provided for @createModeNovel.
  ///
  /// In en, this message translates to:
  /// **'Novel'**
  String get createModeNovel;

  /// No description provided for @createModeChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get createModeChapter;

  /// No description provided for @createNovelButton.
  ///
  /// In en, this message translates to:
  /// **'Create novel'**
  String get createNovelButton;

  /// No description provided for @addChapterButton.
  ///
  /// In en, this message translates to:
  /// **'Add chapter'**
  String get addChapterButton;

  /// No description provided for @novelTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get novelTitleLabel;

  /// No description provided for @novelTitleHint.
  ///
  /// In en, this message translates to:
  /// **'\"Novel title\"'**
  String get novelTitleHint;

  /// No description provided for @novelDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get novelDescriptionLabel;

  /// No description provided for @novelDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short synopsis'**
  String get novelDescriptionHint;

  /// No description provided for @uploadCoverButton.
  ///
  /// In en, this message translates to:
  /// **'Upload cover'**
  String get uploadCoverButton;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags:'**
  String get tagsLabel;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @noTagsSelected.
  ///
  /// In en, this message translates to:
  /// **'No tags selected'**
  String get noTagsSelected;

  /// No description provided for @tagsSelectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Selected:'**
  String get tagsSelectedPrefix;

  /// No description provided for @selectNovelTitle.
  ///
  /// In en, this message translates to:
  /// **'Select novel'**
  String get selectNovelTitle;

  /// No description provided for @searchNovelHint.
  ///
  /// In en, this message translates to:
  /// **'Search novel by title...'**
  String get searchNovelHint;

  /// No description provided for @selectedNovelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Selected novel'**
  String get selectedNovelSubtitle;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @chapterTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter title'**
  String get chapterTitleLabel;

  /// No description provided for @chapterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'\"Chapter name\" | number'**
  String get chapterTitleHint;

  /// No description provided for @chapterContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get chapterContentLabel;

  /// No description provided for @chapterContentHint.
  ///
  /// In en, this message translates to:
  /// **'Paste chapter text here'**
  String get chapterContentHint;

  /// No description provided for @tagsLoadFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tags'**
  String get tagsLoadFailedPrefix;

  /// No description provided for @coverUploaded.
  ///
  /// In en, this message translates to:
  /// **'Cover uploaded'**
  String get coverUploaded;

  /// No description provided for @uploadFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailedPrefix;

  /// No description provided for @searchFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get searchFailedPrefix;

  /// No description provided for @novelFillTitleAndDescription.
  ///
  /// In en, this message translates to:
  /// **'Please fill title and description'**
  String get novelFillTitleAndDescription;

  /// No description provided for @novelCreated.
  ///
  /// In en, this message translates to:
  /// **'Novel created'**
  String get novelCreated;

  /// No description provided for @createNovelFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Create novel failed'**
  String get createNovelFailedPrefix;

  /// No description provided for @pickNovelFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a novel first'**
  String get pickNovelFirst;

  /// No description provided for @chapterFillTitleAndContent.
  ///
  /// In en, this message translates to:
  /// **'Please fill chapter title and content'**
  String get chapterFillTitleAndContent;

  /// No description provided for @chapterAdded.
  ///
  /// In en, this message translates to:
  /// **'Chapter added'**
  String get chapterAdded;

  /// No description provided for @addChapterFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Add chapter failed'**
  String get addChapterFailedPrefix;

  /// No description provided for @mustBeLoggedInToComment.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to comment'**
  String get mustBeLoggedInToComment;

  /// No description provided for @mustBeLoggedInToReport.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to report'**
  String get mustBeLoggedInToReport;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @translatedToPrefix.
  ///
  /// In en, this message translates to:
  /// **'Translated to'**
  String get translatedToPrefix;

  /// No description provided for @translatingToPrefix.
  ///
  /// In en, this message translates to:
  /// **'Translating to'**
  String get translatingToPrefix;

  /// No description provided for @emptyTranslation.
  ///
  /// In en, this message translates to:
  /// **'Empty translation received'**
  String get emptyTranslation;

  /// No description provided for @translationFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Translation failed'**
  String get translationFailedPrefix;

  /// No description provided for @translationErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Translation error'**
  String get translationErrorPrefix;

  /// No description provided for @chapterListTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter list'**
  String get chapterListTitle;

  /// No description provided for @chapterWord.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapterWord;

  /// No description provided for @readingSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readingSettingsTitle;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSizeLabel;

  /// No description provided for @translationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationSectionTitle;

  /// No description provided for @targetLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get targetLanguageLabel;

  /// No description provided for @showTranslatedText.
  ///
  /// In en, this message translates to:
  /// **'Show translated text'**
  String get showTranslatedText;

  /// No description provided for @translateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Translate now'**
  String get translateNowButton;

  /// No description provided for @showingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Showing:'**
  String get showingPrefix;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @lineHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Line height'**
  String get lineHeightLabel;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @chapterReported.
  ///
  /// In en, this message translates to:
  /// **'Chapter reported'**
  String get chapterReported;

  /// No description provided for @commentReported.
  ///
  /// In en, this message translates to:
  /// **'Comment reported'**
  String get commentReported;

  /// No description provided for @unknownNovel.
  ///
  /// In en, this message translates to:
  /// **'Unknown novel'**
  String get unknownNovel;

  /// No description provided for @noChapters.
  ///
  /// In en, this message translates to:
  /// **'No chapters'**
  String get noChapters;

  /// No description provided for @chaptersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTooltip;

  /// No description provided for @textSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Text settings'**
  String get textSettingsTooltip;

  /// No description provided for @reportChapterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report chapter'**
  String get reportChapterTooltip;

  /// No description provided for @reportCommentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportCommentTooltip;

  /// No description provided for @previousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapter;

  /// No description provided for @noPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'No previous chapter'**
  String get noPreviousChapter;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get nextChapter;

  /// No description provided for @backToNovel.
  ///
  /// In en, this message translates to:
  /// **'Back to novel'**
  String get backToNovel;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @writeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeCommentHint;

  /// No description provided for @loginToComment.
  ///
  /// In en, this message translates to:
  /// **'Log in to comment'**
  String get loginToComment;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search novels'**
  String get searchTitle;

  /// No description provided for @searchEnterTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter novel title...'**
  String get searchEnterTitleLabel;

  /// No description provided for @searchErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get searchErrorPrefix;

  /// No description provided for @showFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show filters'**
  String get showFiltersTooltip;

  /// No description provided for @hideFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide filters'**
  String get hideFiltersTooltip;

  /// No description provided for @searchMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Match:'**
  String get searchMatchLabel;

  /// No description provided for @searchMatchAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchMatchAny;

  /// No description provided for @searchMatchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchMatchAll;

  /// No description provided for @searchApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get searchApplyFilters;

  /// No description provided for @searchNoResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get searchNoResultsYet;

  /// No description provided for @searchUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get searchUnknownAuthor;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @homePopularNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular now'**
  String get homePopularNowTitle;

  /// No description provided for @homePopularNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sorted by recent views'**
  String get homePopularNowSubtitle;

  /// No description provided for @homeTopRatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get homeTopRatedTitle;

  /// No description provided for @homeTopRatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Best rated by readers'**
  String get homeTopRatedSubtitle;

  /// No description provided for @homeRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get homeRecommendedTitle;

  /// No description provided for @homeRecommendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Because you liked similar novels'**
  String get homeRecommendedSubtitle;

  /// No description provided for @loginCtaText.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see personal recommendations'**
  String get loginCtaText;

  /// No description provided for @loginCtaButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginCtaButton;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @novelTabInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get novelTabInfo;

  /// No description provided for @novelTabChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get novelTabChapters;

  /// No description provided for @novelTabComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get novelTabComments;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionLabel;

  /// No description provided for @loginToRate.
  ///
  /// In en, this message translates to:
  /// **'Log in to rate'**
  String get loginToRate;

  /// No description provided for @ratingSaved.
  ///
  /// In en, this message translates to:
  /// **'Rating saved'**
  String get ratingSaved;

  /// No description provided for @addToLibraryInfo.
  ///
  /// In en, this message translates to:
  /// **'Add to Library from here too (already implemented)'**
  String get addToLibraryInfo;

  /// No description provided for @addToLibraryButton.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get addToLibraryButton;

  /// No description provided for @readNowButton.
  ///
  /// In en, this message translates to:
  /// **'Read now'**
  String get readNowButton;

  /// No description provided for @replyButton.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyButton;

  /// No description provided for @replyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyDialogTitle;

  /// No description provided for @replyDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Your reply...'**
  String get replyDialogHint;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get statusReading;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get statusOnHold;

  /// No description provided for @statusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get statusDropped;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pl': return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
