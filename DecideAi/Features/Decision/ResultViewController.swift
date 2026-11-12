//
//  ResultViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Controller da tela de resultado.
/// Responsabilidade: receber o plano de sorteio já definido e exibi-lo.
/// O vencedor é decidido uma única vez pelo DecisionService (DrawPlan),
/// então esta tela não realiza um novo sorteio.
final class ResultViewController: UIViewController {

    // View específica desta tela.
    private let resultView = ResultView()

    // Dados recebidos da tela de criação: pergunta exibida e plano do sorteio.
    private let question: String
    private let plan: DrawPlan

    // Recebemos os dados no init para garantir que a tela sempre tenha
    // um resultado válido ao ser apresentada.
    init(question: String, plan: DrawPlan) {
        self.question = question
        self.plan = plan
        super.init(nibName: nil, bundle: nil)
    }

    // Obrigatório ao implementar init customizado em UIViewController.
    // Não usamos Storyboards/XIBs neste projeto.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Substitui a view raiz pela nossa view em código (padrão MVC usado no app).
    override func loadView() {
        view = resultView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Resultado"

        // Exibe a pergunta e o vencedor vindo do DrawPlan (último frame = vencedor).
        resultView.configure(question: question, winner: plan.winner)
    }
}
