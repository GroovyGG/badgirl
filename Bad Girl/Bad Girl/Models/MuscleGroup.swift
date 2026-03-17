import Foundation
import SwiftData

@Model
final class MuscleGroup {
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var displayNameZh: String? = nil
    var bodyRegion: String? = nil   // upper, lower, core, shoulder, hip, ankle, forearm
    var muscleDescription: String? = nil
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var parent: MuscleGroup? = nil

    @Relationship(deleteRule: .nullify, inverse: \MuscleGroup.parent)
    var children: [MuscleGroup] = []

    @Relationship(deleteRule: .cascade, inverse: \MovementTargetMuscle.muscleGroup)
    var movementTargetMuscles: [MovementTargetMuscle] = []

    init(code: String, name: String, displayNameZh: String? = nil, bodyRegion: String? = nil, parent: MuscleGroup? = nil, sortOrder: Int = 0) {
        self.code = code
        self.name = name
        self.displayNameZh = displayNameZh
        self.bodyRegion = bodyRegion
        self.parent = parent
        self.sortOrder = sortOrder
    }
}
