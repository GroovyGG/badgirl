import Foundation
import HealthKit
import Observation

/// Manages HealthKit authorization and data reads.
/// Inject via SwiftUI environment: `.environment(healthKitManager)`.
///
/// All fetch methods are stubs — replace with real HKSampleQuery / HKStatisticsQuery logic
/// once the schema foundation is confirmed.
@Observable
final class HealthKitManager {

    private let store = HKHealthStore()

    var isAuthorized: Bool = false
    var authorizationError: Error? = nil

    // MARK: - Read types

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .activeEnergyBurned,
            .stepCount,
            .appleExerciseTime,
        ]
        let categoryTypes: [HKCategoryTypeIdentifier] = [
            .sleepAnalysis,
        ]
        quantityTypes.compactMap { HKQuantityType($0) }.forEach { types.insert($0) }
        categoryTypes.compactMap { HKCategoryType($0) }.forEach { types.insert($0) }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            authorizationError = error
        }
    }

    // MARK: - Fetch stubs (replace with real HKSampleQuery / HKStatisticsQuery)

    func fetchHeartRateSamples(for date: Date) async -> [HKQuantitySample] {
        // TODO: implement HKSampleQuery for heartRate on given date
        return []
    }

    func fetchActiveEnergyBurned(for date: Date) async -> Double? {
        // TODO: implement HKStatisticsQuery for activeEnergyBurned sum
        return nil
    }

    func fetchSteps(for date: Date) async -> Int? {
        // TODO: implement HKStatisticsQuery for stepCount sum
        return nil
    }

    func fetchSleepHours(for date: Date) async -> Double? {
        // TODO: implement HKSampleQuery for sleepAnalysis on given date
        return nil
    }

    func fetchExerciseMinutes(for date: Date) async -> Double? {
        // TODO: implement HKStatisticsQuery for appleExerciseTime sum
        return nil
    }

    /// Builds a HealthSnapshot from all available data for a given date.
    /// Attach to a TrainingSession or save as standalone daily snapshot.
    func buildSnapshot(for date: Date) async -> HealthSnapshot {
        async let energy  = fetchActiveEnergyBurned(for: date)
        async let steps   = fetchSteps(for: date)
        async let sleep   = fetchSleepHours(for: date)
        async let minutes = fetchExerciseMinutes(for: date)

        let snapshot = HealthSnapshot(snapshotDate: date, source: "apple_health")
        snapshot.activeEnergyKcal  = await energy
        snapshot.steps             = await steps
        snapshot.sleepHours        = await sleep
        snapshot.exerciseMinutes   = await minutes
        return snapshot
    }
}
