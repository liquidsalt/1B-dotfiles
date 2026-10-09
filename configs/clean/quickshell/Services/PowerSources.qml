pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

// Every battery that is not the machine's own, as named by the config

Singleton {
    id: root

    // One entry per configured source, in `power.order`
    readonly property var configured: Config.powerSources

    // name -> { percent, caption, present }
    property var readings: ({})

    // What BarPower draws, in order, in the dial's shape
    readonly property var list: {
        var out = [];
        for (var i = 0; i < root.configured.length; i++) {
            var src = root.configured[i];
            var r = root.readings[src.name];
            out.push({
                label:   src.label,
                present: r !== undefined && r.present === true,
                value:   r !== undefined ? r.percent : 0,
                caption: r !== undefined ? r.caption : ""
            });
        }
        return out;
    }

    function refresh() {
        for (var i = 0; i < repeater.count; i++) {
            var it = repeater.itemAt(i);
            if (it) it.poll();
        }
    }

    // A Repeater over the configured sources, so the number of readers follows
    Repeater {
        id: repeater
        model: root.configured

        delegate: Item {
            required property var modelData

            function poll() { if (!proc.running) proc.running = true; }

            Process {
                id: proc
                command: modelData.argv
                running: false

                stdout: StdioCollector {
                    onStreamFinished: {
                        var line = text.split("\n")[0].trim();
                        var m = /^(\d+)\s*(.*)$/.exec(line);
                        var next = ({});
                        // Copy rather than mutate: QML only notices a var
                        for (var k in root.readings) next[k] = root.readings[k];
                        next[modelData.name] = {
                            percent: m ? parseInt(m[1], 10) : 0,
                            caption: m ? m[2].trim() : "",
                            present: !!m
                        };
                        root.readings = next;
                    }
                }

                // A command that exits non-zero has said the device is not
                onExited: exitCode => {
                    if (exitCode === 0) return;
                    var next = ({});
                    for (var k in root.readings) next[k] = root.readings[k];
                    next[modelData.name] = { percent: 0, caption: "", present: false };
                    root.readings = next;
                }
            }

            // Two minutes, because these are radio round trips to a peripheral
            Timer {
                interval: 120000
                running: true
                triggeredOnStart: true
                repeat: true
                onTriggered: proc.running = true
            }
        }
    }
}
