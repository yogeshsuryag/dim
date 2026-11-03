import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string stateDir: stateHome + "/omarchy/screendim"
  readonly property string activePath: stateDir + "/active.json"
  readonly property string strengthPath: stateDir + "/strength.json"

  // Dimming always starts off after a shell restart; only the strength setting
  // is persisted.
  property bool dimEnabled: false
  property int strength: 35
  property bool stateDirReady: false
  property bool strengthLoaded: false

  function clampStrength(value) {
    var number = Number(value)
    if (!isFinite(number)) return 35
    return Math.max(0, Math.min(100, Math.round(number)))
  }

  function setEnabled(value) {
    root.dimEnabled = !!value
    if (root.stateDirReady) writeActiveState()
  }

  function toggle() {
    setEnabled(!root.dimEnabled)
  }

  function setStrength(value) {
    root.strength = clampStrength(value)
    if (root.stateDirReady) writeStrength()
  }

  function writeActiveState() {
    activeFile.setText(JSON.stringify({ version: 1, enabled: root.dimEnabled }) + "\n")
  }

  function writeStrength() {
    strengthFile.setText(JSON.stringify({ version: 1, strength: root.strength }) + "\n")
  }

  function loadStrength(raw) {
    var parsed = null
    try {
      parsed = raw ? JSON.parse(String(raw)) : null
    } catch (error) {
      parsed = null
    }

    if (parsed && parsed.strength !== undefined)
      root.strength = clampStrength(parsed.strength)
    else {
      root.strength = 35
      if (root.stateDirReady) writeStrength()
    }
    root.strengthLoaded = true
  }

  Process {
    id: prepareStateDir
    command: ["mkdir", "-p", root.stateDir]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        console.warn("oma.dim: could not create state directory")
        return
      }
      root.stateDirReady = true
      strengthFile.reload()
      root.writeActiveState()
    }
  }

  FileView {
    id: activeFile
    path: root.activePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
  }

  FileView {
    id: strengthFile
    path: root.strengthPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: if (root.stateDirReady) root.loadStrength(text())
    onLoadFailed: if (root.stateDirReady) root.loadStrength("")
  }

  IpcHandler {
    target: "oma.dim"

    function status(): string {
      return JSON.stringify({ enabled: root.dimEnabled, strength: root.strength })
    }

    function enable(): string {
      root.setEnabled(true)
      return "enabled"
    }

    function disable(): string {
      root.setEnabled(false)
      return "disabled"
    }

    function toggle(): string {
      var next = !root.dimEnabled
      root.setEnabled(next)
      return next ? "enabled" : "disabled"
    }

    function setStrength(value: string): string {
      root.setStrength(value)
      return String(root.strength)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.dimEnabled && root.strength > 0
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "oma-dim"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.strength / 100
      }
    }
  }

  Component.onCompleted: prepareStateDir.running = true
}
