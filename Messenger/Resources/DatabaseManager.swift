//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Jayden Kong on 16/03/2022.
//

import Foundation
import Firebase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    //    public func test(){
    //        database.child("foo").setValue(["something": true])
    //    }
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: - Account Manager

extension DatabaseManager{
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    /// Inserts new user to database
    public func insert(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            
            "first_name": user.firstName,
            "last_name": user.lastName
            
        ], withCompletionBlock: {error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            /*
             users => [
             [
             "name":
             "safe_email":
             ],
             [
             "name":
             "safe_email":
             ]
             ]
             */
            
            
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String : String]] {
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                    
                } else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
}

// MARK: - Sending messages / conversation

extension DatabaseManager {
    
    /*
     
     "fasdfasdf" {
     "message": [
     {
     "id": String,
     "type": text, photo, video
     "content": String
     "date": Date(),
     "sender_email": String,
     "isRead": true/false,
     }
     ]
     }
     
     
     conversation => [          //every user have a conversation key with array of conversation object
     [
     "conversation_id":
     "other_user_email":
     "latest_message": => {
     "date": Date()
     "latest_message": "message"
     "is_read": true/false
     }
     ],
     ]
     
     */
    
    
    // Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else{
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "latest_message": [],
                "date": dateString,
                "message": message,
                "is_read": false,
            ]
            
            if var conversation = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                
                conversation.append(newConversationData)
                userNode["conversations"] = conversation
                ref.setValue(userNode, withCompletionBlock: {  [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    
                    
                })
                
            }else {
                // conversation does not exist
                // create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                })
            }
            
        })
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping(Bool) -> Void ){
        
        //            {
        //               "id": String,
        //                "type": text, photo, video
        //                "content": String
        //                "date": Date(),
        //                "sender_email": String,
        //                "isRead": true/false,
        //           }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "message": [
                collectionMessage
            ]
        ]
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    
    // Fetches and returns all conversations for the user with passed in email
    public func getAllConversation(for email: String, completion: @escaping (Result<String, Error>) -> Void){
        return
    }
    
    // Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completixon: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    // Send a message with target conversation and message
    public func sendMessage(to conversation:String, message: Message, completion: @escaping (Bool) -> Void){
        
    }
    
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        // jengyang-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
