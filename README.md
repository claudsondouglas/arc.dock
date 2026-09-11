# Arc Dock

A dock for the [Omarchy](https://omarchy.org/) shell (Quickshell) that looks
like the macOS dock: frosted glass, magnification under the pointer, one slot
per app.

![Arc Dock](docs/dock.png)

![Magnification under the pointer](docs/magnify.png)

## Requirements

- Omarchy 4 with the shell. The plugin only uses `qs.Commons`, `qs.Ui` and
  what ships in the package (`hyprctl`, `omarchy-menu`, `omarchy-shell`).
- Hyprland with `decoration:blur` enabled, for the frosted glass. Without blur
  the dock still works; the shell just stays translucent instead of frosted,
  and the settings window tells you so.

## Install

```bash
omarchy plugin add https://github.com/claudsondouglas/arc.dock.git --enable
```

If the dock does not show up right away, run `omarchy restart shell`.
Right-click the dock to open its settings.

## What it is

![The dock on the desktop, with the settings window open](docs/desktop.png)

Pinnable, reorderable slots, recent apps, auto-hide and a settings window. The
dock is a surface anchored to one screen edge on the `Top` layer (above
windows, reserving no space), with a frosted glass background and magnification
under the pointer. Both are settings, and you can go back to the theme's solid
background. It shows on one screen only, by default the largest one in the
setup, picked at runtime, so no monitor name is hardcoded. Inside it the row has
three groups, apps with a slot (pinned and open), recents, and the app button,
with a separator between each pair:

- One slot per app, not per window. Two windows with the same `appId` share a
  slot.
- A pinned app keeps its slot while closed. Pinned apps open the row, in the
  order they were pinned.
- The slot size comes from the icon: 52 px of icon (adjustable) plus 4 px of
  padding on each side makes 60 px, and the dock length comes from the slot
  count.
- With no app open, the app button is what holds the minimum size. With the
  button off too, one empty slot keeps the dock from collapsing.
- A separator only exists when there is a group on both sides of it. With no
  recents you get one separator; with no apps at all you get none. It never
  becomes a stray line at the end of the dock.
- Corners are concentric: the slot radius is the dock radius (Hyprland's
  `decoration:rounding`) minus the 6 px between them, so the two curves run
  parallel in any theme.
- App state is a dot next to the icon, on the side that touches the screen edge
  (below in a bottom dock, on the left in a left dock). Its diameter comes from
  the icon padding, so the dot fits exactly in the strip between the icon and
  the slot edge without asking for extra dock thickness.
- One dot per window, capped at two. One window shows one dot, two or more show
  two. What matters is "more than one", and the gap between dots comes from
  their own diameter.
- A pinned, closed app has no dot. The missing dot is what says the app is
  closed; there is no second mark for that case.
- The focused app paints its dots with the theme's `accent`; the others use
  `muted`. Both come from `colors.toml`, so switching themes switches the marks.
- Every slot's shell looks the same. The dot carries the state, not the fill,
  so the same app is never marked twice.
- The slot shows the app icon from its `.desktop` entry (the window's `appId`
  is resolved through Quickshell's `heuristicLookup`) and turned into a file by
  the shell's `appLibrary`, the same index the menu uses. An app installed while
  the shell is running gets its icon without a restart.
- Without a `.desktop` entry (or with an icon that fails to load) the slot falls
  back to the first letter of the app name.
- The notification counter is a red disc with a number at the top right corner
  of the icon, as in the macOS dock (see below).

The edge is a setting: bottom (the default), top, left or right. On a side edge
the row runs top to bottom, the separator turns horizontal, the state dots move
to the side that touches the screen, the context menu opens inward and the
reorder drag measures the vertical axis. All geometry is written in terms of
length (along the edge) and thickness (across it), and only the window
translates the two back into width and height.

Clicking a slot goes to the app. With one window it activates it; with more
than one, the click walks the queue starting from the focused window. On a
pinned app that is closed, the click launches it through the same path the shell
uses (`uwsm-app -- gtk-launch`), so it is not tied to the shell process and an
entry with `Terminal=true` opens in a terminal.

Right-click opens the app's context menu on its own surface above the dock (the
dock window is exactly the size of the dock, so the menu would not fit inside
it):

- The header names the app, and the menu closes on a click outside. While it is
  open the originating slot stays lit.
- First, what opens: the actions declared by the app's `.desktop` entry ("New
  private window", "Compose message"...) plus a generic "New window", omitted
  when the app already declares an action with that name.
- Then, what navigates: one line per open window, only when there is more than
  one, with the focused window marked in the theme's `accent`.
- Then "Pin to dock" / "Unpin from dock", in its own group, since pinning
  belongs to the dock and not to the app. The item only shows for apps with a
  `.desktop` entry; without one the dock could not find the app again next
  session.
- Last, what closes, away from the top where the pointer arrives first.
- The list scrolls inside the menu when an app has too many windows for the
  screen.

## Notifications

Each slot can carry a counter: a disc in the theme's `urgent` color (the red in
`colors.toml`) with a white number, at the top right corner of the icon on any
dock edge, because that is where the eye learned to look. The diameter is a bit
over a third of the icon, the macOS proportion, and the disc grows with the icon
under magnification.

