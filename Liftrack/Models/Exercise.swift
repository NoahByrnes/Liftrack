import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var createdAt: Date
    var defaultRestSeconds: Int = 90
    
    init(name: String, defaultRestSeconds: Int = 90) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.defaultRestSeconds = defaultRestSeconds
    }
}