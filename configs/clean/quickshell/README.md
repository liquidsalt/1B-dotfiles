# quickshell

The desktop shell for Type B: bar, launcher, power menu, OSDs, notification
centre and a wallpaper picker, on Hyprland.

Ported from `Dev/ai-generated/quickshell-clean`, which was written to be copied
to any machine and so carried a config system to describe one. This copy belongs
to a single machine whose facts are already written down in `Plan.md`,
`monitor.toml` and `hypr/hyprland.lua`, so the config file is gone and the values
are literals in `Common/Config.qml`.

## Running it

```sh
quickshell -p ~/.config/quickshell
```

`hyprland.lua` starts it as `systemctl --user restart quickshell.service`, which
is also what SUPER+SHIFT+R re-runs. Nothing is watched any more, so a change to
`Common/Config.qml` wants that restart.

## The config

One file, `Common/Config.qml`, and one object in it: `values`, a map of the same
keys the upstream `config.example` documented. The readers under it — `str`,
`path`, `argv`, `ints`, `has` and the `has*` flags — are unchanged, which is why
the other 44 files were copied across untouched.

Turning a feature off is `has<Thing>: false` near the bottom. The key can stay.

What it says about this machine, and where each fact came from:

| | | from |
|---|---|---|
| `font.*` | Adwaita Sans, IBM Plex Mono, Material Symbols Rounded, Symbols Nerd Font | `fonts.packages` |
| workspaces | derived — index N gets N*5+1..N*5+5 | `monitor.toml` |
| mode ceilings | read from `monitor.toml` | see below |
| `device.backlight`, `device.battery` | empty — the scripts discover them | `brightness.sh`, `battery.sh` |
| `path.wallpapers*` | `~/media/wallpapers/{horizontal,vertical}` | `dirs.nix` |
| `command.*` | `~/.config/scripts/*.sh`, same shape `hyprland.lua` uses | `dirs.nix` |

The two device keys are deliberately empty, because empty means "find it" and the
discovery is better than a guess from here: the backlight is the first node under
`/sys/class/backlight` with a brightness, and the battery is the first
`/sys/class/power_supply` entry that says Battery *and* has a capacity — the type
check being what stops it picking the AC adapter. `nvidia_wmi_ec_backlight` and
`BAT0` are the likely names on this chassis, but naming them blind breaks the
widget if they are off by a digit, where discovery just works. Pin one only if
the first answer turns out wrong.

## Mode ceilings

A ceiling is the highest mode worth offering for an output, because a monitor
will happily list a mode it cannot actually drive over the cable it is on.

These are **not** in `Common/Config.qml`. They were, as a literal table, which
is a second copy of what `monitor.toml` already says. They come from there now:
a section's `max-resolution` and `max-refresh-rate` become its `port`'s ceiling,
falling back to `resolution` and `refresh-rate` when those are absent.

`Common/Config.qml` carries a small TOML reader for it — `[section.name]`
headers, `key = value`, `#` comments, and quoted-string / integer / boolean
values. Not a general parser: no arrays, no inline tables, no multi-line
strings, because `monitor.toml` has none of those and handling them would be
more code than the file being parsed.

### A ceiling is not the current mode

`monitor.toml` is live monitor state — hyprland reads `resolution` to know what
to drive, and this shell **writes** it when the Display popup changes a mode. A
ceiling is a different fact: the highest mode the panel and its cable can carry.
The two only look alike while an output happens to be running flat out.

So the fallback to `resolution` has a sharp edge. Drop `HDMI-A-1` to 1080p in the
popup, that value is written back, and on the next start it *is* the ceiling — so
1440p is no longer offered and the popup cannot undo itself. It ratchets
downwards.

`max-resolution` is the way out, and worth adding for any output the popup should
be able to raise again:

```toml
[docked.main-external]
port           = "HDMI-A-1"
resolution     = "2560x1440"   # what hyprland drives, what the shell writes
max-resolution = "2560x1440"   # what the panel can do, never written
```

Nothing writes `max-*`, so it stays a fact about the hardware. Without it the
ceiling still works — it just tracks whatever the popup last set.

### Docked and undocked

