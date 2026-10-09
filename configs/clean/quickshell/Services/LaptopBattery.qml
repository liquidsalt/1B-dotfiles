pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

// The machine's own cell, from sysfs

Singleton {
    id: root

    property int    capacity: 0
    property string status:   "Unknown"

    readonly property bool present:  root.base.length > 0 && root.capacity > 0
    readonly property bool charging: root.status === "Charging" || root.status === "Full"

    property string device: Config.batteryDevice
    readonly property string base:
        root.device ? "/sys/class/power_supply/" + root.device : ""

    // Only when the config did not name one
    Process {
        running: Config.batteryDevice === ""
        command: Config.argv("command.battery", ["device"])
        stdout: StdioCollector {
            onStreamFinished: {
                var d = text.trim();
                if (d.length > 0) root.device = d;
            }
        }
    }

    FileView {
        id: cap
        path: root.base ? root.base + "/capacity" : ""
        blockAllReads: root.base === ""
        watchChanges: false
        onLoaded: {
            var n = parseInt(text().trim(), 10);
            if (!isNaN(n)) root.capacity = n;
        }
    }

    FileView {
        id: stat
        path: root.base ? root.base + "/status" : ""
        blockAllReads: root.base === ""
        watchChanges: false
        onLoaded: root.status = text().trim()
    }

    function refresh() {
        if (root.base.length === 0) return;
        cap.reload();
        stat.reload();
    }

    Timer {
        interval: 15000
        running: true
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refresh()
    }
}
