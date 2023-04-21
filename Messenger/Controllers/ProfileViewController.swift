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
import JGProgressHUD
import SDWebImage

final class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    private var newLoginObserver: NSObjectProtocol?
    private var newRegisterObserver: NSObjectProtocol?
    private let spinner = JGProgressHUD(style: .dark)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        refreshProfile()
                
        newLoginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            print("log in observed")
            guard let view = self?.view else {
                return
            }
            self?.spinner.show(in: view)
            self?.refreshProfile()
            self?.spinner.dismiss()

            })

        
        newRegisterObserver = NotificationCenter.default.addObserver(forName: .newRegisterNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            print("register observed")
//            self?.refreshProfile()
            guard let view = self?.view else {
                return
            }
            self?.spinner.show(in: view)

            self?.tableView.tableHeaderView = self?.createTableHeader()
            self?.spinner.dismiss()

            })

        
    }
    
//    deinit {
//        if let observer = newRegisterObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//
//        if let observer = newLoginObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//    }
    
    func refreshProfile() {
        print("Name profile 1:", UserDefaults.standard.value(forKey: "name") ?? "")
        print("Email profile 1:", UserDefaults.standard.value(forKey: "email") ?? "")
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                // Logout Facebook
                FBSDKLoginKit.LoginManager().logOut()
                
                // Logout Google
                GIDSignIn.sharedInstance().signOut()
                
                do{
                    try FirebaseAuth.Auth.auth().signOut()
                    self?.data.removeAll()
                    print("Name profilee:", UserDefaults.standard.value(forKey: "name") ?? "")
                    print("Email profilee:", UserDefaults.standard.value(forKey: "email") ?? "")
                    print("dataa:", self?.data ?? [])
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true)
                } catch{
                    print("Failed to log out")
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            strongSelf.present(actionSheet, animated: true)
        }))
        print("dataaa:", self.data ?? [])


        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        tableView.reloadData()
        
    }
    
    func createTableHeader() -> UIView? {
        spinner.show(in: view)

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
        
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result{
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to download url: \(error)")
            }
        })
        self.spinner.dismiss()
        return headerView
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
      
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel){
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
            case .info:
                textLabel?.textColor = UIColor.label
                textLabel?.textAlignment = .left
                selectionStyle = .none
            case .logout:
                 textLabel?.textColor = .red
                 textLabel?.textAlignment = .center
        }
    }
}
