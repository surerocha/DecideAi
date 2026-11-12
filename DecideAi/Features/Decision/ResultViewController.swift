//
//  ResultViewController.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Controller da tela de resultado.
/// Responsabilidade: reproduzir a animação do sorteio (frames do DrawPlan) e
/// coordenar ações pós-resultado.
/// - "Sortear novamente": gera um novo DrawPlan com a mesma decisão (cópia) e anima.
/// - "Nova decisão": volta ao início do app.
/// O vencedor de cada sorteio é decidido uma única vez pelo DecisionService.
final class ResultViewController: UIViewController {

    // View específica desta tela.
    private let resultView = ResultView()

    // Cópia da decisão usada neste fluxo (pergunta e opções no momento do sorteio).
    // "Sortear novamente" usa esta cópia; a tela de criação mantém seu próprio estado.
    private let decision: Decision

    // Plano atual do sorteio exibido/animado na tela.
    private var plan: DrawPlan

    // Serviço usado para gerar novos sorteios a partir da mesma decisão.
    private let decisionService = DecisionService()

    // Controle da animação: evita sorteios concorrentes e permite cancelar ao sair da tela.
    private var isAnimating = false
    private var pendingFrameWorkItem: DispatchWorkItem?

    // Geradores de feedback tátil (haptics).
    // impact: toque leve a cada passo; notification: sinal de sucesso ao finalizar.
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let successFeedback = UINotificationFeedbackGenerator()

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

        // Mostra a pergunta e inicia a animação do sorteio com os frames do plano.
        resultView.setQuestion(decision.displayQuestion)
        bindViewActions()
        startDrawAnimation(with: plan)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Se o usuário voltar durante a animação, cancela o trabalho pendente
        // para não atualizar a interface após a saída da tela.
        if isMovingFromParent {
            cancelAnimation()
        }
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

    // MARK: - Animação do sorteio

    /// Inicia a reprodução dos frames (troca de opções com desaceleração) do plano informado.
    private func startDrawAnimation(with plan: DrawPlan) {
        // Cancela qualquer animação anterior antes de começar uma nova.
        cancelAnimation()

        guard !plan.frames.isEmpty else {
            resultView.showOption(plan.winner)
            resultView.setActionsEnabled(true)
            return
        }

        isAnimating = true
        // Desabilita ações durante a animação para evitar estados concorrentes.
        resultView.setActionsEnabled(false)

        // Prepara os geradores para resposta tátil imediata.
        impactFeedback.prepare()
        successFeedback.prepare()

        playFrame(at: 0, in: plan.frames, finalWinner: plan.winner)
    }

    /// Reproduz um frame e agenda o próximo respeitando a duração de cada etapa.
    /// A UI apenas toca os frames na ordem; o último frame já é o vencedor (DrawPlan).
    private func playFrame(at index: Int, in frames: [DrawFrame], finalWinner: String) {
        // Se a animação foi cancelada (ex.: usuário voltou), interrompe a sequência.
        guard isAnimating else { return }
        guard frames.indices.contains(index) else {
            finishAnimation(with: finalWinner)
            return
        }

        let frame = frames[index]
        // Atualiza o texto exibido para a opção deste frame (troca estilo "sorteio").
        resultView.showOption(frame.text)

        if index == frames.count - 1 {
            // Último frame: vencedor definido. Finaliza com feedback de sucesso.
            finishAnimation(with: finalWinner)
            return
        }

        // Haptic leve durante a animação. Nos frames iniciais (muito rápidos) pulamos
        // alguns disparos para não ficar excessivo; nos finais (mais lentos) vibra em todos.
        if index % 2 == 0 || frame.duration >= 0.15 {
            impactFeedback.impactOccurred()
        }

        // Agenda o próximo frame após a duração deste, respeitando a desaceleração do plano.
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isAnimating else { return }
            self.playFrame(at: index + 1, in: frames, finalWinner: finalWinner)
        }

        pendingFrameWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + frame.duration, execute: workItem)
    }

    /// Conclui a animação: fixa o vencedor, emite haptic de sucesso e reabilita ações.
    private func finishAnimation(with winner: String) {
        // Garante que o texto final seja exatamente o vencedor.
        resultView.showOption(winner)

        // Feedback tátil de conclusão (sucesso).
        successFeedback.notificationOccurred(.success)

        isAnimating = false
        pendingFrameWorkItem = nil
        resultView.setActionsEnabled(true)
    }

    /// Cancela qualquer frame pendente e marca a animação como encerrada.
    private func cancelAnimation() {
        isAnimating = false
        pendingFrameWorkItem?.cancel()
        pendingFrameWorkItem = nil
    }

    // MARK: - Ações

    /// Gera um novo sorteio com a mesma decisão e reproduz a animação do novo plano.
    private func drawAgain() {
        // Impede múltiplos sorteios enquanto uma animação está em andamento.
        guard !isAnimating else { return }

        do {
            // Valida e gera um novo plano (novo vencedor definido uma única vez).
            try decision.validate()
            let newPlan = try decisionService.makeDrawPlan(for: decision)
            plan = newPlan

            // Reproduz a animação com os frames do novo sorteio.
            startDrawAnimation(with: newPlan)
        } catch let error as DecisionError {
            presentErrorAlert(message: error.userMessage)
        } catch {
            presentErrorAlert(message: "Não foi possível sortear novamente. Tente de novo.")
        }
    }

    /// Volta à tela inicial para começar uma nova decisão.
    private func startNewDecision() {
        // Bloqueia a ação durante a animação (botão já estará desabilitado, mas reforçamos).
        guard !isAnimating else { return }

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
