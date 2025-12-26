import UIKit
import Vision

enum OCRService {

    enum OCRServiceError: LocalizedError {
        case invalidImage
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Couldn’t read the scanned image."
            case .noTextFound:
                return "No readable text was found. Try scanning in better light or closer to the page."
            }
        }
    }

    static func recognizeText(in images: [UIImage], completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let text = try recognizeTextSync(in: images)
                DispatchQueue.main.async { completion(.success(text)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Core OCR

    private static func recognizeTextSync(in images: [UIImage]) throws -> String {
        var pageTexts: [String] = []

        for image in images {
            guard let cgImage = cgImage(from: image) else {
                throw OCRServiceError.invalidImage
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en_GB", "en_US"] // helps UK spellings too

            // Optional: if you find it missing small handwriting, lower this slightly.
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            let rawPageText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            let cleanedPageText = cleanText(rawPageText)
            if !cleanedPageText.isEmpty {
                pageTexts.append(cleanedPageText)
            }
        }

        let combined = pageTexts.joined(separator: "\n\n---\n\n")
        let final = cleanText(combined)

        // If we filtered everything out as garbage, treat as “no text”
        if final.isEmpty {
            throw OCRServiceError.noTextFound
        }

        return final
    }

    private static func cgImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage { return cgImage }
        guard let ciImage = image.ciImage else { return nil }
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }

    // MARK: - Cleaning + “garbage” detection

    static func cleanText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "" }

        // Normalise line endings + whitespace
        cleaned = cleaned.replacingOccurrences(of: "\r\n", with: "\n")
        cleaned = cleaned.replacingOccurrences(of: "\r", with: "\n")
        cleaned = cleaned.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\t+", with: " ", options: .regularExpression)

        // Split into lines and drop obvious junk lines
        var lines = cleaned
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        lines = lines.filter { line in
            guard !line.isEmpty else { return false }

            // Remove lines that are mostly punctuation/symbols
            let alphaNumCount = line.filter { $0.isLetter || $0.isNumber }.count
            let totalCount = line.count
            if totalCount >= 6 {
                let ratio = Double(alphaNumCount) / Double(totalCount)
                if ratio < 0.25 { return false }
            }

            // Remove very short “noise” like "|" "-" "___" etc.
            if line.count <= 2 { return false }

            return true
        }

        // Re-join and collapse excessive blank lines
        cleaned = lines.joined(separator: "\n")
        cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Final gate: if the whole thing looks like garbage, return empty
        if looksLikeGarbage(cleaned) {
            return ""
        }

        return cleaned
    }

    private static func looksLikeGarbage(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        // Too short overall
        if trimmed.count < 25 { return true }

        // Must have some “real” words
        let words = trimmed
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        if words.count < 4 { return true }

        // Require a reasonable letter/number ratio
        let alphaNum = trimmed.filter { $0.isLetter || $0.isNumber }.count
        let total = trimmed.count
        let ratio = Double(alphaNum) / Double(max(total, 1))
        if ratio < 0.35 { return true }

        return false
    }
}

