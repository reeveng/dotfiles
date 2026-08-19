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

  // The player is picked by name. A browser tab publishes MPRIS as well, and
  // the first entry in the list is whoever registered first, so reading index
  // zero reports the browser's silence while kew plays.
  readonly property var player: {
    var players = Mpris.players ? Mpris.players.values : []
    var wanted = root.playerCommand.toLowerCase()
    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      var names = [p.dbusName, p.desktopEntry, p.identity].join(" ").toLowerCase()
      if (names.indexOf(wanted) !== -1) return p
    }
    return null
  }

  // MPRIS pushes: kew signals PropertiesChanged the moment it starts, pauses
  // or stops, so the colour lands with the keypress. The probe below is for a
  // player that publishes nothing, and only runs while there is no such signal.
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

  Timer {
    interval: 10000
    running: root.player === null
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
    // The bar's own active colour is the theme's red, which is right for OBS
    // going live and wrong for music playing: red in a bar means something
    // wants you. Playing is not an alarm, so it lights in the theme's accent
    // and stays whatever green, blue or grey the current theme is in.
    activeColor: Color.accent
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
