import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1


Item {
	id: configGeneral
	Layout.fillWidth: true
	
	property string cfg_title: plasmoid.configuration.title
	property variant titleList: ["Image" , "Name"]
	

	GridLayout {
		columns: 2
		
		Label {
			text: i18n("Item Title:")
		}
		
		ComboBox {
			id: title
			model: titleList
			Layout.minimumWidth: theme.mSize(theme.defaultFont).width * 15
			onActivated: {
				cfg_title = title.textAt(index)
			}
			Component.onCompleted: {
				var sourceIndex = title.find(plasmoid.configuration.title)
				
				if(sourceIndex != -1) {
					title.currentIndex = sourceIndex
				}
			}
		}
		
	}
}
