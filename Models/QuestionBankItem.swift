// File: InterviewReady/Models/QuestionBankItem.swift
import Foundation
import SwiftData

enum QuestionCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case behavioral
    case technical
    case leadership
    case general

    var id: String { rawValue }

    /// UK English labels for UI
    var title: String {
        switch self {
        case .behavioral: return "Behavioural"
        case .technical: return "Technical"
        case .leadership: return "Leadership"
        case .general: return "General"
        }
    }

    /// Helps map old/free-text category strings into these cases
    static func from(_ raw: String) -> QuestionCategory {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if s.contains("behav") || s.contains("behav") || s.contains("competenc") {
            return .behavioral
        }
        if s.contains("tech") || s.contains("system") || s.contains("coding") {
            return .technical
        }
        if s.contains("lead") || s.contains("manage") || s.contains("stakeholder") {
            return .leadership
        }
        if s.isEmpty { return .general }

        // Fallback: try exact matches
        switch s {
        case "behavioural", "behavioral": return .behavioral
        case "technical": return .technical
        case "leadership": return .leadership
        default: return .general
        }
    }
}

/// Lightweight item used by PracticeSessionView (keeps the redesign code stable)
struct QuestionBankItem: Identifiable, Hashable {
    let id: UUID
    let text: String
    let category: QuestionCategory
    let isCustom: Bool

    init(
        id: UUID = UUID(),
        text: String,
        category: QuestionCategory,
        isCustom: Bool = false
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.isCustom = isCustom
    }

    init(_ question: Question) {
        self.id = question.id
        self.text = question.text
        self.category = QuestionCategory.from(question.category)
        self.isCustom = question.isCustom
    }

    static let empty = QuestionBankItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
        text: "No question selected",
        category: .general,
        isCustom: false
    )
}
