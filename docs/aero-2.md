# Aero 2.0 design brief

Status: **proposal, awaiting approval.** Neither existing Aero implementation is
the target. No Aero 2.0 visual changes have been rolled out. The screenshots and
contrast report required before rollout are not produced yet.

## Direction

Modern Frutiger Aero 2.0: mid-2000s optimism without neon cyberpunk. Deep sky
and ice-blue environmental depth, pearl/ice content surfaces, one consistent
light source from the top left, and glass reserved for navigation, sheets,
selected controls, hero cards and overlays. Gloss is one specular highlight, not
a stack of gradients. Body text stays dark navy on light surfaces.

## Palette tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `aeroSkyTop` | `#DDF3FF` | `#071A2B` | Page gradient start |
| `aeroSkyBottom` | `#A9D8F5` | `#0B2740` | Page gradient end |
| `aeroPearl` | `#F7FCFF` | `#132B3E` | Main content surface |
| `aeroPearlAlt` | `#EAF7FF` | `#17354B` | Secondary surface |
| `aeroInk` | `#102A43` | `#EAF6FF` | Body text |
| `aeroInkMuted` | `#4C6780` | `#9DB8CC` | Secondary text |
| `aeroAqua` | `#19A7CE` | `#54D6F0` | Accent, selected rim |
| `aeroAquaSoft` | `#D6F3FC` | `#0E3E52` | Soft selected fill |
| `aeroLeaf` | `#4FB477` | `#63D69A` | Success |
| `aeroSun` | `#F2B544` | `#FFD166` | Warning |
| `aeroCoral` | `#E86A6A` | `#FF8A8A` | Error |
| `aeroGlass` | `rgba(255,255,255,0.62)` | `rgba(14,40,60,0.58)` | Glass fill |
| `aeroGlassEdge` | `rgba(255,255,255,0.80)` | `rgba(120,210,240,0.30)` | 1 px glass rim |
| `aeroHighlight` | `rgba(255,255,255,0.55)` | `rgba(180,230,255,0.12)` | Single top gloss |

Avoid cyan-on-cyan text. Aero light body text is `aeroInk`; dark body text is
`aeroInk` on `aeroPearl`.

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

- Fill: `aeroPearl` with a 2% vertical gradient to `aeroPearlAlt`.
- Border: 1 px `aeroGlassEdge`; inner top highlight 1 px.
- Shadow: `0 10 28 rgba(16,42,67,0.10)`.
- Radius 20. No blur on content cards.

### Navigation rail / bottom bar

- Glass fill, 18 px blur when performance is off.
- Selected item: `aeroAquaSoft` fill, 1 px `aeroAqua` rim, `aeroInk` label.
- Pressed: scale 0.98 and slightly darker fill; 180 ms ease-out.
- The rail keeps the persistent search field and filter badge.

### Button

- Primary: `aeroAqua` fill, white text, one top highlight, radius 16.
- Secondary: pearl fill with aqua rim.
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

- Pearl field, 1 px `aeroGlassEdge`, 14 px radius.
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

## Required before rollout

- [ ] Approve this direction.
- [ ] Render three concepts: Today phone Aero light, Plan week grid desktop Aero
      light, Settings phone Aero dark.
- [ ] Run a text and control contrast check and record the ratios.
- [ ] Apply through theme tokens and one `AeroSurface` family, not per-screen
      raw colours.
- [ ] Provide before/after screenshots in the final report.
