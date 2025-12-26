import SwiftUI
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// ✅ Use on Forms/Lists safely:
    /// - scroll-to-dismiss works
    /// - no background tap gesture (so Picker/TextField never break)
    func formKeyboardBehavior() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
    }

    /// ✅ Use on NON-Form screens only (plain ScrollView/VStack screens).
    /// This will NOT fire inside Forms/Lists to avoid breaking Pickers/TextFields.
    func tapToDismissKeyboard() -> some View {
        self
            .background(KeyboardDismissBackground())
            .scrollDismissesKeyboard(.interactively)
    }
}

private struct KeyboardDismissBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func handleTap() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // If tap happened inside any Form/List (UITableView/UICollectionView), ignore it completely.
            var v: UIView? = touch.view
            while let view = v {
                let name = NSStringFromClass(type(of: view))

                if view is UIControl || view is UITextView || view is UITextField {
                    return false
                }

                // Forms & Lists are backed by UITableView / UICollectionView
                if view is UITableView || view is UICollectionView || name.contains("UITableView") || name.contains("UICollectionView") {
                    return false
                }

                // Also ignore taps inside table/collection cells (private classes on newer iOS)
                if name.contains("Cell") || name.contains("CellContentView") {
                    return false
                }

                v = view.superview
            }

            // Otherwise (plain background area), allow tap-to-dismiss.
            return true
        }
    }
}
