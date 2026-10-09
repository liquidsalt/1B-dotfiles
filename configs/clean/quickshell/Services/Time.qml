pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
}
