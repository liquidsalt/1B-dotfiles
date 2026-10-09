import Quickshell
import Quickshell.Io
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Item {
    id: root
    implicitHeight: 20
    implicitWidth:  strength.implicitWidth

    readonly property bool wifiMode: !NetworkState.isEthernet && NetworkState.wifiEnabled

    // No strength arcs, and no faint cone behind them

    Text {
        id: strength
        anchors.centerIn: parent
        font.family: Glass.fontIcon
        font.pixelSize: 16
        font.variableAxes: NetworkState.connected ? Glass.iconActive : Glass.iconIdle
        color: NetworkState.connected ? Glass.text : Glass.muted

        text: {
            if (NetworkState.isEthernet)   return "\ueb2f";
            if (!NetworkState.wifiEnabled) return "\ue648";
            return "\ue63e";
        }

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            var opening = PopupState.owner !== root;
            PopupState.toggle(root);
            if (opening) NetworkState.refreshNetworks();
        }
    }

    PopupWindow {
        id: popup
        visible: PopupState.owner === root
        grabFocus: true
        onClosed: if (PopupState.owner === root) PopupState.close()
        color: "transparent"
        implicitWidth: 300
        implicitHeight: shell.implicitHeight

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 10

        property string pwdSsid: ""

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
                    title: "Network"
                    on:    NetworkState.wifiEnabled
                    onToggled: NetworkState.toggle(!NetworkState.wifiEnabled)
                }

                Column {
                    width: parent.width; spacing: 2
                    visible: NetworkState.wifiEnabled

                    Repeater {
                        model: NetworkState.networks
                        delegate: PopupRow {
                            required property var modelData
                            width: col.width
                            track: ""
                            glyph: modelData.signal >= 70 ? ""
                                 : modelData.signal >= 40 ? ""
                                 :                          ""
                            label:  modelData.ssid
                            active: modelData.inUse
                            trailing: modelData.inUse ? ""
                                    : (modelData.sec && modelData.sec !== "--") ? "" : ""
                            onActivated: {
                                if (modelData.inUse) {
                                    NetworkState.disconnect();
                                } else if (modelData.sec && modelData.sec !== "--"
                                           && NetworkState.savedConnections.indexOf(modelData.ssid) < 0) {
                                    popup.pwdSsid = modelData.ssid;
                                    pwdField.text = "";
                                    pwdField.forceActiveFocus();
                                } else {
                                    NetworkState.connect(modelData.ssid, "");
                                }
                                pwdRefreshTimer.restart();
                            }
                        }
                    }

                    PopupEmpty {
                        width: parent.width
                        visible: NetworkState.networks.length === 0
                        label: "Scanning…"
                    }
                }

                PopupEmpty {
                    width: parent.width
                    visible: !NetworkState.wifiEnabled
                    label: "Wi-Fi is off"
                }

                Column {
                    visible: popup.pwdSsid !== ""
                    width: parent.width
                    spacing: 5

                    Text {
                        font.family: Glass.fontUi; font.pixelSize: 12
                        color: Glass.muted
                        text:  "Password for " + popup.pwdSsid
                    }
                    Rectangle {
                        width: parent.width; height: 30; radius: 9
                        color: Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1
                        border.color: Glass.stroke
                        TextInput {
                            id: pwdField
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Glass.fontUi; font.pixelSize: 13
                            color: Glass.text
                            echoMode: TextInput.Password
                            focus: popup.pwdSsid !== ""
                            onAccepted: {
                                if (text.length > 0) {
                                    NetworkState.connect(popup.pwdSsid, text);
                                    popup.pwdSsid = ""; text = "";
                                    pwdRefreshTimer.restart();
                                }
                            }
                            Keys.onEscapePressed: { popup.pwdSsid = ""; text = ""; }
                        }
                    }
                }

                PopupAction {
                    width: parent.width
                    glyph: ""
                    label: "Rescan"
                    onActivated: NetworkState.refreshNetworks()
                }
            }
        }

        Timer { id: pwdRefreshTimer; interval: 2000; repeat: false; onTriggered: NetworkState.refreshNetworks() }
    }
}
