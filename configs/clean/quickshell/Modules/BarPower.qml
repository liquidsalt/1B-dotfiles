    import Quickshell
    import QtQuick
    import "../Services"
    import "../Common"
    import "../Widgets"

    Item {
        id: root

        implicitWidth:  line.implicitWidth
        implicitHeight: line.implicitHeight

        property color accent: Glass.accent

        // The machine's own cell first — it outranks anything plugged into it,
        readonly property var readings: {
            var out = [];
            out.push({
                label:   "Laptop",
                present: LaptopBattery.present,
                value:   LaptopBattery.capacity,
                caption: LaptopBattery.charging ? "Charging" : "Discharging",
                color:   PowerProfile.available ? PowerProfile.tint : root.accent,
                burning: PowerProfile.available && PowerProfile.burning
            });
            var ext = PowerSources.list;
            for (var i = 0; i < ext.length; i++) out.push(ext[i]);
            return out;
        }

        // Defaults filled here rather than in every source: a source that
        readonly property var sources: {
            var out = [];
            for (var i = 0; i < root.readings.length; i++) {
                var s = root.readings[i];
                out.push({
                    label:   s.label,
                    present: s.present === true,
                    value:   s.present === true ? s.value : 0,
                    caption: s.caption !== undefined ? s.caption : "",
                    color:   s.color   !== undefined ? s.color : root.accent,
                    burning: s.burning === true
                });
            }
            return out;
        }

        // Only what answered gets a ring, so the dial is as wide as the
        readonly property var live: {
            var out = [];
            for (var i = 0; i < root.sources.length; i++)
                if (root.sources[i].present) out.push(root.sources[i]);
            return out;
        }

        readonly property bool burning: {
            for (var i = 0; i < root.live.length; i++)
                if (root.live[i].burning) return true;
            return false;
        }

        readonly property int worst: {
            var lowest = 101;
            for (var i = 0; i < root.live.length; i++)
                if (root.live[i].value < lowest) lowest = root.live[i].value;
            return lowest === 101 ? 0 : lowest;
        }

        readonly property bool alert: worst > 0 && worst <= 20

        // Called when the menu opens, so the numbers on screen are the ones
        function refreshAll() {
            LaptopBattery.refresh();
            PowerSources.refresh();
            PowerProfile.refresh();
        }

        Row {
            id: line
            anchors.centerIn: parent
            spacing: 5

            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth:  gauge.implicitWidth
                implicitHeight: gauge.implicitHeight

                Dial {
                    id: gauge
                    anchors.centerIn: parent
                    rings: root.live
                    fire: 5.5
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Glass.fontUi
                font.pixelSize: 12
                font.features: Glass.tnum
                // The rings carry proportion and the profile
                color: root.alert ? Glass.critical : Glass.muted
                text:  root.worst + "%"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked: {
                var opening = PopupState.owner !== root;
                PopupState.toggle(root);
                if (opening) root.refreshAll();
            }
        }

        PopupWindow {
            id: popup
            visible: PopupState.owner === root
            grabFocus: true
            onClosed: if (PopupState.owner === root) PopupState.close()
            color: "transparent"
            implicitWidth: Math.max(240, 96 * root.sources.length + 20)
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
                    spacing: 8

                    Text {
                        height: 30
                        verticalAlignment: Text.AlignVCenter
                        font.family: Glass.fontUi
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.13
                        color: Glass.text
                        text:  "Power"
                    }

                    // Every source, present or not — a headset that is off is
                    Row {
                        id: dials
                        width: parent.width
                        bottomPadding: 4

                        Repeater {
                            model: root.sources

                            delegate: Column {
                                required property var modelData
                                width: dials.width / root.sources.length
                                spacing: 6

                                Item {
                                    width: 56; height: 56
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Dial {
                                        id: cell
                                        anchors.centerIn: parent
                                        outer: 44
                                        thickness: 2.8
                                        rings: [ modelData ]
                                        fire: 9
                                    }

                                    Text {
                                        anchors.centerIn: cell
                                        font.family: Glass.fontUi
                                        font.pixelSize: 12
                                        font.features: Glass.tnum
                                        color: modelData.present ? Glass.text : Glass.faint
                                        text:  modelData.present ? modelData.value + "%" : "—"
                                    }
                                }

                                Text {
                                    width: parent.width - 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: Glass.fontUi
                                    font.pixelSize: 11
                                    color: modelData.present ? Glass.text : Glass.muted
                                    text:  modelData.label
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width - 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: Glass.fontUi
                                    font.pixelSize: 10
                                    color: Glass.faint
                                    text:  modelData.caption
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // The toggle this replaced cycled power-saver ->
                    Rectangle {
                        width:  parent.width
                        height: 32
                        radius: 11
                        color:  Qt.rgba(1, 1, 1, 0.05)

                        Row {
                            id: cells
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: PowerProfile.profiles

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property bool on: PowerProfile.current === modelData.id

                                    width:  (cells.width - 6) / 3
                                    height: cells.height
                                    radius: 8
                                    color: on ? Qt.rgba(PowerProfile.tint.r, PowerProfile.tint.g,
                                                        PowerProfile.tint.b, 0.24)
                                         : hover.containsMouse ? Glass.hover
                                         :                       "transparent"

                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Glass.fontUi
                                        font.pixelSize: 11
                                        color: parent.on ? Glass.text : Glass.muted
                                        text:  modelData.label
                                    }

                                    MouseArea {
                                        id: hover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked:    PowerProfile.set(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
