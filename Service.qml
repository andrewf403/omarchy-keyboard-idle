import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  property var shell: null
  property bool restorePending: false

  function turnOff() {
    restorePending = false
    if (!offProcess.running) offProcess.running = true
  }

  function restore() {
    if (offProcess.running) {
      restorePending = true
    } else if (!restoreProcess.running) {
      restoreProcess.running = true
    }
  }

  IdleMonitor {
    timeout: 10
    enabled: true
    // Keyboard lighting should turn off even while media inhibits normal idle actions.
    respectInhibitors: false

    onIsIdleChanged: {
      if (isIdle) root.turnOff()
      else root.restore()
    }
  }

  Process {
    id: offProcess
    command: ["omarchy", "brightness", "keyboard", "off"]

    onExited: {
      if (root.restorePending) {
        root.restorePending = false
        root.restore()
      }
    }
  }

  Process {
    id: restoreProcess
    command: ["omarchy", "brightness", "keyboard", "restore"]
  }
}
