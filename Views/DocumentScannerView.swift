// Manual test checklist:
// - Scan -> OCR -> insert -> field updates once only
// - Tapping Insert repeatedly doesn’t duplicate
// - Empty/garbage OCR output disables Insert
// - While processing, Scan Notes can’t be triggered again
// - Simulator shows friendly message, no crash
import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let onSuccess: ([UIImage]) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        if VNDocumentCameraViewController.isSupported {
            let controller = VNDocumentCameraViewController()
            controller.delegate = context.coordinator
            return controller
        }

        let controller = UIViewController()
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Scanner unavailable",
                message: "Document scanning isn't available on Simulator. Please test Scan Notes on a real iPhone.",
                preferredStyle: .alert
            )
            if let themeColor = UIColor(named: "sage500") {
                alert.view.tintColor = themeColor
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                onCancel()
            })
            controller.present(alert, animated: true)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess, onCancel: onCancel, onError: onError)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onSuccess: ([UIImage]) -> Void
        private let onCancel: () -> Void
        private let onError: (Error) -> Void

        init(onSuccess: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void, onError: @escaping (Error) -> Void) {
            self.onSuccess = onSuccess
            self.onCancel = onCancel
            self.onError = onError
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onError(error)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for index in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: index))
            }
            onSuccess(images)
        }
    }
}
