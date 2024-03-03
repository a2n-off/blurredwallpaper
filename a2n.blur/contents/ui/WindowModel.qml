import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.3
import QtQuick.Window 2.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.taskmanager 0.1 as TaskManager

Item {
	property alias screenGeometry: tasksModel.screenGeometry
	property bool noWindowActive: true
	property bool currentWindowMaximized: false
	property bool isActiveWindowPinned: false

	TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
	TaskManager.ActivityInfo { id: activityInfo }
	TaskManager.TasksModel {
		id: tasksModel
		sortMode: TaskManager.TasksModel.SortVirtualDesktop
		groupMode: TaskManager.TasksModel.GroupDisabled

		activity: activityInfo.currentActivity
		virtualDesktop: virtualDesktopInfo.currentDesktop
		screenGeometry: imageWallpaper.screenGeometry // Warns "Unable to assign [undefined] to QRect" during init, but works thereafter.

		filterByActivity: true
		filterByVirtualDesktop: true
		filterByScreen: true

		onActiveTaskChanged: {
			// console.log('tasksModel.onActiveTaskChanged')
			updateActiveWindowInfo()
		}
		onDataChanged: {
			// console.log('tasksModel.onDataChanged')
			updateActiveWindowInfo()
		}
		Component.onCompleted: {
			// console.log('tasksModel.Component.onCompleted')
			activeWindowModel.sourceModel = tasksModel
		}
	}
	PlasmaCore.SortFilterModel {
		id: activeWindowModel
		filterRole: 'IsActive'
		filterRegExp: 'true'
		onDataChanged: {
			// console.log('activeWindowModel.onDataChanged')
			updateActiveWindowInfo()
		}
		onCountChanged: {
			// console.log('activeWindowModel.onCountChanged')
			updateActiveWindowInfo()
		}
	}


	function activeTask() {
		return activeWindowModel.get(0) || {}
	}

	function updateActiveWindowInfo() {
		var actTask = activeTask()
		noWindowActive = activeWindowModel.count === 0 || actTask.IsActive !== true
		currentWindowMaximized = !noWindowActive && actTask.IsMaximized === true
		isActiveWindowPinned = actTask.VirtualDesktop === -1
	}
}
