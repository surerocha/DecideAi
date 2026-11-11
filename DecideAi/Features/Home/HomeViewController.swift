//
//  HomeViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

final class HomeViewController: UIViewController {

    private let homeView = HomeView()

    // Padrão MVC com UIView própria: o controller troca a view raiz por uma
    // view nossa. Assim o controller não cria subviews, só coordena.
    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Esta propriedade define o texto do botão "voltar" das telas seguintes.
        // Sem ela, apareceria "Back", já que a Home não tem título.
        navigationItem.backButtonTitle = "Início"

        homeView.onStartTapped = { [weak self] in
            self?.showDecisionScreen()
        }
    }

    private func showDecisionScreen() {
        // push empilha a nova tela; a animação e o gesto de voltar vêm de graça.
        navigationController?.pushViewController(DecisionViewController(), animated: true)
    }
}
