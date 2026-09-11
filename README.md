# Arc Dock

A dock for the [Omarchy](https://omarchy.org/) shell that looks like the macOS
dock: frosted glass, magnification under the pointer, one slot per app.

![Arc Dock](preview.png)

## Install

```bash
omarchy plugin add https://github.com/claudsondouglas/arc.dock.git --enable
```

If the dock does not show up right away, run `omarchy restart shell`.
Right-click the dock to open its settings.

Frosted glass needs `decoration:blur` enabled in Hyprland. Without it the dock
still works, the shell just stays translucent instead of frosted.

## What you get

![The dock at rest](docs/dock.png)

![Magnification under the pointer](docs/magnify.png)

- One slot per app. Windows with the same `appId` share it, and a dot under
  the icon shows the app is open (two dots for two or more windows). The
  focused app's dots use the theme accent.
- Pin apps from the context menu. Pinned apps keep their slot while closed,
  and you can drag them to reorder.
- Recent apps, the last ones you closed, sit after the pinned and open ones.
  Click to reopen. Four by default, up to 12, or off.
- A notification counter on the icon, red with a white number, counting what
  arrived since the app was last focused. Focusing the app clears it.
- Magnification: the icon under the pointer grows and rises above the shell,
  neighbors grow less the farther they are. Peak size and reach are settings.
- Frosted glass with adjustable opacity. The dock asks Hyprland for the blur
  rule itself, so there is nothing to add to your config.
- Auto-hide: never, in fullscreen, when a window sits underneath (the
  default), or always. Touching the screen edge brings it back.
- Any edge: bottom, top, left or right. On a side edge the row runs
  vertically.
- Colors, radius and spacing come from the active theme, so switching themes
  restyles the dock.

Left-click goes to the app, or launches it if it is closed. With several
windows the click cycles through them. Right-click opens a menu with the app's
`.desktop` actions, its open windows, pin/unpin and close.

## Settings

![Settings window](docs/settings.png)

Right-click on the dock shell (the app button or any gap between slots) opens
the settings window. Changes apply as you make them. Sections: size,
magnification, background, content, position and hide.

The window is keyboard driven: arrows or `hjkl` to move and change values,
`Tab` to switch section, `Backspace` to reset a row, `Esc` to close.

Values live in `~/.config/omarchy/arc-dock.json`. Editing the file by hand
takes effect immediately. A missing key means the default, and the reset
buttons delete the key rather than writing the default value.

To bind the window to a Hyprland shortcut:

```bash
omarchy-shell shell toggle arc.dock '{}'
```

Pinned apps and recents are stored in `~/.local/state/omarchy/arc-dock.json`.

## Files

| File | What |
| --- | --- |
| `Arcdock.qml` | the dock surface, geometry and the slot model |
| `ArcConfig.qml` | settings and the file they live in |
| `ArcSettings.qml` | the settings window |
| `ArcSlot.qml` | one slot: icon, state dot and notification counter |
| `ArcLauncher.qml` | the button that opens the Omarchy app menu |
| `ArcMenu.qml` | a slot's context menu |
| `ArcGlass.qml` | the light on the glass |
| `ArcShadow.qml` | the shadow under the shell |

The code comments explain the design decisions in detail.

## Development

After editing any `.qml`, run `omarchy restart shell`. Hot reload picks up the
code but not the `PanelWindow` geometry. `hyprctl layers | grep arc-dock`
shows the dock window and its size.

## License

MIT.
