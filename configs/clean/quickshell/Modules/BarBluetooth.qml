import Quickshell
import Quickshell.Io
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Item {
    id: root
    implicitHeight: 20
    implicitWidth:  icon.implicitWidth

    Text {
        id: icon
        anchors.centerIn: parent
        font.family: Glass.fontIcon
        font.pixelSize: 16
        font.variableAxes: BluetoothState.connectedCount > 0 ? Glass.iconActive : Glass.iconIdle
        color: BluetoothState.connectedCount > 0 ? Glass.text : Glass.muted
        // bluetooth_connected has a dot either side, and at every
        text:  BluetoothState.scanning ? "\ue1aa"
             : BluetoothState.powered  ? "\ue1a7"
             :                           "\ue1a9"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            var opening = PopupState.owner !== root;
            PopupState.toggle(root);
            if (opening) BluetoothState.refresh();
        }
    }

    PopupWindow {
        id: popup
        visible: PopupState.owner === root
        grabFocus: true
        onClosed: if (PopupState.owner === root) PopupState.close()
        color: "transparent"
        implicitWidth: 280
        implicitHeight: shell.implicitHeight

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 10

        GlassSurface {
            id: shell
            anchors.fill: parent
            strong: true
            implicitHeight: col.implicitHeight + 20

            Column {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 6

                PopupHeader {
                    width: parent.width
                    title: "Bluetooth"
                    on:    BluetoothState.powered
                    onToggled: BluetoothState.togglePower(!BluetoothState.powered)
                }

                Column {
                    width: parent.width; spacing: 2
                    visible: BluetoothState.powered

                    Repeater {
                        model: BluetoothState.devices
                        delegate: PopupRow {
                            required property var modelData
                            width:  col.width
                            glyph:  modelData.connected ? "" : ""
                            label:  modelData.name
                            active: modelData.connected
                            trailing: modelData.connected ? "" : ""
                            onActivated: {
                                BluetoothState.toggleConnect(modelData.mac, modelData.connected);
                                refreshTimer.restart();
                            }
                        }
                    }

                    PopupEmpty {
                        width: parent.width
                        visible: BluetoothState.devices.length === 0
                        label: "No devices"
                    }
                }

                PopupEmpty {
                    width: parent.width
                    visible: !BluetoothState.powered
                    label: "Bluetooth is off"
                }

                PopupAction {
                    width: parent.width
                    glyph: ""
                    label: BluetoothState.scanning ? "Scanning…" : "Scan for 5s"
                    enabled: !BluetoothState.scanning && BluetoothState.powered
                    onActivated: BluetoothState.scan()
                }
            }
        }

        Timer { id: refreshTimer; interval: 2000; repeat: false; onTriggered: BluetoothState.refresh() }
    }
}
