//
//  DecisionViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Controller da tela de criação da decisão

/// Controller (camada de coordenação) da tela de criação da decisão.
/// Responsabilidades:
/// - conectar eventos da `DecisionView` (callbacks) às ações do app;
/// - manter o estado do `Decision` (Model) e chamar suas APIs (sem duplicar validação);
/// - apresentar alertas de erro/sucesso contextual usando `DecisionError.userMessage`;
/// - navegar para a tela de resultado ao sortear.
///
/// A View não conhece navegação nem regras de negócio; o Model não conhece UIKit.
final class DecisionViewController: UIViewController {

    // MARK: - Propriedades

    /// View customizada responsável pela interface da tela de criação.
    private let decisionView = DecisionView()

    /// Estado da decisão em criação (pergunta e opções).
    /// O Model (`Decision`) é a fonte da verdade para as regras.
    private var decision = Decision()

    /// Serviço de sorteio/geração do plano de animação (não usa UIKit).
    private let decisionService = DecisionService()

    // MARK: - Ciclo de vida

    /// Substitui a view raiz do controller pela `DecisionView`.
    /// Padrão usado no app: o controller coordena, a view monta a UI.
    override func loadView() {
        view = decisionView
    }

    /// Chamado após a view estar carregada. Configura título, bindings e estado inicial.
    override func viewDidLoad() {
        super.viewDidLoad()

        // Título exibido na barra de navegação.
        title = "Nova decisão"
        navigationItem.largeTitleDisplayMode = .never

        // Aparência da barra sobre fundo canvas.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = Theme.Color.canvas.withAlphaComponent(0.9)
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = Theme.Color.accentText

        // Conecta eventos da View aos handlers deste controller.
        bindViewActions()

        // Sincroniza a UI com o estado atual do Model (lista vazia, botão desabilitado etc.).
        refreshView()
    }

    // MARK: - Ligações View -> Controller

    /// Registra callbacks da `DecisionView` para reagir às interações do usuário.
    private func bindViewActions() {
        // Mantém a pergunta do Model sincronizada com o campo de texto.
        decisionView.onQuestionChanged = { [weak self] text in
            self?.decision.question = text
        }

        // Adiciona uma nova alternativa.
        decisionView.onAddOption = { [weak self] text in
            self?.addOption(text)
        }

        // Abre fluxo de edição de uma opção existente.
        decisionView.onEditOption = { [weak self] index in
            self?.presentEditAlert(for: index)
        }

        // Pede confirmação antes de remover uma opção.
        decisionView.onRemoveOption = { [weak self] index in
            self?.presentRemoveConfirmation(for: index)
        }

        // Valida, gera o plano e navega para a tela de resultado.
        decisionView.onDrawTapped = { [weak self] in
            self?.drawDecision()
        }
    }

    // MARK: - Sincronização da UI

    /// Atualiza a lista de opções e o estado do botão "Sortear" com base no Model.
    private func refreshView() {
        decisionView.displayOptions(decision.options)
        // Habilita o sorteio apenas quando há pelo menos 2 opções (regra do Model).
        decisionView.setDrawEnabled(decision.canDraw)
    }

    // MARK: - Ações de opções

    /// Tenta adicionar uma opção ao Model; em caso de erro mostra alerta.
    private func addOption(_ text: String) {
        do {
            // Validações (vazio, tamanho, duplicata, limite) ficam no Decision.
            try decision.addOption(text)
            // Sucesso: limpa o campo e atualiza a tela.
            decisionView.clearNewOptionField()
            refreshView()
        } catch let error as DecisionError {
            presentErrorAlert(title: "Não foi possível adicionar", message: error.userMessage)
        } catch {
            presentErrorAlert(title: "Não foi possível adicionar", message: "Não foi possível adicionar esta alternativa.")
        }
    }

    // MARK: - Edição

    /// Exibe um alerta com campo de texto para editar a opção selecionada.
    private func presentEditAlert(for index: Int) {
        guard decision.options.indices.contains(index) else { return }
        let currentValue = decision.options[index]

        let alert = UIAlertController(title: "Editar opção", message: nil, preferredStyle: .alert)

        // Adiciona um TextField ao alerta, pré-preenchido com o valor atual.
        alert.addTextField { textField in
            textField.text = currentValue
            textField.placeholder = "Alternativa"
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .sentences
        }

        // Cancelar: apenas fecha o alerta.
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Salvar: tenta atualizar via Model.
        alert.addAction(UIAlertAction(title: "Salvar", style: .default) { [weak self] _ in
            guard let self else { return }
            let newText = alert.textFields?.first?.text ?? ""
            self.updateOption(at: index, to: newText)
        })

        present(alert, animated: true)
    }

