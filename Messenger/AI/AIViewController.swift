//
//  AIViewController.swift
//  Messenger
//
//  Created by Jayden Kong on 20/04/2023.
//

import UIKit
import SwiftUI

class AIViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a SwiftUI view
        let mySwiftUIView = AIChatView()
        
        // Embed the SwiftUI view in a UIHostingController
        let hostingController = UIHostingController(rootView: mySwiftUIView)
        
        // Add the hosting controller's view as a subview to the existing view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Set the frame of the hosting controller's view to match the view controller's bounds
        hostingController.view.frame = view.bounds
        
        // Notify the hosting controller that it has been moved to a parent view controller
        hostingController.didMove(toParent: self)
    }
    
    
}

struct AIChatView: View {
    @ObservedObject var viewModel = ViewModel()
    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages.filter({$0.role != .system}), id: \.id) { message in
                    messageView(message: message)
                }
            }
            HStack {
                TextField("Enter a messages...", text: $viewModel.currentInput)
                Button {
                    viewModel.sendMessage()
                } label: {
                    Text("Send")
                }
            }
            
        }
        .padding()
    }
    
    func messageView(message: AIMessage) -> some View {
        HStack {
            if message.role == .user { Spacer()}
            Text(message.content)
                .padding()
                .foregroundColor(message.role == .user ? Color.white : Color.black)
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(8)
            if message.role == .assistant { Spacer()}
                
        }
    }
}
