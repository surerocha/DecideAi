//
//  ResultViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Controller da tela de resultado

/// Controller responsável por:
/// - exibir a pergunta e reproduzir a animação do sorteio usando os `frames` do `DrawPlan`;
/// - coordenar ações pós-resultado ("Sortear novamente" e "Nova decisão");
/// - controlar haptics e acessibilidade (anunciar apenas o resultado final);
/// - evitar estados concorrentes durante a animação e cancelar trabalho ao sair da tela.
///
/// O vencedor de cada sorteio é decidido uma única vez pelo `DecisionService` via `DrawPlan`.
final class ResultViewController: UIViewController {

    // MARK: - Dependências e estado

    /// View customizada da tela.
    private let resultView = ResultView()

    /// Cópia da decisão (struct/value type) usada neste fluxo.
    /// Permite "Sortear novamente" com as mesmas opções sem alterar a tela de criação.
    private let decision: Decision

    /// Plano de sorteio atualmente exibido/animado.
    private var plan: DrawPlan

    /// Serviço para gerar novos planos de sorteio.
    private let decisionService = DecisionService()

    /// Indica se a animação está em andamento (impede ações concorrentes).
    private var isAnimating = false

    /// Referência ao próximo passo agendado da animação, para permitir cancelamento.
    private var pendingFrameWorkItem: DispatchWorkItem?

    /// Haptics: impacto leve nos passos e notificação de sucesso ao concluir.
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let successFeedback = UINotificationFeedbackGenerator()

    // MARK: - Inicialização

    /// Inicializa o controller com os dados necessários para exibir e re-sortear.
    /// - Parameters:
    ///   - question: pergunta exibida (mantida por compatibilidade do fluxo).
    ///   - decision: cópia da decisão (mesmas opções/pergunta) para "Sortear novamente".
    ///   - plan: plano inicial já gerado.
    init(question: String, decision: Decision, plan: DrawPlan) {
        // Armazena dependências/estado.
        self.decision = decision
        self.plan = plan
        // Inicializador designado de UIViewController para criação programática.
        super.init(nibName: nil, bundle: nil)
    }

    /// Inicializador de storyboard/XIB (não suportado).
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Ciclo de vida

    /// Fornece a view customizada como raiz.
    override func loadView() {
        view = resultView
    }

    /// Configura conteúdo inicial e inicia a animação do plano recebido.
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Resultado"

        // Exibe a pergunta da decisão e conecta ações.
        resultView.setQuestion(decision.displayQuestion)
        bindViewActions()

