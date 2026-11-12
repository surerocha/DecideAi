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

        bindViewActions()
        refreshView()
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

        // Solicita edição de uma opção existente.
        decisionView.onEditOption = { [weak self] index in
            self?.presentEditAlert(for: index)
        }

        // Solicita remoção de uma opção existente (com confirmação).
        decisionView.onRemoveOption = { [weak self] index in
            self?.presentRemoveConfirmation(for: index)
        }

        // Toque no botão "Sortear": nesta etapa mostramos apenas um aviso informativo.
        // A integração do sorteio e navegação será feita na Etapa 5.
        decisionView.onDrawTapped = { [weak self] in
            self?.presentDrawInfoAlert()
        }
    }

    // MARK: - Atualização da tela

    /// Atualiza a lista de opções e o estado dos botões com base no Model.
    private func refreshView() {
        decisionView.displayOptions(decision.options)
        // "Sortear" só é habilitado quando há opções suficientes (>= 2), conforme o Model.
        decisionView.setDrawEnabled(decision.canDraw)
    }

    // MARK: - Ações

    private func addOption(_ text: String) {
        do {
            // A validação (vazio, tamanho, duplicata, limite etc.) fica no Decision.
            // Aqui apenas pedimos a alteração e reagimos ao sucesso/erro.
            try decision.addOption(text)

            // Sucesso: limpa o campo e atualiza a lista/estados com base no Model.
            decisionView.clearNewOptionField()
            refreshView()
        } catch let error as DecisionError {
            // Erro de regra conhecido: mostramos a mensagem amigável definida no Model.
            presentErrorAlert(title: "Não foi possível adicionar", message: error.userMessage)
        } catch {
            // Segurança para erros inesperados (não previsto nas regras atuais).
            presentErrorAlert(title: "Não foi possível adicionar", message: "Não foi possível adicionar esta alternativa.")
        }
    }

    // MARK: - Edição

    /// Exibe um alerta com campo de texto para editar a opção selecionada.
    private func presentEditAlert(for index: Int) {
        guard decision.options.indices.contains(index) else { return }
        let currentValue = decision.options[index]

        let alert = UIAlertController(
            title: "Editar opção",
            message: nil,
            preferredStyle: .alert
        )

        // Adiciona um UITextField ao alerta, pré-preenchido com o valor atual.
        alert.addTextField { textField in
            textField.text = currentValue
            textField.placeholder = "Alternativa"
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .sentences
        }

        // "Cancelar" fecha o alerta sem alterar nada.
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // "Salvar" tenta aplicar a edição usando o Model.
        alert.addAction(UIAlertAction(title: "Salvar", style: .default) { [weak self] _ in
            guard let self else { return }
            let newText = alert.textFields?.first?.text ?? ""
            self.updateOption(at: index, to: newText)
        })

        present(alert, animated: true)
    }

    private func updateOption(at index: Int, to text: String) {
        do {
            // O Model valida o novo texto e ignora o próprio índice ao checar duplicatas.
            try decision.updateOption(at: index, to: text)
            refreshView()
        } catch let error as DecisionError {
            presentErrorAlert(title: "Não foi possível editar", message: error.userMessage)
        } catch {
            presentErrorAlert(title: "Não foi possível editar", message: "Não foi possível editar esta alternativa.")
        }
    }

    // MARK: - Remoção

    /// Pede confirmação antes de remover a opção selecionada.
    private func presentRemoveConfirmation(for index: Int) {
        guard decision.options.indices.contains(index) else { return }
        let option = decision.options[index]

        let alert = UIAlertController(
            title: "Remover opção?",
            message: "\"\(option)\" será removida da lista.",
            preferredStyle: .alert
        )

        // "Cancelar" fecha o alerta sem remover.
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // "Remover" usa estilo destrutivo para indicar a ação de exclusão.
        alert.addAction(UIAlertAction(title: "Remover", style: .destructive) { [weak self] _ in
            guard let self else { return }
            // O Model remove pelo índice (ignora índices inválidos com segurança).
            self.decision.removeOption(at: index)
            self.refreshView()
        })

        present(alert, animated: true)
    }

    // MARK: - Sorteio (informativo nesta etapa)

    /// Mostra um aviso informativo ao tocar em "Sortear" enquanto ele estiver habilitado.
    /// A lógica de sorteio e a navegação para o resultado serão implementadas na Etapa 5.
    private func presentDrawInfoAlert() {
        let alert = UIAlertController(
            title: "Sortear",
            message: "O sorteio será implementado na próxima etapa.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Feedback de erro

    /// Exibe um alerta simples usando UIAlertController (componente nativo do UIKit
    /// para mensagens pontuais que pedem confirmação do usuário).
    private func presentErrorAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        // Ação padrão "OK" apenas fecha o alerta.
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        // Apresenta o alerta modalmente sobre a tela atual.
        present(alert, animated: true)
    }
}
