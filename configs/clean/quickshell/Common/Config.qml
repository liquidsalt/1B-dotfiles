pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Everything this shell knows about Type B, stated once

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""

    // The config
    readonly property var values: ({
        // ── type ────────────────────────────────────────────────────────────
        "font.ui":    "Adwaita Sans",
        "font.mono":  "IBM Plex Mono",
        "font.icon":  "Material Symbols Rounded",
        "font.glyph": "Symbols Nerd Font",

        // ── outputs ─────────────────────────────────────────────────────────

        // Mode ceilings are not here

        // ── devices ─────────────────────────────────────────────────────────
        "device.backlight": "",
        "device.battery":   "",

        // ── paths ───────────────────────────────────────────────────────────
        "path.state":              "~/.local/state/quickshell",
        // Where monitor.toml lands
        "path.monitor-toml":       "~/.config/monitor.toml",
        // Lowercase, per dirs.nix
        "path.wallpapers":          "~/media/wallpapers/horizontal",
        "path.wallpapers.vertical": "~/media/wallpapers/vertical",
        "path.monitor-transforms":  "~/.local/state/monitor-transforms",

        // ── commands ────────────────────────────────────────────────────────

        // <cmd> <output> <path> — the counterpart to the `wallpaper.sh restore`
        "command.wallpaper-set": "~/.config/scripts/wallpaper.sh set",

        // <cmd> <output> — `flip` is also on SUPER+backslash, where it takes
        "command.rotate-monitor": "~/.config/scripts/monitor.sh flip",

        // <cmd> <output> <mode>, mode as 2560x1440@144.00 or 2560x1440
        "command.set-monitor-mode": "~/.config/scripts/monitor.sh resolution",

        // <cmd> — prints hyprctl's monitors JSON, which is where the Display
        "command.monitor-list": "~/.config/scripts/monitor.sh list",

        // <cmd> radio on|off | connect <ssid> | disconnect
        "command.wifi": "~/.config/scripts/network.sh",

        // <cmd> power on|off | connect <mac> | disconnect <mac> | scan <secs>
        "command.bluetooth": "~/.config/scripts/bluetooth.sh",

        // <cmd> shutdown | reboot | suspend | lock | logout
        "command.session": "~/.config/scripts/power.sh",

        // <cmd> get | set <name>
        "command.power-profile": "~/.config/scripts/power.sh profile",

        // <cmd> — one line of six comma-separated fields:
        "command.gpu-stats": "~/.config/scripts/gpu.sh",

        // <cmd> — opened by left-clicking the volume figure
        "command.brightness": "~/.config/scripts/brightness.sh",
        "command.battery":    "~/.config/scripts/battery.sh",
        "command.cpu":        "~/.config/scripts/cpu.sh",

        "command.audio-mixer": "pavucontrol"

        // Deliberately absent, and each one's has* flag below says so:
    })

    // ── readers ─────────────────────────────────────────────────────────────

    function has(key) { return root.values[key] !== undefined; }

    function str(key, fallback) {
        var v = root.values[key];
        return v === undefined ? (fallback === undefined ? "" : fallback) : v;
    }

    // A path, with a leading ~ or $HOME expanded
    function path(key, fallback) {
        var v = root.str(key, fallback);
        if (v.length === 0) return "";
        if (v.charAt(0) === "~") return root.home + v.slice(1);
        if (v.indexOf("$HOME") === 0) return root.home + v.slice(5);
        return v;
    }

    // A command as an argv list, or [] when the key is unset
    function argv(key, extra) {
        var v = root.str(key, "");
        if (v.length === 0) return [];
        var out = v.split(/\s+/).filter(function(s) { return s.length > 0; });
        if (out.length > 0 && out[0].charAt(0) === "~")
            out[0] = root.home + out[0].slice(1);
        if (extra !== undefined) out = out.concat(extra);
        return out;
    }

    function flag(key, fallback) {
        var v = root.str(key, "").toLowerCase();
        if (v.length === 0) return fallback === true;
        return v === "true" || v === "yes" || v === "1" || v === "on";
    }

    function ints(key, fallback) {
        var v = root.str(key, "");
        if (v.length === 0) return fallback;
        var out = v.split(/[\s,]+/)
                   .filter(function(s) { return s.length > 0; })
                   .map(function(s) { return parseInt(s, 10); })
                   .filter(function(n) { return !isNaN(n); });
        return out.length > 0 ? out : fallback;
    }

    // ── type ────────────────────────────────────────────────────────────────

    readonly property string fontUi:    str("font.ui",    "Adwaita Sans")
    readonly property string fontMono:  str("font.mono",  "IBM Plex Mono")
    readonly property string fontIcon:  str("font.icon",  "Material Symbols Rounded")
    readonly property string fontGlyph: str("font.glyph", "Symbols Nerd Font")

    // ── outputs ─────────────────────────────────────────────────────────────

    // Five per output, by index: 0 gets 1-5, 1 gets 6-10, and so on.
    function workspacesFor(output) {
        var i = root.monitorIndices[output];
        if (i === undefined) return [];
        var out = [];
        for (var n = 1; n <= 5; n++) out.push(i * 5 + n);
        return out;
    }

    // ── mode ceilings, from monitor.toml ────────────────────────────────────

    readonly property string monitorTomlPath:
        path("path.monitor-toml", "~/.config/monitor.toml")

    FileView {
        id: monitorTomlFile
        blockLoading: true
        printErrors: false
    }

    // { "<port>": { w, h, r } }
    property var monitorCeilings: ({})

    // { "<port>": index }
    property var monitorIndices: ({})

    Component.onCompleted: root._loadMonitorToml()

    function _loadMonitorToml() {
        monitorTomlFile.path = root.monitorTomlPath;
        var text = monitorTomlFile.text();
        if (text.length === 0) return;
        var toml = root._parseToml(text);
        root.monitorCeilings = root._ceilings(toml);
        root.monitorIndices  = root._indices(toml);
    }

    // Enough TOML for this file: `[section.name]` headers, `key = value` pairs,
    function _parseToml(text) {
        var out = ({});
        var section = "";
        var lines = text.split("\n");

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];

            // Strip comments, but not a `#` inside a quoted value
            var quoted = false, cut = -1;
            for (var c = 0; c < line.length; c++) {
                if (line.charAt(c) === '"') quoted = !quoted;
                else if (line.charAt(c) === "#" && !quoted) { cut = c; break; }
            }
            if (cut >= 0) line = line.slice(0, cut);
            line = line.trim();
            if (line.length === 0) continue;

            if (line.charAt(0) === "[") {
                var close = line.indexOf("]");
                if (close > 1) {
                    section = line.slice(1, close).trim();
                    if (out[section] === undefined) out[section] = ({});
                }
                continue;
            }

            var eq = line.indexOf("=");
            if (eq < 0 || section === "") continue;

            var key = line.slice(0, eq).trim();
            var raw = line.slice(eq + 1).trim();
            if (key.length === 0 || raw.length === 0) continue;

            var value;
            if (raw.charAt(0) === '"' && raw.charAt(raw.length - 1) === '"' && raw.length >= 2)
                value = raw.slice(1, -1);
            else if (raw === "true")  value = true;
            else if (raw === "false") value = false;
            else if (/^-?\d+(\.\d+)?$/.test(raw)) value = parseFloat(raw);
            else value = raw;

            out[section][key] = value;
        }
        return out;
    }

    // Sections to ceilings, keyed by port
    function _indices(toml) {
        var out = ({});
        for (var section in toml) {
            var s = toml[section];
            if (!s || !s["port"] || s["index"] === undefined) continue;
            out[String(s["port"]).trim()] = parseInt(s["index"], 10);
        }
        return out;
    }

    function _ceilings(toml) {
        var out = ({});
        for (var section in toml) {
            var s = toml[section];
            if (!s || !s["port"]) continue;

            var res  = s["resolution_ceiling"]   !== undefined
                     ? s["resolution_ceiling"]   : s["resolution"];
            var rate = s["refresh-rate_ceiling"] !== undefined
                     ? s["refresh-rate_ceiling"] : s["refresh-rate"];
            if (res === undefined) continue;

            var m = /^(\d+)\s*x\s*(\d+)$/.exec(String(res).trim());
            if (!m) continue;

            var entry = {
                w: parseInt(m[1], 10),
                h: parseInt(m[2], 10),
                // No rate stated means no rate ceiling, matching what an
                r: (rate === undefined || isNaN(parseFloat(rate)))
                    ? 1e6 : parseFloat(rate)
            };

            var port = String(s["port"]).trim();
            var prev = out[port];
            if (prev === undefined
                || entry.w * entry.h > prev.w * prev.h
                || (entry.w * entry.h === prev.w * prev.h && entry.r > prev.r))
                out[port] = entry;
        }
        return out;
    }

    // { w, h, r } or null for no ceiling
    function monitorMax(output) {
        var v = root.monitorCeilings[output];
        return v === undefined ? null : v;
    }

    // ── devices ─────────────────────────────────────────────────────────────

    readonly property string backlightDevice: str("device.backlight", "")
    readonly property string batteryDevice:   str("device.battery", "")

    // ── paths ───────────────────────────────────────────────────────────────

    readonly property string stateDir:
        path("path.state", "~/.local/state/quickshell")

    // One root per orientation
    readonly property string wallpaperRoot:
        path("path.wallpapers", "")
    readonly property string wallpaperRootVertical:
        path("path.wallpapers.vertical", "")

    // The root for a given orientation, as HyprlandIpc spells it
    function wallpaperRootFor(orientation) {
        if (orientation === "Vertical" && root.wallpaperRootVertical.length > 0)
            return root.wallpaperRootVertical;
        return root.wallpaperRoot.length > 0
            ? root.wallpaperRoot : root.wallpaperRootVertical;
    }

    readonly property string monitorTransformDir:
        path("path.monitor-transforms", "~/.local/state/monitor-transforms")

    // ── power sources ───────────────────────────────────────────────────────
    readonly property var powerSources: [
        { name: "headset", label: "HS", argv: [home + "/.config/scripts/headset.py"] }
    ]

    // ── commands ────────────────────────────────────────────────────────────

    readonly property bool hasTrayLaunch:   false

    readonly property bool hasGpuStats:        true
    readonly property bool hasSetMonitorMode:  true
    readonly property bool hasMonitorList:     true
    readonly property bool hasPowerProfile:    true
    readonly property bool hasSession:         true
    readonly property bool hasWallpaperSet:    true
    readonly property bool hasAudioMixer:      true
    readonly property bool hasWifiCommand:     true
    readonly property bool hasBluetoothCommand: true

    // Two flags for one key
    readonly property bool hasRotateCommand: true
    readonly property bool hasRotate: root.hasRotateCommand

    readonly property bool hasWallpapers:
        root.wallpaperRoot.length > 0 || root.wallpaperRootVertical.length > 0
}
