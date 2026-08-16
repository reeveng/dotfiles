import QtQuick
import qs.Commons

// A rate limit as one thin bar: label on the left, percentage on the right,
// the fill underneath. Enough of the agents panel to answer "how much is
// left" without the panel.
Item {
  id: root

  property QtObject bar: null
  property string label: ""
  property real fraction: 0

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property real clamped: Math.max(0, Math.min(1, fraction))

  // Green is not in the palette to lean on, so the warning is the accent and
  // the alarm is the urgent colour the bar already uses for everything else.
  readonly property color fillColor: clamped >= 0.9
    ? (bar ? bar.urgent : Color.urgent)
    : (clamped >= 0.6 ? Color.accent : foreground)

  width: parent ? parent.width : 0
  implicitHeight: caption.implicitHeight + Style.space(6) + track.height

  Text {
    id: caption
    anchors.left: parent.left
    anchors.top: parent.top
    text: root.label
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    anchors.right: parent.right
    anchors.baseline: caption.baseline
    text: Math.round(root.clamped * 100) + "%"
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
  }

  Rectangle {
    id: track
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Math.max(3, Math.round(Style.spacing.controlHeight * 0.09))
    radius: height / 2
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * root.clamped
      radius: parent.radius
      color: root.fillColor
    }
  }
}
