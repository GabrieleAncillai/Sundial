# Aero 2.0 style system

Status: **shipped (2026-11-23).** Sundial now ships two named visual styles,
**Classic** and **Aero**, through one data-driven style pack. Aero is
brightness-aware (light and dark), uses the accessibility-checked palette below,
and is verified by contrast, style, widget and screenshot tests.

The brief is still the design contract. The implementation lives in
`lib/theme/sundial_style.dart`; this document is the manual for extending it.

## What shipped

- `SundialVisualStyle { classic, aero }` in `lib/theme/sundial_style.dart` and
  `AppSettings.visualStyle`. Brightness is the existing `themeMode`
  (System/Light/Dark), so a style no longer owns the light/dark switch.
- Settings now shows **Style** (Classic/Aero) and **Brightness**
  (System/Light/Dark) separately. Legacy `themeVariant = aero` rows migrate to
  `visualStyle = aero` with light brightness.
- Aero light and Aero dark palettes. OLED still forces the dark surface; Aero
  does not.
- **Open Sans** (SIL OFL) for Aero; Nunito remains the Classic face.
- A procedural Aero environment: sky gradient, top-left light bloom, horizon
  glow, three soft water bands and slow glass bokeh. It is disabled by
  performance mode and by the platform reduce-motion flag.
- Glass chrome across the shell: side rail, bottom navigation, sheets, dialogs,
  inputs, icon buttons, segmented controls, switches, progress and the add
  button.
- An original sundial orb brand mark and glossy glyph treatment. No Microsoft,
  Apple or other proprietary Aero wallpaper, icon or font asset is bundled.
- Aero-specific recipes for cards, task rows, calendar blocks, month/week date
  cells, stats cards, settings icons and filter pills.
- Contrast tests for the candidate and shipped palettes, a style-system test,
  widget tests for the surface recipes, and real-app screenshots.

## Style pack architecture

`SundialStyle` is a resolved `ThemeExtension`; widgets read it through
`context.style`. It carries:

| Field | Purpose |
|---|---|
| `colors` | The shared `SundialColors` palette used through `context.mc`. |
| `bodyFontFamily`, `displayFontFamily` | Per-style type. Classic = Nunito, Aero = Open Sans. |
| `environment` | Background family. Classic is calm; Aero paints the sky. |
| `iconTreatment` | Outline or glossy glyphs. |
| `brandMark` | Flat tile or orb mark. |
| `gloss`, `glassChrome`, `blurChrome` | Material switches for performance mode. |
| `surfaceGradient`, `chromeGradient`, `selectedGradient`, `controlGradient`, `fieldGradient`, `skyGradient`, `glossGradient` | Generic recipes. A style with a gradient opts into the treatment automatically. |
| `highlight`, `rim`, `glow`, `cardShadows`, `chromeShadows`, `horizonGlow` | Light source, rims and depth. |
| `hasSurfaceGradient`, `hasChromeGradient`, `hasSelectedGradient`, `hasControlGradient`, `hasFieldGradient`, `hasSkyGradient` | Feature getters used by components instead of style-name checks. |

`SundialTheme.forSettings` resolves the style and brightness, applies the
Classic accent preset when needed, and builds one `ThemeData` with both the
`SundialColors` and `SundialStyleTheme` extensions.

### Adding another style (for example Cyberpunk)

1. Add a value to `SundialVisualStyle`.
2. Add a `SundialStyle.cyberpunk(brightness, {performanceMode})` constructor with
   its palette, fonts, gradients, environment, icon treatment, brand mark and
   shadows.
3. Add a `SundialEnvironment.cyberpunk` painter branch in
   `lib/core/widgets/app_background.dart`.
4. Add the ARB label and a segment in the Settings style row.
5. Add a contrast test and at least one light and one dark screenshot.

No component should need a new `if (style == cyberpunk)` branch. If a component
seems to need one, add a generic field to `SundialStyle` instead. The existing
components already branch on feature getters, not on `visualStyle`.

## Palette tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `skyTop` | `#DDF3FF` | `#071A2B` | Page gradient start |
| `skyBottom` | `#A9D8F5` | `#0B2740` | Page gradient end |
| `pearl` | `#F2FAFF` | `#132B3E` | Main content surface |
| `pearlAlt` | `#E2F4FF` | `#17354B` | Secondary surface |
| `ink` | `#102A43` | `#EAF6FF` | Body text |
| `inkMuted` | `#4C6780` | `#9DB8CC` | Secondary text |
| `accent` | `#0B6E8A` | `#8CE7FF` | Icons, rims, selected labels |
| `accentFill` | `#0B6E8A` | `#8CE7FF` | Primary button and filled selection |
| `onAccentFill` | `#FFFFFF` | `#03212E` | Text on `accentFill` |
| `accentSoft` | `#D6F3FC` | `#0E3E52` | Soft selected fill |
| `leaf` | `#2F7D4F` | `#8FE3B0` | Success |
| `sun` | `#8A6100` | `#FFD166` | Warning |
| `coral` | `#B23A3A` | `#FFB4B4` | Error |
| `glass` | `rgba(255,255,255,0.62)` | `rgba(14,40,60,0.58)` | Glass fill |
| `glassEdge` | `rgba(255,255,255,0.80)` | `rgba(120,210,240,0.30)` | 1 px glass rim |
| `highlight` | `rgba(255,255,255,0.55)` | `rgba(180,230,255,0.12)` | Single top gloss |

