import Foundation
import HealthKit
import Observation

/// Manages HealthKit authorization and data reads.
/// Inject via SwiftUI environment: `.environment(healthKitManager)`.
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
            authorizationError = nil
        } catch {
            authorizationError = error
            isAuthorized = false
        }
    }

    // MARK: - Fetch (HealthKit queries)

    func fetchHeartRateSamples(for date: Date) async -> [HKQuantitySample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }
    }

    func fetchActiveEnergyBurned(for date: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie())
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    func fetchSteps(for date: Date) async -> Int? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: value.map { Int($0) })
            }
            store.execute(query)
        }
    }

    func fetchSleepHours(for date: Date) async -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, s, _ in
                continuation.resume(returning: (s as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
        // Sum in-bed and asleep durations (value 1 = inBed, 2 = asleep, etc.)
        let validValues: Set<Int> = [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepDeep.rawValue, HKCategoryValueSleepAnalysis.asleepREM.rawValue]
        var total: TimeInterval = 0
        for sample in samples where validValues.contains(sample.value) {
            total += sample.endDate.timeIntervalSince(sample.startDate)
        }
        return total > 0 ? total / 3600.0 : nil
    }

    func fetchExerciseMinutes(for date: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .minute())
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    /// Builds a HealthSnapshot from all available data for a given date.
    func buildSnapshot(for date: Date) async -> HealthSnapshot {
        async let heartRateSamples = fetchHeartRateSamples(for: date)
        async let energy  = fetchActiveEnergyBurned(for: date)
        async let steps   = fetchSteps(for: date)
        async let sleep   = fetchSleepHours(for: date)
        async let minutes = fetchExerciseMinutes(for: date)

        let snapshot = HealthSnapshot(snapshotDate: date, source: "apple_health")
        let samples = await heartRateSamples
        if !samples.isEmpty {
            let unit = HKUnit.count().unitDivided(by: .minute())
            let values = samples.map { $0.quantity.doubleValue(for: unit) }
            snapshot.avgHeartRate = values.reduce(0, +) / Double(values.count)
            snapshot.maxHeartRate = values.max()
        }
        snapshot.activeEnergyKcal  = await energy
        snapshot.steps             = await steps
        snapshot.sleepHours        = await sleep
        snapshot.exerciseMinutes   = await minutes
        return snapshot
    }
}
