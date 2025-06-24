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

enum LLMIntentType: String, Codable {
    case createTask = "create_task"
    case generalConversation = "general_conversation"
    case unknown // Fallback for unexpected intent strings
}

struct LLMTaskDetails: Codable {
    let title: String
    let description: String?
}

struct LLMIntentResponse: Codable {
    let intent: LLMIntentType
    let task_details: LLMTaskDetails? // Optional because it's only for create_task
    let assistant_reply: String

    // Custom decoder to handle potential 'unknown' intent if string doesn't match known cases
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode intent, defaulting to .unknown if the string is not recognized
        if let intentString = try? container.decode(String.self, forKey: .intent),
           let knownIntent = LLMIntentType(rawValue: intentString) {
            self.intent = knownIntent
        } else {
            self.intent = .unknown // Or handle as an error if strict parsing is required
        }
        self.task_details = try container.decodeIfPresent(LLMTaskDetails.self, forKey: .task_details)
        self.assistant_reply = try container.decode(String.self, forKey: .assistant_reply)
    }

    // Define CodingKeys if necessary for mapping, especially if JSON keys differ from struct properties
    private enum CodingKeys: String, CodingKey {
        case intent
        case task_details
        case assistant_reply
    }
}

final class ClaudeLLMService {
    static let shared = ClaudeLLMService()
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiKey: String

    private static let intentDetectionSystemPrompt = """
    You are a helpful assistant. Your primary goal is to assist the user.
    First, analyze the user's message to determine if they intend to create a new task.
    A task creation request typically involves phrases like "create a task", "make a new task", "remind me to", "I need to", "add to my tasks", etc., followed by the task's subject and optionally a more detailed explanation.

    If you detect an intent to create a task:
    - Extract the task title. The title is usually the main subject of the task.
    - Extract the task description if provided. The description is any additional detail or explanation for the task. If no description is explicitly provided, you can infer a brief one if appropriate, or omit it.
    - Formulate a brief, conversational reply confirming you will create the task.
    - Then, respond ONLY with a single JSON object with the following structure:
      {
        "intent": "create_task",
        "task_details": {
          "title": "<extracted title>",
          "description": "<extracted description or null if not provided>"
        },
        "assistant_reply": "<your brief conversational confirmation>"
      }

    If you DO NOT detect an intent to create a task, or if the user's message is a follow-up to a previous turn that was not task creation:
    - Respond conversationally to the user's message.
    - Then, respond ONLY with a single JSON object with the following structure:
      {
        "intent": "general_conversation",
        "assistant_reply": "<your conversational response>"
      }

    IMPORTANT: Always try to use one of the JSON structures above in your response. Do not add any text outside of the JSON object.
    If the user asks a question or makes a statement not related to task creation, use the "general_conversation" intent.
    The task title is mandatory if intent is "create_task".
    """

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

    // New method for intent detection
    func detectIntentAndRespond(userMessageText: String, conversationHistory: [ClaudeMessage], completion: @escaping (Result<LLMIntentResponse, Error>) -> Void) {
        var messagesForClaude: [ClaudeMessage] = []

        // 1. Add the system prompt
        messagesForClaude.append(ClaudeMessage(role: "system", content: ClaudeLLMService.intentDetectionSystemPrompt))

        // 2. Add conversation history
        messagesForClaude.append(contentsOf: conversationHistory)

        // 3. Add the current user message
        messagesForClaude.append(ClaudeMessage(role: "user", content: userMessageText))

        let requestBody = ClaudeRequest(
            model: "claude-3-haiku-20240307", // Or your preferred model
            messages: messagesForClaude,
            max_tokens: 1024 // Adjust if necessary, ensure it's enough for the JSON + reply
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
                completion(.failure(NSError(domain: "ClaudeLLMService.detectIntent", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            // Debug: print the raw response for troubleshooting
            if let rawJsonResponse = String(data: data, encoding: .utf8) {
                print("Claude raw JSON response for intent detection: \(rawJsonResponse)")
            }

            do {
                let decodedResponse = try JSONDecoder().decode(LLMIntentResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch let decodingError {
                 // Attempt to see if it was a simple text response from Claude (if it failed to produce JSON)
                 // This could happen if the prompt isn't strong enough or Claude makes a mistake.
                 if let fallbackText = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !fallbackText.isEmpty {
                     print("Claude intent detection: Failed to decode JSON, but received text: \(fallbackText). Treating as general conversation.")
                     let fallbackResponse = LLMIntentResponse(intent: .generalConversation, task_details: nil, assistant_reply: fallbackText)
                     completion(.success(fallbackResponse))
                 } else {
                     print("Claude intent detection: Failed to decode JSON and no fallback text. Error: \(decodingError)")
                     completion(.failure(decodingError))
                 }
            }
        }.resume()
    }
}
