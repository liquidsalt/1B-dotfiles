pragma Singleton
import Quickshell
import QtQuick

// The whole palette

Singleton {
    id: root

    // ---- surfaces ----------------------------------------------------
    readonly property color ink: "#05070B"

    readonly property color panel:       Qt.rgba(0.071, 0.082, 0.110, 0.44)
    readonly property color panelStrong: Qt.rgba(0.071, 0.082, 0.110, 0.88)

    readonly property color stroke: Qt.rgba(1, 1, 1, 0.11)
    readonly property color hover:  Qt.rgba(1, 1, 1, 0.10)

    // ---- text --------------------------------------------------------
    readonly property color text:     "#EDF0F5"
    readonly property color muted:    Qt.rgba(0.929, 0.941, 0.961, 0.56)
    readonly property color faint:    Qt.rgba(0.929, 0.941, 0.961, 0.28)
    readonly property color critical: "#FF8A80"

    // Fallback accent, used when a monitor has no wallpaper-derived hue
    readonly property color accent:   "#E2C9A2"

    // ---- type --------------------------------------------------------
    readonly property string fontUi:   Config.fontUi
    readonly property string fontMono: Config.fontMono
    readonly property string fontIcon: Config.fontIcon

    // The nerd-patched face, for the handful of glyphs Material Symbols
    readonly property string fontGlyph: Config.fontGlyph

    readonly property var tnum: ({ "tnum": 1 })

    // Material Symbols variable axes
    function icon(fill, weight) {
        return { "FILL": fill, "wght": weight, "GRAD": 0, "opsz": 24 };
    }
    readonly property var iconIdle:   root.icon(0.0, 300)
    readonly property var iconActive: root.icon(1.0, 350)

    // ---- metrics -----------------------------------------------------
    readonly property int barZone:    50   // exclusive zone, full width
    readonly property int barHeight:  34   // the visible panel
    readonly property int barMargin:  12   // left/right inset
    readonly property int barTop:     10   // gap above the panel
    readonly property int barRadius:  12

    readonly property int popupRadius:    14
    readonly property int launcherWidth:  520
    readonly property int launcherRadius: 18
    readonly property int rowHeight:      40
    readonly property int rowRadius:      11
}
