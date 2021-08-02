/*
 * Copyright 2020  Tjaart Blignaut <tjaartblig@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12
import org.kde.plasma.plasmoid 2.0
import QtQml 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root
    Layout.minimumWidth: 400
    Layout.minimumHeight: 100
    
    property var waitingCommands: ({})
    
    ListModel {
        id: dockerServices
    }

    PlasmaCore.DataSource {
		id: shell
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

		function runShell(containerId) {
            var cmd = 'konsole -e "docker exec -it -u 0 '+containerId+' bash"';
			connectSource(cmd);
		}

		signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}
   
    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: ["curl --unix-socket /var/run/docker.sock http://foo/containers/json?all=true"]
       
        onNewData: {
            var stdout = data["stdout"]
            dockerServices.clear()
            var list = JSON.parse(stdout)
            for(var i=0;i<list.length;i++) {
                list[i].Name = list[i]["Names"][0].substring(1);
                dockerServices.append(list[i])
            }
        }
        interval: 1000
    }
    
    PlasmaCore.DataSource {
        id: dockerCommandExecutable
        engine: "executable"
        connectedSources: []
        onNewData: {
            var stdout = data["stdout"].replace(/(\r\n|\n|\r)/gm, "");
            waitingCommands[stdout] = false
            exited(sourceName, stdout)
            disconnectSource(sourceName) // cmd finished
        }

        function execDockerCommand(dockerCommand, containerId) {
            var cmd = 'docker ' + dockerCommand + ' ' + containerId
            waitingCommands[containerId] = true
            connectSource(cmd)
        }
        signal exited(string sourceName, string stdout)
    }
    
    function isBusy(containerId) {
        if (waitingCommands[containerId] === undefined) {
            return false;
        }
       return waitingCommands[containerId]
    }
     
    ColumnLayout {
        id: columns
        spacing: 1;
        anchors.fill: parent;
        Layout.fillWidth: true
        Layout.fillHeight: true
        PlasmaExtras.ScrollArea {
            id: scrollView;

            anchors.top: parent.top;
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right    
          
            ListView {
                id: view
                width: parent.width
                height: parent.height
                model: dockerServices
                spacing: 7
                interactive: false
                clip: false
                
                delegate: RowLayout {
                    width: parent.width
                  
                    PlasmaComponents.Label {
                        id: containerName
                        text: model[plasmoid.configuration.title]
                        clip: false
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    }
                    PlasmaComponents.Label {
                        id: containerState
                        text: model.Status
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    }
                    
                    PlasmaComponents.BusyIndicator {
                        id: connectingIndicator
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Layout.fillHeight: true
                        Layout.preferredHeight: units.iconSizes.small
                        Layout.preferredWidth: units.iconSizes.small
                        running: true
                        visible: isBusy(model.Id)
                    }

                    PlasmaComponents.Button{
                        enabled: !(isBusy(model.Id) || (model.State == "exited"))
                        iconSource: "bash-symbolic"
                        onClicked: function(){
                            shell.runShell(model.Id)
                        }
                    }
                    
                    PlasmaComponents.Button {
                        enabled: !isBusy(model.Id)
                        iconSource: (model.State == "exited") ? "media-playback-start" : "media-playback-stop"
                        onClicked: function () {
                            dockerCommandExecutable.execDockerCommand((model.State == "exited") ? "start" : "stop", model.Id);
                        
                        }
                    }
                }
            }
        }
          
    }
}
