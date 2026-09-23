import Foundation
import SwiftData

@Model
final class Client {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Project.client)
    var projects: [Project] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}
