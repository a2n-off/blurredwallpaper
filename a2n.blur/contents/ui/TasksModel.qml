import QtQuick
import QtQml.Models
import org.kde.taskmanager as TaskManager

Item {
    id: plasmaTasksItem

    readonly property bool existsWindowActive: root.activeTaskItem && tasksRepeater.count > 0 && activeTaskItem.isActive
    property Item activeTaskItem: null

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop
        filterByVirtualDesktop: true
        filterByActivity: true
    }

    Item {
        id: taskList

        Repeater {
            id: tasksRepeater
            model: tasksModel

            Item {
                id: task
                readonly property bool isActive: IsActive === true ? true : false

                onIsActiveChanged: {
                    if (isActive) plasmaTasksItem.activeTaskItem = task
                }
            }
        }
    }
}