        // Inicia a reprodução dos frames do sorteio inicial.
        startDrawAnimation(with: plan)
    }

    /// Se o usuário voltar (pop) durante a animação, cancela o trabalho pendente.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            cancelAnimation()
        }
    }

    // MARK: - Bindings

    /// Conecta callbacks da view às ações do controller.
    private func bindViewActions() {
        resultView.onTryAgainTapped = { [weak self] in
            self?.drawAgain()
        }

        resultView.onNewDecisionTapped = { [weak self] in
            self?.startNewDecision()
        }
    }

    // MARK: - Animação do sorteio

    /// Prepara e inicia a animação de um `DrawPlan`.
    private func startDrawAnimation(with plan: DrawPlan) {
        // Garante que não haja animação anterior ativa.
        cancelAnimation()

        // Caso defensivo: se não houver frames, mostra o vencedor e libera ações.
        guard !plan.frames.isEmpty else {
            resultView.showOption(plan.winner)
            resultView.setActionsEnabled(true)
            return
        }

        // Marca estado de animação e bloqueia interações concorrentes.
        isAnimating = true
        resultView.setActionsEnabled(false)

        // Oculta o texto do resultado para o VoiceOver durante as trocas rápidas.
        // (Anunciaremos apenas o resultado final.)
        resultView.setWinnerAccessibilityHidden(true)

        // Prepara os haptics para resposta imediata.
        impactFeedback.prepare()
        successFeedback.prepare()

        // Inicia pelo primeiro frame.
        playFrame(at: 0, in: plan.frames, finalWinner: plan.winner)
    }

    /// Reproduz um frame e agenda o próximo após a duração do frame atual.
    /// - Parameters:
    ///   - index: índice do frame atual.
    ///   - frames: sequência completa de frames.
    ///   - finalWinner: vencedor final (último frame) para garantir consistência.
    private func playFrame(at index: Int, in frames: [DrawFrame], finalWinner: String) {
        // Se cancelado, interrompe.
        guard isAnimating else { return }

        // Segurança: índice inválido encerra com o vencedor.
        guard frames.indices.contains(index) else {
            finishAnimation(with: finalWinner)
            return
        }

        let frame = frames[index]

        // Mostra a opção correspondente ao frame atual.
        resultView.showOption(frame.text)

        // Se for o último frame, finaliza (vencedor).
        if index == frames.count - 1 {
            finishAnimation(with: finalWinner)
            return
        }

        // Haptic leve: nos frames muito rápidos evitamos vibrar em todos para não exagerar;
        // em frames mais lentos (desaceleração) vibramos com mais frequência.
        if index % 2 == 0 || frame.duration >= 0.15 {
            impactFeedback.impactOccurred()
        }

        // Cria o trabalho para tocar o próximo frame após a duração atual.
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isAnimating else { return }
            self.playFrame(at: index + 1, in: frames, finalWinner: finalWinner)
        }

        // Guarda referência para poder cancelar e agenda na fila principal (UI).
        pendingFrameWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + frame.duration, execute: workItem)
    }

    /// Finaliza a animação: fixa vencedor, anuncia para acessibilidade, emite haptic e libera ações.
    private func finishAnimation(with winner: String) {
        // Garante que o texto final seja o vencedor.
        resultView.showOption(winner)

        // Torna o resultado acessível novamente e anuncia apenas o valor final.
        resultView.setWinnerAccessibilityHidden(false)
        UIAccessibility.post(notification: .announcement, argument: "Resultado: \(winner)")

        // Feedback tátil de sucesso.
        successFeedback.notificationOccurred(.success)

        // Atualiza estado interno e reabilita botões.
        isAnimating = false
        pendingFrameWorkItem = nil
        resultView.setActionsEnabled(true)
    }

    /// Cancela animação em andamento e limpa trabalho agendado.
    private func cancelAnimation() {
        isAnimating = false
        pendingFrameWorkItem?.cancel()
        pendingFrameWorkItem = nil
        // Se interrompida, garante que o resultado não permaneça oculto para acessibilidade.
        resultView.setWinnerAccessibilityHidden(false)
    }

    // MARK: - Ações do usuário

    /// Gera um novo plano com a mesma decisão e anima o novo resultado.
    private func drawAgain() {
        // Evita iniciar outro sorteio durante a animação.
        guard !isAnimating else { return }

        do {
            // Valida e gera um novo plano (vencedor definido uma única vez por sorteio).
            try decision.validate()
            let newPlan = try decisionService.makeDrawPlan(for: decision)
            plan = newPlan

            // Reproduz a nova animação.
            startDrawAnimation(with: newPlan)
        } catch let error as DecisionError {
            presentErrorAlert(message: error.userMessage)
        } catch {
            presentErrorAlert(message: "Não foi possível sortear novamente. Tente de novo.")
        }
    }

    /// Volta à Home para iniciar uma nova decisão.
    private func startNewDecision() {
        // Bloqueio extra além do estado desabilitado dos botões.
        guard !isAnimating else { return }

        // Retorna ao primeiro controller da pilha de navegação (Home).
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Alertas

    /// Exibe alerta de erro simples.
    private func presentErrorAlert(message: String) {
        let alert = UIAlertController(title: "Não foi possível sortear", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 import SwiftUI

 struct ResultScreen: View {
     let question: String
     let decision: Decision

     @State private var displayed = ""
     @State private var isAnimating = false
     @Environment(\.dismiss) private var dismiss
     @Environment(\.accessibilityReduceMotion) private var reduceMotion

     private let service = DecisionService()

     var body: some View {
         VStack(spacing: 16) {
             Text("Pergunta").font(.headline).foregroundStyle(.secondary)
             Text(question).font(.title3)

             Text("Resultado").font(.headline).foregroundStyle(.secondary)
             Text(displayed)
                 .font(.largeTitle.bold())
                 .foregroundStyle(.indigo)
                 .accessibilityHidden(isAnimating)

             Button("Sortear novamente") { Task { await animateDraw() } }
                 .buttonStyle(PrimaryButtonStyle())
                 .disabled(isAnimating)

             Button("Nova decisão") { /* pop to root via path */ }
                 .disabled(isAnimating)
         }
         .padding()
         .navigationTitle("Resultado")
         .task { await animateDraw() } // anima ao entrar
     }

     // Reproduz os frames com delays (equivalente ao asyncAfter encadeado).
     func animateDraw() async {
         guard !isAnimating else { return }
         do {
             try decision.validate()
             let plan = try service.makeDrawPlan(for: decision)

             isAnimating = true
             let impact = UIImpactFeedbackGenerator(style: .light)
             let success = UINotificationFeedbackGenerator()
             impact.prepare(); success.prepare()

             for (index, frame) in plan.frames.enumerated() {
                 displayed = frame.text
                 if index < plan.frames.count - 1 {
                     if index % 2 == 0 || frame.duration >= 0.15 { impact.impactOccurred() }
                     try? await Task.sleep(nanoseconds: UInt64(frame.duration * 1_000_000_000))
                 } else {
                     success.notificationOccurred(.success)
                     UIAccessibility.post(notification: .announcement, argument: "Resultado: \(frame.text)")
                 }
             }
             isAnimating = false
         } catch {
             isAnimating = false
             // apresentar erro via alert/binding
         }
     }
 }

 Observações:
 - `.task` é cancelada automaticamente quando a view some (semelhante a cancelar o DispatchWorkItem).
 - `@State` controla `displayed`/`isAnimating` e a UI atualiza declarativamente.
 - `NavigationStack` com `path` facilita "Nova decisão" (voltar à raiz) de forma declarativa.
*/
