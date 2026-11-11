//
//  SceneDelegate.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // O sistema exige que o SceneDelegate guarde a janela do app.
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Sem storyboard, somos nós que criamos a janela em código.
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.tintColor = Theme.Color.accent

        // O UINavigationController gerencia a pilha de telas e a barra de navegação.
        // O root é a Home; as outras telas entram com push.
        let navigationController = UINavigationController(rootViewController: HomeViewController())

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
