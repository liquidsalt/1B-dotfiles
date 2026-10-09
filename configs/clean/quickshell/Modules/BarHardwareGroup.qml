import QtQuick
import Quickshell.Io
import "../Services"
import "../Common"
import "../Widgets"

Row {
    id: root
    spacing: 13

    property color accent: Glass.accent

    // The mixer, spawned rather than handed to Qt.openUrlExternally
    Process { id: mixerProc; running: false }

    BarStat {
        anchors.verticalCenter: parent.verticalCenter
        glyph:  Audio.muted ? "\ue04f" : "\ue050"
        value:  Audio.volume + "%"
        filled: !Audio.muted
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) Audio.toggleMute();
                else if (Config.hasAudioMixer) {
                    mixerProc.command = Config.argv("command.audio-mixer");
                    mixerProc.running = true;
                }
            }
            onWheel: (wheel) => { Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 5 : -5)); }
        }
    }

    BarLoads {
        anchors.verticalCenter: parent.verticalCenter
        accent: root.accent
    }

    BarPower {
        anchors.verticalCenter: parent.verticalCenter
        accent: root.accent
    }
}
