import Quickshell
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Item {
    id: root

    property color accent: Glass.accent

    implicitWidth:  line.implicitWidth
    implicitHeight: line.implicitHeight

    function gib(v) { return v.toFixed(1); }

    Row {
        id: line
        anchors.centerIn: parent
        // Tighter than the 13 between unrelated widgets: these three are
        spacing: 8

        BarMeter {
            anchors.verticalCenter: parent.verticalCenter
            glyph:     String.fromCodePoint(0xF08AE)
            glyphFont: Glass.fontGlyph
            glyphSize: 14
            value:     SystemStats.gpuPercent
            alertAt:   95
            tint:      root.accent
        }

        BarMeter {
            anchors.verticalCenter: parent.verticalCenter
            glyph:   "\ue322"
            value:   SystemStats.cpuPercent
            alertAt: 90
            tint:    root.accent
        }

        BarMeter {
            anchors.verticalCenter: parent.verticalCenter
            glyph:   "\uf7a3"
            value:   SystemStats.memPercent
            alertAt: 85
            tint:    root.accent
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    PopupState.toggle(root)
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

        GlassSurface {
            id: shell
            anchors.fill: parent
            strong: true
            implicitHeight: col.implicitHeight + 20

            Column {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4

                Text {
                    height: 30
                    verticalAlignment: Text.AlignVCenter
                    font.family: Glass.fontUi
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.13
                    color: Glass.text
                    text:  "Hardware"
                }

                PopupGauge {
                    width: parent.width
                    glyph:     String.fromCodePoint(0xF08AE)
                    glyphFont: Glass.fontGlyph
                    glyphSize: 15
                    title:   "Graphics"
                    value:   SystemStats.gpuPercent
                    alertAt: 95
                    tint:    root.accent
                    detail: [
                        SystemStats.gpuName,
                        root.gib(SystemStats.gpuMemUsed / 1024) + " / "
                          + root.gib(SystemStats.gpuMemTotal / 1024) + " GiB   ·   "
                          + SystemStats.gpuTemp + " °C   ·   "
                          + SystemStats.gpuClock + " MHz"
                    ]
                }

                PopupGauge {
                    width: parent.width
                    glyph:   "\ue322"
                    title:   "Processor"
                    value:   SystemStats.cpuPercent
                    alertAt: 90
                    tint:    root.accent
                    detail: [
                        SystemStats.cpuModel,
                        "load  " + SystemStats.loadAvg
                          + (SystemStats.cpuTemp > 0
                             ? "   ·   " + SystemStats.cpuTemp + " °C" : "")
                    ]
                }

                PopupGauge {
                    width: parent.width
                    glyph:   "\uf7a3"
                    title:   "Memory"
                    value:   SystemStats.memPercent
                    alertAt: 85
                    tint:    root.accent
                    detail: [
                        root.gib(SystemStats.memUsedGiB) + " / "
                          + root.gib(SystemStats.memTotalGiB) + " GiB in use",
                        SystemStats.swapTotalGiB > 0
                          ? "swap  " + root.gib(SystemStats.swapUsedGiB) + " / "
                            + root.gib(SystemStats.swapTotalGiB) + " GiB"
                          : "no swap"
                    ]
                }
            }
        }
    }
}
