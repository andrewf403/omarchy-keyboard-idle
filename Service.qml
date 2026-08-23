import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool restorePending: false

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id)
    : "andrewf.keyboard-idle"
  readonly property var pluginConfig: {
    var plugins = shell && shell.shellConfig && Array.isArray(shell.shellConfig.plugins)
      ? shell.shellConfig.plugins
      : []

    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i] && String(plugins[i].id || "") === pluginId) return plugins[i]
    }

    return ({})
  }
  readonly property int timeoutSeconds: positiveInteger(pluginConfig.timeout, 10)
  readonly property bool monitorEnabled: booleanSetting(pluginConfig.enabled, true)
  readonly property bool respectInhibitors: booleanSetting(pluginConfig.respectInhibitors, false)

  function positiveInteger(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) && parsed >= 1 ? Math.floor(parsed) : fallback
  }

  function booleanSetting(value, fallback) {
    return typeof value === "boolean" ? value : fallback
  }

  function booleanArgument(value) {
    var normalized = String(value || "").toLowerCase()
    if (["true", "on", "yes", "1"].indexOf(normalized) !== -1) return true
    if (["false", "off", "no", "0"].indexOf(normalized) !== -1) return false
    return null
  }

  function saveSetting(key, value) {
    if (!shell || typeof shell.updateEntryInline !== "function") return "shell unavailable"

    var settings = ({})
    for (var existingKey in pluginConfig) {
      if (existingKey !== "id") settings[existingKey] = pluginConfig[existingKey]
    }
    settings[key] = value

    shell.updateEntryInline(pluginId, settings)
    return "ok"
  }

  function statusJson() {
    return JSON.stringify({
      enabled: monitorEnabled,
      timeout: timeoutSeconds,
      respectInhibitors: respectInhibitors,
      idle: idleMonitor.isIdle,
      offProcessRunning: offProcess.running,
      restoreProcessRunning: restoreProcess.running
    })
  }

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
    id: idleMonitor

    timeout: root.timeoutSeconds
    enabled: root.monitorEnabled
    // Keyboard lighting should turn off even while media inhibits normal idle actions.
    respectInhibitors: root.respectInhibitors

    onEnabledChanged: if (!enabled) root.restore()

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

  IpcHandler {
    target: root.pluginId

    function status(): string {
      return root.statusJson()
    }

    function setTimeout(seconds: string): string {
      var parsed = Number(seconds)
      if (!isFinite(parsed) || parsed < 1 || Math.floor(parsed) !== parsed)
        return "timeout must be a positive integer number of seconds"
      return root.saveSetting("timeout", parsed)
    }

    function setEnabled(value: string): string {
      var parsed = root.booleanArgument(value)
      if (parsed === null) return "enabled must be true or false"
      return root.saveSetting("enabled", parsed)
    }

    function setRespectInhibitors(value: string): string {
      var parsed = root.booleanArgument(value)
      if (parsed === null) return "respectInhibitors must be true or false"
      return root.saveSetting("respectInhibitors", parsed)
    }
  }
}
