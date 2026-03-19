import Foundation

/// App scope: general activity + badminton only. Other sports are not supported.
enum AppScope {
    static let supportedSportCode = "badminton"

    /// True if this sport is the single supported sport (badminton).
    static func isSupported(sport: Sport?) -> Bool {
        guard let sport = sport else { return true }
        return sport.code == supportedSportCode
    }

    /// True for general (no sport) or badminton.
    static func isSupportedSport(_ sport: Sport?) -> Bool {
        sport == nil || sport?.code == supportedSportCode
    }
}