The number is how many notifications from that app arrived since it was last
focused. That is the only reading the dock can sustain: on macOS each app
reports its own number (unread messages, mail to open), and here no app talks
to the dock. So:

- A notification arrives, the number goes up. The app gains focus, the number
  goes away.
- A notification from the app that already has focus does not count. The user
  is looking at it.
- A notification silenced by "do not disturb" counts all the same. It is exactly
  the one the user will want to find later.
- The sender withdrawing the notification subtracts it. Chat apps do this when
  the message was read on the phone. Closing the toast, or letting it expire,
  does not subtract: neither says the app was seen, and macOS does not subtract
  for that either.
- Transient notifications (the `transient` hint) do not count. The sender asked
  for them not to stay.
- A slot leaving the row takes its counter along. With no slot there is nowhere
  to count, like an app outside the dock on macOS.
- The count lives in the shell's memory. `omarchy restart shell` clears it.

The shell's `omarchy.notifications` service is what receives notifications.
There is only one D-Bus name, so the dock does not start a server of its own; it
reaches the shell's and listens to the same signal. A notification is matched to
a slot by the `desktop-entry` hint when present (the same id the slot key is
derived from) and otherwise by app name, loosely: "Slack" matches `slack`,
"Telegram Desktop" matches `org.telegram.desktop`, "Google Chrome" matches
`google-chrome`.

The counter turns off under Content → Notification counter.

## Recents

After the apps with a slot come the recents: the last apps the user opened and
has since closed, in the order they were opened. Four by default, adjustable
from 0 (off) to 12. A click reopens the app, and on reopening it leaves the
recents and becomes a slot like the others.

The rule is one app, one slot: anything that already has a place does not show
up here. An open app is in the left group and a pinned app has its own place, so
closing an app is what puts it in the recents, and pinning it is what takes it
out. That also means unpinning a closed app removes it from the dock for good
instead of returning it as a recent. A recent whose `.desktop` entry is gone
(the app was uninstalled) is left out instead of becoming a blank slot, and its
context menu gets "Remove from recents", the exit for the only slot the user did
not ask for.

The history is saved with the pinned apps, in the same file and format, up to
the setting's ceiling (12) rather than today's value. Lowering the count to 2
and raising it back to 6 does not throw away, on the way, the apps the user
expected to find again.

Pinned apps and recents are stored in `~/.local/state/omarchy/arc-dock.json`,
user state, in the same directory the other shell plugins keep theirs. Each
item is `{ key, entry }`: the key that groups the app's windows, and the
`.desktop` entry id that draws the icon and launches the app while there is no
window. Both lists share a file because they answer the same question (who
occupies the row) and because an app moves from one to the other when pinned.

