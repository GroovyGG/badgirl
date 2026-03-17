import Foundation
import SwiftData

/// Links a MovementTarget to a MuscleGroup, describing the muscle's role and contribution.
@Model
final class MovementTargetMuscle {
    var id: UUID = UUID()
    /// prime_mover, stabilizer, synergist, decelerator, transfer
    var role: String = ""
    /// 1–5 scale
    var contributionLevel: Int = 3
    /// initiation, acceleration, contact, deceleration, recovery
    var phase: String? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var movementTarget: MovementTarget? = nil
    var muscleGroup: MuscleGroup? = nil

    init(movementTarget: MovementTarget, muscleGroup: MuscleGroup, role: String, contributionLevel: Int = 3, phase: String? = nil) {
        self.movementTarget = movementTarget
        self.muscleGroup = muscleGroup
        self.role = role
        self.contributionLevel = contributionLevel
        self.phase = phase
    }
}
