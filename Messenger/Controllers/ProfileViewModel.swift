//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Jayden Kong on 19/04/2023.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
