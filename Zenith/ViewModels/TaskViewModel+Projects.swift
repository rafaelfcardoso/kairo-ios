import Foundation

extension TaskViewModel {
    /// Returns the inbox project (system project)
    func getInboxProject() -> Project? {
        // We'll need to use the ProjectViewModel to get the inbox project
        // Since we don't have direct access to it, we'll simulate it by creating a simple Project object
        // In a real implementation, this should be fetched from the API or coordinated with the ProjectViewModel
        
        return Project(
            id: "inbox",
            name: "Entrada",
            description: "Tarefas sem um projeto específico",
            isArchived: false,
            isSystem: true,
            color: "7E7E7E",
            order: 0,
            createdAt: "",
            updatedAt: "",
            taskCount: tasks.filter { $0.project == nil || $0.project?.isSystem == true }.count
        )
    }
    
    /// Returns tasks for a specific project
    func getTasksForProject(projectId: String) -> [TodoTask] {
        // Filter regular tasks
        let projectTasks = tasks.filter { task in
            if projectId == "inbox" {
                // For the inbox, return tasks with no project or with the system project
                return task.project == nil || task.project?.isSystem == true
            } else {
                // For regular projects, match by project ID
                return task.project?.id == projectId
            }
        }
        
        // Filter overdue tasks
        let overdueProjectTasks = overdueTasks.filter { task in
            if projectId == "inbox" {
                return task.project == nil || task.project?.isSystem == true
            } else {
                return task.project?.id == projectId
            }
        }
        
        // Combine both lists
        return overdueProjectTasks + projectTasks
    }
}

// Helper initializer for Project to support the getInboxProject method
extension Project {
    init(id: String, name: String, description: String?, isArchived: Bool, isSystem: Bool, color: String, order: Int, createdAt: String, updatedAt: String, taskCount: Int?) {
        self.id = id
        self.name = name
        self.description = description
        self.isArchived = isArchived
        self.isSystem = isSystem
        self.color = color
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.taskCount = taskCount
    }
} 