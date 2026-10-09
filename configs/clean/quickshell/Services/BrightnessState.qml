pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

// Backlight level, watched so the OSD reacts to whoever changed it

Singleton {
    id: root

    property int brightness:    0
    property int maxBrightness: 100
    property int percent: maxBrightness > 0
        ? Math.round(brightness / maxBrightness * 100)
        : 0

    property string device: Config.backlightDevice
    readonly property string base: device ? "/sys/class/backlight/" + device : ""

    Process {
        running: Config.backlightDevice === ""
        command: Config.argv("command.brightness", ["device"])
        stdout: StdioCollector {
            onStreamFinished: {
                var d = text.trim();
                if (d.length > 0) root.device = d;
            }
        }
    }

    FileView {
        path: root.base ? root.base + "/brightness" : ""
        blockAllReads: root.base === ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var v = parseInt(text().trim());
            if (!isNaN(v)) root.brightness = v;
        }
    }

    FileView {
        path: root.base ? root.base + "/max_brightness" : ""
        blockAllReads: root.base === ""
        onLoaded: {
            var v = parseInt(text().trim());
            if (!isNaN(v)) root.maxBrightness = v;
        }
    }
}
