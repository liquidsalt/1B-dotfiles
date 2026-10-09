import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"
import "../Services"
import "../Widgets"

Item {
    id: root
    implicitHeight: 20
    implicitWidth:  chip.implicitWidth

    // Which output's mode list is expanded, or ""
    property string expanded: ""


    Process { id: rotator; running: false }

    // `rotate-monitor <name>` flips that output's persisted transform and
    function rotate(name) {
        if (!Config.hasRotateCommand) return;
        rotator.command = Config.argv("command.rotate-monitor", [name]);
        rotator.running = true;
        rotated.restart();
    }

    Timer {
        id: rotated
        interval: 2500
        repeat: false
        onTriggered: MonitorModes.refresh()
    }

    Text {
        id: chip
        anchors.centerIn: parent
        font.family: Glass.fontIcon
        font.pixelSize: 17
        font.variableAxes: PopupState.owner === root ? Glass.iconActive : Glass.iconIdle
        color: PopupState.owner === root ? Glass.text : Glass.muted
        // aspect_ratio
        text: "\ue85b"
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var opening = PopupState.owner !== root;
            PopupState.toggle(root);
            if (opening) {
                root.expanded = "";
                MonitorModes.refresh();
            }
        }
    }

    PopupWindow {
        id: popup
        visible: PopupState.owner === root
        grabFocus: true
        onClosed: {
            if (PopupState.owner === root) PopupState.close();
            root.expanded = "";
        }
        color: "transparent"
        // 288 until the rotate button arrived
        implicitWidth:  308
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

                Text {
                    height: 20
                    font.family: Glass.fontUi
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.13
                    color: Glass.text
                    text: "Display"
                }

                // ---- outputs, each with its own modes under it ----
                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: MonitorModes.outputs

                        delegate: Column {
                            id: output
                            required property var modelData
                            width: col.width
                            spacing: 2

                            readonly property bool open:
                                root.expanded === output.modelData.name

                            PopupRow {
                                width: parent.width
                                // monitor
                                glyph:  "\uef5b"
                                label:  output.modelData.name + "  ·  " + output.modelData.current
                                active: output.open
                                // expand_more / chevron_right
                                trailing: output.open ? "\ue5cf" : "\ue409"
                                onActivated: root.expanded =
                                    output.open ? "" : output.modelData.name

                                // Every output can rotate
                                action: "\ue863"
                                onActionTriggered: root.rotate(output.modelData.name)
                            }

                            Column {
                                visible: output.open
                                width: parent.width - 16
                                x: 16
                                spacing: 2
                                bottomPadding: output.open ? 4 : 0

                                Repeater {
                                    model: MonitorModes.modesFor(output.modelData.name)

                                    delegate: PopupRow {
                                        required property var modelData
                                        width: parent.width
                                        // aspect_ratio
                                        glyph:  "\ue85b"
                                        label:  modelData.label + "  ·  " + modelData.rate
                                        active: modelData.active
                                        // check
                                        trailing: modelData.active ? "\ue5ca" : ""
                                        onActivated: {
                                            if (!modelData.active)
                                                MonitorModes.apply(output.modelData.name,
                                                                   modelData.mode);
                                            PopupState.close();
                                            root.expanded = "";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PopupEmpty {
                        width: parent.width
                        visible: MonitorModes.outputs.length === 0
                        label: "Reading outputs…"
                    }
                }
            }
        }
    }
}