The decorative aqua is too light for text or a 3:1 rim on pearl, so the
accessible accent is the deep aqua above. Decorative sky-blue stays in the
background gradient only. Cyan-on-cyan text is not allowed; light body text is
`ink` on `pearl`.

## Surface hierarchy

1. **Environment**: page gradient plus sparse bokeh and one light source.
2. **Content**: pearl/ice cards with a subtle vertical gradient, 1 px top
   highlight and soft shadow. Mostly opaque; readable at a glance.
3. **Glass**: navigation rail, bottom bar, sheets, selected controls and overlays.
   Blur is bounded and disabled in performance mode.
4. **Hero**: one glass card per screen at most, used for the day/week summary.
5. **Scrim**: dimmed, optionally blurred on wide layouts.

Rounded corners come from `lib/theme/app_radii.dart`: 14 px for chips and small
controls, 18 px for inputs and rows, 24 px for cards, 30–34 px for sheets,
dialogs and the rail. Large surfaces use `RoundedSuperellipseBorder`.

## Component recipes

### Card

- Fill: `pearl` with a vertical gradient to `pearlAlt`.
- Border: 1 px glass rim; inner top highlight.
- Shadow: soft navy shadow plus a faint aqua glow. In dark Aero both use
  low alphas against the navy sky, so the depth stays subtle; the light palette
  shows it more strongly. Shift tiles are deliberately flat background blocks
  and carry no shadow.
- Radius 24. No blur on content cards.

### Navigation rail / bottom bar

- Glass gradient with an 18 px backdrop blur when performance is off.
- Selected item: `accentSoft`/white gradient, accent rim, dark ink label and a
  soft cyan glow.
- The tab row is inset 6 px from the shelf edge and the lens spans its slot with
  the 24 px card radius, so the first and last lenses stay inside the 30 px
  shelf corners. Labels carry 5 px of side padding so the longest Spanish label
  stays inside the lens.
- Below a 60 px slot width (a six-tab bar at 360 dp), labels are dropped and the
  icon grows from 22 to 26 px. The pressable keeps the label for screen readers
  and shows it as a long-press/hover tooltip.
- Pressed: scale 0.98; 180–260 ms ease-out.
- The rail keeps the persistent search field and filter badge.

### Button

- Primary: deep aqua with white text, one top highlight, radius 16/stadium.
- Secondary: pearl fill with an accent rim.
- Pressed sinks 1 px and drops gloss; no bouncing.
- The add action is a glossy aqua orb with a specular highlight.

### Chip / segmented control

- Unselected: pearl/field gradient with muted text.
- Selected: aqua-soft gradient, aqua rim, dark ink label.
- The segmented thumb slides with one glossy pill, not per-segment gradients.

### Sheet / dialog

- Compact: bottom sheet with glass edge and pearl body.
- Wide: floating pearl dialog, 24 px radius, dimmed and blurred backdrop only
  when performance mode is off.
- Inputs sit on pearl, not on glass.

### Input / select

- Pearl field with a glass rim and a top highlight.
- Focus: aqua rim and a soft outer glow, no colour inversion.
- Shared `SundialSelectField`, `SundialDateField` and text fields use the same
  recipe.

### Calendar block

- Scheduled entry: pearl gradient, aqua/space rim, dark ink label.
- Shift: translucent sky-blue background block, never draggable.
- Deadline: small coral due marker, not an all-day chip.
- Selected day: aqua rim; today: filled aqua date circle with a gloss.

### Progress

- Inset pearl groove, glossy aqua fill, one top highlight. Shared
  `SundialProgressBar` used by Today and Stats.

### Menu

- Shared `SundialMenuButton` and `SundialMenuAction` in
  `lib/core/widgets/sundial_menu.dart`.
- Surface: pearl with the Aero glass rim, 18 px radius and the shared shadow.
  The menu opens below its trigger instead of over it.
- Rows: 30 px tinted icon tile (accent soft, danger soft for destructive
  actions), 13.5 label and an optional checkmark. Groups are separated by a
  hairline divider.
- Header: a non-interactive context title and caption with a hairline base, so
  a menu names the row it belongs to.
- The Material route is unchanged, so focus, keyboard navigation, dismissal and
  screen-reader semantics keep working.

## Gloss, blur and motion rules

- One specular highlight per surface, aligned to the top-left light.
- Blur only on glass surfaces and wide overlays. Never blur body text.
- Motion: 160–260 ms ease-out for fades, scale and slide. Bubbles drift slowly;
  there is no perpetual UI animation beyond the background.
