pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var workspaces:     Hyprland.workspaces
    readonly property var monitors:       Hyprland.monitors
    readonly property var focused:        Hyprland.focusedWorkspace
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var focusedClient:  Hyprland.focusedClient

    readonly property string focusedName:
        root.focusedMonitor ? root.focusedMonitor.name : ""

    // The ShellScreen behind the focused HyprlandMonitor
    readonly property var focusedScreen: {
        const name = root.focusedName;
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name) return screens[i];
        return null;
    }

    // "Is it taller than it is wide" — the question that actually matters
    readonly property string focusedOrientation:
        (root.focusedScreen && root.focusedScreen.height > root.focusedScreen.width)
            ? "Vertical" : "Horizontal"

    function dispatch(cmd) { Hyprland.dispatch(cmd); }
}
