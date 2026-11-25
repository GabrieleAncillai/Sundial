/// Launcher icon variants. The launcher icon is a device-local choice, so it
/// is deliberately not synced or included in backups.
enum AppIconStyle {
  classic,
  aero;

  static AppIconStyle fromName(String? value) => value == aero.name ? aero : classic;
}
