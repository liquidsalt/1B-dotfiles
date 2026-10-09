pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    // [{ name, current, rate, modes: [{ mode, label, rate, active }] }]
    property var outputs: []

    // The highest mode worth offering per output, read from monitor.toml — see
    function ceilingFor(name) { return Config.monitorMax(name); }

    // Below this, a "resolution" is a thing you set by accident
    readonly property int minWidth: 1280

    // A fixed-pixel panel can only letterbox or stretch a mode that is not
    readonly property real aspectTolerance: 0.02

    readonly property bool available: Config.hasMonitorList

    function refresh() {
        if (root.available && !probe.running) probe.running = true;
    }

    Process {
        id: probe
        running: false
        command: Config.argv("command.monitor-list")
        stdout: StdioCollector {
            onStreamFinished: root.outputs = root.parse(text)
        }
    }

    function parseMode(s) {
        var m = /^(\d+)x(\d+)@([\d.]+)Hz?$/.exec(s.trim());
        if (!m)
            return null;
        return { w: parseInt(m[1]), h: parseInt(m[2]), r: Math.round(parseFloat(m[3])) };
    }

    function parse(raw) {
        var mons;
        try {
            mons = JSON.parse(raw);
        } catch (e) {
            return [];
        }

        var out = [];
        for (var i = 0; i < mons.length; i++) {
            var mon = mons[i];
            var cap = root.ceilingFor(mon.name);
            var list = mon.availableModes || [];

            // The ceiling's shape where one is declared, the running mode's
            var aspect = cap ? (cap.w / cap.h) : (mon.width / mon.height);

            // One entry per resolution, keeping its fastest refresh
            var best = ({});
            for (var j = 0; j < list.length; j++) {
                var mode = root.parseMode(list[j]);
                if (!mode || mode.w < root.minWidth)
                    continue;
                if (cap && (mode.w > cap.w || mode.h > cap.h || mode.r > cap.r))
                    continue;
                if (Math.abs(mode.w / mode.h - aspect) > root.aspectTolerance)
                    continue;
                var key = mode.w + "x" + mode.h;
                if (best[key] === undefined || mode.r > best[key])
                    best[key] = mode.r;
            }

            var dims = [];
            for (var k in best)
                dims.push({ w: parseInt(k.split("x")[0]),
                            h: parseInt(k.split("x")[1]),
                            r: best[k] });
            dims.sort(function (a, b) { return (b.w - a.w) || (b.h - a.h); });

            var rows = [];
            for (var d = 0; d < dims.length; d++) {
                rows.push({
                    mode:  dims[d].w + "x" + dims[d].h + "@" + dims[d].r,
                    label: dims[d].w + " × " + dims[d].h,
                    rate:  dims[d].r + " Hz",
                    // Matched on resolution alone
                    active: dims[d].w === mon.width && dims[d].h === mon.height
                });
            }

            out.push({
                name:    mon.name,
                current: mon.width + " × " + mon.height,
                rate:    Math.round(mon.refreshRate) + " Hz",
                modes:   rows
            });
        }
        return out;
    }

    // One output's rows, or none
    function modesFor(name) {
        for (var i = 0; i < root.outputs.length; i++)
            if (root.outputs[i].name === name)
                return root.outputs[i].modes;
        return [];
    }

    // `command.set-monitor-mode <output> <mode>`, and that is the whole of it
    function apply(name, mode) {
        if (!Config.hasSetMonitorMode) return;
        applier.command = Config.argv("command.set-monitor-mode", [name, mode]);
        applier.running = true;
        settle.restart();
    }

    Process { id: applier; running: false }

    // Re-read after a change lands, so a popup left open stops claiming the
    Timer {
        id: settle
        interval: 2500
        repeat: false
        onTriggered: root.refresh()
    }
}
