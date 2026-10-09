import QtQuick
import "../Common"

Rectangle {
    id: root
    height: Glass.rowHeight - 6
    radius: Glass.rowRadius

    property string glyph:    ""
    // Optional full-strength glyph drawn faintly behind `glyph`
    property string track:    ""
    property string label:    ""
    property string trailing: ""
    property bool   active:   false
    signal activated()

    // An optional second control on the right of the row, for a row that
    property string action: ""
    signal actionTriggered()

    color: mouse.containsMouse || actionMouse.containsMouse ? Glass.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    // Declared before the Row, not after it, so the action button sits on
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
    }

    Row {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 10

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width:  Math.max(rowTrack.implicitWidth, rowGlyph.implicitWidth)
            height: rowGlyph.implicitHeight

            Text {
                id: rowTrack
                anchors.centerIn: parent
                visible: root.track !== ""
                font.family: Glass.fontIcon
                font.pixelSize: 16
                font.variableAxes: Glass.iconIdle
                color: Glass.faint
                text:  root.track
            }

            Text {
                id: rowGlyph
                anchors.centerIn: parent
                font.family: Glass.fontIcon
                font.pixelSize: 16
                font.variableAxes: root.active ? Glass.iconActive : Glass.iconIdle
                color: root.active ? Glass.text : Glass.muted
                text:  root.glyph
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 66 - (root.action !== "" ? 34 : 0)
            font.family: Glass.fontUi
            font.pixelSize: 13
            font.letterSpacing: -0.1
            color: root.active ? Glass.text : Glass.muted
            text:  root.label
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.action !== ""
            width: 24; height: 24
            radius: 8
            color: actionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                font.family: Glass.fontIcon
                font.pixelSize: 15
                font.variableAxes: actionMouse.containsMouse ? Glass.iconActive : Glass.iconIdle
                color: actionMouse.containsMouse ? Glass.text : Glass.muted
                text:  root.action
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.action !== ""
                cursorShape: Qt.PointingHandCursor
                onClicked:   root.actionTriggered()
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailing !== ""
            font.family: Glass.fontIcon
            font.pixelSize: 15
            font.variableAxes: Glass.iconIdle
            color: root.active ? Glass.text : Glass.faint
            text:  root.trailing
        }
    }
}
