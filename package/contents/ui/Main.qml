import QtQuick 2.7
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import QtMultimedia 5.4
import org.kde.kcoreaddons 1.0 as KCoreAddons

import "lib"

Item {
	id: main

	Plasmoid.status: active ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

	Plasmoid.icon: ""
	Plasmoid.toolTipMainText: timeLeftText
	Plasmoid.toolTipSubText: ""
	// Plasmoid.toolTipSubText: KCoreAddons.Format.formatDuration(main.duration)

	property bool active: false
	property bool repeat: false
	property bool running: false
	property int duration: 5 * 60 * 1000
	property int timeLeft: 5 * 60 * 1000
	readonly property bool inProgress: timeLeft != duration
	property var targetTime: null
	readonly property bool hasTargetTime: targetTime != null

	property string timeLeftText: ""
	function updateTimeLeftText() {
		timeLeftText = KCoreAddons.Format.formatDuration(main.timeLeft)
	}
	onTimeLeftChanged: {
		updateTimeLeftText()
	}

	function setDuration(duration) {
		main.targetTime = null
		main.duration = duration
		main.timeLeft = duration
		main.active = true
		if (!main.running) {
			hideTimer.restart()
		}
	}
	function setTargetTime(dt) {
		// console.log('setTargetTime', dt)
		var now = new Date()
		var duration = dt.getTime() - now.getTime()
		// console.log('\t duration', duration)
		setDuration(duration)
		main.targetTime = dt
	}
	function updateTargetTimeDuration() {
		// console.log('updateTargetTimeDuration', main.targetTime)
		setTargetTime(main.targetTime)
	}
	function deltaDuration(multiplier) {
		var delta
		if (main.duration >= 15 * 60 * 1000) { // 15m
			delta = 5 * 60 * 1000 // +5m
		} else if (main.duration >= 60 * 1000) { // 1m
			if (multiplier < 0 && main.duration < 120 * 1000) { // 1-2m -5sec
				delta = 5 * 1000 // -5sec
			} else {
				delta = 60 * 1000 // +1m
			}
		} else if (main.duration >= 15 * 1000) { // 15sec
			delta = 5 * 1000 // +5sec
		} else { // 0-14sec
			delta = 1 * 1000 // +5sec
		}
		var newDuration = Math.max(0, main.duration + (delta * multiplier))
		// console.log(main.duration, multiplier, delta, newDuration)
		setDuration(newDuration)
	}
	function increaseDuration() {
		deltaDuration(1)
	}
	function decreaseDuration() {
		deltaDuration(-1)
	}

	function startTimer() {
		// console.log('startTimer', main.running)
		main.running = true
		main.active = true
		hideTimer.stop()
	}
	function pauseTimer() {
		// console.log('pauseTimer', main.running)
		main.running = false
		hideTimer.restart()
	}

	function toggleTimer() {
		// console.log('toggleTimer', main.running)
		if (main.running) {
			pauseTimer()
		} else {
			// console.log('\t targetTime', main.targetTime)
			// console.log('\t hasTargetTime', main.hasTargetTime)
			if (main.hasTargetTime) {
				updateTargetTimeDuration()
			}
			if (main.duration > 0 && main.timeLeft == 0) {
				main.timeLeft = main.duration
			}
			startTimer()
		}
	}

	signal timerCompleted()
	onTimerCompleted: {
		createNotification()
		if (plasmoid.configuration.timerSfxEnabled) {
			playNotificationSound()
		}

		if (main.repeat) {
			main.setDuration(main.duration)
			main.startTimer()
		} else {
			hideTimer.restart()
		}
	}
	Timer {
		id: hideTimer
		interval: 10 * 1000
		onTriggered: main.active = false
	}

	state: {
		if (timeLeft >= 60 * 60 * 1000) { // >= 1 hour
			return 'hours'
		} else if (timeLeft >= 60 * 1000) { // 1-59 minutes
			return 'minutes'
		} else if (timeLeft >= 10 * 1000) { // 10-59 seconds
			return 'seconds'
		} else if (timeLeft > 0) { // 1-10 seconds
			return '10seconds'
		} else if (timeLeft == 0) {
			return 'complete'
		}
	}
	function getHours(t) {
		var hours = Math.floor(t / (60 * 60 * 1000))
		return hours
	}
	function getMinutes(t) {
		var millisLeftInHour = t % (60 * 60 * 1000)
		var minutes = millisLeftInHour / (60 * 1000)
		return minutes
	}
	function getSeconds(t) {
		var millisLeftInMinute = t % (60 * 1000)
		var seconds = millisLeftInMinute / 1000
		return seconds
	}
	property string line1: {
		if (state == 'hours') {
			var hours = Math.floor(getHours(timeLeft))
			return i18nc("short form for %1 hours", "%1h", hours)
		} else if (state == 'minutes') {
			return Math.floor(getMinutes(timeLeft))
		} else if (state == 'seconds') { 
			return Math.floor(getSeconds(timeLeft))
		} else if (state == '10seconds') {
			return getSeconds(timeLeft).toFixed(1)
		} else {
			return ''
		}
	}
	property string line2: {
		if (state == 'hours') {
			return Math.floor(getMinutes(timeLeft))
		} else if (state == 'minutes') {
			return i18nc("short suffix for minutes", "m")
		} else if (state == 'seconds') {
			return i18nc("short suffix for seconds", "s")
		} else if (state == '10seconds') {
			return i18nc("short suffix for seconds", "s")
		} else {
			return ''
		}
	}

	Timer {
		running: main.running
		repeat: true
		interval: main.timeLeft > (10 * 1000) ? 1000 : 100
		onTriggered: {
			// main.timeLeft = main.timeLeft / 2
			var left = main.timeLeft - interval
			
			if (left > 0) {
				main.timeLeft = left
			} else {
				main.timeLeft = 0
				main.running = false
				main.timerCompleted()
			}
			// console.log('timeLeft', main.timeLeft, Date.now())
			// console.log('state', main.state)
			// console.log('timeLeft', main.timeLeft)
			// console.log('line1', main.line1)
			// console.log('line2', main.line2)
		}
	}

	Plasmoid.compactRepresentation: Item {
		id: panelItem

		Item {
			anchors.fill: parent

			scale: mouseArea.pressed ? 0.8 : 1
			Behavior on scale { NumberAnimation { duration: 200 } }

			ProgressCircle {
				anchors.fill: parent
				visible: main.active

				readonly property int seconds: Math.floor(main.timeLeft/1000) % 60
				currentPercent: (seconds / 60) * 100
				labelVisible: false
				grooveColor: "transparent"
				highlightColor: alpha(theme.textColor, 0.1)

				function alpha(c, a) {
					var c2 = Qt.darker(c, 1)
					c2.a = a
					return c2
				}
			}

			Column {
				anchors.fill: parent
				visible: main.active

				Item {
					id: topLabelBox
					width: parent.width
					height: parent.height * 0.6

					PlasmaComponents.Label {
						id: topLabel
						anchors.centerIn: parent
						text: main.line1
						width: parent.width
						horizontalAlignment: Text.AlignHCenter
						fontSizeMode: Text.HorizontalFit
						font.pointSize: -1
						font.pixelSize: parent.height

						// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent" }
					}
				}

				Item {
					id: bottomLabelBox
					width: parent.width
					height: parent.height - topLabelBox.height

					PlasmaComponents.Label {
						id: bottomLabel
						anchors.centerIn: parent
						text: main.line2
						width: parent.width
						horizontalAlignment: Text.AlignHCenter
						fontSizeMode: Text.HorizontalFit
						font.pointSize: -1
						font.pixelSize: parent.height
						opacity: 0.5

						// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent" }
					}
				}
			}

			PlasmaCore.IconItem {
				anchors.fill: parent
				visible: !main.active
				source: 'chronometer'
			}

			PlasmaCore.IconItem {
				id: timerCompleteIcon
				readonly property bool isAnimating: main.active && main.state == 'complete'
				visible: timerCompleteIcon.isAnimating
				anchors.centerIn: parent
				source: 'kalarm'
				width: parent.width
				height: parent.height

				property bool clockwise: true
				property int swingAngle: 30
				property int swingDuration: 400

				Timer {
					running: timerCompleteIcon.isAnimating
					interval: timerCompleteIcon.swingDuration
					repeat: true
					triggeredOnStart: true
					onTriggered: timerCompleteIcon.clockwise = !timerCompleteIcon.clockwise
				}

				//--- Simple Horizontal Flip Animation
				rotation: -swingAngle
				transform: Scale {
					origin.x: timerCompleteIcon.width/2
					xScale: timerCompleteIcon.clockwise ? -1 : 1
				}
				
				//--- Rotation Animation
				// rotation: clockwise ? -swingAngle : swingAngle
				// Behavior on rotation {
				// 	NumberAnimation {
				// 		duration: timerCompleteIcon.swingDuration
				// 		easing.type: Easing.OutElastic
				// 		easing.amplitude: 2.0
				// 		easing.period: 1.5
				// 	}
				// }
			}
		}

		

		MouseArea {
			id: mouseArea
			anchors.fill: parent
			property int wheelDelta: 0
			onWheel: {
				wheelDelta += wheel.angleDelta.y

				// Magic number 120 for common "one click"
				// See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
				while (wheelDelta >= 120) {
					wheelDelta -= 120
					main.increaseDuration()
				}
				while (wheelDelta <= -120) {
					wheelDelta += 120
					main.decreaseDuration()
				}
			}
			acceptedButtons: Qt.LeftButton | Qt.MiddleButton
			onClicked: {
				if (mouse.button == Qt.LeftButton) {
					plasmoid.expanded = !plasmoid.expanded
				} else if (mouse.button == Qt.MiddleButton) {
					main.toggleTimer()
				}
			}
		}
	}

	Plasmoid.fullRepresentation: Item {
		Layout.minimumWidth: layout.implicitWidth
		Layout.minimumHeight: layout.implicitHeight
		Layout.preferredWidth: layout.implicitWidth
		Layout.preferredHeight: layout.implicitHeight

		// Rectangle { border.color: "#f00"; anchors.fill: layout; border.width: 1; color: "transparent" }

		ColumnLayout {
			id: layout
			anchors.fill: parent
			spacing: 0
			visible: plasmoid.expanded


			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true
			}

			
			GridLayout {
				Layout.fillWidth: true
				columns: 6

				Repeater {
					model: presets
					
					delegate: PlasmaComponents.ToolButton {
						Layout.fillWidth: true
						Layout.minimumWidth: implicitWidth
						implicitWidth: minimumWidth
						// text: JSON.stringify(modelData)
						text: modelData.label
						onClicked: {
							main.setDuration(modelData.durations * 1000)
							main.startTimer()
						}
					}

				}
			}

			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: units.largeSpacing
			}

			GridLayout {
				Layout.fillWidth: true
				columns: 4

				PlasmaCore.DataSource {
					id: timeDataSource
					engine: "time"
					connectedSources: ['Local']
					interval: 60 * 60 * 1000
					intervalAlignment: PlasmaCore.Types.AlignToHour
					onNewData: {
						if (sourceName == 'Local') {
							upcomingHourRepeater.updateModel()
						}
					}
					readonly property var currentHour: timeDataSource.data['Local']['DateTime']
				}

				Repeater {
					id: upcomingHourRepeater
					model: []

					property string timeFormat: Qt.locale().timeFormat(Locale.ShortFormat)
					function updateModel() {
						var newModel = []


						var now = new Date()
						for (var i = 0; i < 16; i++) {
							var nextHour = new Date(timeDataSource.currentHour)
							nextHour.setMinutes(0)
							nextHour.setSeconds(0)

							nextHour.setMinutes(i * 15)

							var label = Qt.formatDateTime(nextHour, timeFormat)
							newModel.push({
								enabled: nextHour.getTime() >= now.getTime(),
								label: label,
								targetTime: nextHour,
							})
						}

						model = newModel
					}
					Component.onCompleted: updateModel()
					
					delegate: PlasmaComponents.ToolButton {
						enabled: modelData.enabled
						Layout.fillWidth: true
						Layout.minimumWidth: implicitWidth
						implicitWidth: minimumWidth
						text: modelData.label
						onClicked: {
							main.setTargetTime(modelData.targetTime)
							main.startTimer()
						}
					}

				}
			}

			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: units.largeSpacing
			}


			RowLayout {
				Layout.preferredHeight: 72 * units.devicePixelRatio
				Layout.maximumHeight: Layout.preferredHeight
				readonly property int textSize: Math.floor(height)

				PlasmaComponents.ToolButton {
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.maximumWidth: parent.width / 4

					onClicked: {
						main.toggleTimer()
					}

					ProgressCircle {
						anchors.fill: parent
						anchors.margins: units.smallSpacing
						currentPercent: (main.timeLeft / main.duration) * 100
						labelVisible: false
						grooveColor: alpha(theme.textColor, 0.1)
						// highlightColor: alpha(theme.textColor, 0.2)
						highlightColor: theme.highlightColor
						
						function alpha(c, a) {
							var c2 = Qt.darker(c, 1)
							c2.a = a
							return c2
						}

						PlasmaCore.IconItem {
							anchors.centerIn: parent
							property int size: parent.innerDiameter - units.smallSpacing*2
							width: size
							height: size
							source: {
								if (!main.active) {
									return 'media-playback-start'
								} else if (main.running) {
									return 'media-playback-pause'
								} else {
									return 'media-playback-start'
								}
							}

							// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent" }
						}
					}
				
				}
				PlasmaComponents.Label {
					Layout.fillWidth: true
					Layout.fillHeight: true
					// Layout.preferredHeight: contentHeight
					text: main.timeLeftText
					horizontalAlignment: Text.AlignHCenter
					fontSizeMode: Text.FixedSize
					font.pointSize: -1
					font.pixelSize: parent.textSize

					// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent" }

					MouseArea {
						id: timeLeftMouseArea
						anchors.fill: parent
						property int wheelDelta: 0
						onWheel: {
							wheelDelta += wheel.angleDelta.y

							// Magic number 120 for common "one click"
							// See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
							while (wheelDelta >= 120) {
								wheelDelta -= 120
								main.increaseDuration()
							}
							while (wheelDelta <= -120) {
								wheelDelta += 120
								main.decreaseDuration()
							}
						}
					}
				}
			}


		}
	}

	//-------
	PlasmaCore.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(sourceName, exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName) // cmd finished
		}
		function exec(cmd) {
			if (cmd) {
				connectSource(cmd)
			}
		}
		signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}

	readonly property string timerSfxFilepath: {
		var sfxFilepath = plasmoid.configuration.timerSfxFilepath
		if (sfxFilepath.indexOf('/') == 0) {
			// Valid
			return sfxFilepath
		} else if (sfxFilepath.indexOf('file:///') == 0) {
			sfxFilepath = sfxFilepath.substr('file://'.length)
			return sfxFilepath
		} else {
			// Invalid
			return ''
		}
	}
	function playNotificationSound() {
		if (timerSfxFilepath) {
			executable.exec('paplay \"' + timerSfxFilepath + '\"')
		}
	}

	//-------
	PlasmaCore.DataSource {
		id: notificationSource
		engine: "notifications"
		connectedSources: "org.freedesktop.Notifications"
	}

	function createNotification() {
		// https://github.com/KDE/plasma-workspace/blob/master/dataengines/notifications/notifications.operations
		var service = notificationSource.serviceForSource("notification")
		var operation = service.operationDescription("createNotification")

		operation.appName = i18n("Timer")
		operation.appIcon = "chronometer"
		operation.summary = i18n("Timer finished")
		operation.body = i18n("%1 has passed", KCoreAddons.Format.formatDuration(main.duration))
		operation.expireTimeout = 2000

		service.startOperationCall(operation)
	}

	//-------
	function contextMenuTimer(minutes) {
		var actionId = "timer" + minutes
		var text = i18n("%1 minutes", minutes)
		var iconName = "chronometer"
		plasmoid.setAction(actionId, text, iconName)
	}

	function actionTriggered(name) {
		// console.log('actionTriggered', name)
		if (name.indexOf('timer') == 0) { // startsWith('timer')
			var minutes = parseInt(name.substr('timer'.length), 10)
			main.setDuration(minutes * 60 * 1000)
			main.startTimer()
		}
	}

	function formatDuration(totalSeconds) {
		var t = totalSeconds * 1000
		var str = ''
		var hours = Math.floor(getHours(t))
		if (hours > 0) {
			str += i18nc("short form for %1 hours", "%1h", hours)
		}
		var minutes = Math.floor(getMinutes(t))
		if (minutes > 0) {
			str += i18nc("short form for %1 minutes", "%1m", minutes)
		}
		var seconds = Math.floor(getSeconds(t))
		if (seconds > 0) {
			str += i18nc("short form for %1 seconds", "%1s", seconds)
		}
		return str
	}
	function presetDuration(durationInSeconds) {
		return formatDuration(durationInSeconds) + ';' + durationInSeconds
	}
	//30s;30,1m;60,Pomorro;240;60
	property string defaultPresetString: {
		return [
			presetDuration(30),
			presetDuration(60),
			presetDuration(60 + 30),
			presetDuration(2*60 + 30),
			presetDuration(5*60),
			presetDuration(10*60),
			presetDuration(15*60),
			presetDuration(20*60),
			presetDuration(25*60),
			presetDuration(30*60),
			presetDuration(45*60),
			presetDuration(60*60),
		].join(',')
	}
	property string presetString: '' || defaultPresetString
	property var presets: {
		var list = []
		var tokens = presetString.split(',')
		for (var i = 0; i < tokens.length; i++) {
			var tokens2 = tokens[i].split(';')
			var preset = {
				'label': tokens2[0],
				'durations': tokens2.slice(1),
			}
			list.push(preset)
		}
		return list
	}

	Component.onCompleted: {
		updateTimeLeftText()

		contextMenuTimer(5)
		contextMenuTimer(10)
		contextMenuTimer(15)
		contextMenuTimer(20)
		contextMenuTimer(30)
		contextMenuTimer(45)
		contextMenuTimer(60)

		// setDuration(65 * 1000)
		// setDuration(1 * 1000)
		// startTimer()
	}
}
