import SwiftUI

// MARK: - Chip (missing in multiple views)
struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(title: String, isSelected: Bool = false, action: @escaping () -> Void = {}) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.ink900 : Color.ink700)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.sage100.opacity(0.55) : Color.surfaceWhite)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.sage500.opacity(0.6) : Color.ink200, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary CTA Button
struct PrimaryCTAButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    // ✅ Supports: PrimaryCTAButton(title: "Start", systemImage: "arrow.right") { ... }
    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    // ✅ Backwards compatible: PrimaryCTAButton("Start") { ... }
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = nil
        self.action = action
    }

    // ✅ Backwards compatible (older call sites): PrimaryCTAButton { ... }
    init(_ action: @escaping () -> Void) {
        self.title = "Continue"
        self.systemImage = nil
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.headline.weight(.semibold))

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.sage500)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Add Button (missing)
struct FloatingAddButton: View {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.sage500))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

// MARK: - AttemptsListView wrapper (temporary)
struct AttemptsListView: View {
    var body: some View {
        Text("Attempts History")
            .font(.title2.bold())
            .padding()

        Text("Hook this up to your real Attempt History screen.")
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }
}
