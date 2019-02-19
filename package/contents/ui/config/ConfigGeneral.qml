import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page
	showAppletVersion: true

	property alias cfg_timerSfxEnabled: timerSfxEnabled.checked
	property alias cfg_timerSfxFilepath: timerSfxFilepath.text

	Kirigami.FormLayout {
		Layout.fillWidth: true
		wideMode: true

		CheckBox {
			id: timerSfxEnabled
			Kirigami.FormData.label: i18n("Sfx:")
			text: i18n("Enabled")
		}

		RowLayout {
			spacing: 0
			Layout.preferredWidth: 16 * Kirigami.Units.gridUnit

			TextField {
				id: timerSfxFilepath
				Layout.fillWidth: true
			}

			Button {
				iconName: "folder-symbolic"
				onClicked: sfxPathDialog.visible = true

				FileDialog {
					id: sfxPathDialog
					title: i18n("Choose a sound effect")
					folder: '/usr/share/sounds'
					nameFilters: [ "Sound files (*.wav *.mp3 *.oga *.ogg)", "All files (*)" ]
					onAccepted: {
						timerSfxFilepath.text = fileUrl
					}
				}
			}
		}
	}
}
