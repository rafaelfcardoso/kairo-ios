import Foundation

enum TaskFilter: String, CaseIterable {
    case today = "Hoje"
    case upcoming = "Próximas"
    case inbox = "Entrada"
    case completed = "Concluídas"
    case focus = "Foco"
} 