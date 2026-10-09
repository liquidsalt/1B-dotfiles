pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

// CPU, memory and GPU, for the bar's meters and the hardware menu

Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    property int gpuPercent: 0

    // Detail, read on the same tick and only ever shown in the menu
    property string cpuModel:  ""
    property string loadAvg:   ""
    property int    cpuTemp:   0

    property string gpuName:     ""
    property int    gpuMemUsed:  0   // MiB
    property int    gpuMemTotal: 0
    property int    gpuTemp:     0
    property int    gpuClock:    0

    property real memUsedGiB:   0
    property real memTotalGiB:  0
    property real swapUsedGiB:  0
    property real swapTotalGiB: 0

    property real lastTotal: 0
    property real lastIdle:  0

    FileView {
        id: statFile
        path: "/proc/stat"
        watchChanges: false
        onLoaded: {
            var line = text().split("\n")[0];
            var f = line.trim().split(/\s+/);
            var user    = parseFloat(f[1]);
            var nice    = parseFloat(f[2]);
            var sys     = parseFloat(f[3]);
            var idle    = parseFloat(f[4]);
            var iowait  = parseFloat(f[5] || 0);
            var irq     = parseFloat(f[6] || 0);
            var softirq = parseFloat(f[7] || 0);
            var total   = user + nice + sys + idle + iowait + irq + softirq;
            var idleAll = idle + iowait;
            if (root.lastTotal > 0) {
                var dt = total - root.lastTotal;
                var di = idleAll - root.lastIdle;
                if (dt > 0) root.cpuPercent = Math.round((1 - di / dt) * 100);
            }
            root.lastTotal = total;
            root.lastIdle  = idleAll;
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        watchChanges: false
        onLoaded: {
            var t = text();
            function kb(key) {
                var m = new RegExp(key + ":\\s+(\\d+)").exec(t);
                return m ? parseInt(m[1], 10) : 0;
            }
            var total = kb("MemTotal");
            var avail = kb("MemAvailable");
            if (total && avail) {
                root.memPercent  = Math.round((1 - avail / total) * 100);
                root.memTotalGiB = total / 1048576;
                root.memUsedGiB  = (total - avail) / 1048576;
            }
            var swTotal = kb("SwapTotal");
            var swFree  = kb("SwapFree");
            root.swapTotalGiB = swTotal / 1048576;
            root.swapUsedGiB  = (swTotal - swFree) / 1048576;
        }
    }

    // Read once
    FileView {
        path: "/proc/cpuinfo"
        watchChanges: false
        onLoaded: {
            var m = /model name\s*:\s*(.+)/.exec(text());
            // "13th Gen Intel(R) Core(TM) i9-13900H" is mostly legal
            if (m) root.cpuModel = m[1].replace(/\((R|TM)\)/g, "")
                                       .replace(/\s+/g, " ").trim();
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        watchChanges: false
        onLoaded: {
            var f = text().trim().split(/\s+/);
            if (f.length >= 3) root.loadAvg = f[0] + "  " + f[1] + "  " + f[2];
        }
    }

    // hwmon numbering is not stable across boots, so the node is found once by
    property string cpuTempPath: ""

    Process {
        running: true
        command: Config.argv("command.cpu", ["temp-path"])
        stdout: StdioCollector { onStreamFinished: root.cpuTempPath = text.trim() }
    }

    FileView {
        id: tempFile
        path: root.cpuTempPath
        watchChanges: false
        onLoaded: {
            var n = parseInt(text().trim(), 10);
            if (!isNaN(n)) root.cpuTemp = Math.round(n / 1000);
        }
    }

    // `command.gpu-stats` prints one line of six comma-separated fields:
    readonly property bool gpuAvailable: Config.hasGpuStats

    Process {
        id: gpuProc
        command: Config.argv("command.gpu-stats")
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split(",");
                if (f.length < 6) return;
                var n = parseInt(f[0], 10);
                if (!isNaN(n)) root.gpuPercent = n;
                root.gpuMemUsed  = parseInt(f[1], 10) || 0;
                root.gpuMemTotal = parseInt(f[2], 10) || 0;
                root.gpuTemp     = parseInt(f[3], 10) || 0;
                root.gpuClock    = parseInt(f[4], 10) || 0;
                root.gpuName     = f.slice(5).join(",").trim();
            }
        }
    }

    Timer {
        interval: 2000; running: true; triggeredOnStart: true; repeat: true
        onTriggered: {
            statFile.reload(); memFile.reload();
            loadFile.reload(); tempFile.reload();
            if (root.gpuAvailable && !gpuProc.running) gpuProc.running = true;
        }
    }
}
