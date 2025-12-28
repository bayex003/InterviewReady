/// Central Pro gating helper.
enum ProGate: String {
    case export
    case reviewMode
    case scanNotes
    case unlimitedAnswers
    case unlimitedCustomQuestions

    var title: String {
        switch self {
        case .export:
            return "Export"
        case .reviewMode:
            return "Review Mode"
        case .scanNotes:
            return "Scan Notes"
        case .unlimitedAnswers:
            return "Unlimited answer history"
        case .unlimitedCustomQuestions:
            return "Unlimited custom questions"
        }
    }

    var inlineMessage: String {
        switch self {
        case .export:
            return "Exporting your data is a Pro feature."
        case .reviewMode:
            return "Review Mode is part of Pro."
        case .scanNotes:
            return "Scan notes into stories with Pro."
        case .unlimitedAnswers:
            return "Free keeps up to three answers per question."
        case .unlimitedCustomQuestions:
            return "Free includes up to ten custom questions."
        }
    }
}

struct ProGatekeeper {
    let isPro: () -> Bool
    let presentPaywall: () -> Void

    init(isPro: @escaping () -> Bool, presentPaywall: @escaping () -> Void) {
        self.isPro = isPro
        self.presentPaywall = presentPaywall
    }

    func requiresPro(_ gate: ProGate) -> Bool {
        _ = gate
        return !isPro()
    }

    func requirePro(_ gate: ProGate, onAllowed: () -> Void, onBlocked: (() -> Void)? = nil) {
        if isPro() {
            onAllowed()
        } else {
            onBlocked?()
            presentPaywall()
        }
    }
}
