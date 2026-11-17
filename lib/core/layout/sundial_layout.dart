// Shared desktop layout metrics.

/// Width of every desktop sidebar.
///
/// The main navigation rail, the settings sidebar and the plan calendar
/// column share this width so switching between screens never shifts the
/// content edge.
const double kSidebarWidth = 286;

/// Reading width for page bodies on wide windows.
///
/// Settings, lists and forms centre their content in this column so the
/// background stays visible on both sides, matching the settings pane. Canvas
/// screens such as the Plan grid intentionally fill the available width.
const double kContentMaxWidth = 760;
