import SwiftUI

extension Color {
    static func forSport(_ code: String?) -> Color {
        switch code {
        case "badminton":    return .blue
        case "climbing":     return .orange
        case "tennis":       return .green
        case "table_tennis": return .red
        default:             return Color(.systemGray)
        }
    }

    static func forSessionType(_ type: String) -> Color {
        switch type {
        case "game":     return .blue
        case "training": return .green
        case "gym":      return .yellow
        case "mobility": return .mint
        case "recovery": return .purple
        case "mixed":    return .indigo
        default:         return Color(.systemGray)
        }
    }

    static func forRPE(_ value: Int) -> Color {
        switch value {
        case 1...3:  return .green
        case 4...6:  return .yellow
        case 7...8:  return .orange
        case 9...10: return .red
        default:     return Color(.systemGray)
        }
    }
}
