//
//  DecisionViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Controller da tela de criação da decisão.
/// Responsabilidade: coordenar a View e o Model (Decision).
/// - Recebe eventos da View (callbacks).
/// - Atualiza o Model usando suas APIs (sem duplicar regras de validação).
/// - Pede para a View refletir o estado atual.
final class DecisionViewController: UIViewController {

    // View específica desta tela (criada por nós, em código).
    private let decisionView = DecisionView()

    // Estado da decisão em criação. O Model concentra os dados e as regras.
    private var decision = Decision()

    // Substituímos a view raiz do controller pela nossa DecisionView.
    // Mesmo padrão usado na Home: o controller coordena, a View cuida da interface.
    override func loadView() {
        view = decisionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Nova decisão"

        // Garante que a lista comece no estado atual do Model (vazia).
        decisionView.displayOptions(decision.options)

        bindViewActions()
    }

    // MARK: - Ligações View -> Controller

    private func bindViewActions() {
        // Mantém a pergunta do Model sincronizada com o que o usuário digita.
        decisionView.onQuestionChanged = { [weak self] text in
            self?.decision.question = text
        }

        // Tenta adicionar uma nova alternativa usando o Model.
        decisionView.onAddOption = { [weak self] text in
            self?.addOption(text)
        }
    }

    // MARK: - Ações

    private func addOption(_ text: String) {
        do {
            // A validação (vazio, tamanho, duplicata, limite etc.) fica no Decision.
            // Aqui apenas pedimos a alteração e reagimos ao sucesso/erro.
            try decision.addOption(text)

            // Sucesso: limpa o campo e atualiza a lista visual com o estado do Model.
            decisionView.clearNewOptionField()
            decisionView.displayOptions(decision.options)
        } catch let error as DecisionError {
            // Erro de regra conhecido: mostramos a mensagem amigável definida no Model.
            presentErrorAlert(message: error.userMessage)
        } catch {
            // Segurança para erros inesperados (não previsto nas regras atuais).
            presentErrorAlert(message: "Não foi possível adicionar esta alternativa.")
        }
    }

    // MARK: - Feedback de erro

    /// Exibe um alerta simples usando UIAlertController (componente nativo do UIKit
    /// para mensagens pontuais que pedem confirmação do usuário).
    private func presentErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Não foi possível adicionar",
            message: message,
            preferredStyle: .alert
        )

        // Ação padrão "OK" apenas fecha o alerta.
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        // Apresenta o alerta modalmente sobre a tela atual.
        present(alert, animated: true)
    }
}

