//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Jayden Kong on 07/01/2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Log Out"]
    private var newLoginObserver: NSObjectProtocol?
    private var newRegisterObserver: NSObjectProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshProfilePicture()
        
        newRegisterObserver = NotificationCenter.default.addObserver(forName: .newLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            self?.refreshProfilePicture()
        })
        
        newLoginObserver = NotificationCenter.default.addObserver(forName: .newRegisterNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            self?.refreshProfilePicture()
        })
    }
    
    deinit {
        if let observer = newRegisterObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = newLoginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func refreshProfilePicture() {
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = safeEmail + "_profile_picture.png"
        
        let path = "image/" + filename
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150) / 2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            print("path: ", path)
            switch result{
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to download url: \(error)")
            }
        })
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
                self.tableView.reloadData()
            }
        }).resume()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            // Logout Facebook
            FBSDKLoginKit.LoginManager().logOut()
            
            // Logout Google
            GIDSignIn.sharedInstance().signOut()
            
            do{
                try FirebaseAuth.Auth.auth().signOut()
                
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
            } catch{
                print("Failed to log out")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
}