- The ambient loop is 256 s and every time-based term completes a whole number
  of cycles per loop. A fractional cycle leaves the end pose different from the
  start pose, so `repeat()` shows a visible cut when it wraps. Keep new motion
  in `AeroMotion`; `test/aero_background_test.dart` checks the seam.
- Performance mode removes blur, bubbles and gloss transitions; it does not
  remove essential selected-state contrast.

## Sound

Aero selects the Aero interaction pack but does not enable sounds. Interaction
sounds remain opt-in and off by default. Alarm sounds are chosen separately and
are used by scheduled reminders.

## Implementation map

| Area | File |
|---|---|
| Style packs, feature getters, environment/brand enums | `lib/theme/sundial_style.dart` |
| Aero token source and contrast helpers | `lib/theme/aero_colors.dart` |
| Shipped Classic/Aero palettes | `lib/theme/app_colors.dart` |
| ThemeData, component themes and font family | `lib/theme/app_theme.dart` |
| Type scale and per-style families | `lib/theme/app_typography.dart` |
| Procedural sky, horizon, bokeh, seam-safe `AeroMotion` phases and glass surface | `lib/core/widgets/app_background.dart` |
| Glossy glyphs and original sundial mark | `lib/core/icons/aero_glyph.dart` |
| Shared card, nav, sheet, menu, switch, segmented, field and progress recipes | `lib/core/widgets/` |
| Settings Style/Brightness rows and search | `lib/features/settings/` |
| Screenshots | `tool/screenshots/screenshot_test.dart` |

## Screenshots

Rendered from the real app, not concept compositions:

- `docs/screenshots/v1.2-today-aero.png` (phone, light)
- `docs/screenshots/v2-aero-today-dark.png` (phone, dark)
- `docs/screenshots/v2-aero-plan-desktop.png` (desktop, light)
- `docs/screenshots/v2-aero-settings-mobile.png` (phone, light)
- `docs/screenshots/v2-aero-appearance-mobile.png` (phone, light; Style and
  Brightness rows)
- `docs/screenshots/v2-context-menu-mobile.png` (Classic inventory menu)
- `docs/screenshots/v2-aero-context-menu-mobile.png` (Aero inventory menu)
- `docs/screenshots/nav-responsive-360-430.png` (nav close-up: 360 dp icon-only
  and 430 dp labeled)

The harness sets `debugDisableShadows = false` for the capture and restores it
before the test ends. `flutter_test` normally removes the shadow blur, which
made screenshots show harder, more prominent shadows than the app paints.

## Contrast check

Measured with WCAG 2.1 relative luminance in `test/aero_contrast_test.dart`,
which fails the build if a pair drops below its floor. The test covers both the
candidate `AeroColors` tokens and the shipped `SundialColors.aeroLight` /
`aeroDark` palettes.

| Pair | Light | Dark | Floor |
|---|---|---|---|
| body ink / pearl | 13.87:1 | 13.26:1 | 7:1 |
| body ink / pearl alt | 12.98:1 | 11.61:1 | 7:1 |
| muted ink / pearl | 5.59:1 | 7.04:1 | 4.5:1 |
| tertiary ink / pearl | 4.72:1 | 6.24:1 | 4.5:1 |
| accent text / pearl | 5.51:1 | 10.39:1 | 4.5:1 |
| accent text / accent soft | 5.01:1 | 8.19:1 | 4.5:1 |
| button label / accent fill | 5.81:1 | 11.89:1 | 4.5:1 |
| ink / accent soft | 12.61:1 | 10.45:1 | 4.5:1 |
| success / pearl | 4.77:1 | 9.55:1 | 4.5:1 |
| warning / pearl | 5.25:1 | 10.09:1 | 4.5:1 |
| error / pearl | 5.59:1 | 8.62:1 | 4.5:1 |
| accent rim / pearl (control) | 5.51:1 | 10.39:1 | 3:1 |
| accent rim / sky bottom | 3.83:1 | n/a | 3:1 |
| ink / sky bottom | 9.64:1 | 13.87:1 | 4.5:1 |

## Verification

- `flutter analyze --no-fatal-infos`: clean.
- `flutter test`: 392 tests pass (including the style, contrast, widget, motion
  seam, nav-lens and compact-nav coverage).
- `(cd packages/sundial_core && dart test)`: 107 tests pass.
- `flutter build linux --debug`: pass.
- `flutter build apk --debug` (Java 21): pass.
- Screenshot harness: `expect` the five Aero screenshots above, with production
  shadow blur enabled.

## Limits

- Aero blur is intentionally bounded. The real-device blur-performance pass is
  part of `docs/device-checklist.md`.
- The Aero sound pack is unchanged from the earlier Aero variant.
- No Windows/macOS Aero asset, font or icon is redistributed. The mark and
  environment are original vector/painter code.
- Custom and OLED backgrounds intentionally opt out of the Aero environment;
  OLED always resolves to the dark surface.
