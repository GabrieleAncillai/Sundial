/// A job, household or person/group inside a space.
///
/// Work contexts are jobs, Home contexts are homes and Personal contexts are
/// people or groups. The same row shape keeps the UI, LAN payload and MCP
/// adapter simple.
class PlannerContext {
  const PlannerContext({
    required this.id,
    required this.spaceId,
    required this.name,
    this.description = '',
    required this.colorValue,
    this.icon = 'folder',
    this.imagePath,
    this.position = 0,
    this.deletedAt,
  });

  final String id;
  final String spaceId;
  final String name;
  final String description;

  /// ARGB value, stored as an int so the core package stays Flutter-free.
  final int colorValue;
  final String icon;

  /// Local sticker image, relative to the app's media folder or absolute.
  final String? imagePath;
  final int position;
  final DateTime? deletedAt;
}

/// A group of related tasks inside a space or context.
class Project {
  const Project({
    required this.id,
    required this.spaceId,
    this.contextId,
    required this.name,
    this.description = '',
    required this.colorValue,
    this.icon = 'folder',
    this.imagePath,
    this.position = 0,
    this.deletedAt,
  });

  final String id;
  final String spaceId;
  final String? contextId;
  final String name;
  final String description;
  final int colorValue;
  final String icon;
  final String? imagePath;
  final int position;
  final DateTime? deletedAt;
}
