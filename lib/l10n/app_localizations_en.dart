// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sundial';

  @override
  String get today => 'Today';

  @override
  String get week => 'Week';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get tags => 'Tags';

  @override
  String get shifts => 'Shifts';

  @override
  String get about => 'About';

  @override
  String get close => 'Close';

  @override
  String get moreActions => 'More actions';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get addEntry => 'Add an entry';

  @override
  String get addSomething => 'Add something';

  @override
  String get addOnThisDay => 'Add on this day';

  @override
  String get noPlanToday => 'Nothing planned for today.';

  @override
  String get noPlanTodayHint => 'That is allowed. If something is missing, add it now.';

  @override
  String get nothingPlanned => 'Nothing planned';

  @override
  String get shiftsSection => 'Shifts';

  @override
  String couldNotLoadDay(String error) {
    return 'Could not load your day: $error';
  }

  @override
  String couldNotLoadShifts(String error) {
    return 'Could not load shifts: $error';
  }

  @override
  String get allDay => 'All day';

  @override
  String get overnightSuffix => '(+1 day)';

  @override
  String get importedEvent => 'Imported calendar event';

  @override
  String get readOnlyNotice => 'This event comes from an imported calendar and is read-only.';

  @override
  String get newEntry => 'New entry';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get titleQuestion => 'What is it?';

  @override
  String get titleRequired => 'Give it a name';

  @override
  String get space => 'Space';

  @override
  String get type => 'Type';

  @override
  String get date => 'Date';

  @override
  String get starts => 'Starts';

  @override
  String get ends => 'Ends';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatYearly => 'Every year';

  @override
  String get repeatAfterCompletion => 'Repeat after completion';

  @override
  String get repeatAfterCompletionSubtitle => 'Schedule the next one from the day you finish.';

  @override
  String get daysRequired => 'Use a number of days greater than zero.';

  @override
  String daysValue(int count) {
    return '$count days';
  }

  @override
  String get repeatAfterDaysLabel => 'Days between completions';

  @override
  String couldNotComplete(String error) {
    return 'Could not complete: $error';
  }

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteEntryQuestion => 'Delete this entry?';

  @override
  String get deleteEntryBody => 'It will disappear from your plan.';

  @override
  String get endAfterStartError => 'The end time has to be after the start.';

  @override
  String couldNotSave(String error) {
    return 'Could not save: $error';
  }

  @override
  String couldNotDelete(String error) {
    return 'Could not delete: $error';
  }

  @override
  String timesDefinedIn(String timeZone) {
    return 'Times are defined in $timeZone';
  }

  @override
  String markAsDone(String title) {
    return 'Mark $title as done';
  }

  @override
  String get entryKindTask => 'Task';

  @override
  String get entryKindEvent => 'Event';

  @override
  String get entryKindObligation => 'Obligation';

  @override
  String get entryKindDeadline => 'Deadline';

  @override
  String get recurrenceEveryDay => 'Every day';

  @override
  String recurrenceEveryNDays(int count) {
    return 'Every $count days';
  }

  @override
  String get recurrenceEveryWeek => 'Every week';

  @override
  String recurrenceEveryNWeeks(int count) {
    return 'Every $count weeks';
  }

  @override
  String recurrenceOnDays(String days) {
    return 'Every week on $days';
  }

  @override
  String recurrenceEveryNWeeksOnDays(int count, String days) {
    return 'Every $count weeks on $days';
  }

  @override
  String get recurrenceEveryMonth => 'Every month';

  @override
  String recurrenceEveryNMonths(int count) {
    return 'Every $count months';
  }

  @override
  String recurrenceEveryNMonthsOnDay(int count, int day) {
    return 'Every $count months on day $day';
  }

  @override
  String recurrenceOnDayOfMonth(int day) {
    return 'Every month on day $day';
  }

  @override
  String get recurrenceEveryYear => 'Every year';

  @override
  String recurrenceEveryNYears(int count) {
    return 'Every $count years';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get jumpToToday => 'Jump to today';

  @override
  String get monthView => 'Month';

  @override
  String get weekView => 'Week';

  @override
  String get selectedDay => 'Selected day';

  @override
  String get noEntriesOnDay => 'Nothing planned on this day.';

  @override
  String calendarDaySemantics(String date, int count) {
    return '$date, $count items';
  }

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get style => 'Style';

  @override
  String get styleClassic => 'Classic';

  @override
  String get styleAero => 'Aero';

  @override
  String get appIcon => 'App icon';

  @override
  String get appIconSubtitle => 'Choose the launcher icon for this device.';

  @override
  String get appIconClassic => 'Classic';

  @override
  String get appIconAero => 'Aero';

  @override
  String get appIconHint => 'Some launchers need a restart before the new icon appears.';

  @override
  String get appIconHintLinux => 'Log out and back in to refresh the desktop icon.';

  @override
  String get appIconApplyFailed => 'Could not update the app icon.';

  @override
  String get brightness => 'Brightness';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get weekStartsOn => 'Week starts on';

  @override
  String get weekStartMonday => 'Monday';

  @override
  String get weekStartSaturday => 'Saturday';

  @override
  String get weekStartSunday => 'Sunday';

  @override
  String get hideWorkSpace => 'Hide the Work space';

  @override
  String get hideWorkSpaceSubtitle => 'Keep work commitments out of Today, Week and Calendar.';

  @override
  String get defaultReminders => 'Default reminders';

  @override
  String get defaultRemindersSubtitle => 'Pre-selected when you add an entry.';

  @override
  String get reminderAtTime => 'At the start time';

  @override
  String reminderMinutesBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String reminderHoursBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String reminderDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get reminders => 'Reminders';

  @override
  String get addReminder => 'Add a reminder';

  @override
  String get removeReminder => 'Remove reminder';

  @override
  String get remindersOff => 'No reminders';

  @override
  String get notificationPermissionDenied =>
      'Notifications are off. Enable them in system settings so reminders can reach you.';

  @override
  String couldNotLoadReminders(String error) {
    return 'Could not load reminders: $error';
  }

  @override
  String get remindersUnavailable => 'Reminders could not be read, so they were left unchanged.';

  @override
  String get dataAndBackup => 'Data and backup';

  @override
  String get exportBackup => 'Export a backup';

  @override
  String get exportBackupSubtitle => 'Write a versioned JSON file of all your data.';

  @override
  String get importBackup => 'Import a backup';

  @override
  String get importBackupSubtitle => 'Replace your data with a validated backup file.';

  @override
  String get importCalendar => 'Import a calendar';

  @override
  String get importCalendarSubtitle => 'Read a local .ics file. Imported events are read-only.';

  @override
  String get importCalendarSpace => 'Import into';

  @override
  String importCalendarDone(int imported, int updated, int skipped) {
    return 'Imported $imported, updated $updated, skipped $skipped duplicates or unsupported events.';
  }

  @override
  String get importCalendarEmpty => 'No events were found in this file.';

  @override
  String importCalendarFailed(String error) {
    return 'Calendar import failed: $error';
  }

  @override
  String get importCompanion => 'Import a companion export';

  @override
  String get importCompanionSubtitle => 'Read a local JSON schedule exported by another app.';

  @override
  String importCompanionDone(int imported, int skipped) {
    return 'Imported $imported events. Skipped $skipped duplicates or invalid rows.';
  }

  @override
  String get importCompanionEmpty => 'No events were found in this file.';

  @override
  String importCompanionFailed(String error) {
    return 'Companion import failed: $error';
  }

  @override
  String backupExported(String path) {
    return 'Backup written to $path';
  }

  @override
  String get backupImported => 'Backup restored.';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get backupInvalid => 'This file is not a valid Sundial backup.';

  @override
  String get backupFuture => 'This backup comes from a newer version of Sundial.';

  @override
  String get importConfirmTitle => 'Replace your data?';

  @override
  String get importConfirmBody => 'The backup replaces every entry, shift, tag and setting on this device.';

  @override
  String get syncAndAgent => 'Sync and local agent';

  @override
  String get syncEnabled => 'LAN sync';

  @override
  String get syncOffInfo => 'Off by default. Automatic only between paired devices on the same network.';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get mcpEnabled => 'Local MCP endpoint';

  @override
  String get mcpOffInfo => 'Off by default. Lets a desktop agent read the plan over loopback.';

  @override
  String get aboutSubtitle => 'License, credits and version';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get plannerSection => 'Planner';

  @override
  String get librarySection => 'Library';

  @override
  String get privacySection => 'Privacy';

  @override
  String get notSet => 'None';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get basedOnSundial => 'Based on Sundial by Gabriele Ancillai';

  @override
  String get inspiredBy => 'Inspired by GymMane and Streak by InlitX';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get license => 'License';

  @override
  String get licenseBody =>
      'Sundial is free software under GPL-3.0-only. It comes with no warranty. See LICENSE and ADDITIONAL_TERMS.md in the repository.';

  @override
  String get credits => 'Credits';

  @override
  String get creditsBody => 'An independent project by Gabriele Ancillai.';

  @override
  String get tagsManager => 'Tags';

  @override
  String get homeInventory => 'Home inventory';

  @override
  String get homeInventorySubtitle => 'Everything you keep at home, with stock levels that stay useful.';

  @override
  String get shoppingList => 'Shopping list';

  @override
  String get shoppingListSubtitle => 'Restock what the house needs, plus the occasional one-off.';

  @override
  String get addHomeItem => 'Add an item';

  @override
  String get editHomeItem => 'Edit item';

  @override
  String get itemName => 'Item';

  @override
  String get category => 'Category';

  @override
  String get location => 'Location';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get reorderLevel => 'Reorder at';

  @override
  String get lowStock => 'Low stock';

  @override
  String get inStock => 'In stock';

  @override
  String get addToShoppingList => 'Add to shopping list';

  @override
  String get addLowStockItems => 'Add low-stock items';

  @override
  String get noLowStock => 'Nothing is below its minimum stock.';

  @override
  String get homeInventoryEmpty => 'Your home inventory is empty.';

  @override
  String get shoppingListEmpty => 'Nothing to buy yet.';

  @override
  String get addShoppingItem => 'Add to the list';

  @override
  String get editShoppingItem => 'Edit list item';

  @override
  String get linkedItem => 'Linked inventory item';

  @override
  String get noLink => 'None';

  @override
  String get note => 'Note';

  @override
  String get archiveItemQuestion => 'Archive this item?';

  @override
  String get archiveItemBody => 'It disappears from the inventory but stays in backups.';

  @override
  String shoppingProgress(int done, int total) {
    return '$done of $total bought';
  }

  @override
  String get sleepWindow => 'Sleep window';

  @override
  String get sleepWindowSubtitle => 'A soft block from the last commitment today to the first tomorrow.';

  @override
  String get sleepBuffers => 'Sleep buffers';

  @override
  String sleepBuffersSummary(int commute, int windDown, int wake) {
    return '$commute commute · $windDown wind-down · $wake wake';
  }

  @override
  String get commute => 'Commute (minutes)';

  @override
  String get windDown => 'Wind-down (minutes)';

  @override
  String get wakeBuffer => 'Wake buffer (minutes)';

  @override
  String sleepBedtime(String time) {
    return 'Bedtime around $time';
  }

  @override
  String sleepWake(String time) {
    return 'Wake around $time';
  }

  @override
  String get sleepWarning => 'This plan leaves little room to sleep.';

  @override
  String get sleepNoEarlyStart => 'No early start tomorrow.';

  @override
  String minutesValue(int count) {
    return '$count min';
  }

  @override
  String get tagsManagerSubtitle => 'Separate jobs in Work and people or groups in Personal.';

  @override
  String get shiftPatterns => 'Shift patterns';

  @override
  String get shiftPatternsSubtitle => 'Cycles, per-day slots and date exceptions.';

  @override
  String get addTag => 'Add a tag';

  @override
  String get editTag => 'Edit tag';

  @override
  String get tagName => 'Name';

  @override
  String get tagColor => 'Color';

  @override
  String get tagSpace => 'Space';

  @override
  String get tagSpaceAny => 'Any space';

  @override
  String get noTags => 'No tags yet.';

  @override
  String get deleteTagQuestion => 'Delete this tag?';

  @override
  String get deleteTagBody => 'It will be removed from every entry that uses it.';

  @override
  String get tagNameRequired => 'Give the tag a name.';

  @override
  String get manageTags => 'Manage tags';

  @override
  String get filterByTag => 'Filter by tag';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get newShiftPattern => 'New shift pattern';

  @override
  String get editShiftPattern => 'Edit shift pattern';

  @override
  String get patternName => 'Pattern name';

  @override
  String get cycleLength => 'Cycle length';

  @override
  String cycleLengthValue(int count) {
    return '$count days';
  }

  @override
  String get anchorDate => 'Anchor date';

  @override
  String get timeZone => 'Time zone';

  @override
  String cycleDay(int index) {
    return 'Day $index';
  }

  @override
  String get addSlot => 'Add a slot';

  @override
  String get removeSlot => 'Remove slot';

  @override
  String get slotLabel => 'Label';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get exceptions => 'Date exceptions';

  @override
  String get addException => 'Add exception';

  @override
  String get exceptionFree => 'Free day';

  @override
  String get exceptionOverride => 'Replace shifts';

  @override
  String get exceptionExtra => 'Extra shift';

  @override
  String get exceptionNote => 'Note';

  @override
  String get exceptionDate => 'Date';

  @override
  String get preview => 'Next 28 days';

  @override
  String get conflictsFound => 'Some shifts overlap. Fix them before saving.';

  @override
  String get noConflicts => 'No overlapping shifts.';

  @override
  String get savePattern => 'Save pattern';

  @override
  String get deletePatternQuestion => 'Delete this shift pattern?';

  @override
  String get deletePatternBody => 'Its shifts will disappear from the calendar.';

  @override
  String get discardChangesQuestion => 'Discard your changes?';

  @override
  String get discardChangesBody => 'This shift pattern has unsaved changes. Leaving now will not save them.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discardChanges => 'Discard';

  @override
  String get invalidTimeZone => 'Use an IANA time zone such as Europe/Madrid.';

  @override
  String get patternNameRequired => 'Give the pattern a name.';

  @override
  String get noShiftPatterns => 'No shift patterns yet.';

  @override
  String get noSlots => 'No slots on this day.';

  @override
  String get noExceptions => 'No exceptions.';

  @override
  String get adjustShifts => 'Adjust shifts';

  @override
  String get shiftDayTitle => 'Day shifts';

  @override
  String get shiftDayUsual => 'Usual';

  @override
  String get shiftDayWorking => 'Working';

  @override
  String get shiftDayFree => 'Free';

  @override
  String get shiftDayFreeAllDay => 'Free all day';

  @override
  String shiftDayShiftCount(int count) {
    return '$count shifts';
  }

  @override
  String get shiftDayMultipleHint => 'This day has more than one shift. Edit the pattern to change them.';

  @override
  String get shiftTimes => 'Shift times';

  @override
  String get shiftChecklist => 'Shift checklist';

  @override
  String get shiftChecklistSubtitle => 'Items to tick off on each shift of this pattern.';

  @override
  String get addChecklistItem => 'Add checklist item';

  @override
  String get checklistItemLabel => 'Checklist item';

  @override
  String get checklistAppliesTo => 'Applies to';

  @override
  String get noChecklistItems => 'No checklist items yet.';

  @override
  String checklistDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get devices => 'Devices';

  @override
  String get devicesSubtitle => 'Pair your own devices over the local network.';

  @override
  String get thisDevice => 'This device';

  @override
  String get pairingIdentity => 'Pairing identity';

  @override
  String get pairingIdentitySubtitle => 'A local username and PIN. Never sent anywhere.';

  @override
  String get username => 'Username';

  @override
  String get deviceName => 'Device name';

  @override
  String get pin => 'PIN';

  @override
  String get pinHint => 'At least four digits.';

  @override
  String get createIdentity => 'Create identity';

  @override
  String get identityCreated => 'Pairing identity created.';

  @override
  String get editIdentity => 'Edit identity';

  @override
  String get changePin => 'Change PIN';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get identityRequired => 'Set a username and PIN before pairing.';

  @override
  String get pairDevice => 'Pair a device';

  @override
  String get showPairingCode => 'Show a code on this device';

  @override
  String get enterPairingCode => 'Enter a code from another device';

  @override
  String get pairingCode => 'Pairing code';

  @override
  String get pairingCodeHint => 'On the other device, choose “Enter a code” and type this code.';

  @override
  String get pairingExpires => 'Valid for five minutes.';

  @override
  String get newCode => 'New code';

  @override
  String pairingSucceeded(String name) {
    return 'Paired with $name.';
  }

  @override
  String pairingFailed(String error) {
    return 'Pairing failed: $error';
  }

  @override
  String get discoveredOnNetwork => 'Found on this network';

  @override
  String get noDiscoveredDevices => 'No other Sundial devices found yet.';

  @override
  String get address => 'Address';

  @override
  String get port => 'Port';

  @override
  String get code => 'Code';

  @override
  String get pair => 'Pair';

  @override
  String get pairedDevices => 'Paired devices';

  @override
  String get noPairedDevices => 'No paired devices yet.';

  @override
  String get noPairedDevicesHint => 'Pair a phone or computer to sync your plan here.';

  @override
  String get unpair => 'Unpair';

  @override
  String get unpairQuestion => 'Unpair this device?';

  @override
  String get unpairBody => 'It disappears from this device. The other device keeps its own copy.';

  @override
  String lastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get neverReached => 'Not reached yet';

  @override
  String get refreshDevices => 'Refresh devices';

  @override
  String remoteToday(int entries, int shifts) {
    return '$entries entries, $shifts shifts today';
  }

  @override
  String remoteNextShift(String label) {
    return 'Next shift: $label';
  }

  @override
  String remoteShopping(int count) {
    return '$count shopping items open';
  }

  @override
  String remoteContexts(int count) {
    return '$count jobs, homes or people';
  }

  @override
  String remoteInventory(int count) {
    return '$count inventory items';
  }

  @override
  String get syncStatusNever => 'Not synced yet';

  @override
  String get syncStatusPulling => 'Syncing…';

  @override
  String syncStatusLast(String time) {
    return 'Last synced $time';
  }

  @override
  String syncStatusError(String error) {
    return 'Sync error: $error';
  }

  @override
  String get syncStatusReplacing => 'Replacing this device\'s plan…';

  @override
  String get differentPlanTitle => 'Different plan';

  @override
  String differentPlanBody(String name) {
    return '$name keeps its own plan. Choose which plan this device should use.';
  }

  @override
  String usePeerPlan(String name) {
    return 'Use $name\'s plan';
  }

  @override
  String get keepThisPlan => 'Keep this plan';

  @override
  String keepThisPlanNote(String name) {
    return 'To adopt this plan instead, open Sundial on $name and choose “Replace this device from …”.';
  }

  @override
  String replaceFromDevice(String name) {
    return 'Replace this device from $name';
  }

  @override
  String get replaceWarningTitle => 'Replace this device\'s plan?';

  @override
  String replaceWarningBody(String name) {
    return 'The plan on $name replaces this device\'s plan. Identity, pairing and device-local settings stay. A backup is written first when this device has data.';
  }

  @override
  String get replacePinLabel => 'This device\'s PIN';

  @override
  String get replaceAction => 'Replace';

  @override
  String get replaceDone => 'The plan was replaced.';

  @override
  String replaceFailed(String error) {
    return 'Could not replace the plan: $error';
  }

  @override
  String get knownDevicesTitle => 'Known from your other devices';

  @override
  String get knownDevicesBody =>
      'These devices share a plan with a paired device. Pair them directly so their changes reach this device.';

  @override
  String knownDeviceFingerprint(String fingerprint) {
    return 'Fingerprint $fingerprint';
  }

  @override
  String serverOnPort(int port) {
    return 'Server on port $port';
  }

  @override
  String get serverOff => 'Server off';

  @override
  String get discoveryUnavailable => 'Network discovery is unavailable. Use the address manually.';

  @override
  String get identityFingerprint => 'Certificate fingerprint';

  @override
  String get manualAddress => 'Device address';

  @override
  String get manualAddressHint =>
      'Enter the address and port shown on the other device. Use this when network discovery is blocked.';

  @override
  String get hostHint => '192.168.1.20';

  @override
  String get mcpEndpoint => 'Local MCP endpoint';

  @override
  String get mcpEndpointSubtitle => 'Read-only by default, loopback only, off unless enabled.';

  @override
  String mcpStartFailed(String error) {
    return 'Could not start the MCP server: $error';
  }

  @override
  String get mcpWriteTools => 'Allow write tools';

  @override
  String get mcpWriteToolsSubtitle => 'Lets the local agent create and complete entries.';

  @override
  String get mcpToken => 'Access token';

  @override
  String get mcpTokenHint => 'Use it as a Bearer token. Rotating it disconnects existing agents.';

  @override
  String get rotateToken => 'Rotate token';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied.';

  @override
  String get mcpLoopbackHint => 'Bound to 127.0.0.1 only. The agent must run on this machine.';

  @override
  String mcpRunning(int port) {
    return 'Listening on 127.0.0.1:$port';
  }

  @override
  String get mcpStopped => 'MCP endpoint is off.';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search entries, tags, items';

  @override
  String get searchPrompt => 'Type a title, a note, a tag or a household item.';

  @override
  String searchNoResults(String query) {
    return 'Nothing matches “$query”.';
  }

  @override
  String get searchEntries => 'Entries';

  @override
  String get searchHomeItems => 'Home items';

  @override
  String get nextShiftPrefix => 'Next: ';

  @override
  String get backupRestoredReminders => 'Reminders have been rescheduled.';

  @override
  String get dayView => 'Day';

  @override
  String get shiftTags => 'Job tags';

  @override
  String get commuteOverride => 'Commute override';

  @override
  String get windDownOverride => 'Wind-down override';

  @override
  String get inheritSleepBuffers => 'Leave empty to use the sleep settings.';

  @override
  String get endDate => 'Ends on';

  @override
  String get multiDayHint => 'Leave the end date empty for a single day.';

  @override
  String get skipThisOccurrence => 'Skip this occurrence';

  @override
  String get skippedOccurrences => 'Skipped dates';

  @override
  String get recurrenceExceptions => 'Exceptions';

  @override
  String get exportCalendar => 'Export calendar (.ics)';

  @override
  String get exportCalendarSubtitle => 'Share a read-only calendar file. No account or network is used.';

  @override
  String calendarExported(String path) {
    return 'Calendar exported to $path';
  }

  @override
  String calendarExportFailed(String error) {
    return 'Could not export the calendar: $error';
  }

  @override
  String icsUpdated(int count) {
    return '$count updated';
  }

  @override
  String get onlyThisOccurrence => 'Only this occurrence';

  @override
  String get onlyThisOccurrenceSubtitle => 'Keep the series and change just this date.';

  @override
  String get singleDay => 'Single day';

  @override
  String get automaticBackups => 'Automatic local backups';

  @override
  String get automaticBackupsSubtitle => 'A daily JSON copy in the app folder. Older copies rotate out.';

  @override
  String get keepBackups => 'Copies to keep';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportCsvSubtitle => 'Entries, shopping or inventory.';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get importCsvSubtitle => 'Entries, shopping or inventory.';

  @override
  String get csvEntries => 'Entries';

  @override
  String get csvShopping => 'Shopping';

  @override
  String get csvInventory => 'Inventory';

  @override
  String csvExported(String path) {
    return 'CSV exported to $path';
  }

  @override
  String csvExportFailed(String error) {
    return 'Could not export the CSV: $error';
  }

  @override
  String csvImportDone(int imported, int duplicates, int skipped) {
    return '$imported imported, $duplicates duplicates, $skipped skipped';
  }

  @override
  String get csvImportEmpty => 'No rows to import.';

  @override
  String get gymmaneImport => 'GymMane schedule';

  @override
  String get gymmaneImportSubtitle => 'Read-only weekly gym blocks from a GymMane JSON backup.';

  @override
  String gymmaneImportDone(int imported, int timed, int allDay, int skipped) {
    return '$imported blocks imported ($timed timed, $allDay all-day), $skipped skipped.';
  }

  @override
  String gymmaneImportFailed(String error) {
    return 'Could not import GymMane: $error';
  }

  @override
  String get gymmaneImportEmpty => 'The backup has no weekly plan.';

  @override
  String get purchaseHistory => 'Purchase history';

  @override
  String get purchaseHistoryEmpty => 'No purchases recorded yet.';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String lowStockCount(int count) {
    return '$count items below their minimum stock';
  }

  @override
  String get maintenance => 'Gadgets';

  @override
  String get maintenanceSubtitle => 'Service schedules for appliances, filters and vehicles.';

  @override
  String get maintenanceDue => 'Due now';

  @override
  String get maintenanceUpcoming => 'Upcoming';

  @override
  String get maintenanceNone => 'No maintenance tasks yet.';

  @override
  String maintenanceDone(String date) {
    return 'Done. Next due $date.';
  }

  @override
  String get clearChecked => 'Clear bought';

  @override
  String get clearCheckedBody => 'Remove every bought line? This cannot be undone.';

  @override
  String get shoppingToBuy => 'To buy';

  @override
  String get shoppingBought => 'Bought';

  @override
  String get shoppingOther => 'Other';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get complete => 'Complete';

  @override
  String get beforeStart => 'Before the start';

  @override
  String get atTimeSection => 'At a time';

  @override
  String get addTime => 'Add time';

  @override
  String get customReminderHint => 'A custom time fires on the occurrence day in the device timezone.';

  @override
  String get workHours => 'Work hours';

  @override
  String get workHoursSubtitle => 'Hide Work tasks outside these hours. Work deadlines stay visible.';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get quietHoursSubtitle => 'Pause notifications during this window.';

  @override
  String get mcpTools => 'MCP tools';

  @override
  String get mcpToolsHint =>
      'Loopback only. Initialize returns an Mcp-Session-Id header; clients that accept text/event-stream receive one SSE message per call. Writes stay gated by the switch above.';

  @override
  String get hoursWindow => 'Set window';

  @override
  String get todayTab => 'Today';

  @override
  String get planTab => 'Plan';

  @override
  String get statsTab => 'Stats';

  @override
  String get workTab => 'Work';

  @override
  String get homeTab => 'Home';

  @override
  String get personalTab => 'Personal';

  @override
  String get workSpace => 'Work';

  @override
  String get homeSpace => 'Home';

  @override
  String get personalSpace => 'Personal';

  @override
  String get jobs => 'Jobs';

  @override
  String get homes => 'Homes';

  @override
  String get chooseHome => 'Choose a home';

  @override
  String get peopleAndGroups => 'People & groups';

  @override
  String get projectsSection => 'Projects';

  @override
  String get householdSection => 'Household';

  @override
  String get tasksSection => 'Tasks';

  @override
  String get habitsSection => 'Habits';

  @override
  String get gadgetsSection => 'Gadgets';

  @override
  String get inventorySection => 'Inventory';

  @override
  String get shoppingSection => 'Shopping';

  @override
  String get newJob => 'New job';

  @override
  String get editJob => 'Edit job';

  @override
  String get newHome => 'New home';

  @override
  String get editHome => 'Edit home';

  @override
  String get newPerson => 'New person or group';

  @override
  String get editPerson => 'Edit person or group';

  @override
  String get newProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get jobName => 'Job name';

  @override
  String get homeName => 'Home name';

  @override
  String get personName => 'Name';

  @override
  String get projectName => 'Project name';

  @override
  String get projectDescription => 'Description (optional)';

  @override
  String get name => 'Name';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Colour';

  @override
  String get image => 'Image';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String get searchIcons => 'Search icons';

  @override
  String get noIconsFound => 'No icon matches that search.';

  @override
  String get recommendedIcons => 'Suggested';

  @override
  String get allIcons => 'All icons';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get changeImage => 'Change image';

  @override
  String get removeImage => 'Remove image';

  @override
  String get imageHintEmpty => 'Add a photo or keep the icon.';

  @override
  String get imageHintSet => 'Replace the photo or remove it.';

  @override
  String get createJob => 'Create job';

  @override
  String get createHome => 'Create home';

  @override
  String get createPerson => 'Create person or group';

  @override
  String get createProject => 'Create project';

  @override
  String get noJobs => 'No jobs yet.';

  @override
  String get noJobsHint => 'Add a job to give its shifts, projects and tasks a home.';

  @override
  String get noHomes => 'No homes yet.';

  @override
  String get noHomesHint => 'Homes group house projects and tasks. Inventory and shopping work without one.';

  @override
  String get noPeople => 'No people or groups yet.';

  @override
  String get noPeopleHint => 'Use projects to keep time with different people separate.';

  @override
  String get noProjects => 'No projects yet.';

  @override
  String get noProjectsHint => 'Projects group related tasks without adding another space.';

  @override
  String get noHabits => 'No habits yet.';

  @override
  String get noHabitsHint => 'Add a habit to track a personal routine.';

  @override
  String get noTasks => 'Nothing here yet.';

  @override
  String get noTasksHint => 'Add a task from this screen or from Today.';

  @override
  String get upcomingTasks => 'Upcoming';

  @override
  String get openTasks => 'Open tasks';

  @override
  String get overdueTasks => 'Overdue';

  @override
  String get unscheduledTasks => 'Anytime';

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String projectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects',
      one: '1 project',
      zero: 'No projects',
    );
    return '$_temp0';
  }

  @override
  String habitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits',
      one: '1 habit',
      zero: 'No habits',
    );
    return '$_temp0';
  }

  @override
  String get addTask => 'Add a task';

  @override
  String addTaskFor(String name) {
    return 'Add a task for $name';
  }

  @override
  String get jobSummary => 'Shifts, checklists and work projects';

  @override
  String get homeSummary => 'Inventory, gadgets and household projects';

  @override
  String get personalSummary => 'Projects, habits and personal admin';

  @override
  String get manageJobs => 'Manage jobs';

  @override
  String get manageHomes => 'Manage homes';

  @override
  String get managePeople => 'Manage people and groups';

  @override
  String get noContextsYet => 'Create one to get started.';

  @override
  String get addFirstContext => 'Create the first one';

  @override
  String get shiftChecklists => 'Shift checklists';

  @override
  String checklistForDay(int day) {
    return 'Checklist for day $day';
  }

  @override
  String get allDays => 'Every day';

  @override
  String get checklistItemHint => 'What needs doing?';

  @override
  String get reorderChecklistHint => 'Drag to reorder. Different days can have different lists.';

  @override
  String get addProject => 'Add project';

  @override
  String get addHabit => 'Add habit';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get habitName => 'Habit name';

  @override
  String get habitTargetPeriod => 'Target period';

  @override
  String get targetPerWeek => 'Target per week';

  @override
  String get targetPerMonth => 'Target per month';

  @override
  String timesPerWeek(int count) {
    return '$count× per week';
  }

  @override
  String timesPerMonth(int count) {
    return '$count× per month';
  }

  @override
  String get increaseTarget => 'Increase target';

  @override
  String get decreaseTarget => 'Decrease target';

  @override
  String streakDays(int count) {
    return '$count day streak';
  }

  @override
  String streakWeeks(int count) {
    return '$count week streak';
  }

  @override
  String streakMonths(int count) {
    return '$count month streak';
  }

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get habitHistory => 'History';

  @override
  String get habitActiveDays => 'Active days';

  @override
  String get habitCheckIns => 'Check-ins';

  @override
  String get habitHistoryHint => 'Filled days are done. Outlined days are scheduled.';

  @override
  String get habitMonthHistoryHint => 'Each bar is one month. The number shows check-ins against the target.';

  @override
  String get markHabitDone => 'Mark done';

  @override
  String get habitDone => 'Done today';

  @override
  String get logHabitOne => 'Log one';

  @override
  String get undoHabitOne => 'Undo one';

  @override
  String get addGadget => 'Add gadget';

  @override
  String get gadgetEdit => 'Edit gadget';

  @override
  String get gadgetIcon => 'Icon';

  @override
  String get gadgetIntervalDays => 'Interval (days)';

  @override
  String get gadgetLastServiced => 'Last serviced';

  @override
  String get gadgetNeverServiced => 'Never serviced';

  @override
  String gadgetLastServicedOn(String date) {
    return 'Last serviced $date';
  }

  @override
  String gadgetNextDue(String date) {
    return 'Next due $date';
  }

  @override
  String get clearDate => 'Clear date';

  @override
  String get clearText => 'Clear text';

  @override
  String get gadgetName => 'Gadget name';

  @override
  String get maintenanceIntervalDays => 'Days between services';

  @override
  String nextDue(String date) {
    return 'Next due $date';
  }

  @override
  String deleteContextQuestion(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteContextBody =>
      'Its tasks stay in your plan but lose this grouping. Its shifts, habits and household links are removed.';

  @override
  String get deleteProjectQuestion => 'Delete this project?';

  @override
  String get deleteProjectBody => 'Tasks lose this project but keep their space and context.';

  @override
  String get listView => 'List';

  @override
  String get timelineView => 'Timeline';

  @override
  String get progressToday => 'Today\'s progress';

  @override
  String doneOfTotal(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get allDone => 'Everything for today is done.';

  @override
  String tasksLeft(int count) {
    return '$count left today';
  }

  @override
  String get clockIn => 'Clock in';

  @override
  String get clockOut => 'Clock out';

  @override
  String get clockedIn => 'Running';

  @override
  String get trackedTime => 'Tracked';

  @override
  String trackedTimeValue(String duration) {
    return '$duration tracked';
  }

  @override
  String get deadline => 'Deadline';

  @override
  String dueIn(String time) {
    return 'Due in $time';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get anytime => 'Anytime';

  @override
  String get priority => 'Priority';

  @override
  String get priorityNone => 'No priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get completeTask => 'Complete task';

  @override
  String get reopenTask => 'Reopen task';

  @override
  String get plan => 'Plan';

  @override
  String get month => 'Month';

  @override
  String get day => 'Day';

  @override
  String get collapseCalendar => 'Collapse calendar';

  @override
  String get expandCalendar => 'Expand calendar';

  @override
  String get desktopWeekHint =>
      'Drag blocks to move them, drag the bottom edge to resize, or drag an empty slot to create.';

  @override
  String createEntryAt(String time) {
    return 'Create at $time';
  }

  @override
  String get entryMoved => 'Entry moved.';

  @override
  String couldNotMoveEntry(String error) {
    return 'Could not move the entry: $error';
  }

  @override
  String get stats => 'Stats';

  @override
  String get overview => 'Overview';

  @override
  String get completionRate => 'Completion rate';

  @override
  String get tasksCompleted => 'Tasks completed';

  @override
  String get overdueDeadlines => 'Overdue deadlines';

  @override
  String get bySpace => 'By space';

  @override
  String get byProject => 'By project';

  @override
  String get byDay => 'By day';

  @override
  String get noDataInRange => 'No data in this range.';

  @override
  String get habitConsistency => 'Habit consistency';

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeMonth => 'Month';

  @override
  String get rangeQuarter => 'Quarter';

  @override
  String get rangeYear => 'Year';

  @override
  String get exportReport => 'Export report';

  @override
  String get exportSummaryReport => 'Summary report';

  @override
  String get exportSummaryCsv => 'Summary CSV';

  @override
  String get exportDetailedCsv => 'Detailed CSV';

  @override
  String get exportDetailedReport => 'Detailed report (PDF)';

  @override
  String get exportReportCsv => 'Report (CSV)';

  @override
  String get reportExported => 'Report saved.';

  @override
  String reportFailed(String error) {
    return 'Could not export the report: $error';
  }

  @override
  String get totalTracked => 'Total tracked';

  @override
  String get shiftHours => 'Shift hours';

  @override
  String get shiftHoursHint => 'Scheduled shifts in this range. Not counted as tracked time.';

  @override
  String get shareOfTotal => 'Share';

  @override
  String get noTrackedTime => 'No tracked time in this range.';

  @override
  String get completed => 'Completed';

  @override
  String get openLabel => 'Open';

  @override
  String get deadlineLoad => 'Deadlines';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String get generalSection => 'General';

  @override
  String get noSettingsFound => 'No setting matches that search.';

  @override
  String get appearanceSubtitle => 'Theme, colour, background and text size';

  @override
  String get preferencesSubtitle => 'Language, dates, hours and reminders';

  @override
  String get dataSubtitle => 'Backups, calendars, CSV and local data';

  @override
  String get onlineSubtitle => 'Pair devices and run the local MCP endpoint';

  @override
  String get themeAero => 'Aero';

  @override
  String get colorScheme => 'Colour scheme';

  @override
  String get schemeSage => 'Sage';

  @override
  String get schemeOcean => 'Ocean';

  @override
  String get schemeSunset => 'Sunset';

  @override
  String get schemeViolet => 'Violet';

  @override
  String get schemeMono => 'Mono';

  @override
  String get background => 'Background';

  @override
  String get backgroundDots => 'Dots';

  @override
  String get backgroundGrid => 'Grid';

  @override
  String get backgroundOled => 'OLED black';

  @override
  String get backgroundPlain => 'Plain';

  @override
  String get backgroundCustom => 'Custom';

  @override
  String get customBackgroundColor => 'Custom colour';

  @override
  String get textSize => 'Text size';

  @override
  String get textSmall => 'Small';

  @override
  String get textDefault => 'Default';

  @override
  String get textLarge => 'Large';

  @override
  String get textExtraLarge => 'Extra large';

  @override
  String get navigationSide => 'Navigation side';

  @override
  String get navLeft => 'Left';

  @override
  String get navRight => 'Right';

  @override
  String get dateFormatLabel => 'Date format';

  @override
  String get dateFormatSystem => 'System';

  @override
  String get dateFormatDmy => 'Day / month / year';

  @override
  String get dateFormatMdy => 'Month / day / year';

  @override
  String get dateFormatYmd => 'Year / month / day';

  @override
  String get performanceMode => 'Performance mode';

  @override
  String get performanceModeSubtitle => 'Reduce blur, shadows and long animations.';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get dataSection => 'Data and backup';

  @override
  String get onlineSection => 'Online functionalities';

  @override
  String get onlineEnable => 'Enable online functionalities';

  @override
  String get onlineEnableSubtitle =>
      'LAN sync and the local MCP endpoint. Off by default; the planner works without them.';

  @override
  String get devicesAndSync => 'Devices & Sync';

  @override
  String get devicesAndSyncSubtitle => 'Find devices on this network and pair them.';

  @override
  String get mcpServer => 'MCP Server';

  @override
  String get mcpPort => 'Port';

  @override
  String get mcpPortHint => 'Loopback port between 1024 and 65535.';

  @override
  String get applyPort => 'Apply port';

  @override
  String portSaved(int port) {
    return 'MCP endpoint now uses port $port.';
  }

  @override
  String mcpPortUnavailable(int port) {
    return 'Could not use port $port. It may already be in use.';
  }

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataSubtitle =>
      'Remove the plan, devices, backups links and settings from this device.';

  @override
  String get deleteAllDataQuestion => 'Delete all local data?';

  @override
  String get deleteAllDataBody => 'This cannot be undone. Exported files are not deleted.';

  @override
  String get dataDeleted => 'Local data deleted.';

  @override
  String get dataDeleteFailed => 'Could not delete local data. Nothing was removed.';

  @override
  String get dataDeleteIncomplete =>
      'The plan was deleted, but some media or automatic backups could not be removed. Check storage permissions and delete them from the app\'s data folder.';

  @override
  String get nearbyDevices => 'Nearby devices';

  @override
  String get scanningDevices => 'Looking for Sundial devices on this network…';

  @override
  String get searchingNearbyHint =>
      'Keep both devices on the same network. You can also enter the address manually.';

  @override
  String get noNearbyDevices =>
      'No nearby Sundial devices found. Make sure the other device has online functionalities enabled.';

  @override
  String pairWithDevice(String name) {
    return 'Pair with $name';
  }

  @override
  String get pairCode => 'Pairing code';

  @override
  String get pairCodeHint => 'Enter the six-digit code shown on the other device.';

  @override
  String pairingWith(String name) {
    return 'Pairing with $name';
  }

  @override
  String get sendPairingRequest => 'Send pairing request';

  @override
  String get sendPairingRequestHint =>
      'The other device shows an approval card. Approve it there with that device\'s PIN.';

  @override
  String waitingForApproval(String name) {
    return 'Waiting for approval on $name…';
  }

  @override
  String get pairingRequestTitle => 'Pairing request';

  @override
  String pairingRequestBody(String name, String username) {
    return '$name ($username) wants to pair with this device.';
  }

  @override
  String get pairingRequestCode => 'Check this code on both devices';

  @override
  String get pairingRequestCodeHint => 'The codes must match before you approve. The PIN is never sent.';

  @override
  String get pairingRequestFingerprint => 'Certificate fingerprint';

  @override
  String get pairingPlanSame => 'Both devices use the same plan.';

  @override
  String get pairingPlanDifferent =>
      'These devices have different plans. Pairing stores the link; full sync will ask which plan to keep.';

  @override
  String get pairingApproved => 'Pairing approved';

  @override
  String pairingApprovedHint(String name) {
    return 'Finish the request on $name. It will connect on its own.';
  }

  @override
  String get pairingApprovePinHint => 'Your PIN approves this request locally.';

  @override
  String get pairingRequestRejected => 'The other device rejected the request.';

  @override
  String get pairingRequestExpired =>
      'The request expired. Make sure Sundial is open on the other device and send it again.';

  @override
  String get pairingFailedGeneric => 'Pairing did not finish. Try again.';

  @override
  String get invalidHostPort => 'Enter a valid address and port.';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get back => 'Back';

  @override
  String get tryAgain => 'Try again';

  @override
  String get syncExplainer =>
      'Sundial finds your other devices on the local network. Pairing stores a shared key once, so changing networks or IP addresses does not break the link. Changes then replicate directly over the LAN; the first pairing asks which plan should survive.';

  @override
  String get pairSuccess => 'Device paired.';

  @override
  String pairFailed(String error) {
    return 'Could not pair: $error';
  }

  @override
  String get timing => 'Timing';

  @override
  String get timingScheduled => 'Scheduled';

  @override
  String get timingClockIn => 'Clock in';

  @override
  String get timingDeadline => 'Deadline';

  @override
  String get timingAnytime => 'Anytime';

  @override
  String get timingScheduledHint => 'Starts and ends at a set time.';

  @override
  String get timingClockInHint => 'Clock in when you start; clocking out pauses and keeps the tracked time.';

  @override
  String get timingDeadlineHint => 'Can happen any time until the deadline.';

  @override
  String get timingAnytimeHint => 'No fixed time. Complete it whenever it is done.';

  @override
  String get context => 'Job, home or person';

  @override
  String get noContext => 'No job, home or person';

  @override
  String get noProject => 'No project';

  @override
  String get project => 'Project';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get noCategories => 'No categories yet.';

  @override
  String get stickerImage => 'Image';

  @override
  String get pickImage => 'Pick an image';

  @override
  String get zoomHint => 'Pinch or scroll to zoom and drag to frame the square.';

  @override
  String get tolerance => 'Background tolerance';

  @override
  String get outline => 'White sticker outline';

  @override
  String get outlineWidth => 'Outline width';

  @override
  String get reset => 'Reset';

  @override
  String get useImage => 'Use image';

  @override
  String get noImage => 'No image selected.';

  @override
  String get imageError => 'Could not load that image.';

  @override
  String get choosePhotoOrIcon => 'Choose a photo or use an icon';

  @override
  String get mediaHint => 'Crop the image, remove a plain background and add a white sticker outline.';

  @override
  String get soundSection => 'Sound';

  @override
  String get interactionSounds => 'Interaction sounds';

  @override
  String get interactionSoundsSubtitle =>
      'Short, quiet cues for taps, tabs, completions, checklists and timers. Off by default.';

  @override
  String get soundPackLabel => 'Sound pack';

  @override
  String get soundPackSoft => 'Soft';

  @override
  String get soundPackAero => 'Aero';

  @override
  String get previewSound => 'Preview';

  @override
  String get soundLibrary => 'Sound library';

  @override
  String get soundLibrarySubtitle => 'Preview every cue in the current pack.';

  @override
  String get soundGroupNavigation => 'Navigation';

  @override
  String get soundGroupToggles => 'Toggles';

  @override
  String get soundGroupCompletion => 'Completion';

  @override
  String get soundGroupTimers => 'Timers';

  @override
  String get soundGroupSystem => 'Feedback';

  @override
  String get soundTap => 'Tap';

  @override
  String get soundNavigate => 'Tab change';

  @override
  String get soundOpen => 'Open';

  @override
  String get soundBack => 'Back';

  @override
  String get soundSelect => 'Select';

  @override
  String get soundToggleOn => 'On';

  @override
  String get soundToggleOff => 'Off';

  @override
  String get soundComplete => 'Task complete';

  @override
  String get soundUncomplete => 'Reopen task';

  @override
  String get soundCheck => 'Check off';

  @override
  String get soundUncheck => 'Uncheck';

  @override
  String get soundConfirm => 'Save';

  @override
  String get soundRemove => 'Delete';

  @override
  String get soundStart => 'Start timer';

  @override
  String get soundPause => 'Pause timer';

  @override
  String get soundFinish => 'Finish timer';

  @override
  String get soundError => 'Error';

  @override
  String get alarmSounds => 'Alarm sounds';

  @override
  String get alarmSoundsSubtitle => 'Used by scheduled reminders.';

  @override
  String get alarmSoundSoft => 'Soft';

  @override
  String get alarmSoundChime => 'Chime';

  @override
  String get alarmSoundBright => 'Bright';

  @override
  String get timezoneSubtitle => 'Zone for new timed entries. Display follows the device.';

  @override
  String get timezoneDevice => 'Device time zone';

  @override
  String get timezoneSearch => 'Search city or region';

  @override
  String get timezoneUseDevice => 'Use device time zone';

  @override
  String get planningTimeZone => 'Planning time zone';

  @override
  String get repeatEnds => 'Ends';

  @override
  String get repeatEndsNever => 'Never';

  @override
  String get repeatEndsOnDate => 'On a date';

  @override
  String get repeatEndsAfter => 'After';

  @override
  String repeatOccurrences(int count) {
    return '$count times';
  }

  @override
  String get repeatEvery => 'Every';

  @override
  String get repeatUnitDays => 'days';

  @override
  String get repeatUnitWeeks => 'weeks';

  @override
  String get repeatUnitMonths => 'months';

  @override
  String get repeatUnitYears => 'years';

  @override
  String get repeatOnDays => 'Repeat on';

  @override
  String get repeatMonthlyMode => 'Monthly pattern';

  @override
  String get repeatMonthlyDay => 'Day of month';

  @override
  String get repeatMonthlyOrdinal => 'Weekday position';

  @override
  String get repeatOrdinalFirst => 'First';

  @override
  String get repeatOrdinalSecond => 'Second';

  @override
  String get repeatOrdinalThird => 'Third';

  @override
  String get repeatOrdinalFourth => 'Fourth';

  @override
  String get repeatOrdinalLast => 'Last';

  @override
  String get repeatEndDate => 'End date';

  @override
  String get repeatSummaryNever => 'Does not repeat';

  @override
  String get clearStart => 'Clear start';

  @override
  String get clearEnd => 'Clear end';

  @override
  String get clearTime => 'Clear time';

  @override
  String get time => 'Time';

  @override
  String get setTime => 'Set';

  @override
  String get timeFieldInvalid => 'Enter a time like 9:30 or 21:30.';

  @override
  String get noTime => 'No time';

  @override
  String get pauseTask => 'Pause';

  @override
  String get resumeTask => 'Resume';

  @override
  String get finishTask => 'Finish';

  @override
  String get paused => 'Paused';

  @override
  String sessionsTracked(int count) {
    return '$count sessions';
  }

  @override
  String get sessionsTrackedOne => '1 session';

  @override
  String recurrenceUntil(Object date) {
    return 'until $date';
  }

  @override
  String get homeInventoryEmptyBody => 'Start from the household catalog or add something custom.';

  @override
  String get addInventoryItem => 'Add to inventory';

  @override
  String get browseHouseholdCatalog => 'Browse the household catalog';

  @override
  String get householdCatalog => 'Household catalog';

  @override
  String get catalogSubtitle => 'Common household items with sensible defaults.';

  @override
  String get catalogSearchHint => 'Search olive oil, toilet paper, coffee…';

  @override
  String get catalogNoResults => 'No catalog items match.';

  @override
  String get catalogInInventory => 'In inventory';

  @override
  String get catalogAddItem => 'Add';

  @override
  String get createCustomItem => 'Create a custom item';

  @override
  String get createCustomHint => 'Something that is not in the catalog.';

  @override
  String get inventorySearch => 'Search inventory';

  @override
  String get inventoryFilterAll => 'All';

  @override
  String get inventoryFilterLow => 'Low stock';

  @override
  String get inventoryFilterExpiring => 'Expiring';

  @override
  String get inventoryNoMatches => 'No items match these filters.';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String productsCount(int count) {
    return '$count products';
  }

  @override
  String get productsCountOne => '1 product';

  @override
  String variantsCount(int count) {
    return '$count sizes';
  }

  @override
  String get variantsCountOne => '1 size';

  @override
  String get lowStockItems => 'Low stock';

  @override
  String get expiringItems => 'Expiring soon';

  @override
  String get expiredItems => 'Expired';

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get expiresAtLabel => 'Expires at';

  @override
  String get noExpiry => 'No expiry date';

  @override
  String get expiresToday => 'Expires today';

  @override
  String expiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String get minimumStock => 'Minimum stock';

  @override
  String minStockValue(String quantity) {
    return 'Min $quantity';
  }

  @override
  String get packSize => 'Size / pack';

  @override
  String get packSizeHint => 'e.g. 5 gal bottle, 1 kg bag';

  @override
  String get packSizeRequired => 'Give this size a pack description, for example 5 gal or 1 kg.';

  @override
  String get description => 'Description';

  @override
  String get locations => 'Locations';

  @override
  String get addAnotherSize => 'Add another size';

  @override
  String get editProduct => 'Edit product';

  @override
  String get variantEditHint =>
      'Changes here apply to this size only. Open the product to rename every size.';

  @override
  String get archiveProductQuestion => 'Remove this product?';

  @override
  String get archiveProductBody => 'Every size of this product leaves the inventory but stays in backups.';

  @override
  String get archiveVariantQuestion => 'Remove this size?';

  @override
  String get archiveVariantBody => 'This size leaves the inventory. Other sizes stay.';

  @override
  String get inventorySetup => 'Inventory setup';

  @override
  String get inventorySetupSubtitle => 'Categories, locations and units';

  @override
  String get manageInventorySetup => 'Manage categories, locations and units';

  @override
  String get manageCategories => 'Categories';

  @override
  String get manageLocations => 'Locations';

  @override
  String get manageUnits => 'Units';

  @override
  String get newCategory => 'New category';

  @override
  String get newLocation => 'New location';

  @override
  String get editLocation => 'Edit location';

  @override
  String get newUnit => 'New unit';

  @override
  String get editUnit => 'Edit unit';

  @override
  String get noLocations => 'No locations yet.';

  @override
  String get noUnits => 'No units yet.';

  @override
  String get duplicateName => 'That name is already in use.';

  @override
  String get categoryManagerSubtitle => 'Give each kind of household item a color and icon.';

  @override
  String get locationManagerSubtitle => 'Where things live in and around the house.';

  @override
  String get unitManagerSubtitle => 'How you count, weigh or measure stock.';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get locationName => 'Location name';

  @override
  String get unitName => 'Unit name';

  @override
  String get unitSymbol => 'Short form';

  @override
  String get unitKind => 'Unit type';

  @override
  String get unitKindCount => 'Count';

  @override
  String get unitKindWeight => 'Weight';

  @override
  String get unitKindVolume => 'Volume';

  @override
  String get unitKindLength => 'Length';

  @override
  String get unitKindOther => 'Other';

  @override
  String get deleteCategoryQuestion => 'Delete this category?';

  @override
  String get deleteCategoryBody => 'Items keep their text category until you edit them.';

  @override
  String get deleteLocationQuestion => 'Delete this location?';

  @override
  String get deleteLocationBody => 'It is removed from every item that uses it.';

  @override
  String get deleteUnitQuestion => 'Delete this unit?';

  @override
  String get deleteUnitBody => 'Items keep the unit text until you edit them.';

  @override
  String inStockCount(String count) {
    return '$count in stock';
  }

  @override
  String get shoppingListEmptyBody => 'Add an item or let the inventory suggest what is running low.';

  @override
  String couldNotLoadHome(Object error) {
    return 'Could not load household data: $error';
  }

  @override
  String get stockSuggestions => 'Stock suggestions';

  @override
  String get stockSuggestionsBody => 'From your inventory, ready to add.';

  @override
  String get addAllSuggestions => 'Add all';

  @override
  String suggestionLowStock(String quantity) {
    return 'Low stock · buy $quantity';
  }

  @override
  String get suggestionOutOfStock => 'Out of stock';

  @override
  String get suggestionExpired => 'Expired · replace';

  @override
  String get suggestionAlreadyListed => 'On the list';

  @override
  String get addSuggestion => 'Add';

  @override
  String get shoppingSearch => 'Search the list';

  @override
  String get shoppingOneOff => 'One-off item';

  @override
  String get shoppingOneOffHint => 'Something you do not keep in inventory.';

  @override
  String get shoppingAddHint => 'What do you need to buy?';

  @override
  String get linkedInventory => 'Inventory';

  @override
  String linkedTo(String name) {
    return 'Linked to $name';
  }

  @override
  String get restocksInventory => 'Restocks inventory';

  @override
  String addedToInventory(String quantity, String name) {
    return 'Added $quantity to $name.';
  }

  @override
  String get shoppingItemCategory => 'Category';

  @override
  String get shoppingItemQuantity => 'Quantity';

  @override
  String get shoppingItemUnit => 'Unit';

  @override
  String get shoppingItemPack => 'Size / pack';

  @override
  String shoppingItemsCount(int count) {
    return '$count items';
  }

  @override
  String get shoppingItemsCountOne => '1 item';

  @override
  String get noShoppingSuggestions => 'Nothing needs restocking.';

  @override
  String get markBought => 'Mark bought';

  @override
  String get markNotBought => 'Mark not bought';

  @override
  String get gadgetsEmpty => 'No gadgets yet.';

  @override
  String get gadgetsEmptyBody =>
      'Track the AC, water tank, boiler, car and anything else that needs service.';

  @override
  String get gadgetAll => 'All gadgets';

  @override
  String gadgetEveryDays(int count) {
    return 'Every $count days';
  }

  @override
  String get gadgetDueToday => 'Due today';

  @override
  String gadgetDueIn(int count) {
    return 'Due in $count days';
  }

  @override
  String gadgetOverdueBy(int count) {
    return 'Overdue by $count days';
  }

  @override
  String get gadgetNoTime => 'All day';

  @override
  String gadgetTimeRange(String start, String end) {
    return '$start–$end';
  }

  @override
  String get logService => 'Log service';

  @override
  String get logServiceTitle => 'Log service';

  @override
  String get serviceDate => 'Service date';

  @override
  String get serviceNote => 'What was done?';

  @override
  String get serviceNoteHint => 'Optional notes for the history';

  @override
  String serviceLogged(String date) {
    return 'Service logged. Next due $date.';
  }

  @override
  String get couldNotLogService => 'Could not log the service. Check the gadget and try again.';

  @override
  String get couldNotReschedule => 'Could not reschedule. The gadget may have changed.';

  @override
  String get serviceHistory => 'Service history';

  @override
  String get serviceHistoryEmpty => 'No services logged yet.';

  @override
  String serviceHistoryNext(String date) {
    return 'Next due $date';
  }

  @override
  String get reschedule => 'Reschedule';

  @override
  String get rescheduleMaintenance => 'Reschedule maintenance';

  @override
  String get rescheduleBody => 'Move the next due date without logging a service.';

  @override
  String get newDueDate => 'New due date';

  @override
  String rescheduled(String date) {
    return 'Next due $date.';
  }

  @override
  String get addCalendarEvent => 'Add to calendar';

  @override
  String get addCalendarEventBody => 'Record the service as a completed event with a time block.';

  @override
  String get serviceAt => 'Service time';

  @override
  String get duration => 'Duration';

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String durationHours(int count) {
    return '$count h';
  }

  @override
  String get durationCustom => 'Custom';

  @override
  String get durationMinutesLabel => 'Minutes';

  @override
  String get blockCalendar => 'Show on the calendar';

  @override
  String get blockCalendarBody => 'Reserve a time block on the due date.';

  @override
  String serviceEventTitle(String name) {
    return '$name service';
  }

  @override
  String get developerSection => 'Developer';

  @override
  String get developerSubtitle => 'Diagnostic tools and local logs';

  @override
  String get developerOptions => 'Enable developer options';

  @override
  String get developerOptionsSubtitle => 'Show diagnostic tools such as the sync log.';

  @override
  String get syncDebugLog => 'Sync debug log';

  @override
  String get syncDebugLogSubtitle => 'Inspect field-level HLC changes, versions and peer cursors.';

  @override
  String get syncDebugTitle => 'Sync debug';

  @override
  String get syncDebugSubtitle => 'Local HLC merge bookkeeping on this device.';

  @override
  String get syncDebugExplainer =>
      'Each local edit appends a change with the HLC of every changed field group. Remote applies update the field versions but never append here.';

  @override
  String get syncDebugLocalState => 'Local sync state';

  @override
  String get syncDebugChanges => 'Changes';

  @override
  String get syncDebugFields => 'Fields';

  @override
  String get syncDebugFieldVersions => 'Field versions';

  @override
  String get syncDebugTombstones => 'Tombstones';

  @override
  String get syncDebugPeers => 'Peers';

  @override
  String get syncDebugRefresh => 'Refresh log';

  @override
  String get syncDebugCopy => 'Copy log';

  @override
  String get syncDebugCopied => 'Sync log copied.';

  @override
  String get syncDebugCopyChange => 'Copy change';

  @override
  String get syncDebugCopiedChange => 'Change copied.';

  @override
  String get syncDebugFilter => 'Filter entity, row, field or value';

  @override
  String syncDebugShowing(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String get syncDebugNoChanges => 'No local changes yet.';

  @override
  String get syncDebugNoFields => 'No field versions yet.';

  @override
  String get syncDebugNoTombstones => 'No tombstones.';

  @override
  String get syncDebugNoPeers => 'No peer cursors yet.';

  @override
  String get syncDebugNoMatches => 'Nothing matches that filter.';

  @override
  String get syncDebugNode => 'Node';

  @override
  String get syncDebugDataset => 'Dataset';

  @override
  String get syncDebugEpoch => 'Epoch';

  @override
  String get syncDebugClock => 'HLC clock';

  @override
  String get syncDebugUpsert => 'Upsert';

  @override
  String get syncDebugDelete => 'Delete';

  @override
  String syncDebugFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count fields', one: '1 field');
    return '$_temp0';
  }

  @override
  String get syncDebugTombstone => 'Tombstone';

  @override
  String get syncDebugRowPayload => 'Row payload';

  @override
  String get syncDebugCursor => 'Cursor';

  @override
  String get syncDebugLastSynced => 'Last synced';

  @override
  String get syncDebugPeerError => 'Error';

  @override
  String get syncDebugUpdated => 'Updated';

  @override
  String get saveSettings => 'Save';
}
