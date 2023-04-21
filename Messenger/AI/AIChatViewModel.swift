//
//  AIChatViewModel.swift
//  Messenger
//
//  Created by Jayden Kong on 20/04/2023.
//

import Foundation

extension AIChatView {
    class ViewModel: ObservableObject{
        @Published var messages: [AIMessage] = []
        
        @Published var currentInput: String = ""
        
        private let openAIService = OpenAIService()
        
        func sendMessage() {
            let newMessage = AIMessage(id: UUID().uuidString, role: .user, content: currentInput, createAt: Date())
            messages.append(newMessage)
            currentInput = ""
            
//                        Task {
//                            let response = await openAIService.sendMessage(messages: messages)
////                            print("response:", response)
//                            guard let receivedOpenAIMessage = response?.choices.first?.message else {
//                                print("Had no received message")
//                                return
//                            }
//                            let receivedMessage = AIMessage(id: UUID().uuidString, role: receivedOpenAIMessage.role, content: receivedOpenAIMessage.content, createAt: Date())
//                            await MainActor.run {
//                                messages.append(receivedMessage)
//
//                            }
////                            print("messagess:", messages)
//                        }
            openAIService.sendStreamMessage(messages: messages).responseStreamString{ [weak self] stream in
                guard let self = self else {
                    return
                }

                switch stream.event {
                case .stream(let response):
                    switch response {
                    case .success(let string):
                        let streamResponse = self.parseStreamData(string)
                        print(streamResponse)

                        streamResponse.forEach{ newMessageResponse in

                            guard let messageContent = newMessageResponse.choices.first?.delta.content else {
                                return
                            }

                            guard let existingMessageIndex = self.messages.lastIndex(where: {$0.id == newMessageResponse.id}) else {
                                let newMessage = AIMessage(id: newMessageResponse.id, role: .assistant, content: messageContent, createAt: Date())
                                print("newMessage1:", newMessage.content)

                                self.messages.append(newMessage)
                                return
                            }
                            let newMessage = AIMessage(id: newMessageResponse.id, role: .assistant, content: self.messages[existingMessageIndex].content + messageContent, createAt: Date())
                            self.messages[existingMessageIndex] = newMessage

                        }


                    case .failure(_):
                        print("Something failed")
                    }
                    print(response)
                case .complete(_):
                    print("COMPLETE")
                }
            }
            
        }
        
        func parseStreamData(_ data: String) -> [ChatStreamCompletionResponse] {
            let responseStrings = data.split(separator: "data:").map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).filter({!$0.isEmpty})
            let jsonDecoder = JSONDecoder()
            
            return responseStrings.compactMap{ jsonString in
                guard let jsonData = jsonString.data(using: .utf8), let streamResponse = try? jsonDecoder.decode(ChatStreamCompletionResponse.self, from: jsonData)
                else {
                    return nil
                }
                return streamResponse
            }
        
        }
    }
}

struct AIMessage: Decodable {
    let id: String
    let role: SenderRole
    let content: String
    let createAt: Date
}

struct ChatStreamCompletionResponse: Decodable {
    let id: String
    let choices: [ChatStreamChoice]
}

struct ChatStreamChoice: Decodable {
    let delta: ChatStreamContent
}

struct ChatStreamContent: Decodable{
    let content: String
}
