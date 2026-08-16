import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.Ui
import qs.Commons

// One bar icon, one popup, holding everything that used to want an icon of
// its own. Volume and brightness are live sliders; the rest are one-line
// toggles. Wi-Fi hands off to nmtui for the parts a single row cannot do.
Panel {
  id: root
  moduleName: "local.quicksettings"
  ipcTarget: "local.quicksettings"

  // --- shell services ------------------------------------------------------

  readonly property var notifications: bar && bar.shell ? bar.shell.firstPartyServiceFor("omarchy.notifications") : null
  readonly property var idleService: bar && bar.shell ? bar.shell.firstPartyServiceFor("omarchy.idle") : null
  readonly property var nightlightService: bar && bar.shell ? bar.shell.firstPartyServiceFor("omarchy.nightlight") : null

  readonly property bool dnd: notifications ? notifications.doNotDisturb : false
  readonly property bool stayAwake: idleService ? idleService.stayAwake : false
  readonly property bool nightlight: nightlightService ? nightlightService.enabled : false

  // --- audio ---------------------------------------------------------------

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var sinkAudio: sink && sink.audio ? sink.audio : null
  readonly property real volume: sinkAudio ? sinkAudio.volume : 0
  readonly property bool muted: sinkAudio ? sinkAudio.muted : false

  PwObjectTracker { objects: root.sink ? [root.sink] : [] }

  function setVolume(value) {
    if (!sinkAudio) return
    sinkAudio.muted = false
    sinkAudio.volume = Math.max(0, Math.min(1, value))
  }

  function toggleMute() {
    if (sinkAudio) sinkAudio.muted = !sinkAudio.muted
  }

  // --- polled state --------------------------------------------------------

  property int brightness: 0
  property bool brightnessAvailable: false
  property string networkKind: "disconnected"
  property string networkName: ""
  property string networkSignal: ""
  property bool bluetoothOn: false
  property string powerProfile: ""
  property var powerProfiles: []
  property string updateSummary: ""
  property bool tailscaleUp: false
  property int tailscalePeers: 0
  property string tailscaleAddress: ""
  property var claudeLimits: []
  property string claudeTier: ""

  readonly property bool updateAvailable: updateSummary !== ""
  readonly property bool claudeReady: claudeLimits.length > 0

  function refresh() {
    if (!brightnessProc.running) brightnessProc.running = true
    if (!networkProc.running) networkProc.running = true
    if (!bluetoothProc.running) bluetoothProc.running = true
    if (!profileProc.running) profileProc.running = true
    if (!profileListProc.running) profileListProc.running = true
    if (!tailscaleProc.running) tailscaleProc.running = true
  }

  function run(command) {
    if (bar) bar.run(command)
  }

  function setBrightness(percent) {
    var value = Math.max(1, Math.min(100, Math.round(percent)))
    root.brightness = value
    brightnessDebounce.restart()
  }

  function commitBrightness() {
    if (setBrightnessProc.running) return
    setBrightnessProc.command = ["omarchy-brightness-display", "--no-osd", root.brightness + "%"]
    setBrightnessProc.running = true
  }

  function cycleProfile(step) {
    if (powerProfiles.length === 0) return
    var index = powerProfiles.indexOf(powerProfile)
    if (index < 0) index = 0
    var next = powerProfiles[(index + powerProfiles.length + step) % powerProfiles.length]
    root.powerProfile = next
    run("omarchy-powerprofiles-set " + (onBattery ? "battery" : "ac") + " " + next)
  }

  readonly property bool onBattery: UPower.onBattery

  // --- keyboard cursor -----------------------------------------------------

  readonly property var entries: {
    var list = ["volume"]
    if (brightnessAvailable) list.push("brightness")
    list.push("network", "bluetooth", "nightlight", "dnd", "stayawake")
    if (powerProfiles.length > 0) list.push("profile")
    list.push("tailscale")
    if (updateAvailable) list.push("update")
    return list
  }

  property int cursorIndex: 0
  property bool cursorActive: false

  function entryAt(index) {
    return index >= 0 && index < entries.length ? entries[index] : ""
  }

  function moveCursor(delta) {
    if (entries.length === 0) return
    cursorIndex = Math.max(0, Math.min(entries.length - 1, cursorIndex + delta))
  }

  function adjustCursor(delta) {
    var entry = entryAt(cursorIndex)
    if (entry === "volume") setVolume(volume + delta * 0.05)
    else if (entry === "brightness") setBrightness(brightness + delta * 5)
    else if (entry === "profile") cycleProfile(delta)
  }

  function activateCursor() {
    var entry = entryAt(cursorIndex)
    if (entry === "volume") toggleMute()
    else if (entry === "network") openNetwork()
    else if (entry === "bluetooth") toggleBluetooth()
    else if (entry === "nightlight") toggleNightlight()
    else if (entry === "dnd") toggleDnd()
    else if (entry === "stayawake") toggleStayAwake()
    else if (entry === "profile") cycleProfile(1)
    else if (entry === "tailscale") toggleTailscale()
    else if (entry === "update") { run("omarchy-menu toggle update"); close() }
  }

  // --- actions -------------------------------------------------------------

  // Wi-Fi keeps its own bar icon, so hand the click to that panel rather than
  // growing a second network picker in here.
  function openNetwork() {
    close()
    run("omarchy-shell omarchy.network toggle")
  }

  function toggleBluetooth() {
    root.bluetoothOn = !root.bluetoothOn
    run("omarchy-bluetooth-power toggle")
    bluetoothRecheck.restart()
  }

  function toggleNightlight() {
    if (nightlightService) nightlightService.toggle()
  }

  function toggleDnd() {
    if (notifications) notifications.setDoNotDisturb(!notifications.doNotDisturb)
  }

  function toggleStayAwake() {
    if (idleService) idleService.setIdleEnabled(root.stayAwake)
  }

  function toggleTailscale() {
    var wanted = !root.tailscaleUp
    root.tailscaleUp = wanted
    run("tailscale " + (wanted ? "up" : "down"))
    tailscaleRecheck.restart()
  }

  function copyTailscaleAddress() {
    if (root.tailscaleAddress === "") return
    run("printf %s " + Util.shellQuote(root.tailscaleAddress) + " | wl-copy")
  }

  // --- glyphs --------------------------------------------------------------

  function volumeGlyph() {
    if (muted || volume <= 0.001) return "󰝟"
    if (volume < 0.34) return "󰕿"
    if (volume < 0.67) return "󰖀"
    return "󰕾"
  }

  function networkGlyph() {
    if (networkKind === "ethernet") return "󰈁"
    if (networkKind !== "wifi") return "󰤮"
    var strength = parseInt(networkSignal, 10)
    if (isNaN(strength)) return "󰤨"
    if (strength < 30) return "󰤟"
    if (strength < 55) return "󰤢"
    if (strength < 80) return "󰤥"
    return "󰤨"
  }

  function networkLabel() {
    if (networkKind === "ethernet") return "Wired"
    if (networkKind === "wifi") return "Wi-Fi"
    return "Offline"
  }

  function networkValue() {
    if (networkKind === "disconnected") return "not connected"
    if (networkKind === "ethernet") return networkName
    var strength = parseInt(networkSignal, 10)
    return isNaN(strength) ? networkName : networkName + "  " + strength + "%"
  }

  // --- processes -----------------------------------------------------------

  Process {
    id: brightnessProc
    command: ["omarchy-monitor-state"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var first = String(text || "").split("\n")[0].trim()
        root.brightnessAvailable = first !== "" && first !== "unavailable"
        if (root.brightnessAvailable) root.brightness = Math.max(1, Math.min(100, parseInt(first, 10)))
      }
    }
  }

  Process {
    id: setBrightnessProc
    stdout: StdioCollector { waitForEnd: true }
  }

  Timer {
    id: brightnessDebounce
    interval: 160
    onTriggered: root.commitBrightness()
  }

  Process {
    id: networkProc
    command: ["omarchy-network-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var fields = String(text || "").split("\n")[0].split("\t")
        root.networkKind = String(fields[0] || "disconnected").trim()
        root.networkName = String(fields[1] || "").trim()
        root.networkSignal = String(fields[2] || "").trim()
      }
    }
  }

  Process {
    id: bluetoothProc
    command: ["omarchy-bluetooth-power", "is-on"]
    onExited: function(code) { root.bluetoothOn = code === 0 }
  }

  Timer {
    id: bluetoothRecheck
    interval: 1200
    onTriggered: if (!bluetoothProc.running) bluetoothProc.running = true
  }

  Process {
    id: profileProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.powerProfile = String(text || "").trim()
    }
  }

  Process {
    id: profileListProc
    command: ["omarchy-powerprofiles-list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var found = []
        for (var i = 0; i < lines.length; i++) {
          var name = lines[i].trim()
          if (name !== "") found.push(name)
        }
        root.powerProfiles = found
      }
    }
  }

  Process {
    id: tailscaleProc
    command: ["tailscale", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = null
        try { data = JSON.parse(String(text || "")) } catch (error) { data = null }
        if (!data) {
          root.tailscaleUp = false
          root.tailscalePeers = 0
          root.tailscaleAddress = ""
          return
        }

        root.tailscaleUp = data.BackendState === "Running"

        var peers = data.Peer || {}
        var online = 0
        for (var key in peers) if (peers[key] && peers[key].Online) online++
        root.tailscalePeers = online

        var addresses = data.Self && data.Self.TailscaleIPs ? data.Self.TailscaleIPs : []
        root.tailscaleAddress = addresses.length > 0 ? addresses[0] : ""
      }
    }
  }

  Timer {
    id: tailscaleRecheck
    interval: 2500
    onTriggered: if (!tailscaleProc.running) tailscaleProc.running = true
  }

  // Reading the whole Claude usage history is not cheap, so it runs on open
  // and on its own slow clock rather than with the rest.
  Process {
    id: claudeProc
    command: ["omarchy-agent-usage-claude"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = null
        try { data = JSON.parse(String(text || "")) } catch (error) { data = null }
        if (!data || !data.ready) {
          root.claudeLimits = []
          root.claudeTier = ""
          return
        }

        root.claudeTier = String(data.tierLabel || "")
        root.claudeLimits = Array.isArray(data.limits) ? data.limits : []
      }
    }
  }

  Process {
    id: updateProc
    command: ["omarchy-update-available"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root._updateText = String(text || "").split("\n")[0].trim()
    }
    onExited: function(code) { root.updateSummary = code === 0 ? root._updateText : "" }
  }

  property string _updateText: ""

  // --- lifecycle -----------------------------------------------------------

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: {
    refresh()
    if (!updateProc.running) updateProc.running = true
  }

  onOpenedChanged: {
    if (!opened) return
    refresh()
    if (!claudeProc.running) claudeProc.running = true
    cursorIndex = 0
    cursorActive = false
  }

  // Only while open: nothing here is worth a timer against an idle desktop.
  Timer {
    interval: 5000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  // Updates change on the scale of days, so this one keeps its own slow clock.
  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: if (!updateProc.running) updateProc.running = true
  }

  // --- bar button ----------------------------------------------------------

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.updateAvailable ? "󰚰" : "󰒓"
    active: root.updateAvailable
    tooltipText: "Quick settings"
    onPressed: function(b) { root.toggle() }
    onWheelMoved: function(delta) {
      root.setVolume(root.volume + (delta > 0 ? 0.05 : -0.05))
    }
  }

  // --- panel ---------------------------------------------------------------

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(330))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(900))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) root.adjustCursor(dx)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        // ---------- hero ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroGlyph.implicitHeight, heroText.implicitHeight)

          Text {
            id: heroGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰒓"
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.display
          }

          Column {
            id: heroText
            anchors.left: heroGlyph.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Quick settings"
              color: root.bar ? root.bar.foreground : Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: root.powerProfile === "" ? root.networkValue() : root.powerProfile + " · " + root.networkValue()
              color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelSeparator { foreground: root.bar ? root.bar.foreground : Color.foreground }

        // ---------- sliders ----------
        Item {
          width: parent.width
          implicitHeight: volumeSlider.implicitHeight

          Text {
            id: volumeGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.volumeGlyph()
            color: root.entryAt(root.cursorIndex) === "volume" && root.cursorActive
              ? Color.accent
              : (root.bar ? root.bar.foreground : Color.foreground)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            width: Style.space(22)

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleMute()
            }
          }

          PanelSlider {
            id: volumeSlider
            anchors.left: volumeGlyph.right
            anchors.leftMargin: Style.space(10)
            anchors.right: volumeValue.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            bar: root.bar
            value: root.muted ? 0 : root.volume
            onMoved: function(value) { root.setVolume(value) }
            onRightClicked: root.toggleMute()
          }

          Text {
            id: volumeValue
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "muted" : Math.round(root.volume * 100) + "%"
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            width: Style.space(46)
            horizontalAlignment: Text.AlignRight
          }
        }

        Item {
          width: parent.width
          visible: root.brightnessAvailable
          implicitHeight: visible ? brightnessSlider.implicitHeight : 0

          Text {
            id: brightnessGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃠"
            color: root.entryAt(root.cursorIndex) === "brightness" && root.cursorActive
              ? Color.accent
              : (root.bar ? root.bar.foreground : Color.foreground)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            width: Style.space(22)
          }

          PanelSlider {
            id: brightnessSlider
            anchors.left: brightnessGlyph.right
            anchors.leftMargin: Style.space(10)
            anchors.right: brightnessValue.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            bar: root.bar
            minimum: 1
            maximum: 100
            integer: true
            step: 5
            value: root.brightness
            onMoved: function(value) { root.setBrightness(value) }
          }

          Text {
            id: brightnessValue
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.brightness + "%"
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            width: Style.space(46)
            horizontalAlignment: Text.AlignRight
          }
        }

        PanelSeparator { foreground: root.bar ? root.bar.foreground : Color.foreground }

        // ---------- rows ----------
        SettingRow {
          bar: root.bar
          icon: root.networkGlyph()
          label: root.networkLabel()
          value: root.networkValue()
          on: root.networkKind !== "disconnected"
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "network"
          onActivated: root.openNetwork()
        }

        SettingRow {
          bar: root.bar
          icon: root.bluetoothOn ? "󰂯" : "󰂲"
          label: "Bluetooth"
          value: root.bluetoothOn ? "on" : "off"
          on: root.bluetoothOn
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "bluetooth"
          onActivated: root.toggleBluetooth()
        }

        SettingRow {
          bar: root.bar
          icon: "󰛨"
          label: "Night light"
          value: root.nightlight ? "warm" : "on a clock"
          on: root.nightlight
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "nightlight"
          onActivated: root.toggleNightlight()
        }

        SettingRow {
          bar: root.bar
          icon: "󰂛"
          label: "Do not disturb"
          value: root.dnd ? "silenced" : "off"
          on: root.dnd
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "dnd"
          onActivated: root.toggleDnd()
        }

        SettingRow {
          bar: root.bar
          icon: "󰅶"
          label: "Stay awake"
          value: root.stayAwake ? "no idle lock" : "off"
          on: root.stayAwake
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "stayawake"
          onActivated: root.toggleStayAwake()
        }

        SettingRow {
          bar: root.bar
          visible: root.powerProfiles.length > 0
          icon: root.powerProfile === "power-saver" ? "󰾆" : (root.powerProfile === "performance" ? "󰓅" : "󰾅")
          label: "Power profile"
          value: root.powerProfile
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "profile"
          onActivated: root.cycleProfile(1)
          onSecondary: root.cycleProfile(-1)
        }

        SettingRow {
          bar: root.bar
          icon: root.tailscaleUp ? "󰖂" : "󰦞"
          label: "Tailscale"
          value: root.tailscaleUp
            ? (root.tailscalePeers === 1 ? "1 machine up" : root.tailscalePeers + " machines up")
            : "off"
          on: root.tailscaleUp
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "tailscale"
          onActivated: root.toggleTailscale()
          onSecondary: root.copyTailscaleAddress()
        }

        PanelSeparator {
          visible: root.claudeReady
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        PanelSectionHeader {
          visible: root.claudeReady
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          text: root.claudeTier === "" ? "CLAUDE" : "CLAUDE · " + root.claudeTier.toUpperCase()
        }

        Repeater {
          model: root.claudeReady ? root.claudeLimits : []

          Meter {
            required property var modelData

            bar: root.bar
            label: String(modelData.title || modelData.label || "")
            fraction: Number(modelData.percent || 0)
          }
        }

        PanelSeparator {
          visible: root.updateAvailable
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        SettingRow {
          bar: root.bar
          visible: root.updateAvailable
          icon: "󰚰"
          label: "Update available"
          value: root.updateSummary
          on: true
          cursor: root.cursorActive && root.entryAt(root.cursorIndex) === "update"
          onActivated: { root.run("omarchy-menu toggle update"); root.close() }
        }
      }
    }
  }
}
