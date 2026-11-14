# Aero 2.0 design brief

Status: **proposal, awaiting approval.** Neither existing Aero implementation is
the target and no Aero 2.0 visual changes are rolled out. The three concept
screens and the contrast report exist (below); the remaining step is the user's
sign-off on the direction.

Tokens live in `lib/theme/aero_colors.dart`. Nothing imports them yet, so the
current Aero surface is untouched until approval.

## Direction

Modern Frutiger Aero 2.0: mid-2000s optimism without neon cyberpunk. Deep sky
and ice-blue environmental depth, pearl/ice content surfaces, one consistent
light source from the top left, and glass reserved for navigation, sheets,
selected controls, hero cards and overlays. Gloss is one specular highlight, not
a stack of gradients. Body text stays dark navy on light surfaces.

## Palette tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `skyTop` | `#DDF3FF` | `#071A2B` | Page gradient start |
| `skyBottom` | `#A9D8F5` | `#0B2740` | Page gradient end |
| `pearl` | `#F7FCFF` | `#132B3E` | Main content surface |
| `pearlAlt` | `#EAF7FF` | `#17354B` | Secondary surface |
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

The earlier `#19A7CE` sky aqua fails as text and as a 3:1 rim on pearl
(2.8:1), so it is not a token: the accessible accent is the deep aqua above.
Decorative sky-blue stays in the background gradient only. Cyan-on-cyan text is
not allowed; light body text is `ink` on `pearl`.

## Surface hierarchy

1. **Environment**: page gradient plus sparse bubbles/bokeh and one light source.
2. **Content**: pearl/ice cards with a subtle vertical gradient, 1 px top
   highlight and soft shadow. Mostly opaque; readable at a glance.
3. **Glass**: navigation rail, bottom bar, sheets, selected controls and overlays.
   Blur is bounded and disabled in performance mode.
4. **Hero**: one glass card per screen at most, used for the day/week summary.
5. **Scrim**: dimmed, optionally blurred on wide layouts.

Rounded corners: 16 px for chips and small controls, 20–24 px for cards, 26–28 px
for sheets and the rail. Avoid giant blobs.

## Component recipes

### Card

- Fill: `pearl` with a 2% vertical gradient to `pearlAlt`.
- Border: 1 px `glassEdge`; inner top highlight 1 px.
- Shadow: `0 10 28 rgba(16,42,67,0.10)`.
- Radius 20. No blur on content cards.

### Navigation rail / bottom bar

- Glass fill, 18 px blur when performance is off.
- Selected item: `accentSoft` fill, 1 px `accent` rim, `ink` label.
- Pressed: scale 0.98 and slightly darker fill; 180 ms ease-out.
- The rail keeps the persistent search field and filter badge.

### Button

- Primary: `accentFill` with `onAccentFill` text, one top highlight, radius 16.
  Light uses deep aqua with white text; dark uses light aqua with dark ink.
- Secondary: pearl fill with an `accent` rim.
- Pressed sinks 1 px and drops gloss; no bouncing.

### Chip / segmented control

- Unselected: pearl fill, muted text.
- Selected: aqua-soft fill, aqua rim, dark ink label.
- Segmented control uses one sliding aqua pill, not per-segment gradients.

### Sheet / dialog

- Compact: bottom sheet with glass edge and pearl body.
- Wide: floating pearl dialog, 24 px radius, dimmed and blurred backdrop only
  when performance mode is off.
- Inputs sit on pearl, not on glass.

### Input / select

- Pearl field, 1 px `glassEdge`, 14 px radius.
- Focus: aqua rim and a soft outer glow, no colour inversion.
- Shared `ManeSelectField` and future `ManeTimeField` use the same recipe.

### Calendar block

- Scheduled entry: aqua-soft fill, aqua left bar, dark ink label.
- Shift: translucent sky-blue background block, never draggable.
- Deadline: small coral due marker, not an all-day chip.
- Selected day: aqua rim; today: filled aqua date circle.

## Gloss, blur and motion rules

- One specular highlight per surface, aligned to the top-left light.
- Blur only on glass surfaces and wide overlays. Never blur body text.
- Motion: 160–260 ms ease-out for fades, scale and slide. No perpetual bubbles.
- Performance mode removes blur, bubbles and gloss transitions; it does not
  remove essential selected-state contrast.

## Sound

Aero selects the Aero interaction pack but does not enable sounds. Interaction
sounds remain opt-in and off by default. Alarm sounds are chosen separately and
are used by scheduled reminders.

## Concept screens

Rendered by `tool/screenshots/aero_concept_test.dart` from the tokens above.
These are concept compositions, not the shipped screens.

- Today, phone, light: `docs/screenshots/aero2-today-phone-light.png`
- Plan week grid, desktop, light:
  `docs/screenshots/aero2-plan-desktop-light.png`
- Settings, phone, dark: `docs/screenshots/aero2-settings-phone-dark.png`

## Contrast check

Measured with WCAG 2.1 relative luminance in `test/aero_contrast_test.dart`,
which fails the build if a pair drops below its floor.

| Pair | Light | Dark | Floor |
|---|---|---|---|
| body ink / pearl | 14.17:1 | 13.26:1 | 7:1 |
| body ink / pearl alt | 13.42:1 | 11.61:1 | 7:1 |
| muted ink / pearl | 5.71:1 | 7.04:1 | 4.5:1 |
| accent text / pearl | 5.63:1 | 10.39:1 | 4.5:1 |
| accent text / accent soft | 5.01:1 | 8.19:1 | 4.5:1 |
| button label / accent fill | 5.81:1 | 11.89:1 | 4.5:1 |
| ink / accent soft | 12.61:1 | 10.45:1 | 4.5:1 |
| success / pearl | 4.88:1 | 9.55:1 | 4.5:1 |
| warning / pearl | 5.36:1 | 10.09:1 | 4.5:1 |
| error / pearl | 5.71:1 | 8.62:1 | 4.5:1 |
| accent rim / pearl (control) | 5.63:1 | 10.39:1 | 3:1 |
| accent rim / sky bottom | 3.83:1 | n/a | 3:1 |
| ink / sky bottom | 9.64:1 | 13.87:1 | 4.5:1 |

## Required before rollout

- [ ] Approve this direction (stop gate).
- [x] Render three concepts: Today phone Aero light, Plan week grid desktop
      Aero light, Settings phone Aero dark.
- [x] Run a text and control contrast check and record the ratios.
- [ ] Apply through theme tokens and one `AeroSurface` family, not per-screen
      raw colours.
- [ ] Provide before/after screenshots in the final report.
