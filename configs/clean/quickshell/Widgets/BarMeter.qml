import QtQuick
import "../Common"

Item {
    id: root

    property string glyph:     ""
    // Material Symbols unless something says otherwise
    property string glyphFont: Glass.fontIcon
    property real   glyphSize: 15
    property int    value:     0
    property int    alertAt: 101
    property color  tint:    Glass.muted

    readonly property bool alert: value >= alertAt

    implicitWidth:  line.implicitWidth
    implicitHeight: line.implicitHeight

    Row {
        id: line
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.glyphFont
            font.pixelSize: root.glyphSize
            font.variableAxes: Glass.iconIdle
            color: root.alert ? Glass.critical : Glass.muted
            text:  root.glyph
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Repeater {
                model: 5
                delegate: Rectangle {
                    required property int index

                    readonly property bool lit: root.value >= index * 20 + 10

                    width: 3; height: 13; radius: 1.5
                    color: !lit       ? Qt.rgba(1, 1, 1, 0.11)
                         : root.alert ? Glass.critical
                         :              root.tint
                    Behavior on color { ColorAnimation { duration: 220 } }
                }
            }
        }
    }
}