The section prefix is a **NixOS specialisation**, picked at boot, not a runtime
mode. `hardware.nix` gives `docked` nvidia sync, disabled sleep targets, and
`video=eDP-1:d`, which turns the laptop panel off at the kernel level.

The two states are therefore mutually exclusive and share no output: undocked is
`eDP-1` alone, docked is `HDMI-A-1` and `DP-1` with `eDP-1` gone. That is why
every section can be flattened into one port → ceiling map with no state
detection — a ceiling is only looked up for an output that exists, and an output
exists in exactly one state, so `eDP-1`'s entry is simply never consulted while
docked.

There is a largest-wins tie-break for a port appearing twice, but it is not
resolving docked against undocked; that case cannot arise.

### Other details

- Read **once, blocking, at startup**. Nothing watches it, so a change to
  `monitor.toml` wants the same restart a change to `Config.qml` does.
- A section with no resolution is skipped; one with no refresh rate gets no rate
  ceiling, which is what an absent `@R` meant before.
- **No `monitor.toml` at all is fine.** Every output then has no ceiling and is
  filtered only by the generic rules in `Services/MonitorModes.qml` — a minimum
  width and the output's own aspect.

`path.monitor-toml` is where it looks, defaulting to `~/.config/monitor.toml`:
the file sits at the top of `configs/clean` beside the per-program directories,
so it deploys to the root of `~/.config`.

## Glass

Glass, always. There is no `look` key, no `solid` variant and no switch —
`Common/Glass.qml` carries the glass alphas as literals.

Upstream that was a switch, because glass is two decisions that have to agree
and only one is the shell's: Quickshell paints translucent panels but cannot
blur what is behind a layer surface, having no access to those pixels. A copy
that might land on a compositor doing nothing about that needed an opaque
fallback, or the text would sit on the wallpaper.

Here the compositor's half is done and declarative. `hyprland.lua` blurs
`^quickshell:(bar|popup|launcher|notifications|osd)$` with `ignore_alpha = 0.08`
— which keeps the blur to the bar's inset 34px panel rather than the full 50px
strip — and excludes the picker, so choosing a wallpaper does not blur the
wallpaper. Being a `layer_rule` in the compositor config, it survives a restart
on its own. So the fallback had nothing left to fall back from, and
`command.look-set`, which existed to apply the compositor's half on a change, is
gone rather than merely off.

Panels sit at 0.44 and menus at 0.88 — menus carry text you have to read against
whatever the wallpaper happens to be, so they trade transparency for legibility.
The stroke is 11% white, which is plenty when the blur already separates the
panel from the desktop.

## Commands

Thirteen contracts upstream, each the shell saying what argv it will use and what
it expects back. Ten are wired here. Subcommands are part of the value, because
`argv()` splits on whitespace and the shell appends its arguments after them:
`monitor.sh flip` + `["DP-1"]` runs `monitor.sh flip DP-1`.

| key | runs | contract |
|---|---|---|
| `wallpaper-set` | `wallpaper.sh set` | `<output> <path>` |
| `rotate-monitor` | `monitor.sh flip` | `<output>` |
| `set-monitor-mode` | `monitor.sh resolution` | `<output> <mode>` |
| `monitor-list` | `monitor.sh list` | prints the monitors JSON |
| `wifi` | `network.sh` | `radio on\|off \| connect <ssid> \| disconnect`, passphrase on stdin |
| `bluetooth` | `bluetooth.sh` | `power on\|off \| connect <mac> \| disconnect <mac> \| scan <secs>` |
| `session` | `power.sh` | `shutdown\|reboot\|suspend\|lock\|logout` |
| `power-profile` | `power.sh profile` | `get \| set <name>` |
| `gpu-stats` | `gpu.sh` | one line, six fields |
| `brightness` | `brightness.sh` | `get \| set <value> \| device` |
| `battery` | `battery.sh` | `device \| get \| status` |
| `cpu` | `cpu.sh` | `temp \| temp-path` |
| `audio-mixer` | `pavucontrol` | — |

Off, each with its reason in the file: `phone-display` (no VNC here) and
`tray-launch` (a fallback for tray icons that do not implement Activate).
`look-set` is gone entirely — see Glass above.

