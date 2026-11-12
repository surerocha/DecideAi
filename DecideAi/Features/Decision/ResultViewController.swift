//
//  ResultViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Controller da tela de resultado.
/// Responsabilidade: exibir o resultado do sorteio e coordenar ações pós-resultado.
/// - "Sortear novamente": gera um novo DrawPlan com a mesma decisão (cópia) e atualiza a tela.
/// - "Nova decisão": volta ao início do app.
/// O vencedor de cada sorteio é decidido uma única vez pelo DecisionService.
final class ResultViewController: UIViewController {

    // View específica desta tela.
    private let resultView = ResultView()

    // Cópia da decisão usada neste fluxo (pergunta e opções no momento do sorteio).
    // "Sortear novamente" usa esta cópia; a tela de criação mantém seu próprio estado.
    private let decision: Decision

    // Plano atual do sorteio exibido na tela.
    private var plan: DrawPlan

    // Serviço usado para gerar novos sorteios a partir da mesma decisão.
    private let decisionService = DecisionService()

    // Recebemos os dados no init para garantir que a tela sempre tenha
    // um resultado válido ao ser apresentada.
    init(question: String, decision: Decision, plan: DrawPlan) {
        self.decision = decision
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

        // Exibe a pergunta e o vencedor do sorteio inicial.
        resultView.configure(question: decision.displayQuestion, winner: plan.winner)

        bindViewActions()
    }

    // MARK: - Ligações View -> Controller

    private func bindViewActions() {
        resultView.onTryAgainTapped = { [weak self] in
            self?.drawAgain()
        }

        resultView.onNewDecisionTapped = { [weak self] in
            self?.startNewDecision()
        }
    }

    // MARK: - Ações

    /// Gera um novo sorteio com a mesma decisão e atualiza apenas a tela de resultado.
    private func drawAgain() {
        do {
            // Valida e gera um novo plano (novo vencedor definido uma única vez).
            try decision.validate()
            let newPlan = try decisionService.makeDrawPlan(for: decision)
            plan = newPlan

            // Atualiza o vencedor com feedback visual (mesmo se o resultado repetir).
            resultView.updateWinner(newPlan.winner)
        } catch let error as DecisionError {
            presentErrorAlert(message: error.userMessage)
        } catch {
            presentErrorAlert(message: "Não foi possível sortear novamente. Tente de novo.")
        }
    }

    /// Volta à tela inicial para começar uma nova decisão.
    private func startNewDecision() {
        // popToRootViewController retorna ao primeiro view controller da pilha (Home).
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Feedback de erro

    private func presentErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Não foi possível sortear",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
