//
//  DecisionViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Controller da tela de criação da decisão (protótipo v2)

/// Coordena a tela de criação: conecta eventos da `DecisionView`, mantém o `Decision`
/// (fonte da verdade das regras) e navega para o sorteio.
///
/// Validações na criação são exibidas inline (sem alertas), conforme o protótipo v2:
/// opção vazia/repetida/limite e pergunta vazia ao tentar sortear (com foco no campo).
/// O único alerta que permanece é o de edição de opção.
final class DecisionViewController: UIViewController {

    // MARK: - Propriedades

    private let decisionView = DecisionView()
    private var decision = Decision()
    private let decisionService = DecisionService()

    /// Observador para atualizar o estado do botão "Salvar" no alerta de edição.
    private var editAlertObserver: NSObjectProtocol?

    // MARK: - Ciclo de vida

    override func loadView() {
        view = decisionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Nova decisão"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonTitle = "Opções"

        // Aparência da barra sobre fundo canvas.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = Theme.Color.canvas.withAlphaComponent(0.95)
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = Theme.Color.accentText

        bindViewActions()
        refreshView()
    }

    /// Ao retornar do resultado, garante que a UI reflita o estado atual.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }

    deinit {
        if let obs = editAlertObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Ligações View -> Controller

    private func bindViewActions() {
        // Pergunta: atualiza o Model e limpa erro inline ao digitar (a view também limpa o visual).
        decisionView.onQuestionChanged = { [weak self] text in
            guard let self else { return }
            self.decision.question = text
            // Limpa erro de pergunta se o usuário passou a digitar algo.
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.decisionView.setQuestionErrorVisible(false)
            }
        }

        // Rascunho de opção: ao digitar, limpa mensagem inline de erro.
        decisionView.onDraftChanged = { [weak self] _ in
            self?.decisionView.setDraftMessage(nil)
        }

        decisionView.onAddOption = { [weak self] in
            self?.addOption()
        }

        decisionView.onEditOption = { [weak self] index in
            self?.presentEditAlert(for: index)
        }

        // Remoção imediata (sem confirmação), como no protótipo v2.
        decisionView.onRemoveOption = { [weak self] index in
            self?.removeOption(at: index)
        }

        decisionView.onDrawTapped = { [weak self] in
            self?.drawDecision()
        }
    }

    // MARK: - Sincronização

    private func refreshView() {
        decisionView.displayOptions(decision.options)
    }

    // MARK: - Adicionar opção (validação inline)

    private func addOption() {
        let text = decisionView.draftText

        // Limite atingido: nada a adicionar.
        guard decision.options.count < Decision.maxOptions else { return }

        do {
            // Reaproveita validações do Decision (trim, vazio, duplicata, tamanho).
            try decision.addOption(text)
            decisionView.setDraftMessage(nil)
            decisionView.clearDraft()
            refreshView()
        } catch let error as DecisionError {
            // Mensagens inline do protótipo v2.
            switch error {
            case .emptyOption:
                decisionView.setDraftMessage("Escreva o nome da opção.")
            case .duplicateOption:
                decisionView.setDraftMessage("Essa opção já existe.")
            case .tooManyOptions, .optionTooLong:
                // Limite/tamanho são tratados pela UI (bloqueio/contador); ignora silenciosamente.
                break
            default:
                break
            }
        } catch {
            // Ignora erros inesperados na adição inline.
        }
    }

    // MARK: - Edição (único alerta)

    private func presentEditAlert(for index: Int) {
        guard decision.options.indices.contains(index) else { return }
        let currentValue = decision.options[index]

        let alert = UIAlertController(
            title: "Editar opção",
            message: "Altere o nome da opção.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = currentValue
            textField.placeholder = "Nome da opção"
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .sentences
        }

        let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            if let obs = self?.editAlertObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.editAlertObserver = nil
            }
        }

        let save = UIAlertAction(title: "Salvar", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            if let obs = self.editAlertObserver {
                NotificationCenter.default.removeObserver(obs)
                self.editAlertObserver = nil
            }
            let newText = alert?.textFields?.first?.text ?? ""
            self.updateOption(at: index, to: newText)
        }

        // Estado inicial do botão Salvar conforme validade.
        save.isEnabled = isValidEdit(text: currentValue, at: index)

        alert.addAction(cancel)
        alert.addAction(save)

        // Observa digitação para habilitar/desabilitar "Salvar" e limitar tamanho (máx. 40).
        if let textField = alert.textFields?.first {
            editAlertObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { [weak self, weak save, weak textField] _ in
                guard let self, let save, let textField else { return }
                var text = textField.text ?? ""
                if text.count > Decision.maxOptionLength {
                    text = String(text.prefix(Decision.maxOptionLength))
                    textField.text = text
                }
                save.isEnabled = self.isValidEdit(text: text, at: index)
            }
        }

        present(alert, animated: true)
    }

    /// Valida texto de edição: não vazio (após trim) e não duplicado de outra opção (ignorando índice/caixa/acentos).
    private func isValidEdit(text: String, at index: Int) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let key = folded(trimmed)
        for (i, existing) in decision.options.enumerated() where i != index {
            if folded(existing) == key { return false }
        }
        // Respeita limite de caracteres (defesa; o campo do alerta também limita).
        return trimmed.count <= Decision.maxOptionLength
    }

    /// Normaliza para comparação (mesma regra de duplicata do Decision: caixa/acentos).
    private func folded(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    private func updateOption(at index: Int, to text: String) {
        do {
            // Reaproveita regra do Decision (ignora o próprio índice ao checar duplicata).
            try decision.updateOption(at: index, to: text)
            refreshView()
        } catch {
            // "Salvar" só fica habilitado quando válido; falhas aqui são improváveis, então ignoramos.
        }
    }

    // MARK: - Remoção imediata

    private func removeOption(at index: Int) {
        guard decision.options.indices.contains(index) else { return }
        decision.removeOption(at: index)
        refreshView()
    }

    // MARK: - Sorteio

    private func drawDecision() {
        // Botão fica habilitado com 2+ opções; se a pergunta estiver vazia, mostra erro inline e foca.
        let questionEmpty = decision.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if questionEmpty {
            decisionView.setQuestionErrorVisible(true)
            decisionView.focusQuestion()
            return
        }

        guard decision.canDraw else { return }

        do {
            // Validação final via Model (fonte da verdade) antes de sortear.
            try decision.validate()
            let plan = try decisionService.makeDrawPlan(for: decision)

            // Cópia da decisão para "Sortear novamente" usar as mesmas opções.
            let resultController = ResultViewController(decision: decision, plan: plan)
            navigationController?.pushViewController(resultController, animated: true)
        } catch let error as DecisionError {
            // Defesa: se algo escapar, direciona feedback apropriado.
            if case .emptyQuestion = error {
                decisionView.setQuestionErrorVisible(true)
                decisionView.focusQuestion()
            }
            // Demais erros (ex.: opções insuficientes) já são prevenidos pela UI.
        } catch {
            // Falha inesperada: sem ação disruptiva.
        }
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, a View manteria `@State` para pergunta/opções/erros inline e chamaria o Model
 (`Decision`) diretamente. A edição continuaria sendo o único alerta com campo de texto.
 O fluxo de "Sortear" com pergunta vazia mostraria erro inline e aplicaria `@FocusState`.
*/

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
#Preview("Nova decisão") {
    UINavigationController(rootViewController: DecisionViewController())
}
#endif