`gpu-stats` is `gpu.sh`, which wraps `nvidia-smi`. Six fields, verified on the
4060:

```
24, 1639, 8188, 60, 345, NVIDIA GeForce RTX 4060 Laptop GPU
```

utilisation %, memory used MiB, memory total MiB, temp C, clock MHz, name. The
name goes last because it is the only field that could contain a comma.

## Scripts

All written, in `new-system/scripts`, deployed to `~/.config/scripts`.

Rotation and mode changes both want the wallpaper re-sent afterwards: a wallpaper
daemon holds the image at the geometry it was handed, so a screen that has just
turned keeps showing the old frame stretched to fit.

## The accent

One palette, one accent: `#E2C9A2` in `Common/Glass.qml`. It used to be derived
per-output from that output's wallpaper, with the hue kept and the saturation
and lightness pinned — which meant it was that orange with a few degrees of
wobble, never anything else. It is a constant now and the derivation is gone.

`wallpaper.sh set` still records which image is on which output in
`~/.local/state/quickshell/wallpapers.json`, because `awww` and `mpvpaper` have
no memory and `wallpaper.sh restore` replays it at startup:

```json
{ "DP-1": { "path": "/…/x.jpg" } }
```

## What changed from quickshell-clean

Beyond the config going literal, four places where the upstream copy never
actually read its own config — each one hardcoded, and two of them wrong here:

| | |
|---|---|
| `WallpaperPicker.qml` | scanned `$HOME/Media/Wallpapers/<Orientation>`, hardcoded, ignoring `path.wallpapers`. The directories here are `~/media/wallpapers/{horizontal,vertical}` — all lowercase — so it would have found nothing. Reads `Config.wallpaperRootFor(orientation)` now, one root per orientation rather than a subdirectory |
| `WallpaperPicker.qml` | the empty-state text named that same wrong path. Shows the real one |
| `BarTray.qml` | ran a bare `tray-launch` on PATH, hoping it existed, while `hasTrayLaunch` sat unused. Reads the key, and is off |
| `BarHardwareGroup.qml` | `Qt.openUrlExternally("pavucontrol")` — a program name handed to a URL opener, and named in the module rather than the config. Spawns `command.audio-mixer` as a `Process` |

The picker also declines to open when no wallpaper directory is set, which is
what the upstream README said it did and the code did not.

Two things that README promised and the 45 files do not contain: the bar's
HORIZ/VERT rotation chip, and any reader of `path.monitor-transforms`. Rotation
works from the Display popup, which rotates whichever row you clicked. The key
and `hasRotate` are kept so the contract still reads straight, but nothing uses
them yet.

## What it needs

| | |
|---|---|
| `quickshell` ≥ 0.3.0 | where `Quickshell.Networking` and `Quickshell.Bluetooth` land; wifi and bluetooth read over DBus and need both |
| qt6 declarative | in `dev.nix` already |
| Hyprland | workspaces, monitors, focus and the layer shell. Not swappable — the shell is built on it |
| **Adwaita Sans**, **IBM Plex Mono** | the UI and the figures |
| **Material Symbols Rounded** | every icon. Missing, the bar fills with boxes |
| **Symbols Nerd Font** | the few glyphs Material does not carry |

## State of the port

`Common/Config.qml` was run through the real QML engine and every value checked:
the per-output workspace sets, tilde expansion in both `path()` and `argv()`,
every command's resolved argv, and the off keys correctly returning `[]`. All 45
files compile and resolve their types.

The TOML reader was checked against the real `monitor.toml` — correct ceilings
for all three ports — and against hand-written cases for the things that are
easy to get wrong: a `#` inside a quoted value, a trailing comment, integer and
boolean typing, a port appearing twice, a section missing `resolution`, a
section missing `refresh-rate`, empty input, and the file being absent
altogether.

**No bar has been drawn from these files.** Neither this copy nor the one it came
from has been run against a live compositor — `PanelWindow` needs a Wayland
layer-shell backend, so it cannot be checked headless. Expect the first run to
want fixes.

Clicking a workspace number calls `Hyprland.dispatch("workspace N")` in-process,
through Quickshell's own compositor module rather than a tool it spawns. It is the
one place the shell changes something outside itself without a command.
