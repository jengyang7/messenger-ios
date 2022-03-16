//
//  ViewController.swift
//  Messenger
//
//  Created by Jayden Kong on 06/01/2022.
//

import UIKit
import Firebase

class ConversationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .red
        
//        DatabaseManager.shared.test()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        validateAuth()
    }
    
    private func validateAuth(){
        print("user:", FirebaseAuth.Auth.auth().currentUser)
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    
}

