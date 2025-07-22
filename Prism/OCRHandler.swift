import Vision
import AppKit

func performOCR(on image: CGImage, completion: @escaping (String?) -> Void) {
    let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
    let request = VNRecognizeTextRequest { (request, error) in
        if let error = error {
            print("OCR Error: \(error)")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            DispatchQueue.main.async { completion("") }
            return
        }
        
        let recognizedStrings = observations.compactMap { obs in
            obs.topCandidates(1).first?.string
        }
        let combinedString = recognizedStrings.joined(separator: "\n")
        DispatchQueue.main.async {
            completion(combinedString)
        }
    }
    
    // Accurate パスを使う
    request.revision = VNRecognizeTextRequestRevision3
    request.recognitionLevel = .accurate
    
    // 日本語と英語の混在をサポート
    // Apple がサポートしている言語リストを取得してもよいですが、ここでは明示的に指定
    request.recognitionLanguages = ["ja-JP", "en-US"]
    
    // 言語補正を有効化（日本語にも適用されます）
    request.usesLanguageCorrection = true

    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform OCR request: \(error)")
            DispatchQueue.main.async { completion(nil) }
        }
    }
}
