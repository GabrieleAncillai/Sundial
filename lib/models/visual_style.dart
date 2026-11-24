/// The visual language selected in Settings.
///
/// The enum lives in the model layer so persisted preferences do not depend on
/// the theme implementation. `SundialStyle` resolves this value into concrete
/// palettes, fonts, gradients, icons and environment data.
enum SundialVisualStyle { classic, aero }
