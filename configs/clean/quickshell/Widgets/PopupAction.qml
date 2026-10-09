import QtQuick
import "../Common"

Rectangle {
    id: root
    height: 32
    radius: Glass.rowRadius

    property string glyph:   ""
    property string label:   ""
    property bool   enabled: true
    signal activated()

    color: mouse.containsMouse && root.enabled ? Glass.hover : Qt.rgba(1, 1, 1, 0.04)
    Behavior on color { ColorAnimation { duration: 120 } }
    opacity: root.enabled ? 1.0 : 0.45

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Glass.fontIcon
            font.pixelSize: 15
            font.variableAxes: Glass.iconIdle
            color: Glass.muted
            text:  root.glyph
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Glass.fontUi
            font.pixelSize: 12
            color: Glass.muted
            text:  root.label
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled:      root.enabled
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
    }
}
