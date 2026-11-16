//
//  SceneDelegate.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Cena e janela (UI inicial sem Storyboard)

/// `SceneDelegate` gerencia o ciclo de vida de uma "cena" (instância de UI) do app.
/// Como o projeto não usa Storyboard para a interface principal, este é o lugar
/// onde criamos a `UIWindow`, definimos o `rootViewController` e tornamos a janela visível.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // A janela principal da cena.
    // O sistema mantém referência à cena, mas a propriedade `window` é necessária
    // para que o app (e o UIKit) saiba qual janela está sendo exibida.
    var window: UIWindow?

    /// Chamado quando a cena está sendo conectada ao app (momento de configurar a UI).
    /// Aqui montamos a hierarquia inicial: Janela -> NavigationController -> Home.
    ///
    /// - Parameters:
    ///   - scene: cena fornecida pelo sistema (pode ser de vários tipos; queremos `UIWindowScene`).
    ///   - session: sessão associada à cena.
    ///   - connectionOptions: contexto da conexão (atalhos, atividades, etc.).
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Garantimos que a cena é uma cena de janela (UI). Se não for, não há UI para montar.
        guard let windowScene = scene as? UIWindowScene else { return }

        // Cria a janela vinculada à cena recebida.
        let window = UIWindow(windowScene: windowScene)

        // Define a cor de destaque (tint) global dos controles interativos.
        window.tintColor = Theme.Color.accent

        // UINavigationController gerencia navegação em pilha:
        // - mantém uma lista de view controllers;
        // - mostra barra de navegação e botão de voltar;
        // - `push` coloca uma tela no topo, `pop` volta.
        // A Home é a raiz (primeira tela).
        let navigationController = UINavigationController(rootViewController: HomeViewController())

        // Define o controller raiz da janela e a torna a janela principal/visível.
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        // Guarda a referência na propriedade exigida pelo delegate.
        self.window = window
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, não criamos manualmente `UIWindow` nem `UINavigationController` para o fluxo básico.
 O `WindowGroup` fornece a janela e o `NavigationStack` fornece a navegação em pilha.

 import SwiftUI

 @main
 struct DecideAiApp: App {
     var body: some Scene {
         WindowGroup {
             NavigationStack {
                 // Equivalente à root HomeViewController.
                 HomeView()
             }
             // Equivalente ao window.tintColor.
             .tint(.indigo)
         }
     }
 }

 // Navegar para outra tela (equivalente ao pushViewController):
 // NavigationStack {
 //     HomeView()
 //         .navigationDestination(isPresented: $mostrarCriacao) {
 //             DecisionView()
 //         }
 // }
 // ou usando NavigationLink / navigationDestination(for:).
*/
