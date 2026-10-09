pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import "../Common"

// Wifi and ethernet state, and a way to ask for a change

Singleton {
    id: root

    readonly property var wifiDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        return null;
    }

    readonly property var wiredDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wired) return devs[i];
        return null;
    }

    readonly property string wifiDev: wifiDevice ? wifiDevice.name : "wlan0"

    readonly property bool isEthernet: wiredDevice ? wiredDevice.connected : false
    readonly property bool connected:  isEthernet || (wifiDevice ? wifiDevice.connected : false)

    readonly property var activeNetwork: {
        if (!wifiDevice) return null;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i];
        return null;
    }

    readonly property string ssid:
        (!isEthernet && activeNetwork) ? activeNetwork.name : ""
    readonly property int signal:
        activeNetwork ? Math.round(activeNetwork.signalStrength * 100) : 0

    readonly property bool wifiEnabled: Networking.wifiEnabled

    // Strongest first, the one in use pinned to the top — the sort nmcli's
    readonly property var networks: {
        if (!wifiDevice) return [];
        var nets = wifiDevice.networks.values.map(function(n) {
            return {
                inUse:  n.connected,
                ssid:   n.name,
                signal: Math.round(n.signalStrength * 100),
                sec:    root.securityLabel(n.security),
                known:  n.known,
                network: n
            };
        }).filter(function(n) { return n.ssid.length > 0; });
        nets.sort(function(a, b) {
            if (a.inUse !== b.inUse) return a.inUse ? -1 : 1;
            return b.signal - a.signal;
        });
        return nets;
    }

    readonly property var savedConnections:
        root.networks.filter(function(n) { return n.known; })
                     .map(function(n) { return n.ssid; })

    function securityLabel(sec) {
        if (sec === WifiSecurityType.Open || sec === WifiSecurityType.Unknown) return "--";
        return WifiSecurityType.toString(sec);
    }

    // Kept for call compatibility: state arrives on its own now
    function refresh() {}

    // The scanner keeps the network list live while it is on, so it runs only
    function refreshNetworks() {
        if (wifiDevice) wifiDevice.scannerEnabled = true;
    }

    function stopScanning() {
        if (wifiDevice) wifiDevice.scannerEnabled = false;
    }

    // ── acting ──────────────────────────────────────────────────────────────

    readonly property bool canAct: Config.hasWifiCommand

    property string _psk: ""

    Process {
        id: ctl
        running: false
        onStarted: {
            // Always write, even when empty: the command reads one line and a
            ctl.write(root._psk + "\n");
            root._psk = "";
            ctl.stdinEnabled = false;
        }
    }

    function _run(args, psk) {
        if (!root.canAct) return;
        root._psk = psk === undefined ? "" : psk;
        ctl.stdinEnabled = true;
        ctl.command = Config.argv("command.wifi", args);
        ctl.running = true;
    }

    function toggle(state)      { root._run(["radio", state ? "on" : "off"]); }
    function connect(ssid, pwd) { root._run(["connect", ssid], pwd); }
    function disconnect()       { root._run(["disconnect"]); }
}
