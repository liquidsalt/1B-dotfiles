pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

// The power profile, as a name and a colour

Singleton {
    id: root

    property string current: "balanced"

    readonly property bool available: Config.hasPowerProfile

    readonly property var profiles: [
        { id: "power-saver",  label: "Eco"         },
        { id: "balanced",     label: "Balanced"    },
        { id: "performance",  label: "Performance" }
    ]

    // Green idling, amber working, red burning
    readonly property color tint:
          root.current === "power-saver" ? "#7BD88F"
        : root.current === "performance" ? "#FF5A3C"
        :                                  "#E8913A"

    readonly property bool burning: root.current === "performance"

    Process {
        id: getProfile
        command: Config.argv("command.power-profile", ["get"])
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var name = text.trim();
                if (name.length > 0) root.current = name;
            }
        }
    }

    Process { id: setProfile; running: false }

    function refresh() {
        if (root.available && !getProfile.running) getProfile.running = true;
    }

    function set(next) {
        if (next === root.current || !root.available) return;
        setProfile.command = Config.argv("command.power-profile", ["set", next]);
        setProfile.running = true;
        // Shown immediately rather than waited for: the next `get` corrects it
        root.current = next;
    }

    Timer {
        interval: 10000
        running: root.available
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refresh()
    }
}
