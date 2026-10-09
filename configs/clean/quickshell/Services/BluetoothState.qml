pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import "../Common"

// Adapter and device state, and a way to ask for a change

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property bool scanning: adapter ? adapter.discovering : false

    // Paired and (while scanning) discovered devices, connected ones first,
    readonly property var devices: {
        var devs = Bluetooth.devices.values.map(function(d) {
            return { connected: d.connected, mac: d.address, name: d.name, device: d };
        });
        devs.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
        });
        return devs;
    }

    readonly property int connectedCount:
        Bluetooth.devices.values.filter(function(d) { return d.connected; }).length

    // Kept for call compatibility: nothing needs a manual refresh any more
    function refresh() {}

    // ── acting ──────────────────────────────────────────────────────────────

    readonly property bool canAct: Config.hasBluetoothCommand

    readonly property int scanSeconds: 5

    Process { id: ctl; running: false }

    function _run(args) {
        if (!root.canAct) return;
        ctl.command = Config.argv("command.bluetooth", args);
        ctl.running = true;
    }

    function togglePower(state) { root._run(["power", state ? "on" : "off"]); }

    function toggleConnect(mac, connected) {
        root._run([connected ? "disconnect" : "connect", mac]);
    }

    function scan() {
        if (root.scanning) return;
        root._run(["scan", String(root.scanSeconds)]);
    }
}
