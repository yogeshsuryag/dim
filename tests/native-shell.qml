import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "file:/usr/share/omarchy/shell/services" as Omarchy

// Real Omarchy registry and IPC, without desktop windows or the user's config.
ShellRoot {
  id: shell
  property var config: ({})
  FileView {
    id: configFile
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    atomicWrites: true
    onLoaded: shell.config = JSON.parse(text())
  }
  Omarchy.PluginRegistry {
    id: registry
    firstPartyDir: "/usr/share/omarchy/shell/plugins"
    shellConfigProvider: () => shell.config
    shellConfigMutator: function(mutate) {
      var next = Util.cloneJson(shell.config)
      mutate(next)
      shell.config = next
      configFile.setText(JSON.stringify(next))
    }
  }
  // Reproduce the documented asynchronous discovery boundary deterministically.
  Timer { id: rescan; interval: 300; onTriggered: registry.rescan() }
  IpcHandler {
    target: "shell"
    function ping(): string { return shell.config.version === 1 ? "pong" : "starting" }
    function rescanPlugins(): void { rescan.restart() }
    function enablePlugin(id: string, placement: string): string {
      return registry.setEnabled(id, true, JSON.parse(placement || "{}")) ? "ok" : "unknown"
    }
    function setPluginEnabled(id: string, enabled: string): string {
      return registry.setEnabled(id, enabled === "true") ? "ok" : "unknown"
    }
    function listPlugins(): string {
      var result = []
      for (var id in registry.installedPlugins) {
        var manifest = registry.installedPlugins[id]
        result.push({id: id, kinds: manifest.kinds,
          enabled: manifest.kinds.indexOf("bar-widget") >= 0 ? registry.inBar(id) : registry.isEnabled(id)})
      }
      return JSON.stringify(result)
    }
  }
}
