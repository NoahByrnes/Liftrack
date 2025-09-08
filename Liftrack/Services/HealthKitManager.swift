import Foundation
import HealthKit

/// Manages HealthKit integration for HRV and recovery metrics
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var latestHRV: Double? = nil
    @Published var hrvTrend: HRVTrend = .stable
    @Published var recoveryScore: Int = 75 // 0-100 scale
    
    enum HRVTrend {
        case improving
        case stable
        case declining
    }
    
    private init() {
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchLatestHRV()
                    self?.calculateRecoveryScore()
                }
            }
        }
    }
    
    private func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let status = healthStore.authorizationStatus(for: hrvType)
        
        DispatchQueue.main.async { [weak self] in
            self?.isAuthorized = (status == .sharingAuthorized)
            if self?.isAuthorized == true {
                self?.fetchLatestHRV()
                self?.calculateRecoveryScore()
            }
        }
    }
    
    // MARK: - HRV Data
    
    func fetchLatestHRV() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            DispatchQueue.main.async {
                self?.latestHRV = hrv
                self?.analyzeHRVTrend()
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchHRVHistory(days: Int = 7, completion: @escaping ([Double]) -> Void) {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            let hrvValues = samples?.compactMap { sample -> Double? in
                guard let sample = sample as? HKQuantitySample else { return nil }
                return sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            } ?? []
            
            DispatchQueue.main.async {
                completion(hrvValues)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func analyzeHRVTrend() {
        fetchHRVHistory(days: 7) { [weak self] values in
            guard values.count >= 3 else {
                self?.hrvTrend = .stable
                return
            }
            
            // Calculate 7-day rolling average vs last 3 days
            let sevenDayAvg = values.reduce(0, +) / Double(values.count)
            let recentValues = Array(values.suffix(3))
            let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
            
            // Determine trend
            let percentChange = ((recentAvg - sevenDayAvg) / sevenDayAvg) * 100
            
            if percentChange > 5 {
                self?.hrvTrend = .improving
            } else if percentChange < -5 {
                self?.hrvTrend = .declining
            } else {
                self?.hrvTrend = .stable
            }
        }
    }
    
    // MARK: - Recovery Score
    
    func calculateRecoveryScore() {
        var components: [(weight: Double, score: Double)] = []
        
        // HRV Component (40% weight)
        if let hrv = latestHRV {
            let hrvScore = calculateHRVScore(hrv)
            components.append((weight: 0.4, score: hrvScore))
        }
        
        // Sleep Component (30% weight)
        fetchSleepData { sleepHours in
            let sleepScore = self.calculateSleepScore(sleepHours)
            components.append((weight: 0.3, score: sleepScore))
            
            // Resting Heart Rate Component (20% weight)
            self.fetchRestingHeartRate { rhr in
                let rhrScore = self.calculateRHRScore(rhr)
                components.append((weight: 0.2, score: rhrScore))
                
                // Calculate final recovery score
                var totalScore = 0.0
                var totalWeight = 0.0
                
                for component in components {
                    totalScore += component.weight * component.score
                    totalWeight += component.weight
                }
                
                // If we don't have all data, adjust weights
                if totalWeight < 1.0 {
                    totalScore = totalScore / totalWeight
                }
                
                DispatchQueue.main.async {
                    self.recoveryScore = Int(totalScore)
                }
            }
        }
    }
    
    private func calculateHRVScore(_ hrv: Double) -> Double {
        // HRV scoring based on population norms
        // Average HRV is 20-100ms, with higher being better
        switch hrv {
        case 60...: return 100
        case 50..<60: return 85
        case 40..<50: return 70
        case 30..<40: return 55
        case 20..<30: return 40
        default: return 25
        }
    }
    
    private func calculateSleepScore(_ hours: Double) -> Double {
        // Optimal sleep is 7-9 hours
        switch hours {
        case 7..<9: return 100
        case 6..<7, 9..<10: return 80
        case 5..<6, 10..<11: return 60
        case 4..<5, 11..<12: return 40
        default: return 20
        }
    }
    
    private func calculateRHRScore(_ rhr: Double) -> Double {
        // Lower resting heart rate is generally better
        // Average is 60-100 bpm
        switch rhr {
        case ..<50: return 100
        case 50..<60: return 90
        case 60..<70: return 75
        case 70..<80: return 60
        case 80..<90: return 45
        default: return 30
        }
    }
    
    // MARK: - Helper Data Fetchers
    
    private func fetchSleepData(completion: @escaping (Double) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            let sleepSamples = samples as? [HKCategorySample] ?? []
            
            var totalSleepTime: TimeInterval = 0
            for sample in sleepSamples {
                // Count all sleep stages except awake
                if sample.value != HKCategoryValueSleepAnalysis.awake.rawValue {
                    totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            let sleepHours = totalSleepTime / 3600
            DispatchQueue.main.async {
                completion(sleepHours)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate(completion: @escaping (Double) -> Void) {
        let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: rhrType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(70) // Default value
                return
            }
            
            let rhr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                completion(rhr)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Recovery Recommendations
    
    func getRecoveryRecommendation() -> (intensity: Double, volumeAdjustment: Double, message: String) {
        switch (recoveryScore, hrvTrend) {
        case (80..., .improving):
            return (1.0, 1.1, "Excellent recovery! You can push harder today.")
        case (80..., .stable):
            return (1.0, 1.0, "Well recovered. Normal training intensity.")
        case (80..., .declining):
            return (0.95, 1.0, "Good recovery, but monitor fatigue.")
            
        case (60..<80, .improving):
            return (0.95, 1.0, "Moderate recovery. Standard workout recommended.")
        case (60..<80, .stable):
            return (0.9, 0.95, "Average recovery. Consider slightly reduced volume.")
        case (60..<80, .declining):
            return (0.85, 0.9, "Recovery declining. Reduce intensity today.")
            
        case (40..<60, _):
            return (0.8, 0.8, "Low recovery. Light workout or active recovery recommended.")
            
        case (..<40, _):
            return (0.6, 0.6, "Poor recovery. Rest day or very light activity only.")
            
        default:
            return (0.9, 0.95, "Moderate workout recommended.")
        }
    }
    
    // MARK: - Readiness Score (for pre-workout)
    
    func calculateReadinessScore(recentRPE: [Int], recentWorkouts: [WorkoutSession]) -> Int {
        var factors: [(weight: Double, score: Double)] = []
        
        // Recovery score (40% weight)
        factors.append((weight: 0.4, score: Double(recoveryScore)))
        
        // Recent RPE trend (30% weight)
        if !recentRPE.isEmpty {
            let avgRPE = recentRPE.reduce(0, +) / recentRPE.count
            let rpeScore = max(0, 100 - (avgRPE * 10))
            factors.append((weight: 0.3, score: Double(rpeScore)))
        }
        
        // Training frequency (30% weight)
        let daysInWeek = 7
        let workoutsThisWeek = recentWorkouts.filter { session in
            guard let completedAt = session.completedAt else { return false }
            return completedAt > Calendar.current.date(byAdding: .day, value: -daysInWeek, to: Date())!
        }.count
        
        let frequencyScore: Double
        switch workoutsThisWeek {
        case 0...2: frequencyScore = 100 // Well rested
        case 3...4: frequencyScore = 85  // Good balance
        case 5...6: frequencyScore = 70  // Getting tired
        default: frequencyScore = 50     // Overtraining risk
        }
        factors.append((weight: 0.3, score: frequencyScore))
        
        // Calculate weighted average
        let totalScore = factors.reduce(0) { $0 + ($1.weight * $1.score) }
        let totalWeight = factors.reduce(0) { $0 + $1.weight }
        
        return Int(totalScore / totalWeight)
    }
}

// MARK: - PerformanceBasedRecovery

/// Fallback recovery system when HRV data is not available
class PerformanceBasedRecovery {
    
    /// Calculate recovery without HRV using performance metrics
    static func calculateRecovery(from sessions: [WorkoutSession]) -> (score: Int, recommendation: String) {
        guard !sessions.isEmpty else {
            return (75, "No recent workout data. Start with moderate intensity.")
        }
        
        // Get last 7 days of workouts
        let recentSessions = sessions.filter { session in
            guard let completedAt = session.completedAt else { return false }
            return completedAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
        
        // Calculate metrics
        let volumeScore = calculateVolumeScore(recentSessions)
        let intensityScore = calculateIntensityScore(recentSessions)
        let performanceScore = calculatePerformanceScore(recentSessions)
        let frequencyScore = calculateFrequencyScore(recentSessions)
        
        // Weighted average
        let totalScore = (volumeScore * 0.25 + intensityScore * 0.35 + 
                         performanceScore * 0.25 + frequencyScore * 0.15)
        
        // Generate recommendation
        let recommendation = generateRecommendation(score: totalScore)
        
        return (Int(totalScore), recommendation)
    }
    
    private static func calculateVolumeScore(_ sessions: [WorkoutSession]) -> Double {
        // Calculate acute:chronic workload ratio
        let acuteWindow = 7  // days
        let chronicWindow = 28 // days
        
        let acuteVolume = calculateTotalVolume(sessions, days: acuteWindow)
        let chronicVolume = calculateTotalVolume(sessions, days: chronicWindow) / 4 // Weekly average
        
        guard chronicVolume > 0 else { return 75 }
        
        let ratio = acuteVolume / chronicVolume
        
        // Optimal ACWR is 0.8-1.3
        switch ratio {
        case 0.8..<1.3: return 100
        case 0.5..<0.8, 1.3..<1.5: return 80
        case 0.3..<0.5, 1.5..<2.0: return 60
        default: return 40
        }
    }
    
    private static func calculateIntensityScore(_ sessions: [WorkoutSession]) -> Double {
        let recentSets = sessions.flatMap { $0.exercises }.flatMap { $0.sets }
        let completedSets = recentSets.filter { $0.isCompleted }
        
        guard !completedSets.isEmpty else { return 75 }
        
        // RPE tracking would go here when smart features are enabled
        // For now, return a default recovery score
        return 75
    }
    
    private static func calculatePerformanceScore(_ sessions: [WorkoutSession]) -> Double {
        // Look at performance trends (are weights/reps improving?)
        guard sessions.count >= 2 else { return 75 }
        
        var improvementCount = 0
        var comparisonCount = 0
        
        // Compare recent workouts to previous ones for same exercises
        for session in sessions.prefix(3) {
            for exercise in session.exercises {
                // Find previous instance of same exercise
                let previousSets = sessions
                    .filter { $0.completedAt ?? Date() < session.startedAt }
                    .flatMap { $0.exercises }
                    .filter { $0.exerciseName == exercise.exerciseName }
                    .flatMap { $0.sets }
                    .filter { $0.isCompleted }
                
                let currentSets = exercise.sets.filter { $0.isCompleted }
                
                if !previousSets.isEmpty && !currentSets.isEmpty {
                    comparisonCount += 1
                    
                    let prevAvgWeight = previousSets.map { $0.weight }.reduce(0, +) / Double(previousSets.count)
                    let currAvgWeight = currentSets.map { $0.weight }.reduce(0, +) / Double(currentSets.count)
                    
                    if currAvgWeight >= prevAvgWeight {
                        improvementCount += 1
                    }
                }
            }
        }
        
        guard comparisonCount > 0 else { return 75 }
        
        let improvementRate = Double(improvementCount) / Double(comparisonCount)
        return improvementRate * 100
    }
    
    private static func calculateFrequencyScore(_ sessions: [WorkoutSession]) -> Double {
        // Rest days between workouts
        let sortedSessions = sessions.sorted { ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) }
        
        guard sortedSessions.count >= 2 else { return 100 }
        
        var restDays: [Int] = []
        for i in 1..<sortedSessions.count {
            if let prevDate = sortedSessions[i-1].completedAt,
               let currDate = sortedSessions[i].completedAt {
                let days = Calendar.current.dateComponents([.day], from: prevDate, to: currDate).day ?? 0
                restDays.append(days)
            }
        }
        
        guard !restDays.isEmpty else { return 75 }
        
        let avgRestDays = restDays.reduce(0, +) / restDays.count
        
        // Optimal rest is 1-2 days between workouts
        switch avgRestDays {
        case 1...2: return 100
        case 3: return 85
        case 0, 4: return 70
        default: return 50
        }
    }
    
    private static func calculateTotalVolume(_ sessions: [WorkoutSession], days: Int) -> Double {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let relevantSessions = sessions.filter { session in
            guard let completedAt = session.completedAt else { return false }
            return completedAt > cutoffDate
        }
        
        var totalVolume = 0.0
        for session in relevantSessions {
            for exercise in session.exercises {
                for set in exercise.sets where set.isCompleted {
                    totalVolume += set.weight * Double(set.reps)
                }
            }
        }
        
        return totalVolume
    }
    
    private static func generateRecommendation(score: Double) -> String {
        switch score {
        case 90...: return "Excellent recovery! Full intensity training recommended."
        case 75..<90: return "Good recovery. Normal training intensity."
        case 60..<75: return "Moderate recovery. Consider 90% intensity."
        case 45..<60: return "Limited recovery. Reduce volume by 20-30%."
        case 30..<45: return "Poor recovery. Light workout or active recovery only."
        default: return "Very poor recovery. Rest day recommended."
        }
    }
}