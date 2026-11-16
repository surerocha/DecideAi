//
//  HomeViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Controller da Home

/// Controller da tela inicial.
/// Responsabilidades (MVC):
/// - fornecer a view da tela (`loadView`);
/// - configurar comportamentos de navegação;
/// - conectar eventos da view (callbacks) a ações (navegar).
///
/// Não cria componentes visuais detalhados; isso fica em `HomeView`.
final class HomeViewController: UIViewController {

    // Instância da view customizada da Home.
    private let homeView = HomeView()

    // MARK: - Ciclo de vida da view

    /// Chamado quando o controller precisa criar sua `view`.
    /// Aqui substituímos a view padrão por `homeView`.
    /// Esse padrão mantém a separação: View cuida da UI, Controller coordena.
    override func loadView() {
        view = homeView
    }

    /// Chamado após a view ser carregada em memória.
    /// Usado para configurações iniciais que dependem da view já existente.
    override func viewDidLoad() {
        super.viewDidLoad()

        // Define o título do botão "voltar" exibido nas telas empilhadas depois desta.
        // Como a Home não define `title`, sem isso o botão poderia aparecer como "Back".
        navigationItem.backButtonTitle = "Início"

        // Conecta o evento da view à navegação.
        // `[weak self]` evita ciclo de retenção caso a view mantenha a closure e o controller mantenha a view.
        homeView.onStartTapped = { [weak self] in
            self?.showDecisionScreen()
        }
    }

    // MARK: - Navegação

    /// Empilha a tela de criação de decisão no `UINavigationController`.
    private func showDecisionScreen() {
        // `pushViewController` adiciona o controller ao topo da pilha.
        // `animated: true` aplica a animação padrão de transição.
        // `navigationController` é opcional (nil se o controller não estiver em uma pilha).
        navigationController?.pushViewController(DecisionViewController(), animated: true)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, muitas vezes não há um "ViewController" explícito: a própria `View` declara
 estado e navegação. Ainda assim, podemos separar responsabilidades (View + ViewModel).

 import SwiftUI

 struct HomeScreen: View {
     @State private var showDecision = false

     var body: some View {
         HomeView {
             // Dispara navegação (equivalente ao push).
             showDecision = true
         }
         .navigationTitle("") // Home sem título grande, se desejado
         .navigationDestination(isPresented: $showDecision) {
             DecisionScreen()
         }
     }
 }

 // O equivalente ao backButtonTitle pode ser configurado com:
 // .navigationTitle("Início") na tela anterior em alguns casos,
 // ou com toolbar/navigationBarBackButtonHidden + botão customizado quando necessário.

 Diferenças principais:
 - Navegação declarativa via estado (`isPresented`, `path`) em vez de push imperativo.
 - O ciclo de vida do controller (loadView/viewDidLoad) não existe da mesma forma.
*/
