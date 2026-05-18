import Foundation

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
    let safetySettings: [GeminiSafetySetting]

    init(prompt: String) {
        self.contents = [GeminiContent(parts: [GeminiPart(text: prompt)])]
        self.generationConfig = GeminiGenerationConfig(temperature: 0.7, maxOutputTokens: 1024, topP: 0.95, topK: 40)
        self.safetySettings = [
            GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
            GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
            GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_LOW_AND_ABOVE"),
            GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
        ]
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    let topK: Int
}

struct GeminiSafetySetting: Encodable {
    let category: String
    let threshold: String
}

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent
    let finishReason: String?
}
