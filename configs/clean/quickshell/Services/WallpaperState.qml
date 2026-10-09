pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    // Beside everything else the shell watches, so one key moves the lot
    readonly property string statePath: Config.stateDir + "/wallpapers.json"

    // { "<monitor>": { "path": "...", "accent": "#RRGGBB" } }
    property var entries: ({})

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object")
                    root.entries = parsed;
            } catch (e) {
                // Half-written file mid-`mv`
            }
        }
    }

    function entryFor(name) {
        return (name && root.entries[name]) ? root.entries[name] : null;
    }

    function pathFor(name) {
        const e = root.entryFor(name);
        return (e && e.path) ? e.path : "";
    }


    Process { id: applier; running: false }

    // Fire and forget
    function apply(monitor, path) {
        if (!monitor || !path || !Config.hasWallpaperSet) return;
        applier.command = Config.argv("command.wallpaper-set", [monitor, path]);
        applier.running = true;
    }
}
