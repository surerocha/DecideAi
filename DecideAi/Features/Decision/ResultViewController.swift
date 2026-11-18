//
//  ResultViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Controller da tela de sorteio/resultado (protótipo v2)

/// Reproduz a animação do sorteio e exibe o resultado unificado.
/// - Vencedor definido uma única vez pelo `DecisionService` (UI só reproduz o plano).
/// - Mensagem aleatória sem repetir em seguida; "Saiu de novo!" quando o vencedor se repete.
/// - Hápticos, acessibilidade (anúncio só do resultado) e respeito a Reduzir Movimento.
/// - "Tentar novamente" reutiliza as mesmas opções; "Nova decisão" volta à Home.
final class ResultViewController: UIViewController {

    // MARK: - Dependências e estado

    private let resultView = ResultView()
    private let decision: Decision
    private var plan: DrawPlan
    private let decisionService = DecisionService()

    private var isAnimating = false
    private var pendingWork: DispatchWorkItem?

    /// Repetição de vencedor entre sorteios na mesma tela (para "Saiu de novo!").
    private var lastWinnerIndex: Int?
    /// Índice da última mensagem exibida (evita repetir em seguida).
    private var lastMessageIndex: Int = -1

    /// Hápticos: impacto leve nas trocas desaceleradas e sucesso ao concluir.
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let successFeedback = UINotificationFeedbackGenerator()

    // MARK: - Init

    init(decision: Decision, plan: DrawPlan) {
        self.decision = decision
        self.plan = plan
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Ciclo de vida

    override func loadView() {
        view = resultView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = false
        navigationItem.backButtonTitle = "Opções"

        // Aparência da barra sobre o gradiente.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        resultView.configure(question: decision.displayQuestion, options: decision.options)
        bindViewActions()
        startDrawAnimation(with: plan)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Cancela animação se sair da tela; bloqueia voltar durante o sorteio via interação.
        if isMovingFromParent || isBeingDismissed {
            cancelAnimation()
        }
    }

    // MARK: - Bindings

    private func bindViewActions() {
        resultView.onTryAgainTapped = { [weak self] in
            self?.drawAgain()
        }
        resultView.onNewDecisionTapped = { [weak self] in
            self?.startNewDecision()
        }
    }

    // MARK: - Animação

    private func startDrawAnimation(with plan: DrawPlan) {
        cancelAnimation()

        guard !plan.frames.isEmpty else {
            finishAsResult(winnerIndex: plan.winnerIndex)
            return
        }

        isAnimating = true
        setInteractiveBackEnabled(false)
        resultView.setActionsEnabled(false)
        resultView.setWinnerAccessibilityHidden(true)

        impactFeedback.prepare()
        successFeedback.prepare()

        // Primeiro frame imediatamente.
        playFrame(at: 0, in: plan)
    }

    private func playFrame(at index: Int, in plan: DrawPlan) {
        guard isAnimating else { return }
        let frames = plan.frames
        guard frames.indices.contains(index) else {
            finishAsResult(winnerIndex: plan.winnerIndex)
            return
        }

        let frame = frames[index]
        let options = decision.options
        let optionIndex = options.firstIndex(of: frame.text) ?? 0
        let reduced = UIAccessibility.isReduceMotionEnabled

        if index == frames.count - 1 {
            // Último frame: vencedor parado; após a pausa (duration) revela o resultado.
            // Mantemos estado de "sorteando" visualmente enquanto segura a pausa final.
            resultView.showSpinningOption(frame.text, index: optionIndex, total: options.count, reducedMotion: reduced)
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.isAnimating else { return }
                self.finishAsResult(winnerIndex: plan.winnerIndex)
            }
            pendingWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + frame.duration, execute: work)
            return
        }

        // Troca intermediária.
        resultView.showSpinningOption(frame.text, index: optionIndex, total: options.count, reducedMotion: reduced)

        // Háptico leve nas trocas com intervalo >= 250ms (desaceleração), como no protótipo v2.
        if frame.duration >= DecisionService.hapticFromDuration {
            impactFeedback.impactOccurred()
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isAnimating else { return }
            self.playFrame(at: index + 1, in: plan)
        }
        pendingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + frame.duration, execute: work)
    }

    private func finishAsResult(winnerIndex: Int) {
        let options = decision.options
        guard options.indices.contains(winnerIndex) else {
            isAnimating = false
            setInteractiveBackEnabled(true)
            resultView.setActionsEnabled(true)
            resultView.setWinnerAccessibilityHidden(false)
            return
        }

        let winner = options[winnerIndex]
        let repeated = (lastWinnerIndex == winnerIndex)
        lastWinnerIndex = winnerIndex

        let message = pickMessage()
        let reduced = UIAccessibility.isReduceMotionEnabled

        resultView.showResult(option: winner, index: winnerIndex, repeated: repeated, message: message, reducedMotion: reduced)
        resultView.setWinnerAccessibilityHidden(false)

        // Anuncia apenas o resultado final.
        UIAccessibility.post(notification: .announcement, argument: "Resultado: \(winner). \(message)")
        successFeedback.notificationOccurred(.success)

        isAnimating = false
        pendingWork = nil
        setInteractiveBackEnabled(true)
        resultView.setActionsEnabled(true)
    }

    private func pickMessage() -> String {
        let messages = ResultView.messages
        guard !messages.isEmpty else { return "" }
        var idx = Int.random(in: 0..<messages.count)
        if messages.count > 1 && idx == lastMessageIndex {
            idx = (idx + 1) % messages.count
        }
        lastMessageIndex = idx
        return messages[idx]
    }

    private func cancelAnimation() {
        isAnimating = false
        pendingWork?.cancel()
        pendingWork = nil
        resultView.setWinnerAccessibilityHidden(false)
        setInteractiveBackEnabled(true)
    }

    private func setInteractiveBackEnabled(_ enabled: Bool) {
        // Evita voltar durante o sorteio (o resultado ainda não foi revelado).
        navigationItem.hidesBackButton = !enabled
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
    }

    // MARK: - Ações

    private func drawAgain() {
        guard !isAnimating else { return }
        do {
            try decision.validate()
            let newPlan = try decisionService.makeDrawPlan(for: decision)
            plan = newPlan
            startDrawAnimation(with: newPlan)
        } catch {
            // Decisão já validada anteriormente; falha inesperada ignorada.
        }
    }

    private func startNewDecision() {
        guard !isAnimating else { return }
        // "Nova decisão": volta à Home e limpa a próxima decisão (nova criação do zero).
        navigationController?.popToRootViewController(animated: true)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, a reprodução dos frames pode ocorrer em `.task` com `Task.sleep`, checando
 `UIAccessibility.isReduceMotionEnabled` para trocar animação por cross-dissolve.
 O estado (opção exibida, resultado, mensagem, repetição) seria `@State`, e "Nova decisão"
 voltaria à raiz via `NavigationPath`.
*/