    /// Aplica a edição no Model e atualiza a UI ou mostra erro.
    private func updateOption(at index: Int, to text: String) {
        do {
            // O Model ignora o próprio índice ao checar duplicatas (ignoringIndex).
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

        // Cancelar: não remove.
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Remover: estilo destrutivo indica ação de exclusão.
        alert.addAction(UIAlertAction(title: "Remover", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.decision.removeOption(at: index)
            self.refreshView()
        })

        present(alert, animated: true)
    }

    // MARK: - Sorteio e navegação

    /// Valida a decisão, gera o `DrawPlan` e navega para a tela de resultado.
    private func drawDecision() {
        do {
            // Validação final (pergunta, opções suficientes etc.).
            try decision.validate()

            // Sorteio e preparação da animação (vencedor definido uma única vez).
            let plan = try decisionService.makeDrawPlan(for: decision)

            // Passa uma cópia da decisão e o plano para a tela de resultado.
            // A cópia permite "Sortear novamente" no resultado sem alterar esta tela.
            let resultController = ResultViewController(
                question: decision.displayQuestion,
                decision: decision,
                plan: plan
            )
            navigationController?.pushViewController(resultController, animated: true)
        } catch let error as DecisionError {
            presentErrorAlert(title: "Não foi possível sortear", message: error.userMessage)
        } catch {
            presentErrorAlert(title: "Não foi possível sortear", message: "Tente novamente.")
        }
    }

    // MARK: - Feedback

    /// Exibe um alerta simples (`UIAlertController`) com título e mensagem.
    private func presentErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, o controller explícito muitas vezes some: a View mantém estado (`@State`) e chama
 o Model/Service diretamente. Também podemos usar `@Observable` (ou ObservableObject) para
 separar melhor a lógica.

 import SwiftUI

 struct DecisionScreen: View {
     @State private var decision = Decision()
     @State private var newOptionText = ""
     @State private var alertError: DecisionError?
     @State private var showResult = false
     @State private var resultPlan: DrawPlan?

     private let service = DecisionService()

     var body: some View {
         Form {
             Section("O que você quer decidir?") {
                 TextField("Digite sua pergunta", text: $decision.question)
             }

             Section("Opções") {
                 ForEach(Array(decision.options.enumerated()), id: \.offset) { index, option in
                     HStack {
                         Text(option)
                         Spacer()
                         Button("Editar") { /* apresentar sheet/alert com textfield */ }
                         Button("Remover") { decision.removeOption(at: index) }
                             .foregroundStyle(.red)
                     }
                 }
             }

             HStack {
                 TextField("Nova alternativa", text: $newOptionText)
                 Button("Adicionar") {
                     do {
                         try decision.addOption(newOptionText)
                         newOptionText = ""
                     } catch let e as DecisionError { alertError = e }
                     catch { alertError = .emptyOption } // fallback
                 }
             }

             Button("Sortear") {
                 do {
                     try decision.validate()
                     let plan = try service.makeDrawPlan(for: decision)
                     resultPlan = plan
                     showResult = true
                 } catch let e as DecisionError { alertError = e }
                 catch { alertError = .notEnoughOptions }
             }
             .disabled(!decision.canDraw)
         }
         .navigationTitle("Nova decisão")
         .alert("Erro", isPresented: .constant(alertError != nil)) {
             Button("OK") { alertError = nil }
         } message: { Text(alertError?.userMessage ?? "") }
         .navigationDestination(isPresented: $showResult) {
             if let plan = resultPlan {
                 ResultScreen(question: decision.displayQuestion, decision: decision, plan: plan)
             }
         }
     }
 }

 Pontos equivalentes:
 - `UIAlertController` vira `.alert(...)`.
 - Editar/remover podem ser feitos em `ForEach` com botões ou em uma `List` com swipe actions.
 - Navegação: `navigationDestination` com estado em vez de `pushViewController`.
*/
