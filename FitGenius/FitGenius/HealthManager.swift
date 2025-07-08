//
//  HealthManager.swift
//  FitGenius
//
//  Created by Arpa Hakopian on 2/27/25.
//

import Foundation
import HealthKit
// Extension to fetch the start of the day
extension Date {
    static var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }
}
// HealthManager: Manages fetching HealthKit data
class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var steps: Double = 0
    @Published var distance: Double = 0
    @Published var calories: Double = 0
    @Published var weeklySteps: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklyDistance: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklyCalories: [Double] = Array(repeating: 0, count: 7)
    init() {
        requestAuthorization()
    }
    /// Requests permission to read health data
    private func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let healthTypes: Set = [stepType, distanceType, calorieType]
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
                print("✅ HealthKit authorization granted")
            } catch {
                print("❌ Error requesting HealthKit authorization: \(error)")
            }
        }
    }
    /// Fetches all activity data for today
    func fetchTodayActivity() {
        fetchTodaySteps()
        fetchTodayDistance()
        fetchTodayCalories()
        fetchWeeklySteps()
        fetchWeeklyDistance()
        fetchWeeklyCalories()
    }
    /// Fetches today's step count
    private func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("❌ Error fetching steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let stepCount = quantity.doubleValue(for: .count())
            DispatchQueue.main.async {
                self.steps = stepCount
            }
            print("🚶 Steps: \(stepCount.formattedString())")
        }
        healthStore.execute(query)
    }
    /// Fetches today's distance walked or run
    private func fetchTodayDistance() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("❌ Error fetching distance: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let distanceMeters = quantity.doubleValue(for: .meter())
            DispatchQueue.main.async {
                self.distance = distanceMeters
            }
            print("📏 Distance: \(distanceMeters.formattedString()) meters")
        }
        healthStore.execute(query)
    }
    /// Fetches today's active energy burned (calories)
    private func fetchTodayCalories() {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("❌ Error fetching calories: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let calorieCount = quantity.doubleValue(for: .kilocalorie())
            DispatchQueue.main.async {
                self.calories = calorieCount
            }
            print("🔥 Calories: \(calorieCount.formattedString()) kcal")
        }
        healthStore.execute(query)
    }
    /// Fetches step data for the last 7 days
    private func fetchWeeklySteps() {
        guard let stepType = HKSampleType.quantityType(forIdentifier: .stepCount) else { return }
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        var interval = DateComponents()
        interval.day = 1
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results, error == nil else {
                print("❌ Error fetching weekly steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            var stepsPerDay: [Double] = []
            statsCollection.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                let value = stat.sumQuantity()?.doubleValue(for: .count()) ?? 0
                stepsPerDay.append(value)
            }
            DispatchQueue.main.async {
                self.weeklySteps = stepsPerDay
            }
        }
        healthStore.execute(query)
    }
    // New function: Fetch weekly distance
    private func fetchWeeklyDistance() {
        fetchWeeklyData(for: .distanceWalkingRunning) { values in
            DispatchQueue.main.async {
                self.weeklyDistance = values
            }
        }
    }
    // New function: Fetch weekly calories
    private func fetchWeeklyCalories() {
        fetchWeeklyData(for: .activeEnergyBurned) { values in
            DispatchQueue.main.async {
                self.weeklyCalories = values
            }
        }
    }
    // Helper function to fetch weekly data
    private func fetchWeeklyData(for identifier: HKQuantityTypeIdentifier, completion: @escaping ([Double]) -> Void) {
        guard let quantityType = HKSampleType.quantityType(forIdentifier: identifier) else { return }
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        var interval = DateComponents()
        interval.day = 1
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results, error == nil else {
                print("❌ Error fetching weekly data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            var valuesPerDay: [Double] = []
            statsCollection.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                let value = stat.sumQuantity()?.doubleValue(for: identifier == .activeEnergyBurned ? .kilocalorie() : .meter()) ?? 0
                valuesPerDay.append(value)
            }
            completion(valuesPerDay)
        }
        healthStore.execute(query)
    }
}
// Extension to format numbers
extension Double {
    func formattedString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

