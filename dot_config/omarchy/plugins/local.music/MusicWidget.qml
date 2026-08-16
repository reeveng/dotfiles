import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons

// A music note in the bar. Clicking it toggles the same scratchpad SUPER + M
// does, so the whole of kew is one click away instead of a strip of transport
// buttons nobody aims at. Running or not is a colour change and nothing else:
// a widget that moves in the corner of the eye is a widget you fight.
BarWidget {
  id: root
  moduleName: "local.music"

  readonly property string playerCommand: setting("player", "kew")

  readonly property var player: Mpris.players && Mpris.players.values.length > 0
    ? Mpris.players.values[0]
    : null

  // kew publishes no MPRIS, so the player being alive is the only signal
  // there is for it. Anything that does publish gets read properly.
  property bool playerRunning: false
  readonly property bool live: player !== null ? player.isPlaying : playerRunning

  readonly property string nowPlaying: {
    if (!player) return playerRunning ? playerCommand + " is playing" : "Music"
    var title = String(player.trackTitle || "").trim()
    var artist = String(player.trackArtist || "").trim()
    if (title === "") return "Music"
    return artist === "" ? title : title + " · " + artist
  }

  function refresh() {
    if (!runningProbe.running) runningProbe.running = true
  }

  Process {
    id: runningProbe
    command: ["pgrep", "-x", root.playerCommand]
    onExited: function(code) { root.playerRunning = code === 0 }
  }

  // Nothing here is worth a tight clock: the answer changes when the user
  // starts or stops a player, and a few seconds late costs nothing.
  Timer {
    interval: 10000
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
    // One glyph, always. Playing or not is the colour's job; swapping the
    // shape as well would make the bar flicker between two silhouettes.
    text: "󰎈"
    active: root.live
    tooltipText: root.nowPlaying
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.bar.run("omarchy-shell media playPause")
      else root.bar.run(root.setting("command", "~/.config/hypr/scripts/scratchpad music kew"))
      probeSoon.restart()
    }
    onWheelMoved: function(delta) {
      root.bar.run(delta > 0 ? "omarchy-shell media next" : "omarchy-shell media previous")
    }
  }

  Timer {
    id: probeSoon
    interval: 1200
    onTriggered: root.refresh()
  }
}
