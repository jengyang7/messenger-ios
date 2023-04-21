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
            let newMessage = AIMessage(id: UUID(), role: .user, content: currentInput, createAt: Date())
            messages.append(newMessage)
            currentInput = ""
            
            Task {
                let response = await openAIService.sendMessage(messages: messages)
                print("response:", response)
                guard let receivedOpenAIMessage = response?.choices.first?.message else {
                    print("Had no received message")
                    return
                }
                let receivedMessage = AIMessage(id: UUID(), role: receivedOpenAIMessage.role, content: receivedOpenAIMessage.content, createAt: Date())
                await MainActor.run {
                    messages.append(receivedMessage)

                }
            }
        }
    }
}

struct AIMessage: Decodable {
    let id: UUID
    let role: SenderRole
    let content: String
    let createAt: Date
}
