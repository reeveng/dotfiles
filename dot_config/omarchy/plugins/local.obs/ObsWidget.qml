import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

// The streaming dot, carried over from the waybar module that died with
// waybar. Three states, all of them colour: dimmed while OBS is closed, plain
// while it is open and idle, lit while a stream is live. Clicking it brings
// OBS up, or starts it. The state comes from the log banners OBS already
// writes, so there is no websocket and no password anywhere in this.
BarWidget {
  id: root
  moduleName: "local.obs"

  // closed | idle | live
  property string state: "closed"

  readonly property bool live: state === "live"
  readonly property bool running: state !== "closed"

  readonly property string tooltip: {
    if (live) return "Live"
    if (running) return "OBS is open, not streaming"
    return "OBS is closed"
  }

  function refresh() {
    if (!probe.running) probe.running = true
  }

  Process {
    id: probe
    command: ["obs-stream-state"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = String(text || "").trim()
        root.state = value === "" ? "closed" : value
      }
    }
  }

  Timer {
    interval: Math.max(1000, root.setting("intervalMs", 3000))
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰑋"
    active: root.live
    dimmed: !root.running
    tooltipText: root.tooltip
    onPressed: function(b) {
      root.bar.run("omarchy-launch-or-focus obs 'uwsm-app -- obs'")
      wake.restart()
    }
  }

  Timer {
    id: wake
    interval: 2000
    onTriggered: root.refresh()
  }
}
