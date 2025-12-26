import UIKit
import Vision

enum OCRService {
    enum OCRServiceError: Error {
        case invalidImage
    }

    static func recognizeText(in images: [UIImage], completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let text = try recognizeTextSync(in: images)
                DispatchQueue.main.async {
                    completion(.success(text))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func recognizeTextSync(in images: [UIImage]) throws -> String {
        var pageTexts: [String] = []

        for image in images {
            guard let cgImage = cgImage(from: image) else {
                throw OCRServiceError.invalidImage
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            let pageText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            if !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                pageTexts.append(pageText)
            }
        }

        return pageTexts.joined(separator: "\n\n---\n\n")
    }

    private static func cgImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage {
            return cgImage
        }

        guard let ciImage = image.ciImage else {
            return nil
        }

        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
