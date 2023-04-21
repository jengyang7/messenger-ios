//
//  OpenAIService.swift
//  Messenger
//
//  Created by Jayden Kong on 20/04/2023.
//

import Foundation
import Alamofire

class OpenAIService {
    private let endpointURL = "https://api.openai.com/v1/chat/completions"
    
    func sendMessage(messages: [AIMessage]) async -> OpenAIChatResponse? {
        let openAIMessages = messages.map({OpenAIChatMessage(role: $0.role, content: $0.content)})
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages, stream: false)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)"
        ]
        return try? await AF.request(endpointURL, method: .post, parameters: body, encoder: .json, headers: headers).serializingDecodable(OpenAIChatResponse.self).value
    }
    
    func sendStreamMessage(messages: [AIMessage]) -> DataStreamRequest{
           let openAIMessages = messages.map({OpenAIChatMessage(role: $0.role, content: $0.content)})

           let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages, stream: true)
           let headers: HTTPHeaders = [
               "Authorization": "Bearer \(Constants.openAIAPIKey)"
           ]
           return AF.streamRequest(endpointURL, method: .post, parameters: body, encoder: .json, headers: headers)
       }
}


struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let stream: Bool

}

struct OpenAIChatMessage: Codable {
    let role: SenderRole
    let content: String
}

enum SenderRole: String, Codable {
    case system
    case user
    case assistant
}

struct OpenAIChatResponse: Decodable {
    let choices: [OpenAIChatChoice]
}

struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatMessage
}
