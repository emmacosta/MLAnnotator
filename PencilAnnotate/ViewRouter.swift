//
//  ViewRouter.swift
//  PencilAnnotate
//

import SwiftUI

@MainActor
class ViewRouter: ObservableObject {
    @Published var currentPage: Page = UserDefaults.standard.string(forKey: "user") == nil ? .login : .home
    @Published var transitionHome: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    @Published var transitionImage: AnyTransition = .asymmetric(insertion:  .move(edge: .trailing), removal: .move(edge: .trailing))
    @Published var changing: Bool = false
    
}

enum Page {
    case home
    case image
    case changing
    case login
    case done
    
}


