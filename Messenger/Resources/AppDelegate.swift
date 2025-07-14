//
//  AppDelegate.swift
//  Messenger
//
//  Created by Jayden Kong on 06/01/2022.
//


// AppDelegate.swift
import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        
        let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0)]
        UITabBarItem.appearance().setTitleTextAttributes(systemFontAttributes, for: .normal)
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return true }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - Google Sign-In Helper

extension AppDelegate {
    
    static func handleGoogleSignIn(result: Result<GIDGoogleUser, Error>) {
        switch result {
        case .success(let user):
            print("Did sign in with Google: \(user)")
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else {
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            
            DatabaseManager.shared.userExists(with: email, completion:  { exist in
                if !exist{
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)

                    // insert to database
                    DatabaseManager.shared.insert(with: chatUser, completion: {success in
                        // upload image
                        
                        if user.profile?.hasImage == true {
                            guard let url = user.profile?.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: {data, _, _ in
                                guard let data = data else {
                                    return
                                }
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            
            guard
                let idToken = user.idToken?.tokenString
            else {
                print("Missing auth object off of google user")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
                guard authResult != nil, error == nil else {
                    print("failed to log in with google credential")
                    return
                }
                print("Successfully signed in with Google cred.")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            })
            
        case .failure(let error):
            print("Failed to sign in with Google: \(error)")
        }
    }
}


