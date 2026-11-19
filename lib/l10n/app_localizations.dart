import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sundial'**
  String get appName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @shifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get shifts;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add an entry'**
  String get addEntry;

  /// No description provided for @addSomething.
  ///
  /// In en, this message translates to:
  /// **'Add something'**
  String get addSomething;

  /// No description provided for @addOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'Add on this day'**
  String get addOnThisDay;

  /// No description provided for @noPlanToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for today.'**
  String get noPlanToday;

  /// No description provided for @noPlanTodayHint.
  ///
  /// In en, this message translates to:
  /// **'That is allowed. If something is missing, add it now.'**
  String get noPlanTodayHint;

  /// No description provided for @nothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get nothingPlanned;

  /// No description provided for @shiftsSection.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get shiftsSection;

  /// No description provided for @couldNotLoadDay.
  ///
  /// In en, this message translates to:
  /// **'Could not load your day: {error}'**
  String couldNotLoadDay(String error);

  /// No description provided for @couldNotLoadShifts.
  ///
  /// In en, this message translates to:
  /// **'Could not load shifts: {error}'**
  String couldNotLoadShifts(String error);

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @overnightSuffix.
  ///
  /// In en, this message translates to:
  /// **'(+1 day)'**
  String get overnightSuffix;

  /// No description provided for @importedEvent.
  ///
  /// In en, this message translates to:
  /// **'Imported calendar event'**
  String get importedEvent;

  /// No description provided for @readOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This event comes from an imported calendar and is read-only.'**
  String get readOnlyNotice;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @titleQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get titleQuestion;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get titleRequired;

  /// No description provided for @space.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get space;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @starts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get starts;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatYearly;

  /// No description provided for @repeatAfterCompletion.
  ///
  /// In en, this message translates to:
  /// **'Repeat after completion'**
  String get repeatAfterCompletion;

  /// No description provided for @repeatAfterCompletionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule the next one from the day you finish.'**
  String get repeatAfterCompletionSubtitle;

  /// No description provided for @daysRequired.
  ///
  /// In en, this message translates to:
  /// **'Use a number of days greater than zero.'**
  String get daysRequired;

  /// No description provided for @daysValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysValue(int count);

  /// No description provided for @repeatAfterDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days between completions'**
  String get repeatAfterDaysLabel;

  /// No description provided for @couldNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Could not complete: {error}'**
  String couldNotComplete(String error);

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @deleteEntryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryQuestion;

  /// No description provided for @deleteEntryBody.
  ///
  /// In en, this message translates to:
  /// **'It will disappear from your plan.'**
  String get deleteEntryBody;

  /// No description provided for @endAfterStartError.
  ///
  /// In en, this message translates to:
  /// **'The end time has to be after the start.'**
  String get endAfterStartError;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String couldNotSave(String error);

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDelete(String error);

  /// No description provided for @timesDefinedIn.
  ///
  /// In en, this message translates to:
  /// **'Times are defined in {timeZone}'**
  String timesDefinedIn(String timeZone);

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark {title} as done'**
  String markAsDone(String title);

  /// No description provided for @entryKindTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get entryKindTask;

  /// No description provided for @entryKindEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get entryKindEvent;

  /// No description provided for @entryKindObligation.
  ///
  /// In en, this message translates to:
  /// **'Obligation'**
  String get entryKindObligation;

  /// No description provided for @entryKindDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get entryKindDeadline;

  /// No description provided for @recurrenceEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get recurrenceEveryDay;

  /// No description provided for @recurrenceEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String recurrenceEveryNDays(int count);

  /// No description provided for @recurrenceEveryWeek.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get recurrenceEveryWeek;

  /// No description provided for @recurrenceEveryNWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every {count} weeks'**
  String recurrenceEveryNWeeks(int count);

  /// No description provided for @recurrenceOnDays.
  ///
  /// In en, this message translates to:
  /// **'Every week on {days}'**
  String recurrenceOnDays(String days);

  /// No description provided for @recurrenceEveryNWeeksOnDays.
  ///
  /// In en, this message translates to:
  /// **'Every {count} weeks on {days}'**
  String recurrenceEveryNWeeksOnDays(int count, String days);

  /// No description provided for @recurrenceEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get recurrenceEveryMonth;

  /// No description provided for @recurrenceEveryNMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {count} months'**
  String recurrenceEveryNMonths(int count);

  /// No description provided for @recurrenceEveryNMonthsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Every {count} months on day {day}'**
  String recurrenceEveryNMonthsOnDay(int count, int day);

  /// No description provided for @recurrenceOnDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day}'**
  String recurrenceOnDayOfMonth(int day);

  /// No description provided for @recurrenceEveryYear.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get recurrenceEveryYear;

  /// No description provided for @recurrenceEveryNYears.
  ///
  /// In en, this message translates to:
  /// **'Every {count} years'**
  String recurrenceEveryNYears(int count);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @jumpToToday.
  ///
  /// In en, this message translates to:
  /// **'Jump to today'**
  String get jumpToToday;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthView;

  /// No description provided for @weekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekView;

  /// No description provided for @selectedDay.
  ///
  /// In en, this message translates to:
  /// **'Selected day'**
  String get selectedDay;

  /// No description provided for @noEntriesOnDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned on this day.'**
  String get noEntriesOnDay;

  /// No description provided for @calendarDaySemantics.
  ///
  /// In en, this message translates to:
  /// **'{date}, {count} items'**
  String calendarDaySemantics(String date, int count);

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

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

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @weekStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get weekStartsOn;

  /// No description provided for @weekStartMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekStartMonday;

  /// No description provided for @weekStartSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekStartSaturday;

  /// No description provided for @weekStartSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekStartSunday;

  /// No description provided for @hideWorkSpace.
  ///
  /// In en, this message translates to:
  /// **'Hide the Work space'**
  String get hideWorkSpace;

  /// No description provided for @hideWorkSpaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep work commitments out of Today, Week and Calendar.'**
  String get hideWorkSpaceSubtitle;

  /// No description provided for @defaultReminders.
  ///
  /// In en, this message translates to:
  /// **'Default reminders'**
  String get defaultReminders;

  /// No description provided for @defaultRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-selected when you add an entry.'**
  String get defaultRemindersSubtitle;

  /// No description provided for @reminderAtTime.
  ///
  /// In en, this message translates to:
  /// **'At the start time'**
  String get reminderAtTime;

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before'**
  String reminderMinutesBefore(int count);

  /// No description provided for @reminderHoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} hours before'**
  String reminderHoursBefore(int count);

  /// No description provided for @reminderDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} days before'**
  String reminderDaysBefore(int count);

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder'**
  String get addReminder;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder;

  /// No description provided for @remindersOff.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get remindersOff;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Enable them in system settings so reminders can reach you.'**
  String get notificationPermissionDenied;

  /// No description provided for @couldNotLoadReminders.
  ///
  /// In en, this message translates to:
  /// **'Could not load reminders: {error}'**
  String couldNotLoadReminders(String error);

  /// No description provided for @remindersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reminders could not be read, so they were left unchanged.'**
  String get remindersUnavailable;

  /// No description provided for @dataAndBackup.
  ///
  /// In en, this message translates to:
  /// **'Data and backup'**
  String get dataAndBackup;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export a backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write a versioned JSON file of all your data.'**
  String get exportBackupSubtitle;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get importBackup;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace your data with a validated backup file.'**
  String get importBackupSubtitle;

  /// No description provided for @importCalendar.
  ///
  /// In en, this message translates to:
  /// **'Import a calendar'**
  String get importCalendar;

  /// No description provided for @importCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read a local .ics file. Imported events are read-only.'**
  String get importCalendarSubtitle;

  /// No description provided for @importCalendarSpace.
  ///
  /// In en, this message translates to:
  /// **'Import into'**
  String get importCalendarSpace;

  /// No description provided for @importCalendarDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported}, updated {updated}, skipped {skipped} duplicates or unsupported events.'**
  String importCalendarDone(int imported, int updated, int skipped);

  /// No description provided for @importCalendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events were found in this file.'**
  String get importCalendarEmpty;

  /// No description provided for @importCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Calendar import failed: {error}'**
  String importCalendarFailed(String error);

  /// No description provided for @importCompanion.
  ///
  /// In en, this message translates to:
  /// **'Import a companion export'**
  String get importCompanion;

  /// No description provided for @importCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read a local JSON schedule exported by another app.'**
  String get importCompanionSubtitle;

  /// No description provided for @importCompanionDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported} events. Skipped {skipped} duplicates or invalid rows.'**
  String importCompanionDone(int imported, int skipped);

  /// No description provided for @importCompanionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events were found in this file.'**
  String get importCompanionEmpty;

  /// No description provided for @importCompanionFailed.
  ///
  /// In en, this message translates to:
  /// **'Companion import failed: {error}'**
  String importCompanionFailed(String error);

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup written to {path}'**
  String backupExported(String path);

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup restored.'**
  String get backupImported;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid Sundial backup.'**
  String get backupInvalid;

  /// No description provided for @backupFuture.
  ///
  /// In en, this message translates to:
  /// **'This backup comes from a newer version of Sundial.'**
  String get backupFuture;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace your data?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The backup replaces every entry, shift, tag and setting on this device.'**
  String get importConfirmBody;

  /// No description provided for @syncAndAgent.
  ///
  /// In en, this message translates to:
  /// **'Sync and local agent'**
  String get syncAndAgent;

  /// No description provided for @syncEnabled.
  ///
  /// In en, this message translates to:
  /// **'LAN sync'**
  String get syncEnabled;

  /// No description provided for @syncOffInfo.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Automatic only between paired devices on the same network.'**
  String get syncOffInfo;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @mcpEnabled.
  ///
  /// In en, this message translates to:
  /// **'Local MCP endpoint'**
  String get mcpEnabled;

  /// No description provided for @mcpOffInfo.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Lets a desktop agent read the plan over loopback.'**
  String get mcpOffInfo;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'License, credits and version'**
  String get aboutSubtitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @plannerSection.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get plannerSection;

  /// No description provided for @librarySection.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get librarySection;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySection;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get notSet;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @basedOnSundial.
  ///
  /// In en, this message translates to:
  /// **'Based on Sundial by Gabriele Ancillai'**
  String get basedOnSundial;

  /// No description provided for @inspiredBy.
  ///
  /// In en, this message translates to:
  /// **'Inspired by GymMane and Streak by InlitX'**
  String get inspiredBy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @licenseBody.
  ///
  /// In en, this message translates to:
  /// **'Sundial is free software under GPL-3.0-only. It comes with no warranty. See LICENSE and ADDITIONAL_TERMS.md in the repository.'**
  String get licenseBody;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @creditsBody.
  ///
  /// In en, this message translates to:
  /// **'An independent project by Gabriele Ancillai.'**
  String get creditsBody;

  /// No description provided for @tagsManager.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsManager;

  /// No description provided for @homeInventory.
  ///
  /// In en, this message translates to:
  /// **'Home inventory'**
  String get homeInventory;

  /// No description provided for @homeInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you keep at home, with stock levels that stay useful.'**
  String get homeInventorySubtitle;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingList;

  /// No description provided for @shoppingListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restock what the house needs, plus the occasional one-off.'**
  String get shoppingListSubtitle;

  /// No description provided for @addHomeItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get addHomeItem;

  /// No description provided for @editHomeItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editHomeItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @reorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder at'**
  String get reorderLevel;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @addToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get addToShoppingList;

  /// No description provided for @addLowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Add low-stock items'**
  String get addLowStockItems;

  /// No description provided for @noLowStock.
  ///
  /// In en, this message translates to:
  /// **'Nothing is below its minimum stock.'**
  String get noLowStock;

  /// No description provided for @homeInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your home inventory is empty.'**
  String get homeInventoryEmpty;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to buy yet.'**
  String get shoppingListEmpty;

  /// No description provided for @addShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Add to the list'**
  String get addShoppingItem;

  /// No description provided for @editShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Edit list item'**
  String get editShoppingItem;

  /// No description provided for @linkedItem.
  ///
  /// In en, this message translates to:
  /// **'Linked inventory item'**
  String get linkedItem;

  /// No description provided for @noLink.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noLink;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @archiveItemQuestion.
  ///
  /// In en, this message translates to:
  /// **'Archive this item?'**
  String get archiveItemQuestion;

  /// No description provided for @archiveItemBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears from the inventory but stays in backups.'**
  String get archiveItemBody;

  /// No description provided for @shoppingProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} bought'**
  String shoppingProgress(int done, int total);

  /// No description provided for @sleepWindow.
  ///
  /// In en, this message translates to:
  /// **'Sleep window'**
  String get sleepWindow;

  /// No description provided for @sleepWindowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A soft block from the last commitment today to the first tomorrow.'**
  String get sleepWindowSubtitle;

  /// No description provided for @sleepBuffers.
  ///
  /// In en, this message translates to:
  /// **'Sleep buffers'**
  String get sleepBuffers;

  /// No description provided for @sleepBuffersSummary.
  ///
  /// In en, this message translates to:
  /// **'{commute} commute · {windDown} wind-down · {wake} wake'**
  String sleepBuffersSummary(int commute, int windDown, int wake);

  /// No description provided for @commute.
  ///
  /// In en, this message translates to:
  /// **'Commute (minutes)'**
  String get commute;

  /// No description provided for @windDown.
  ///
  /// In en, this message translates to:
  /// **'Wind-down (minutes)'**
  String get windDown;

  /// No description provided for @wakeBuffer.
  ///
  /// In en, this message translates to:
  /// **'Wake buffer (minutes)'**
  String get wakeBuffer;

  /// No description provided for @sleepBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime around {time}'**
  String sleepBedtime(String time);

  /// No description provided for @sleepWake.
  ///
  /// In en, this message translates to:
  /// **'Wake around {time}'**
  String sleepWake(String time);

  /// No description provided for @sleepWarning.
  ///
  /// In en, this message translates to:
  /// **'This plan leaves little room to sleep.'**
  String get sleepWarning;

  /// No description provided for @sleepNoEarlyStart.
  ///
  /// In en, this message translates to:
  /// **'No early start tomorrow.'**
  String get sleepNoEarlyStart;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesValue(int count);

  /// No description provided for @tagsManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Separate jobs in Work and people or groups in Personal.'**
  String get tagsManagerSubtitle;

  /// No description provided for @shiftPatterns.
  ///
  /// In en, this message translates to:
  /// **'Shift patterns'**
  String get shiftPatterns;

  /// No description provided for @shiftPatternsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cycles, per-day slots and date exceptions.'**
  String get shiftPatternsSubtitle;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get addTag;

  /// No description provided for @editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get editTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagName;

  /// No description provided for @tagColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tagColor;

  /// No description provided for @tagSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get tagSpace;

  /// No description provided for @tagSpaceAny.
  ///
  /// In en, this message translates to:
  /// **'Any space'**
  String get tagSpaceAny;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet.'**
  String get noTags;

  /// No description provided for @deleteTagQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this tag?'**
  String get deleteTagQuestion;

  /// No description provided for @deleteTagBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from every entry that uses it.'**
  String get deleteTagBody;

  /// No description provided for @tagNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the tag a name.'**
  String get tagNameRequired;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get manageTags;

  /// No description provided for @filterByTag.
  ///
  /// In en, this message translates to:
  /// **'Filter by tag'**
  String get filterByTag;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @newShiftPattern.
  ///
  /// In en, this message translates to:
  /// **'New shift pattern'**
  String get newShiftPattern;

  /// No description provided for @editShiftPattern.
  ///
  /// In en, this message translates to:
  /// **'Edit shift pattern'**
  String get editShiftPattern;

  /// No description provided for @patternName.
  ///
  /// In en, this message translates to:
  /// **'Pattern name'**
  String get patternName;

  /// No description provided for @cycleLength.
  ///
  /// In en, this message translates to:
  /// **'Cycle length'**
  String get cycleLength;

  /// No description provided for @cycleLengthValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String cycleLengthValue(int count);

  /// No description provided for @anchorDate.
  ///
  /// In en, this message translates to:
  /// **'Anchor date'**
  String get anchorDate;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZone;

  /// No description provided for @cycleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {index}'**
  String cycleDay(int index);

  /// No description provided for @addSlot.
  ///
  /// In en, this message translates to:
  /// **'Add a slot'**
  String get addSlot;

  /// No description provided for @removeSlot.
  ///
  /// In en, this message translates to:
  /// **'Remove slot'**
  String get removeSlot;

  /// No description provided for @slotLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get slotLabel;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @exceptions.
  ///
  /// In en, this message translates to:
  /// **'Date exceptions'**
  String get exceptions;

  /// No description provided for @addException.
  ///
  /// In en, this message translates to:
  /// **'Add exception'**
  String get addException;

  /// No description provided for @exceptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free day'**
  String get exceptionFree;

  /// No description provided for @exceptionOverride.
  ///
  /// In en, this message translates to:
  /// **'Replace shifts'**
  String get exceptionOverride;

  /// No description provided for @exceptionExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra shift'**
  String get exceptionExtra;

  /// No description provided for @exceptionNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get exceptionNote;

  /// No description provided for @exceptionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exceptionDate;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Next 28 days'**
  String get preview;

  /// No description provided for @conflictsFound.
  ///
  /// In en, this message translates to:
  /// **'Some shifts overlap. Fix them before saving.'**
  String get conflictsFound;

  /// No description provided for @noConflicts.
  ///
  /// In en, this message translates to:
  /// **'No overlapping shifts.'**
  String get noConflicts;

  /// No description provided for @savePattern.
  ///
  /// In en, this message translates to:
  /// **'Save pattern'**
  String get savePattern;

  /// No description provided for @deletePatternQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this shift pattern?'**
  String get deletePatternQuestion;

  /// No description provided for @deletePatternBody.
  ///
  /// In en, this message translates to:
  /// **'Its shifts will disappear from the calendar.'**
  String get deletePatternBody;

  /// No description provided for @discardChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardChangesQuestion;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'This shift pattern has unsaved changes. Leaving now will not save them.'**
  String get discardChangesBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// No description provided for @invalidTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Use an IANA time zone such as Europe/Madrid.'**
  String get invalidTimeZone;

  /// No description provided for @patternNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the pattern a name.'**
  String get patternNameRequired;

  /// No description provided for @noShiftPatterns.
  ///
  /// In en, this message translates to:
  /// **'No shift patterns yet.'**
  String get noShiftPatterns;

  /// No description provided for @noSlots.
  ///
  /// In en, this message translates to:
  /// **'No slots on this day.'**
  String get noSlots;

  /// No description provided for @noExceptions.
  ///
  /// In en, this message translates to:
  /// **'No exceptions.'**
  String get noExceptions;

  /// No description provided for @shiftChecklist.
  ///
  /// In en, this message translates to:
  /// **'Shift checklist'**
  String get shiftChecklist;

  /// No description provided for @shiftChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items to tick off on each shift of this pattern.'**
  String get shiftChecklistSubtitle;

  /// No description provided for @addChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add checklist item'**
  String get addChecklistItem;

  /// No description provided for @checklistItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist item'**
  String get checklistItemLabel;

  /// No description provided for @noChecklistItems.
  ///
  /// In en, this message translates to:
  /// **'No checklist items yet.'**
  String get noChecklistItems;

  /// No description provided for @checklistDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String checklistDone(int done, int total);

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @devicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pair your own devices over the local network.'**
  String get devicesSubtitle;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @pairingIdentity.
  ///
  /// In en, this message translates to:
  /// **'Pairing identity'**
  String get pairingIdentity;

  /// No description provided for @pairingIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A local username and PIN. Never sent anywhere.'**
  String get pairingIdentitySubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'At least four digits.'**
  String get pinHint;

  /// No description provided for @createIdentity.
  ///
  /// In en, this message translates to:
  /// **'Create identity'**
  String get createIdentity;

  /// No description provided for @identityCreated.
  ///
  /// In en, this message translates to:
  /// **'Pairing identity created.'**
  String get identityCreated;

  /// No description provided for @editIdentity.
  ///
  /// In en, this message translates to:
  /// **'Edit identity'**
  String get editIdentity;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @identityRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a username and PIN before pairing.'**
  String get identityRequired;

  /// No description provided for @pairDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get pairDevice;

  /// No description provided for @showPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Show a code on this device'**
  String get showPairingCode;

  /// No description provided for @enterPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a code from another device'**
  String get enterPairingCode;

  /// No description provided for @pairingCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get pairingCode;

  /// No description provided for @pairingCodeHint.
  ///
  /// In en, this message translates to:
  /// **'On the other device, choose “Enter a code” and type this code.'**
  String get pairingCodeHint;

  /// No description provided for @pairingExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid for five minutes.'**
  String get pairingExpires;

  /// No description provided for @newCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newCode;

  /// No description provided for @pairingSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Paired with {name}.'**
  String pairingSucceeded(String name);

  /// No description provided for @pairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed: {error}'**
  String pairingFailed(String error);

  /// No description provided for @discoveredOnNetwork.
  ///
  /// In en, this message translates to:
  /// **'Found on this network'**
  String get discoveredOnNetwork;

  /// No description provided for @noDiscoveredDevices.
  ///
  /// In en, this message translates to:
  /// **'No other Sundial devices found yet.'**
  String get noDiscoveredDevices;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @pairedDevices.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get pairedDevices;

  /// No description provided for @noPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'No paired devices yet.'**
  String get noPairedDevices;

  /// No description provided for @unpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get unpair;

  /// No description provided for @unpairQuestion.
  ///
  /// In en, this message translates to:
  /// **'Unpair this device?'**
  String get unpairQuestion;

  /// No description provided for @unpairBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears from this device. The other device keeps its own copy.'**
  String get unpairBody;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String lastSeen(String time);

  /// No description provided for @neverReached.
  ///
  /// In en, this message translates to:
  /// **'Not reached yet'**
  String get neverReached;

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh devices'**
  String get refreshDevices;

  /// No description provided for @remoteToday.
  ///
  /// In en, this message translates to:
  /// **'{entries} entries, {shifts} shifts today'**
  String remoteToday(int entries, int shifts);

  /// No description provided for @remoteNextShift.
  ///
  /// In en, this message translates to:
  /// **'Next shift: {label}'**
  String remoteNextShift(String label);

  /// No description provided for @remoteShopping.
  ///
  /// In en, this message translates to:
  /// **'{count} shopping items open'**
  String remoteShopping(int count);

  /// No description provided for @serverOnPort.
  ///
  /// In en, this message translates to:
  /// **'Server on port {port}'**
  String serverOnPort(int port);

  /// No description provided for @serverOff.
  ///
  /// In en, this message translates to:
  /// **'Server off'**
  String get serverOff;

  /// No description provided for @discoveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network discovery is unavailable. Use the address manually.'**
  String get discoveryUnavailable;

  /// No description provided for @identityFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Certificate fingerprint'**
  String get identityFingerprint;

  /// No description provided for @manualAddress.
  ///
  /// In en, this message translates to:
  /// **'Device address'**
  String get manualAddress;

  /// No description provided for @hostHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.20'**
  String get hostHint;

  /// No description provided for @mcpEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Local MCP endpoint'**
  String get mcpEndpoint;

  /// No description provided for @mcpEndpointSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read-only by default, loopback only, off unless enabled.'**
  String get mcpEndpointSubtitle;

  /// No description provided for @mcpStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the MCP server: {error}'**
  String mcpStartFailed(String error);

  /// No description provided for @mcpWriteTools.
  ///
  /// In en, this message translates to:
  /// **'Allow write tools'**
  String get mcpWriteTools;

  /// No description provided for @mcpWriteToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lets the local agent create and complete entries.'**
  String get mcpWriteToolsSubtitle;

  /// No description provided for @mcpToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get mcpToken;

  /// No description provided for @mcpTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Use it as a Bearer token. Rotating it disconnects existing agents.'**
  String get mcpTokenHint;

  /// No description provided for @rotateToken.
  ///
  /// In en, this message translates to:
  /// **'Rotate token'**
  String get rotateToken;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get copied;

  /// No description provided for @mcpLoopbackHint.
  ///
  /// In en, this message translates to:
  /// **'Bound to 127.0.0.1 only. The agent must run on this machine.'**
  String get mcpLoopbackHint;

  /// No description provided for @mcpRunning.
  ///
  /// In en, this message translates to:
  /// **'Listening on 127.0.0.1:{port}'**
  String mcpRunning(int port);

  /// No description provided for @mcpStopped.
  ///
  /// In en, this message translates to:
  /// **'MCP endpoint is off.'**
  String get mcpStopped;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries, tags and home items'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a title, a note, a tag or a household item.'**
  String get searchPrompt;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String searchNoResults(String query);

  /// No description provided for @searchEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get searchEntries;

  /// No description provided for @searchHomeItems.
  ///
  /// In en, this message translates to:
  /// **'Home items'**
  String get searchHomeItems;

  /// No description provided for @nextShiftPrefix.
  ///
  /// In en, this message translates to:
  /// **'Next: '**
  String get nextShiftPrefix;

  /// No description provided for @backupRestoredReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders have been rescheduled.'**
  String get backupRestoredReminders;

  /// No description provided for @dayView.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayView;

  /// No description provided for @shiftTags.
  ///
  /// In en, this message translates to:
  /// **'Job tags'**
  String get shiftTags;

  /// No description provided for @commuteOverride.
  ///
  /// In en, this message translates to:
  /// **'Commute override'**
  String get commuteOverride;

  /// No description provided for @windDownOverride.
  ///
  /// In en, this message translates to:
  /// **'Wind-down override'**
  String get windDownOverride;

  /// No description provided for @inheritSleepBuffers.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the sleep settings.'**
  String get inheritSleepBuffers;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get endDate;

  /// No description provided for @multiDayHint.
  ///
  /// In en, this message translates to:
  /// **'Leave the end date empty for a single day.'**
  String get multiDayHint;

  /// No description provided for @skipThisOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Skip this occurrence'**
  String get skipThisOccurrence;

  /// No description provided for @skippedOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Skipped dates'**
  String get skippedOccurrences;

  /// No description provided for @recurrenceExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get recurrenceExceptions;

  /// No description provided for @exportCalendar.
  ///
  /// In en, this message translates to:
  /// **'Export calendar (.ics)'**
  String get exportCalendar;

  /// No description provided for @exportCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a read-only calendar file. No account or network is used.'**
  String get exportCalendarSubtitle;

  /// No description provided for @calendarExported.
  ///
  /// In en, this message translates to:
  /// **'Calendar exported to {path}'**
  String calendarExported(String path);

  /// No description provided for @calendarExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the calendar: {error}'**
  String calendarExportFailed(String error);

  /// No description provided for @icsUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count} updated'**
  String icsUpdated(int count);

  /// No description provided for @onlyThisOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Only this occurrence'**
  String get onlyThisOccurrence;

  /// No description provided for @onlyThisOccurrenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the series and change just this date.'**
  String get onlyThisOccurrenceSubtitle;

  /// No description provided for @singleDay.
  ///
  /// In en, this message translates to:
  /// **'Single day'**
  String get singleDay;

  /// No description provided for @automaticBackups.
  ///
  /// In en, this message translates to:
  /// **'Automatic local backups'**
  String get automaticBackups;

  /// No description provided for @automaticBackupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A daily JSON copy in the app folder. Older copies rotate out.'**
  String get automaticBackupsSubtitle;

  /// No description provided for @keepBackups.
  ///
  /// In en, this message translates to:
  /// **'Copies to keep'**
  String get keepBackups;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Entries, shopping or inventory.'**
  String get exportCsvSubtitle;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @importCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Entries, shopping or inventory.'**
  String get importCsvSubtitle;

  /// No description provided for @csvEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get csvEntries;

  /// No description provided for @csvShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get csvShopping;

  /// No description provided for @csvInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get csvInventory;

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported to {path}'**
  String csvExported(String path);

  /// No description provided for @csvExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the CSV: {error}'**
  String csvExportFailed(String error);

  /// No description provided for @csvImportDone.
  ///
  /// In en, this message translates to:
  /// **'{imported} imported, {duplicates} duplicates, {skipped} skipped'**
  String csvImportDone(int imported, int duplicates, int skipped);

  /// No description provided for @csvImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rows to import.'**
  String get csvImportEmpty;

  /// No description provided for @gymmaneImport.
  ///
  /// In en, this message translates to:
  /// **'GymMane schedule'**
  String get gymmaneImport;

  /// No description provided for @gymmaneImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read-only weekly gym blocks from a GymMane JSON backup.'**
  String get gymmaneImportSubtitle;

  /// No description provided for @gymmaneImportDone.
  ///
  /// In en, this message translates to:
  /// **'{imported} blocks imported ({timed} timed, {allDay} all-day), {skipped} skipped.'**
  String gymmaneImportDone(int imported, int timed, int allDay, int skipped);

  /// No description provided for @gymmaneImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import GymMane: {error}'**
  String gymmaneImportFailed(String error);

  /// No description provided for @gymmaneImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'The backup has no weekly plan.'**
  String get gymmaneImportEmpty;

  /// No description provided for @purchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase history'**
  String get purchaseHistory;

  /// No description provided for @purchaseHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No purchases recorded yet.'**
  String get purchaseHistoryEmpty;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items below their minimum stock'**
  String lowStockCount(int count);

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Gadgets'**
  String get maintenance;

  /// No description provided for @maintenanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service schedules for appliances, filters and vehicles.'**
  String get maintenanceSubtitle;

  /// No description provided for @maintenanceDue.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get maintenanceDue;

  /// No description provided for @maintenanceUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get maintenanceUpcoming;

  /// No description provided for @maintenanceNone.
  ///
  /// In en, this message translates to:
  /// **'No maintenance tasks yet.'**
  String get maintenanceNone;

  /// No description provided for @maintenanceDone.
  ///
  /// In en, this message translates to:
  /// **'Done. Next due {date}.'**
  String maintenanceDone(String date);

  /// No description provided for @clearChecked.
  ///
  /// In en, this message translates to:
  /// **'Clear bought'**
  String get clearChecked;

  /// No description provided for @clearCheckedBody.
  ///
  /// In en, this message translates to:
  /// **'Remove every bought line? This cannot be undone.'**
  String get clearCheckedBody;

  /// No description provided for @shoppingToBuy.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get shoppingToBuy;

  /// No description provided for @shoppingBought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get shoppingBought;

  /// No description provided for @shoppingOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get shoppingOther;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @beforeStart.
  ///
  /// In en, this message translates to:
  /// **'Before the start'**
  String get beforeStart;

  /// No description provided for @atTimeSection.
  ///
  /// In en, this message translates to:
  /// **'At a time'**
  String get atTimeSection;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @customReminderHint.
  ///
  /// In en, this message translates to:
  /// **'A custom time fires on the occurrence day in the device timezone.'**
  String get customReminderHint;

  /// No description provided for @workHours.
  ///
  /// In en, this message translates to:
  /// **'Work hours'**
  String get workHours;

  /// No description provided for @workHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide Work tasks outside these hours. Work deadlines stay visible.'**
  String get workHoursSubtitle;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pause notifications during this window.'**
  String get quietHoursSubtitle;

  /// No description provided for @mcpTools.
  ///
  /// In en, this message translates to:
  /// **'MCP tools'**
  String get mcpTools;

  /// No description provided for @mcpToolsHint.
  ///
  /// In en, this message translates to:
  /// **'Loopback only. Initialize returns an Mcp-Session-Id header; clients that accept text/event-stream receive one SSE message per call. Writes stay gated by the switch above.'**
  String get mcpToolsHint;

  /// No description provided for @hoursWindow.
  ///
  /// In en, this message translates to:
  /// **'Set window'**
  String get hoursWindow;

  /// No description provided for @todayTab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// No description provided for @planTab.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @workTab.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workTab;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @personalTab.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalTab;

  /// No description provided for @workSpace.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workSpace;

  /// No description provided for @homeSpace.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeSpace;

  /// No description provided for @personalSpace.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalSpace;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @homes.
  ///
  /// In en, this message translates to:
  /// **'Homes'**
  String get homes;

  /// No description provided for @chooseHome.
  ///
  /// In en, this message translates to:
  /// **'Choose a home'**
  String get chooseHome;

  /// No description provided for @peopleAndGroups.
  ///
  /// In en, this message translates to:
  /// **'People & groups'**
  String get peopleAndGroups;

  /// No description provided for @projectsSection.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsSection;

  /// No description provided for @householdSection.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdSection;

  /// No description provided for @tasksSection.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksSection;

  /// No description provided for @habitsSection.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsSection;

  /// No description provided for @gadgetsSection.
  ///
  /// In en, this message translates to:
  /// **'Gadgets'**
  String get gadgetsSection;

  /// No description provided for @inventorySection.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventorySection;

  /// No description provided for @shoppingSection.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shoppingSection;

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New job'**
  String get newJob;

  /// No description provided for @editJob.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get editJob;

  /// No description provided for @newHome.
  ///
  /// In en, this message translates to:
  /// **'New home'**
  String get newHome;

  /// No description provided for @editHome.
  ///
  /// In en, this message translates to:
  /// **'Edit home'**
  String get editHome;

  /// No description provided for @newPerson.
  ///
  /// In en, this message translates to:
  /// **'New person or group'**
  String get newPerson;

  /// No description provided for @editPerson.
  ///
  /// In en, this message translates to:
  /// **'Edit person or group'**
  String get editPerson;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @jobName.
  ///
  /// In en, this message translates to:
  /// **'Job name'**
  String get jobName;

  /// No description provided for @homeName.
  ///
  /// In en, this message translates to:
  /// **'Home name'**
  String get homeName;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personName;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get projectDescription;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get color;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseIcon;

  /// No description provided for @searchIcons.
  ///
  /// In en, this message translates to:
  /// **'Search icons'**
  String get searchIcons;

  /// No description provided for @noIconsFound.
  ///
  /// In en, this message translates to:
  /// **'No icon matches that search.'**
  String get noIconsFound;

  /// No description provided for @recommendedIcons.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get recommendedIcons;

  /// No description provided for @allIcons.
  ///
  /// In en, this message translates to:
  /// **'All icons'**
  String get allIcons;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @imageHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or keep the icon.'**
  String get imageHintEmpty;

  /// No description provided for @imageHintSet.
  ///
  /// In en, this message translates to:
  /// **'Replace the photo or remove it.'**
  String get imageHintSet;

  /// No description provided for @createJob.
  ///
  /// In en, this message translates to:
  /// **'Create job'**
  String get createJob;

  /// No description provided for @createHome.
  ///
  /// In en, this message translates to:
  /// **'Create home'**
  String get createHome;

  /// No description provided for @createPerson.
  ///
  /// In en, this message translates to:
  /// **'Create person or group'**
  String get createPerson;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet.'**
  String get noJobs;

  /// No description provided for @noJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a job to give its shifts, projects and tasks a home.'**
  String get noJobsHint;

  /// No description provided for @noHomes.
  ///
  /// In en, this message translates to:
  /// **'No homes yet.'**
  String get noHomes;

  /// No description provided for @noHomesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a home to organise inventory, gadgets and house projects.'**
  String get noHomesHint;

  /// No description provided for @noPeople.
  ///
  /// In en, this message translates to:
  /// **'No people or groups yet.'**
  String get noPeople;

  /// No description provided for @noPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Use projects to keep time with different people separate.'**
  String get noPeopleHint;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet.'**
  String get noProjects;

  /// No description provided for @noProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Projects group related tasks without adding another space.'**
  String get noProjectsHint;

  /// No description provided for @noHabits.
  ///
  /// In en, this message translates to:
  /// **'No habits yet.'**
  String get noHabits;

  /// No description provided for @noHabitsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a habit to track a personal routine.'**
  String get noHabitsHint;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get noTasks;

  /// No description provided for @noTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Add a task from this screen or from Today.'**
  String get noTasksHint;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTasks;

  /// No description provided for @openTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get openTasks;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasks;

  /// No description provided for @unscheduledTasks.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get unscheduledTasks;

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No tasks} =1 {1 task} other {{count} tasks}}'**
  String taskCount(int count);

  /// No description provided for @projectCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No projects} =1 {1 project} other {{count} projects}}'**
  String projectCount(int count);

  /// No description provided for @habitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No habits} =1 {1 habit} other {{count} habits}}'**
  String habitCount(int count);

  /// No description provided for @addTaskFor.
  ///
  /// In en, this message translates to:
  /// **'Add a task for {name}'**
  String addTaskFor(String name);

  /// No description provided for @jobSummary.
  ///
  /// In en, this message translates to:
  /// **'Shifts, checklists and work projects'**
  String get jobSummary;

  /// No description provided for @homeSummary.
  ///
  /// In en, this message translates to:
  /// **'Inventory, gadgets and household projects'**
  String get homeSummary;

  /// No description provided for @personalSummary.
  ///
  /// In en, this message translates to:
  /// **'Projects, habits and personal admin'**
  String get personalSummary;

  /// No description provided for @manageJobs.
  ///
  /// In en, this message translates to:
  /// **'Manage jobs'**
  String get manageJobs;

  /// No description provided for @manageHomes.
  ///
  /// In en, this message translates to:
  /// **'Manage homes'**
  String get manageHomes;

  /// No description provided for @managePeople.
  ///
  /// In en, this message translates to:
  /// **'Manage people and groups'**
  String get managePeople;

  /// No description provided for @noContextsYet.
  ///
  /// In en, this message translates to:
  /// **'Create one to get started.'**
  String get noContextsYet;

  /// No description provided for @addFirstContext.
  ///
  /// In en, this message translates to:
  /// **'Create the first one'**
  String get addFirstContext;

  /// No description provided for @shiftChecklists.
  ///
  /// In en, this message translates to:
  /// **'Shift checklists'**
  String get shiftChecklists;

  /// No description provided for @checklistForDay.
  ///
  /// In en, this message translates to:
  /// **'Checklist for day {day}'**
  String checklistForDay(int day);

  /// No description provided for @allDays.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get allDays;

  /// No description provided for @checklistItemHint.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get checklistItemHint;

  /// No description provided for @reorderChecklistHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Different days can have different lists.'**
  String get reorderChecklistHint;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProject;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get addHabit;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @targetPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Target per week'**
  String get targetPerWeek;

  /// No description provided for @timesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count}× per week'**
  String timesPerWeek(int count);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String streakDays(int count);

  /// No description provided for @streakWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} week streak'**
  String streakWeeks(int count);

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @habitHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get habitHistory;

  /// No description provided for @habitActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get habitActiveDays;

  /// No description provided for @habitCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get habitCheckIns;

  /// No description provided for @habitHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Filled days are done. Outlined days are scheduled.'**
  String get habitHistoryHint;

  /// No description provided for @markHabitDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markHabitDone;

  /// No description provided for @habitDone.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get habitDone;

  /// No description provided for @addGadget.
  ///
  /// In en, this message translates to:
  /// **'Add gadget'**
  String get addGadget;

  /// No description provided for @gadgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit gadget'**
  String get gadgetEdit;

  /// No description provided for @gadgetIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get gadgetIcon;

  /// No description provided for @gadgetIntervalDays.
  ///
  /// In en, this message translates to:
  /// **'Interval (days)'**
  String get gadgetIntervalDays;

  /// No description provided for @gadgetLastServiced.
  ///
  /// In en, this message translates to:
  /// **'Last serviced'**
  String get gadgetLastServiced;

  /// No description provided for @gadgetNeverServiced.
  ///
  /// In en, this message translates to:
  /// **'Never serviced'**
  String get gadgetNeverServiced;

  /// No description provided for @gadgetLastServicedOn.
  ///
  /// In en, this message translates to:
  /// **'Last serviced {date}'**
  String gadgetLastServicedOn(String date);

  /// No description provided for @gadgetNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String gadgetNextDue(String date);

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @clearText.
  ///
  /// In en, this message translates to:
  /// **'Clear text'**
  String get clearText;

  /// No description provided for @gadgetName.
  ///
  /// In en, this message translates to:
  /// **'Gadget name'**
  String get gadgetName;

  /// No description provided for @maintenanceIntervalDays.
  ///
  /// In en, this message translates to:
  /// **'Days between services'**
  String get maintenanceIntervalDays;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String nextDue(String date);

  /// No description provided for @deleteContextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteContextQuestion(String name);

  /// No description provided for @deleteContextBody.
  ///
  /// In en, this message translates to:
  /// **'Its tasks stay in your plan but lose this grouping. Its shifts, habits and household links are removed.'**
  String get deleteContextBody;

  /// No description provided for @deleteProjectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this project?'**
  String get deleteProjectQuestion;

  /// No description provided for @deleteProjectBody.
  ///
  /// In en, this message translates to:
  /// **'Tasks lose this project but keep their space and context.'**
  String get deleteProjectBody;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @timelineView.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineView;

  /// No description provided for @progressToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get progressToday;

  /// No description provided for @doneOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String doneOfTotal(int done, int total);

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'Everything for today is done.'**
  String get allDone;

  /// No description provided for @tasksLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left today'**
  String tasksLeft(int count);

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get clockOut;

  /// No description provided for @clockedIn.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get clockedIn;

  /// No description provided for @trackedTime.
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get trackedTime;

  /// No description provided for @trackedTimeValue.
  ///
  /// In en, this message translates to:
  /// **'{duration} tracked'**
  String trackedTimeValue(String duration);

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @dueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {time}'**
  String dueIn(String time);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityNone.
  ///
  /// In en, this message translates to:
  /// **'No priority'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @completeTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get completeTask;

  /// No description provided for @reopenTask.
  ///
  /// In en, this message translates to:
  /// **'Reopen task'**
  String get reopenTask;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @collapseCalendar.
  ///
  /// In en, this message translates to:
  /// **'Collapse calendar'**
  String get collapseCalendar;

  /// No description provided for @expandCalendar.
  ///
  /// In en, this message translates to:
  /// **'Expand calendar'**
  String get expandCalendar;

  /// No description provided for @desktopWeekHint.
  ///
  /// In en, this message translates to:
  /// **'Drag blocks to move them, drag the bottom edge to resize, or drag an empty slot to create.'**
  String get desktopWeekHint;

  /// No description provided for @createEntryAt.
  ///
  /// In en, this message translates to:
  /// **'Create at {time}'**
  String createEntryAt(String time);

  /// No description provided for @entryMoved.
  ///
  /// In en, this message translates to:
  /// **'Entry moved.'**
  String get entryMoved;

  /// No description provided for @couldNotMoveEntry.
  ///
  /// In en, this message translates to:
  /// **'Could not move the entry: {error}'**
  String couldNotMoveEntry(String error);

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRate;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get tasksCompleted;

  /// No description provided for @overdueDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Overdue deadlines'**
  String get overdueDeadlines;

  /// No description provided for @bySpace.
  ///
  /// In en, this message translates to:
  /// **'By space'**
  String get bySpace;

  /// No description provided for @byProject.
  ///
  /// In en, this message translates to:
  /// **'By project'**
  String get byProject;

  /// No description provided for @byDay.
  ///
  /// In en, this message translates to:
  /// **'By day'**
  String get byDay;

  /// No description provided for @habitConsistency.
  ///
  /// In en, this message translates to:
  /// **'Habit consistency'**
  String get habitConsistency;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get rangeMonth;

  /// No description provided for @rangeQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get rangeQuarter;

  /// No description provided for @rangeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get rangeYear;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// No description provided for @exportSummaryReport.
  ///
  /// In en, this message translates to:
  /// **'Summary report'**
  String get exportSummaryReport;

  /// No description provided for @exportSummaryCsv.
  ///
  /// In en, this message translates to:
  /// **'Summary CSV'**
  String get exportSummaryCsv;

  /// No description provided for @exportDetailedCsv.
  ///
  /// In en, this message translates to:
  /// **'Detailed CSV'**
  String get exportDetailedCsv;

  /// No description provided for @exportDetailedReport.
  ///
  /// In en, this message translates to:
  /// **'Detailed report (PDF)'**
  String get exportDetailedReport;

  /// No description provided for @exportReportCsv.
  ///
  /// In en, this message translates to:
  /// **'Report (CSV)'**
  String get exportReportCsv;

  /// No description provided for @reportExported.
  ///
  /// In en, this message translates to:
  /// **'Report saved.'**
  String get reportExported;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the report: {error}'**
  String reportFailed(String error);

  /// No description provided for @totalTracked.
  ///
  /// In en, this message translates to:
  /// **'Total tracked'**
  String get totalTracked;

  /// No description provided for @shiftHours.
  ///
  /// In en, this message translates to:
  /// **'Shift hours'**
  String get shiftHours;

  /// No description provided for @shiftHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Scheduled shifts in this range. Not counted as tracked time.'**
  String get shiftHoursHint;

  /// No description provided for @shareOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareOfTotal;

  /// No description provided for @noTrackedTime.
  ///
  /// In en, this message translates to:
  /// **'No tracked time in this range.'**
  String get noTrackedTime;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @deadlineLoad.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get deadlineLoad;

  /// No description provided for @settingsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearch;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @noSettingsFound.
  ///
  /// In en, this message translates to:
  /// **'No setting matches that search.'**
  String get noSettingsFound;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, colour, background and text size'**
  String get appearanceSubtitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, dates, hours and reminders'**
  String get preferencesSubtitle;

  /// No description provided for @dataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backups, calendars, CSV and local data'**
  String get dataSubtitle;

  /// No description provided for @onlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pair devices and run the local MCP endpoint'**
  String get onlineSubtitle;

  /// No description provided for @themeAero.
  ///
  /// In en, this message translates to:
  /// **'Aero'**
  String get themeAero;

  /// No description provided for @colorScheme.
  ///
  /// In en, this message translates to:
  /// **'Colour scheme'**
  String get colorScheme;

  /// No description provided for @schemeSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get schemeSage;

  /// No description provided for @schemeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get schemeOcean;

  /// No description provided for @schemeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get schemeSunset;

  /// No description provided for @schemeViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get schemeViolet;

  /// No description provided for @schemeMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get schemeMono;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @backgroundDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get backgroundDots;

  /// No description provided for @backgroundGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get backgroundGrid;

  /// No description provided for @backgroundOled.
  ///
  /// In en, this message translates to:
  /// **'OLED black'**
  String get backgroundOled;

  /// No description provided for @backgroundPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get backgroundPlain;

  /// No description provided for @backgroundCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get backgroundCustom;

  /// No description provided for @customBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Custom colour'**
  String get customBackgroundColor;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textSmall;

  /// No description provided for @textDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textDefault;

  /// No description provided for @textLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textLarge;

  /// No description provided for @textExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textExtraLarge;

  /// No description provided for @navigationSide.
  ///
  /// In en, this message translates to:
  /// **'Navigation side'**
  String get navigationSide;

  /// No description provided for @navLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get navLeft;

  /// No description provided for @navRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get navRight;

  /// No description provided for @dateFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get dateFormatLabel;

  /// No description provided for @dateFormatSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get dateFormatSystem;

  /// No description provided for @dateFormatDmy.
  ///
  /// In en, this message translates to:
  /// **'Day / month / year'**
  String get dateFormatDmy;

  /// No description provided for @dateFormatMdy.
  ///
  /// In en, this message translates to:
  /// **'Month / day / year'**
  String get dateFormatMdy;

  /// No description provided for @dateFormatYmd.
  ///
  /// In en, this message translates to:
  /// **'Year / month / day'**
  String get dateFormatYmd;

  /// No description provided for @performanceMode.
  ///
  /// In en, this message translates to:
  /// **'Performance mode'**
  String get performanceMode;

  /// No description provided for @performanceModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce blur, shadows and long animations.'**
  String get performanceModeSubtitle;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data and backup'**
  String get dataSection;

  /// No description provided for @onlineSection.
  ///
  /// In en, this message translates to:
  /// **'Online functionalities'**
  String get onlineSection;

  /// No description provided for @onlineEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable online functionalities'**
  String get onlineEnable;

  /// No description provided for @onlineEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LAN sync and the local MCP endpoint. Off by default; the planner works without them.'**
  String get onlineEnableSubtitle;

  /// No description provided for @devicesAndSync.
  ///
  /// In en, this message translates to:
  /// **'Devices & Sync'**
  String get devicesAndSync;

  /// No description provided for @devicesAndSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find devices on this network and pair them.'**
  String get devicesAndSyncSubtitle;

  /// No description provided for @mcpServer.
  ///
  /// In en, this message translates to:
  /// **'MCP Server'**
  String get mcpServer;

  /// No description provided for @mcpPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get mcpPort;

  /// No description provided for @mcpPortHint.
  ///
  /// In en, this message translates to:
  /// **'Loopback port between 1024 and 65535.'**
  String get mcpPortHint;

  /// No description provided for @applyPort.
  ///
  /// In en, this message translates to:
  /// **'Apply port'**
  String get applyPort;

  /// No description provided for @portSaved.
  ///
  /// In en, this message translates to:
  /// **'MCP endpoint now uses port {port}.'**
  String portSaved(int port);

  /// No description provided for @mcpPortUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not use port {port}. It may already be in use.'**
  String mcpPortUnavailable(int port);

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the plan, devices, backups links and settings from this device.'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteAllDataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete all local data?'**
  String get deleteAllDataQuestion;

  /// No description provided for @deleteAllDataBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Exported files are not deleted.'**
  String get deleteAllDataBody;

  /// No description provided for @dataDeleted.
  ///
  /// In en, this message translates to:
  /// **'Local data deleted.'**
  String get dataDeleted;

  /// No description provided for @dataDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete local data. Nothing was removed.'**
  String get dataDeleteFailed;

  /// No description provided for @dataDeleteIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The plan was deleted, but some media or automatic backups could not be removed. Check storage permissions and delete them from the app\'s data folder.'**
  String get dataDeleteIncomplete;

  /// No description provided for @nearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get nearbyDevices;

  /// No description provided for @scanningDevices.
  ///
  /// In en, this message translates to:
  /// **'Looking for Sundial devices on this network…'**
  String get scanningDevices;

  /// No description provided for @noNearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'No nearby Sundial devices found. Make sure the other device has online functionalities enabled.'**
  String get noNearbyDevices;

  /// No description provided for @pairWithDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair with {name}'**
  String pairWithDevice(String name);

  /// No description provided for @pairCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get pairCode;

  /// No description provided for @pairCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit code shown on the other device.'**
  String get pairCodeHint;

  /// No description provided for @pairingWith.
  ///
  /// In en, this message translates to:
  /// **'Pairing with {name}'**
  String pairingWith(String name);

  /// No description provided for @syncExplainer.
  ///
  /// In en, this message translates to:
  /// **'Sundial finds your other devices on the local network. Pairing stores a shared key once, so changing networks or IP addresses does not break the link. Sync stays read-only and never replaces your local plan.'**
  String get syncExplainer;

  /// No description provided for @pairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device paired.'**
  String get pairSuccess;

  /// No description provided for @pairFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pair: {error}'**
  String pairFailed(String error);

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @timingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get timingScheduled;

  /// No description provided for @timingClockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get timingClockIn;

  /// No description provided for @timingDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get timingDeadline;

  /// No description provided for @timingAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get timingAnytime;

  /// No description provided for @timingScheduledHint.
  ///
  /// In en, this message translates to:
  /// **'Starts and ends at a set time.'**
  String get timingScheduledHint;

  /// No description provided for @timingClockInHint.
  ///
  /// In en, this message translates to:
  /// **'Clock in when you start; clocking out pauses and keeps the tracked time.'**
  String get timingClockInHint;

  /// No description provided for @timingDeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'Can happen any time until the deadline.'**
  String get timingDeadlineHint;

  /// No description provided for @timingAnytimeHint.
  ///
  /// In en, this message translates to:
  /// **'No fixed time. Complete it whenever it is done.'**
  String get timingAnytimeHint;

  /// No description provided for @context.
  ///
  /// In en, this message translates to:
  /// **'Job, home or person'**
  String get context;

  /// No description provided for @noContext.
  ///
  /// In en, this message translates to:
  /// **'No job, home or person'**
  String get noContext;

  /// No description provided for @noProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get noProject;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get noCategories;

  /// No description provided for @stickerImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get stickerImage;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick an image'**
  String get pickImage;

  /// No description provided for @zoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch or scroll to zoom and drag to frame the square.'**
  String get zoomHint;

  /// No description provided for @tolerance.
  ///
  /// In en, this message translates to:
  /// **'Background tolerance'**
  String get tolerance;

  /// No description provided for @outline.
  ///
  /// In en, this message translates to:
  /// **'White sticker outline'**
  String get outline;

  /// No description provided for @outlineWidth.
  ///
  /// In en, this message translates to:
  /// **'Outline width'**
  String get outlineWidth;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @useImage.
  ///
  /// In en, this message translates to:
  /// **'Use image'**
  String get useImage;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image selected.'**
  String get noImage;

  /// No description provided for @imageError.
  ///
  /// In en, this message translates to:
  /// **'Could not load that image.'**
  String get imageError;

  /// No description provided for @choosePhotoOrIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo or use an icon'**
  String get choosePhotoOrIcon;

  /// No description provided for @mediaHint.
  ///
  /// In en, this message translates to:
  /// **'Crop the image, remove a plain background and add a white sticker outline.'**
  String get mediaHint;

  /// No description provided for @soundSection.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get soundSection;

  /// No description provided for @interactionSounds.
  ///
  /// In en, this message translates to:
  /// **'Interaction sounds'**
  String get interactionSounds;

  /// No description provided for @interactionSoundsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short, quiet blips for taps, tabs, completions and clock actions. Off by default.'**
  String get interactionSoundsSubtitle;

  /// No description provided for @soundPackLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound pack'**
  String get soundPackLabel;

  /// No description provided for @soundPackSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get soundPackSoft;

  /// No description provided for @soundPackAero.
  ///
  /// In en, this message translates to:
  /// **'Aero'**
  String get soundPackAero;

  /// No description provided for @previewSound.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewSound;

  /// No description provided for @alarmSounds.
  ///
  /// In en, this message translates to:
  /// **'Alarm sounds'**
  String get alarmSounds;

  /// No description provided for @alarmSoundsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used by scheduled reminders.'**
  String get alarmSoundsSubtitle;

  /// No description provided for @alarmSoundSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get alarmSoundSoft;

  /// No description provided for @alarmSoundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get alarmSoundChime;

  /// No description provided for @alarmSoundBright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get alarmSoundBright;

  /// No description provided for @timezoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zone for new timed entries. Display follows the device.'**
  String get timezoneSubtitle;

  /// No description provided for @timezoneDevice.
  ///
  /// In en, this message translates to:
  /// **'Device time zone'**
  String get timezoneDevice;

  /// No description provided for @timezoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search city or region'**
  String get timezoneSearch;

  /// No description provided for @timezoneUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Use device time zone'**
  String get timezoneUseDevice;

  /// No description provided for @planningTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Planning time zone'**
  String get planningTimeZone;

  /// No description provided for @repeatEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get repeatEnds;

  /// No description provided for @repeatEndsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatEndsNever;

  /// No description provided for @repeatEndsOnDate.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get repeatEndsOnDate;

  /// No description provided for @repeatEndsAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get repeatEndsAfter;

  /// No description provided for @repeatOccurrences.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String repeatOccurrences(int count);

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get repeatEvery;

  /// No description provided for @repeatUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get repeatUnitDays;

  /// No description provided for @repeatUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get repeatUnitWeeks;

  /// No description provided for @repeatUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get repeatUnitMonths;

  /// No description provided for @repeatUnitYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get repeatUnitYears;

  /// No description provided for @repeatOnDays.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOnDays;

  /// No description provided for @repeatMonthlyMode.
  ///
  /// In en, this message translates to:
  /// **'Monthly pattern'**
  String get repeatMonthlyMode;

  /// No description provided for @repeatMonthlyDay.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get repeatMonthlyDay;

  /// No description provided for @repeatMonthlyOrdinal.
  ///
  /// In en, this message translates to:
  /// **'Weekday position'**
  String get repeatMonthlyOrdinal;

  /// No description provided for @repeatOrdinalFirst.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get repeatOrdinalFirst;

  /// No description provided for @repeatOrdinalSecond.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get repeatOrdinalSecond;

  /// No description provided for @repeatOrdinalThird.
  ///
  /// In en, this message translates to:
  /// **'Third'**
  String get repeatOrdinalThird;

  /// No description provided for @repeatOrdinalFourth.
  ///
  /// In en, this message translates to:
  /// **'Fourth'**
  String get repeatOrdinalFourth;

  /// No description provided for @repeatOrdinalLast.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get repeatOrdinalLast;

  /// No description provided for @repeatEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get repeatEndDate;

  /// No description provided for @repeatSummaryNever.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get repeatSummaryNever;

  /// No description provided for @clearStart.
  ///
  /// In en, this message translates to:
  /// **'Clear start'**
  String get clearStart;

  /// No description provided for @clearEnd.
  ///
  /// In en, this message translates to:
  /// **'Clear end'**
  String get clearEnd;

  /// No description provided for @clearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get clearTime;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setTime;

  /// No description provided for @timeFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a time like 9:30 or 21:30.'**
  String get timeFieldInvalid;

  /// No description provided for @noTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get noTime;

  /// No description provided for @pauseTask.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTask;

  /// No description provided for @resumeTask.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeTask;

  /// No description provided for @finishTask.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishTask;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @sessionsTracked.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String sessionsTracked(int count);

  /// No description provided for @sessionsTrackedOne.
  ///
  /// In en, this message translates to:
  /// **'1 session'**
  String get sessionsTrackedOne;

  /// No description provided for @recurrenceUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String recurrenceUntil(Object date);

  /// No description provided for @homeInventoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start from the household catalog or add something custom.'**
  String get homeInventoryEmptyBody;

  /// No description provided for @addInventoryItem.
  ///
  /// In en, this message translates to:
  /// **'Add to inventory'**
  String get addInventoryItem;

  /// No description provided for @browseHouseholdCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse the household catalog'**
  String get browseHouseholdCatalog;

  /// No description provided for @householdCatalog.
  ///
  /// In en, this message translates to:
  /// **'Household catalog'**
  String get householdCatalog;

  /// No description provided for @catalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Common household items with sensible defaults.'**
  String get catalogSubtitle;

  /// No description provided for @catalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search olive oil, toilet paper, coffee…'**
  String get catalogSearchHint;

  /// No description provided for @catalogNoResults.
  ///
  /// In en, this message translates to:
  /// **'No catalog items match.'**
  String get catalogNoResults;

  /// No description provided for @catalogInInventory.
  ///
  /// In en, this message translates to:
  /// **'In inventory'**
  String get catalogInInventory;

  /// No description provided for @catalogAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get catalogAddItem;

  /// No description provided for @createCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Create a custom item'**
  String get createCustomItem;

  /// No description provided for @createCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Something that is not in the catalog.'**
  String get createCustomHint;

  /// No description provided for @inventorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search inventory'**
  String get inventorySearch;

  /// No description provided for @inventoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryFilterAll;

  /// No description provided for @inventoryFilterLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventoryFilterLow;

  /// No description provided for @inventoryFilterExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get inventoryFilterExpiring;

  /// No description provided for @inventoryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No items match these filters.'**
  String get inventoryNoMatches;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsCount(int count);

  /// No description provided for @productsCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 product'**
  String get productsCountOne;

  /// No description provided for @variantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sizes'**
  String variantsCount(int count);

  /// No description provided for @variantsCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 size'**
  String get variantsCountOne;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockItems;

  /// No description provided for @expiringItems.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringItems;

  /// No description provided for @expiredItems.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredItems;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @expiresAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires at'**
  String get expiresAtLabel;

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get noExpiry;

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String expiredOn(String date);

  /// No description provided for @minimumStock.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock'**
  String get minimumStock;

  /// No description provided for @minStockValue.
  ///
  /// In en, this message translates to:
  /// **'Min {quantity}'**
  String minStockValue(String quantity);

  /// No description provided for @packSize.
  ///
  /// In en, this message translates to:
  /// **'Size / pack'**
  String get packSize;

  /// No description provided for @packSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5 gal bottle, 1 kg bag'**
  String get packSizeHint;

  /// No description provided for @packSizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this size a pack description, for example 5 gal or 1 kg.'**
  String get packSizeRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locations;

  /// No description provided for @addAnotherSize.
  ///
  /// In en, this message translates to:
  /// **'Add another size'**
  String get addAnotherSize;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @variantEditHint.
  ///
  /// In en, this message translates to:
  /// **'Changes here apply to this size only. Open the product to rename every size.'**
  String get variantEditHint;

  /// No description provided for @archiveProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this product?'**
  String get archiveProductQuestion;

  /// No description provided for @archiveProductBody.
  ///
  /// In en, this message translates to:
  /// **'Every size of this product leaves the inventory but stays in backups.'**
  String get archiveProductBody;

  /// No description provided for @archiveVariantQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this size?'**
  String get archiveVariantQuestion;

  /// No description provided for @archiveVariantBody.
  ///
  /// In en, this message translates to:
  /// **'This size leaves the inventory. Other sizes stay.'**
  String get archiveVariantBody;

  /// No description provided for @inventorySetup.
  ///
  /// In en, this message translates to:
  /// **'Inventory setup'**
  String get inventorySetup;

  /// No description provided for @inventorySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Categories, locations and units'**
  String get inventorySetupSubtitle;

  /// No description provided for @manageInventorySetup.
  ///
  /// In en, this message translates to:
  /// **'Manage categories, locations and units'**
  String get manageInventorySetup;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get manageCategories;

  /// No description provided for @manageLocations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get manageLocations;

  /// No description provided for @manageUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get manageUnits;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newLocation.
  ///
  /// In en, this message translates to:
  /// **'New location'**
  String get newLocation;

  /// No description provided for @editLocation.
  ///
  /// In en, this message translates to:
  /// **'Edit location'**
  String get editLocation;

  /// No description provided for @newUnit.
  ///
  /// In en, this message translates to:
  /// **'New unit'**
  String get newUnit;

  /// No description provided for @editUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit unit'**
  String get editUnit;

  /// No description provided for @noLocations.
  ///
  /// In en, this message translates to:
  /// **'No locations yet.'**
  String get noLocations;

  /// No description provided for @noUnits.
  ///
  /// In en, this message translates to:
  /// **'No units yet.'**
  String get noUnits;

  /// No description provided for @duplicateName.
  ///
  /// In en, this message translates to:
  /// **'That name is already in use.'**
  String get duplicateName;

  /// No description provided for @categoryManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give each kind of household item a color and icon.'**
  String get categoryManagerSubtitle;

  /// No description provided for @locationManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where things live in and around the house.'**
  String get locationManagerSubtitle;

  /// No description provided for @unitManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How you count, weigh or measure stock.'**
  String get unitManagerSubtitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @locationName.
  ///
  /// In en, this message translates to:
  /// **'Location name'**
  String get locationName;

  /// No description provided for @unitName.
  ///
  /// In en, this message translates to:
  /// **'Unit name'**
  String get unitName;

  /// No description provided for @unitSymbol.
  ///
  /// In en, this message translates to:
  /// **'Short form'**
  String get unitSymbol;

  /// No description provided for @unitKind.
  ///
  /// In en, this message translates to:
  /// **'Unit type'**
  String get unitKind;

  /// No description provided for @unitKindCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get unitKindCount;

  /// No description provided for @unitKindWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get unitKindWeight;

  /// No description provided for @unitKindVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get unitKindVolume;

  /// No description provided for @unitKindLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get unitKindLength;

  /// No description provided for @unitKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get unitKindOther;

  /// No description provided for @deleteCategoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get deleteCategoryQuestion;

  /// No description provided for @deleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Items keep their text category until you edit them.'**
  String get deleteCategoryBody;

  /// No description provided for @deleteLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this location?'**
  String get deleteLocationQuestion;

  /// No description provided for @deleteLocationBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from every item that uses it.'**
  String get deleteLocationBody;

  /// No description provided for @deleteUnitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this unit?'**
  String get deleteUnitQuestion;

  /// No description provided for @deleteUnitBody.
  ///
  /// In en, this message translates to:
  /// **'Items keep the unit text until you edit them.'**
  String get deleteUnitBody;

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStockCount(String count);

  /// No description provided for @shoppingListEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add an item or let the inventory suggest what is running low.'**
  String get shoppingListEmptyBody;

  /// No description provided for @couldNotLoadHome.
  ///
  /// In en, this message translates to:
  /// **'Could not load household data: {error}'**
  String couldNotLoadHome(Object error);

  /// No description provided for @stockSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Stock suggestions'**
  String get stockSuggestions;

  /// No description provided for @stockSuggestionsBody.
  ///
  /// In en, this message translates to:
  /// **'From your inventory, ready to add.'**
  String get stockSuggestionsBody;

  /// No description provided for @addAllSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Add all'**
  String get addAllSuggestions;

  /// No description provided for @suggestionLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock · buy {quantity}'**
  String suggestionLowStock(String quantity);

  /// No description provided for @suggestionOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get suggestionOutOfStock;

  /// No description provided for @suggestionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired · replace'**
  String get suggestionExpired;

  /// No description provided for @suggestionAlreadyListed.
  ///
  /// In en, this message translates to:
  /// **'On the list'**
  String get suggestionAlreadyListed;

  /// No description provided for @addSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addSuggestion;

  /// No description provided for @shoppingSearch.
  ///
  /// In en, this message translates to:
  /// **'Search the list'**
  String get shoppingSearch;

  /// No description provided for @shoppingOneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off item'**
  String get shoppingOneOff;

  /// No description provided for @shoppingOneOffHint.
  ///
  /// In en, this message translates to:
  /// **'Something you do not keep in inventory.'**
  String get shoppingOneOffHint;

  /// No description provided for @shoppingAddHint.
  ///
  /// In en, this message translates to:
  /// **'What do you need to buy?'**
  String get shoppingAddHint;

  /// No description provided for @linkedInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get linkedInventory;

  /// No description provided for @linkedTo.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String linkedTo(String name);

  /// No description provided for @restocksInventory.
  ///
  /// In en, this message translates to:
  /// **'Restocks inventory'**
  String get restocksInventory;

  /// No description provided for @addedToInventory.
  ///
  /// In en, this message translates to:
  /// **'Added {quantity} to {name}.'**
  String addedToInventory(String quantity, String name);

  /// No description provided for @shoppingItemCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get shoppingItemCategory;

  /// No description provided for @shoppingItemQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get shoppingItemQuantity;

  /// No description provided for @shoppingItemUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get shoppingItemUnit;

  /// No description provided for @shoppingItemPack.
  ///
  /// In en, this message translates to:
  /// **'Size / pack'**
  String get shoppingItemPack;

  /// No description provided for @shoppingItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String shoppingItemsCount(int count);

  /// No description provided for @shoppingItemsCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 item'**
  String get shoppingItemsCountOne;

  /// No description provided for @noShoppingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs restocking.'**
  String get noShoppingSuggestions;

  /// No description provided for @markBought.
  ///
  /// In en, this message translates to:
  /// **'Mark bought'**
  String get markBought;

  /// No description provided for @markNotBought.
  ///
  /// In en, this message translates to:
  /// **'Mark not bought'**
  String get markNotBought;

  /// No description provided for @gadgetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No gadgets yet.'**
  String get gadgetsEmpty;

  /// No description provided for @gadgetsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Track the AC, water tank, boiler, car and anything else that needs service.'**
  String get gadgetsEmptyBody;

  /// No description provided for @gadgetAll.
  ///
  /// In en, this message translates to:
  /// **'All gadgets'**
  String get gadgetAll;

  /// No description provided for @gadgetEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String gadgetEveryDays(int count);

  /// No description provided for @gadgetDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get gadgetDueToday;

  /// No description provided for @gadgetDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {count} days'**
  String gadgetDueIn(int count);

  /// No description provided for @gadgetOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {count} days'**
  String gadgetOverdueBy(int count);

  /// No description provided for @gadgetNoTime.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get gadgetNoTime;

  /// No description provided for @gadgetTimeRange.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end}'**
  String gadgetTimeRange(String start, String end);

  /// No description provided for @logService.
  ///
  /// In en, this message translates to:
  /// **'Log service'**
  String get logService;

  /// No description provided for @logServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Log service'**
  String get logServiceTitle;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Service date'**
  String get serviceDate;

  /// No description provided for @serviceNote.
  ///
  /// In en, this message translates to:
  /// **'What was done?'**
  String get serviceNote;

  /// No description provided for @serviceNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for the history'**
  String get serviceNoteHint;

  /// No description provided for @serviceLogged.
  ///
  /// In en, this message translates to:
  /// **'Service logged. Next due {date}.'**
  String serviceLogged(String date);

  /// No description provided for @couldNotLogService.
  ///
  /// In en, this message translates to:
  /// **'Could not log the service. Check the gadget and try again.'**
  String get couldNotLogService;

  /// No description provided for @couldNotReschedule.
  ///
  /// In en, this message translates to:
  /// **'Could not reschedule. The gadget may have changed.'**
  String get couldNotReschedule;

  /// No description provided for @serviceHistory.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get serviceHistory;

  /// No description provided for @serviceHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No services logged yet.'**
  String get serviceHistoryEmpty;

  /// No description provided for @serviceHistoryNext.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String serviceHistoryNext(String date);

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @rescheduleMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Reschedule maintenance'**
  String get rescheduleMaintenance;

  /// No description provided for @rescheduleBody.
  ///
  /// In en, this message translates to:
  /// **'Move the next due date without logging a service.'**
  String get rescheduleBody;

  /// No description provided for @newDueDate.
  ///
  /// In en, this message translates to:
  /// **'New due date'**
  String get newDueDate;

  /// No description provided for @rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}.'**
  String rescheduled(String date);

  /// No description provided for @addCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addCalendarEvent;

  /// No description provided for @addCalendarEventBody.
  ///
  /// In en, this message translates to:
  /// **'Record the service as a completed event with a time block.'**
  String get addCalendarEventBody;

  /// No description provided for @serviceAt.
  ///
  /// In en, this message translates to:
  /// **'Service time'**
  String get serviceAt;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String durationHours(int count);

  /// No description provided for @durationCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get durationCustom;

  /// No description provided for @durationMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get durationMinutesLabel;

  /// No description provided for @blockCalendar.
  ///
  /// In en, this message translates to:
  /// **'Show on the calendar'**
  String get blockCalendar;

  /// No description provided for @blockCalendarBody.
  ///
  /// In en, this message translates to:
  /// **'Reserve a time block on the due date.'**
  String get blockCalendarBody;

  /// No description provided for @serviceEventTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} service'**
  String serviceEventTitle(String name);

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveSettings;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
