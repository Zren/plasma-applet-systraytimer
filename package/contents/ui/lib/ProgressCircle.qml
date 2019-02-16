// Version 2

import QtQuick 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
	id: progressCircle
	width: 400
	height: 400

	property real currentPercent: 100

	readonly property real thickness: Math.max(grooveThickness, highlightThickness)
	property real grooveThickness: radius * 0.25
	property real highlightThickness: radius * 0.25

	property color grooveColor: Qt.rgba(.5, .5, .5)
	property color highlightColor: {
		if (0 <= currentPercent && currentPercent <= 14) {
			return Qt.rgba(251/255, 0/255, 0/255) // #fb0000
		} else if (15 <= currentPercent && currentPercent <= 29) {
			return Qt.rgba(247/255, 160/255, 0/255) // #f7a000
		} else if (30 <= currentPercent && currentPercent <= 49) {
			return Qt.rgba(245/255, 245/255, 0/255) // #f5f500
		} else if (50 <= currentPercent && currentPercent <= 75) {
			return Qt.rgba(0/255, 245/255, 0/255) // #00f500
		} else if (75 <= currentPercent && currentPercent <= 100) {
			return Qt.rgba(0/255, 151/255, 240/255) // #009ff8
		} else {
			return Qt.rgba(0.7, 0.7, 0.7)
		}
	}

	property alias labelVisible: label.visible
	property alias label: label.text
	property color labelColor: {
		if (0 <= currentPercent && currentPercent <= 14) {
			return Qt.rgba(251/255, 0/255, 0/255)
		} else {
			return theme.textColor
		}
	}

	property bool clockwise: true

	property int maskCount: 0
	property real maskWidth: Math.PI/30

	readonly property real centerX: width / 2
	readonly property real centerY: height / 2
	readonly property real radius: Math.min(centerX, centerY)

	property alias canvas: canvas
	onCurrentPercentChanged: canvas.requestPaint()

	Canvas {
		id: canvas
		anchors.fill: parent
		contextType: "2d"

		readonly property real zeroPercentAngle: -Math.PI/2
		readonly property real hundredPercentAngle: zeroPercentAngle + (clockwise ? 1 : -1) * Math.PI*2
		readonly property real delta: (clockwise ? 1 : -1)
		readonly property real doublePiDelta: (Math.PI * 2) * delta
		readonly property real maskedTotalAngle: (Math.PI * 2 - maskCount * maskWidth) * delta

		function calcPercentAngle(percent) {
			var ratio = percent/100
			var angle = zeroPercentAngle + ratio * doublePiDelta

			// Attempt to skip the masks
			// This works for maskCount = 10 but not for 12. So we need to iterate... something
			// var angle = zeroPercentAngle + ratio * maskedTotalAngle
			// if (maskCount > 0) {
			// 	angle += maskWidth/2
			// 	angle += maskWidth * Math.floor(ratio/maskCount)
			// }

			return angle
		}

		onPaint: {
			if (!context) {
				getContext('2d')
			}
			context.reset()

			var currentPercentAngle = calcPercentAngle(currentPercent)

			context.globalCompositeOperation = "source-over"
			context.strokeStyle = grooveColor
			context.beginPath()
			context.lineWidth = grooveThickness
			context.arc(centerX, centerY, radius-thickness/2, currentPercentAngle, hundredPercentAngle, !clockwise)
			context.stroke()
			
			context.strokeStyle = highlightColor
			context.beginPath()
			context.lineWidth = highlightThickness
			context.arc(centerX, centerY, radius-thickness/2, zeroPercentAngle, currentPercentAngle, !clockwise)
			context.stroke()

			context.strokeStyle = "#000"
			context.globalCompositeOperation = "destination-out"
			context.lineWidth = 0
			for (var i = 0; i < maskCount; i++) {
				context.beginPath()
				var maskAngle = zeroPercentAngle + (doublePiDelta * (i/maskCount))
				var maskAngleStart = maskAngle - (delta * maskWidth/2)
				var maskAngleEnd = maskAngle + (delta * maskWidth/2)
				context.arc(centerX, centerY, radius+thickness, maskAngleStart, maskAngleEnd, !clockwise)
				context.arc(centerX, centerY, radius-thickness*2, maskAngleEnd, maskAngleStart - doublePiDelta, !clockwise)
				context.fill()
				context.closePath()
			}

		}
	}

	readonly property int innerDiameter: radius*2 - thickness*2
	readonly property int innerAreaSize: innerDiameter * Math.cos(Math.PI/4)
	PlasmaComponents.Label {
		id: label
		anchors.centerIn: parent
		width: innerAreaSize
		height: innerAreaSize
		font.pixelSize: height
		font.pointSize: -1
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		fontSizeMode: Text.Fit
		text: Math.round(currentPercent)
		color: labelColor
	}


	//--- Testing
	// Rectangle {
	// 	anchors.centerIn: parent
	// 	width: label.width
	// 	height: label.height
	// 	color: "transparent"
	// 	border.width: 1
	// 	border.color: "#0ff"
	// }

	// Timer {
	// 	running: true
	// 	repeat: true
	// 	interval: 100
	// 	onTriggered: {
	// 		parent.currentPercent = (parent.currentPercent+1) % 101
	// 	}
	// }
}