Dragging a pinned slot along the row reorders the pinned group, and the new
order is saved to the same file. It is the order of `pinned`, so the dock comes
back with it next session. Only pinned apps move: open apps keep the order they
appeared in, recents the order they were opened in. The grabbed slot cannot
leave its group (the offset is clamped to the pinned range), the swap happens
half a step from the neighbor, and a gesture below the threshold still counts
as a click. A window opening in the middle of a drag aborts the gesture: the
`Repeater` recreates the slots and the one in hand would stop existing, so
losing the drag beats saving a half-finished order.

## Getting out of the way

When the dock hides is a choice of four values: `Never`, `Fullscreen`, `Window
underneath` (the default) and `Always`. The rest of the hiding path is the same
for all four.

In `Fullscreen`, when an app takes the screen (maximized or fullscreen) on the
active workspace of the dock's monitor, the shell slides out and only a strip at
the edge remains, the same 14 px gap the dock already left there. Touching it
with the pointer brings the dock back immediately; leaving the dock only hides
it after half a second of grace (adjustable), so a passing pointer does not make
the dock run away from under the cursor. The dock also stays up while the
context menu is open or a slot is being dragged.

The truth comes from `hasFullscreen` on the active workspace of the dock's
monitor, not from the focused window, since focus may sit on a floating dialog
over the app that took the screen. Quickshell does not re-query workspaces on
Hyprland's `fullscreen` event, so the dock listens for it and asks for the
refresh. Closing a fullscreen window emits it too, so it is the only event
needed.

`Window underneath` answers the same question with geometry instead of
fullscreen state: in a tiling WM two apps side by side cover the same area with
neither in fullscreen. The dock compares the rectangle it rests in (the resting
one, otherwise hiding would uncover it and it would come back the next frame)
with the `at`/`size` of every window on the monitor's active workspace, in
Hyprland layout coordinates. Any overlap hides it.

That geometry does not arrive on its own: each toplevel's `lastIpcObject` only
changes when someone asks. The dock asks (`refreshToplevels`, coalesced by a 60
ms timer) on the events that rearrange the screen: open, close, move, float and
unfloat, group, workspace or monitor change. Focus changes are deliberately left
out. Hyprland emits `activewindow` with every title change, and a terminal with
a clock in its title would ask for a query every second, forever.

One gesture has no event at all: dragging a split divider emits nothing, and
Hyprland has no resize event. The pointer itself corrects the count in that
case. Touching the dock (or leaving it) asks for the query again, which is
exactly when it is going to be read.

The window does not change size to hide. The content slides, and the input mask
changes: hidden, only the trigger strip receives the pointer, and the rest
passes clicks through to the app below.

## Magnification

On by default. The dock responds to the pointer with a wave: the icon under the
cursor grows and rises above the shell, neighbors grow less the farther they
are, and the row opens to fit what grew. It is the macOS dock gesture.

- The wave's weight is a raised cosine: 1 under the pointer, 0 at the end of
  the reach, arriving at both ends with zero slope, so there is no corner at the
  peak or at the edge of the reach.
- Each cell's offset is the integral of that same weight, which is what keeps
  anything from overlapping: each icon moves exactly as much as the neighbors
  between it and the cursor grew, no more, no less.
- The icon stays seated and rises: the side that touches the screen edge does
  not move, so the state dot stays where it was and all the growth goes inward.
- The separator moves with the wave but does not grow with it (a separator that
  grows becomes a bar), and the app button is a cell like any other.
- While following the pointer the scale is not animated. It is a function of
  where the cursor is, and animating it would only make the wave arrive after
  the hand. The return to rest does settle, on the same 140 ms as the pointer
  highlight.
- While dragging, the wave leaves. The drag already moves the slots, and two
  translations fighting over the same row would leave the grabbed slot sliding
  sideways while the finger holds it still.

The shell grows and shrinks, but the window does not. Every resize of a layer
surface is a round trip to the compositor, and the pointer would ask for one per
frame. The window is born with the maximum reserve the wave can ask for, along
the edge for the spread and across it for the icon to rise, all transparent,
and the shell opens inside it. With the defaults (125%, reach of 2 slots, 52 px
icon) that is 26 px of length and 10 px of thickness. Off, the reserve is zero
and the window goes back to the exact size of the dock.

