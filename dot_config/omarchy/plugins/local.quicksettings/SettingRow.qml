import QtQuick
import qs.Commons

// One line of the quick settings panel: glyph, label, value, and a click.
// Rows that carry state paint their glyph in the accent colour when on, the
// way the bar indicators do, so the panel reads at a glance.
Item {
  id: root

  property QtObject bar: null
  property string icon: ""
  property string label: ""
  property string value: ""
  property bool on: false
  property bool cursor: false
  property bool enabled: true

  signal activated()
  signal secondary()

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent

  width: parent ? parent.width : 0
  implicitHeight: Math.round(Style.spacing.controlHeight * 0.92)
  opacity: enabled ? 1 : 0.45

  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: -Style.space(6)
    anchors.rightMargin: -Style.space(6)
    radius: Style.cornerRadius
    color: mouse.containsMouse || root.cursor
      ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
      : "transparent"
  }

  Text {
    id: glyph
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: root.icon
    color: root.on ? root.accent : root.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    width: Style.space(22)
  }

  Text {
    anchors.left: glyph.right
    anchors.leftMargin: Style.space(10)
    anchors.right: valueText.left
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: root.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    elide: Text.ElideRight
  }

  Text {
    id: valueText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: root.value
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignRight
    width: Math.min(implicitWidth, root.width * 0.45)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(event) {
      if (event.button === Qt.RightButton) root.secondary()
      else root.activated()
    }
  }
}
