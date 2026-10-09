import QtQuick
import "../Common"

Item {
    id: root

    property alias spacing: line.spacing

    implicitWidth:  line.implicitWidth
    implicitHeight: line.implicitHeight

    property string glyph:  ""
    property string value:  ""
    property bool   alert:  false
    property bool   filled: false
    property color  tint:   Glass.muted

    Row {
        id: line
        anchors.centerIn: parent
        // Tight: an icon and its own number are one thing
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Glass.fontIcon
            font.pixelSize: 15
            font.variableAxes: root.filled ? Glass.iconActive : Glass.iconIdle
            color: root.alert ? Glass.critical : root.tint
            text:  root.glyph
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Glass.fontUi
            font.pixelSize: 12
            font.features: Glass.tnum
            color: root.alert ? Glass.critical : Glass.muted
            text:  root.value
        }
    }
}