Two settings drive it: the size at the peak (110% to 200%) and the reach (1 to 4
slots on each side). The reach is counted in slots rather than pixels, so it
follows an icon size or theme spacing change on its own.

## Frosted glass

On by default, the glass swaps the shell's solid background for a translucent
one (25% by default, adjustable from 10 to 100) and asks Hyprland to blur what
passes behind it. Both halves are needed: translucency alone would leave the
windows behind sharp through the dock, and blur alone would have nothing to
show through.

The context menu does not go along. It stays in the theme's popup color, as the
theme delivers it, and the rule's blur does not reach it. The dock shell carries
icons, which read over anything; the menu is a sheet of text, and on glass every
label fights for contrast with whatever passes behind. The theme decides its
material (`popups.background`), not the dock setting.

The separator goes along, and for one more reason: with glass the shell has no
fixed color. It shows what passes behind, so it is light over a light desktop
and dark over a dark one, and no single color is visible on both. A single line
is either hard (solid color) or gone (color with alpha). On glass the separator
becomes a pair of lines, the popup's text and background colors, which are the
two ends of the surface and by the theme's own definition contrast with each
other: one of them always shows, and neither needs to be opaque for that. It is
the same bevel macOS uses for separators on glass. The ends dissolve; they are
where the separator meets the shell padding, and a line cut dead there marks the
padding instead of separating the groups.

The border goes along too. On glass it stops being color and becomes light. The
theme's color (`popups.border`) comes opaque, and on a shell where everything
else is translucent it would be the only solid thing in the dock, a line drawn
over the glass that receives nothing from what passes behind. So only the
thickness comes from the theme, and it drops to a hairline (a theme that
declares `popups.border-width` still wins). The line becomes the edge highlight
of macOS glass: a diagonal gradient, full at the top left corner, fading along
the top and left edges, gone at the bottom and right, with a fainter reflection
in the opposite corner. There is no dark line at the base. The shadow is what
seats the piece (see below). Inside the border the dock tilts the light on the
face: brighter at the top, settling at the bottom (`ArcGlass.qml`). All of this
is vertical (or diagonal) even with the dock anchored on the left or right. It
is the only part of the plugin not written in length and thickness, because the
light comes from the top of the screen, not from the edge the dock is on.

The frosting is a compositor `layerrule`, requested by the dock itself at
runtime. A setting that only worked after editing `looknfeel.lua` by hand would
not be a setting. The rule is declared with a name (`arc-dock-glass`): in
Hyprland's Lua parser, redeclaring the same name replaces the previous rule
instead of stacking another, and that is what lets the glass be turned off
without a `hyprctl reload`, which would take everything else the user adjusted
at runtime with it. A third-party `hyprctl reload` (`omarchy theme set` does one
at the end) erases the rule, so the dock listens for `configreloaded` and puts
it back.

The blur ignores everything below an alpha floor. Without it the compositor
would also blur the transparent gap between the shell and the screen edge, a
frosted rectangle around a dock with round corners. The floor is half the lowest
opacity the setting allows: above zero, so the gap stays out, and below any
alpha the shell can have, so the shell always gets in.

With `decoration:blur` off in Hyprland the rule is accepted and does nothing:
the shell is translucent without being frosted. The dock checks `hyprctl
getoption` and the settings window says so instead of leaving the switch looking
broken.

## Shadow

The shell casts a penumbra so it does not sit on the screen weightless. It comes
from `menu.scrim`, the tone the theme uses to darken what is behind one of its
surfaces, and reaches as far as the shell's corner radius: the shadow of a piece
is on the order of its curve, so a theme with tighter corners casts less.

Three implementation choices are worth writing down.

It is a stack of one-pixel rings, not a blur under the shell. The middle has to
stay empty: with glass on, the shell lets through what is behind it, including
its own shadow, and a dark rectangle underneath would darken the glass instead
of lifting it.

It is cast downward, by a third of the reach, whatever edge the dock is on. It
is the shadow of a light coming from the top of the screen, and it seats the
piece in place of a dark line at the base. With the drop, the inner rings would
enter the shell's silhouette from above and the glass would show them, so a
`MultiEffect` mask cuts the silhouette out of the stack and the middle stays
empty.

