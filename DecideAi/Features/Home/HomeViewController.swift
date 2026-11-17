//
//  HomeViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Controller da Home

/// Controller da tela inicial. Coordena navegação e aparência da barra na Home
/// (a Home usa visual imersivo com gradiente, então a navigation bar fica oculta).
final class HomeViewController: UIViewController {

    private let homeView = HomeView()

    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Texto do botão "voltar" nas telas seguintes.
        navigationItem.backButtonTitle = "Início"
        homeView.onStartTapped = { [weak self] in
            self?.showDecisionScreen()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Home em tela cheia com gradiente: esconde a barra para seguir o protótipo.
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restaura a barra para as próximas telas.
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Navegação

    private func showDecisionScreen() {
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
