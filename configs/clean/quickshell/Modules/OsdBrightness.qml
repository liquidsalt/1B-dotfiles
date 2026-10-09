import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

OsdPill {
    id: root
    glyph:   ""
    percent: BrightnessState.percent

    // First read on startup would otherwise pop the OSD unprompted
    property bool primed: false

    Connections {
        target: BrightnessState
        function onBrightnessChanged() {
            if (!root.primed) { root.primed = true; return; }
            root.show();
        }
    }
}
