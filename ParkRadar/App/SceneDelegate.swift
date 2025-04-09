//
//  SceneDelegate.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let targetVC = MapViewController(viewModel: DIContainer.shared.makeMapViewModel())
        window?.rootViewController = UINavigationController(rootViewController: targetVC)
        window?.makeKeyAndVisible()
    }
}

