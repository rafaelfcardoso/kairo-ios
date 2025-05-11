import Foundation

struct ClaudeMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String // e.g., "claude-3-haiku-20240307"
    let messages: [ClaudeMessage]
    let max_tokens: Int
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

final class ClaudeLLMService {
    static let shared = ClaudeLLMService()
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiKey: String

    private init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String else {
            fatalError("Claude API key not found in Info.plist")
        }
        self.apiKey = key
    }

    func sendMessage(_ userMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        let requestBody = ClaudeRequest(
            model: "claude-3-haiku-20240307",
            messages: [ClaudeMessage(role: "user", content: userMessage)],
            max_tokens: 1024
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }


        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "ClaudeLLMService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            // Debug: print the raw response for troubleshooting
            if let raw = String(data: data, encoding: .utf8) {
                print("Claude raw response: \(raw)")
            }
            do {
                let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
                let reply = decoded.content.first?.text ?? ""
                completion(.success(reply))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// Generate a concise title for a chat session based on conversation history
    /// - Parameters:
    ///   - messages: The conversation history as ClaudeMessage (user and assistant turns)
    ///   - completion: Completion handler with the generated title or error
    func generateTitleForChatSession(messages: [ClaudeMessage], completion: @escaping (Result<String, Error>) -> Void) {
        // Combine instruction and conversation into a single user prompt
        let instruction = "Given the following conversation, generate a concise and descriptive title (max 8 words) that summarizes the main topic. Respond with only the title and nothing else."
        let conversation = messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n\n")
        let prompt = instruction + "\n\n" + conversation
        // Delegate to sendMessage to avoid unsupported roles
        sendMessage(prompt) { result in
            switch result {
            case .success(let reply):
                let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
                completion(.success(trimmed))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
