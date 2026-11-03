import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Mirrors NightLight.qml. The only differences are forced: a third-party
// service gets no proxy on the bar's scoped shell facade, so state comes from
// the file the service writes and the toggle goes through its IPC target.
BarIndicator {
  id: root

  readonly property string activePath: (Quickshell.env("XDG_STATE_HOME") || ((Quickshell.env("HOME") || "") + "/.local/state")) + "/omarchy/screendim/active.json"

  property bool dimEnabled: false

  active: root.dimEnabled

  activeText: "󰃠"
  inactiveText: "󰃠"
  activeTooltipText: "Screen dim off"
  inactiveTooltipText: "Screen dim on"

  function toggle() {
    if (root.bar && typeof root.bar.run === "function")
      root.bar.run("omarchy-shell jarvis.dim toggle")
    else
      console.warn("jarvis.dim: bar command runner unavailable")
  }

  function updateDimState(raw) {
    var parsed = null
    try { parsed = raw ? JSON.parse(String(raw)) : null } catch (error) { parsed = null }
    root.dimEnabled = !!(parsed && parsed.enabled === true)
  }

  FileView {
    path: root.activePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.updateDimState(text())
    onLoadFailed: root.dimEnabled = false
  }

  onPressed: function() { root.toggle() }
}