import QtQuick
import "../Common"

Item {
    id: root
    height: visible ? 30 : 0

    property string label: ""

    Text {
        anchors.centerIn: parent
        font.family: Glass.fontUi
        font.pixelSize: 12
        color: Glass.faint
        text:  root.label
    }
}
