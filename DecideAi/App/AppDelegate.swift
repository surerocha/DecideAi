//
//  AppDelegate.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Ponto de entrada (processo do app)

/// `@main` indica ao sistema qual tipo é o ponto de entrada do aplicativo.
/// Em projetos UIKit com cenas (iOS 13+), o `AppDelegate` cuida de eventos do
/// processo/aplicativo e da configuração das sessões de cena.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Lançamento do app

    /// Chamado quando o app termina de iniciar.
    /// Aqui costumamos configurar serviços globais (analytics, aparência, etc.).
    /// Neste projeto, não há configuração extra no lançamento, então retornamos `true`.
    ///
    /// - Parameters:
    ///   - application: instância singleton do aplicativo.
    ///   - launchOptions: informações sobre o motivo do lançamento (notificação, URL, etc.).
    /// - Returns: `true` para indicar que a inicialização foi concluída com sucesso.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Ponto de customização após o lançamento (nenhuma configuração adicional aqui).
        return true
    }

    // MARK: - Ciclo de vida das cenas (UISceneSession)

    /// Chamado quando o sistema cria uma nova sessão de cena.
    /// Retorna a configuração que descreve qual "scene" usar (definida no Info.plist/target).
    /// Com essa configuração, o sistema instancia o `SceneDelegate` correspondente.
    ///
    /// - Parameters:
    ///   - application: instância do aplicativo.
    ///   - connectingSceneSession: sessão de cena sendo criada.
    ///   - options: opções de conexão (ex.: atividade do usuário).
    /// - Returns: configuração da cena a ser criada.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // "Default Configuration" está associada ao SceneDelegate no Info.plist.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Chamado quando o usuário/sistema descarta sessões de cena.
    /// Útil para liberar recursos específicos de cenas descartadas.
    /// Não há recursos por cena para liberar neste app.
    ///
    /// - Parameters:
    ///   - application: instância do aplicativo.
    ///   - sceneSessions: conjunto de sessões descartadas.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Nenhum recurso específico de cena para liberar.
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI (iOS 14+), o ciclo de vida do app costuma ser declarativo com `@main` em um `App`.
 A criação da janela e da tela inicial é feita com `WindowGroup`, sem `AppDelegate/SceneDelegate`
 para casos simples. Quando precisamos integrar APIs do UIKit, podemos usar adaptadores.

 import SwiftUI

 // Ponto de entrada do app em SwiftUI.
 @main
 struct DecideAiApp: App {

     // Se fosse necessário acessar callbacks do AppDelegate (push, etc.), poderíamos adaptar:
     // @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

     var body: some Scene {
         // WindowGroup cria e gerencia a janela principal.
         WindowGroup {
             // Tela raiz do app (equivalente ao rootViewController).
             // NavigationStack substitui o UINavigationController para navegação em pilha.
             NavigationStack {
                 HomeView() // versão SwiftUI da Home
             }
             // Cor de destaque global (equivalente ao window.tintColor).
             .tint(.indigo)
         }
     }
 }

 Observação: neste projeto UIKit, AppDelegate + SceneDelegate fazem o papel de configurar
 processo e cena/janela; em SwiftUI puro, `App` + `WindowGroup` concentram isso.
*/