It lives in its own window (`arc-dock-shadow`) rather than the dock's, because
of the blur. The glass rule blurs everything on the surface above the alpha
floor, and a penumbra above the floor would become a frosted halo with a hard
limit where the alpha crosses it; below the floor it would fit in the dock
window but be too faint to be a shadow. Since the rule matches `^(arc-dock)$`
in full, a namespace next to it is already outside. Both windows read the same
`bodyOffset`, so hiding has no second state to keep in sync, and the shadow
surface has an empty input region. It never receives the pointer.

## Settings

![Settings window](docs/settings.png)

Right-click on the dock shell, on the app button or any gap between slots,
opens the settings window. It is the plugin's second entry point (`kind: panel`
in the manifest), so the host injects the live service into it and the controls
write straight to the dock. There is no "apply" or "cancel", because the preview
is the result.

The layout follows [Omaland](https://github.com/bobbynicholas/omaland), the
Hyprland settings panel: a rail of sections on the left and a page of rows on
the right, each row with its name and explanation on one side and the control
on the other. A `·` mark next to a section says something in it is off the
default, without making you open each one to check.

| Section | What |
| --- | --- |
| Size | icon size, gap between slots, inner padding, distance to the edge |
| Magnification | the wave under the pointer, its peak size and reach |
| Background | shell tone, frosted glass and its opacity |
| Content | app button, separator, state dots, the open-app mark, the notification counter and how many recent apps |
| Position | screen edge and monitor (automatic, or an output name) |
| Hide | when to get out of the way, grace before hiding, slide duration |

The whole window is keyboard driven, since whoever opens dock settings usually
has a hand on the keyboard:

| Key | What |
| --- | --- |
| `↑` `↓` or `k` `j` | move through the section's rows |
| `←` `→` or `h` `l` | change the row's value: toggle, next in the list, one step of the number |
| `Enter` / `Space` | flip the switch, or advance the choice |
| `Tab` / `Shift+Tab` | switch section |
| `Backspace` | reset the row to its default |
| `Esc` | close |

Values live in `~/.config/omarchy/arc-dock.json`, config, next to `shell.json`,
as opposed to state (pinned apps and recents stay in `~/.local/state`, a
different kind of data). The file is read with `watchChanges`, so editing it by
hand takes effect immediately, and anything out of range is clamped rather than
breaking the dock.

A missing key means "use the plugin default". The undo button on each row, and
"Reset all" in the header, delete the key instead of writing the number that
happens to be the default today. While a key is off the default it gets a dot
in the theme's `accent` next to its name, and its value shows in the same
`accent`; the header counts how many.

It can also be opened over IPC, which is the way to bind it to a Hyprland
shortcut:

```bash
omarchy-shell shell toggle arc.dock '{}'
```

## Files

| File | What |
| --- | --- |
| `Arcdock.qml` | the surface (`PanelWindow`), geometry and the slot model |
| `ArcConfig.qml` | the settings and the file they live in |
| `ArcSettings.qml` | the settings window (`kind: panel`) |
| `ArcSlot.qml` | one slot: space, icon, fallback initial, the state dot and the notification counter |
| `ArcLauncher.qml` | the button that opens the Omarchy app menu |
| `ArcMenu.qml` | a slot's context menu (its own popup) |
| `ArcGlass.qml` | the glass light: the face that brightens at the top and settles at the bottom |
| `ArcShadow.qml` | the penumbra, in one-pixel rings, cast downward |

## Development

After editing any `.qml`, run `omarchy restart shell`. Omarchy's hot reload
reloads the code but does not reapply the `PanelWindow` geometry.

To check that the new version is up:

```bash
hyprctl layers | grep arc-dock
```

With default settings the expected length is `10 + slots*60 + separators + 60`
px (the gap between slots is zero), where `slots` counts pinned, open and recent
apps, so you can validate the row without relying on the eye. The thickness is
`70`, and the window adds `14` px of gap to the edge.

## License

MIT.
