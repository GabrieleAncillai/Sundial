import 'package:flutter/material.dart';

/// Corner radii for the whole app, taken from the app icon.
///
/// The icon is a soft square whose corner is roughly a quarter of its shortest
/// side, and the curve eases into the straight edge instead of stopping at a
/// circular arc. Components therefore pick a step from this scale rather than
/// their own number, and surfaces use [SundialShapes.rounded] so the same
/// continuous curvature carries into cards, sheets and the navigation bar.
///
/// The steps are deliberately far apart: adjacent tokens must not be
/// interchangeable, otherwise values drift back to one-off numbers.
abstract final class SundialRadii {
  SundialRadii._();

  /// Corner radius as a fraction of an icon tile's shortest side. Taken from
  /// the app-icon silhouette, so avatars and icon tiles match it.
  static const double iconRatio = 0.24;

  /// Thin bars and markers: timeline ticks, chart bars, progress fills.
  static const double marker = 4;

  /// Square marks: checkboxes and small selection boxes.
  static const double xxs = 6;

  /// Badges, counters, chips and the smallest tiles.
  static const double xs = 10;

  /// Tag pills, day cells, segmented items and compact blocks.
  static const double sm = 14;

  /// Inputs, buttons, rows and calendar blocks.
  static const double md = 18;

  /// Cards and content panels.
  static const double lg = 24;

  /// Sheets, dialogs and floating navigation surfaces.
  static const double xl = 30;

  /// Bottom-sheet top corners, where the surface meets the screen.
  static const double xxl = 34;

  /// Fully rounded: pills, search bars and stadium shapes.
  static const double pill = 999;
}

/// Shape helpers that keep the icon's continuous corners in one place.
abstract final class SundialShapes {
  SundialShapes._();

  /// A rounded superellipse. Prefer it over [RoundedRectangleBorder] wherever
  /// the corner is large enough to read, since its curvature matches the icon
  /// rather than Flutter's default circular arc.
  static RoundedSuperellipseBorder rounded({
    double radius = SundialRadii.lg,
    BorderRadiusGeometry? borderRadius,
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(side: side, borderRadius: borderRadius ?? BorderRadius.circular(radius));
  }

  /// The same shape with only the top corners rounded, for bottom sheets.
  static RoundedSuperellipseBorder sheetTop({
    double radius = SundialRadii.xxl,
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(
      side: side,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    );
  }

  /// Continuous rounding for an icon tile sized by [size].
  static BorderRadius icon(double size) => BorderRadius.circular(size * SundialRadii.iconRatio);
}
