import SwiftUI
import UIKit
#if canImport(VisionKit)
import VisionKit
#endif

struct DocumentScannerView: View {
    let onSuccess: ([UIImage]) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void

    var body: some View {
        #if canImport(VisionKit)
        if VNDocumentCameraViewController.isSupported {
            DocumentCameraRepresentable(onSuccess: onSuccess, onCancel: onCancel, onError: onError)
        } else {
            fallbackView
        }
        #else
        fallbackView
        #endif
    }

    private var fallbackView: some View {
        VStack(spacing: 20) {
            Text("Document scanner is not available on this device.")
                .multilineTextAlignment(.center)
            Button("Close") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#if canImport(VisionKit)
private struct DocumentCameraRepresentable: UIViewControllerRepresentable {
    let onSuccess: ([UIImage]) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess, onCancel: onCancel, onError: onError)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onSuccess: ([UIImage]) -> Void
        let onCancel: () -> Void
        let onError: (Error) -> Void

        init(onSuccess: @escaping ([UIImage]) -> Void,
             onCancel: @escaping () -> Void,
             onError: @escaping (Error) -> Void) {
            self.onSuccess = onSuccess
            self.onCancel = onCancel
            self.onError = onError
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                images.append(image)
            }
            onSuccess(images)
            // Do NOT dismiss controller here; dismissal handled by SwiftUI sheet
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
            // Do NOT dismiss controller here; dismissal handled by SwiftUI sheet
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onError(error)
            // Do NOT dismiss controller here; dismissal handled by SwiftUI sheet
        }
    }
}
#endif

struct DocumentScannerView_Previews: PreviewProvider {
    static var previews: some View {
        // Force fallback path by ignoring VisionKit on simulator or showing fallback explicitly
        DocumentScannerView(
            onSuccess: { _ in },
            onCancel: {},
            onError: { _ in }
        )
    }
}
