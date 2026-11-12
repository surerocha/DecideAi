//
//  ResultView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Parte visual da tela de resultado.
/// Responsabilidade: exibir a pergunta e a opção sorteada, e informar ações do usuário.
/// Não conhece navegação nem regras de sorteio; apenas dispara callbacks.
final class ResultView: UIView {

    // MARK: - Callbacks (View -> Controller)

    /// Chamado quando o usuário toca em "Sortear novamente".
    var onTryAgainTapped: (() -> Void)?

    /// Chamado quando o usuário toca em "Nova decisão".
    var onNewDecisionTapped: (() -> Void)?

    // MARK: - Componentes de UI

    // UIScrollView: permite rolar caso o conteúdo cresça (textos longos ou Dynamic Type).
    private let scrollView = UIScrollView()

    // UIStackView (vertical): organiza os elementos em coluna com espaçamento consistente.
    private let contentStack = UIStackView()

    // UILabels: exibem textos com suporte a múltiplas linhas e fontes dinâmicas.
    private let questionTitleLabel = ResultView.makeLabel(
        text: "Pergunta",
        textStyle: .headline,
        color: Theme.Color.secondaryText,
        bold: true
    )

    private let questionLabel = ResultView.makeLabel(
        text: "",
        textStyle: .title3,
        color: Theme.Color.primaryText,
        bold: false
    )

    private let winnerTitleLabel = ResultView.makeLabel(
        text: "Resultado",
        textStyle: .headline,
        color: Theme.Color.secondaryText,
        bold: true
    )

    private let winnerLabel = ResultView.makeLabel(
        text: "",
        textStyle: .largeTitle,
        color: Theme.Color.accent,
        bold: true
    )

    // UIStackView para agrupar os botões de ação pós-resultado.
    private let actionsStack = UIStackView()

    // PrimaryButton: ação principal da tela (sortear novamente com as mesmas opções).
    private let tryAgainButton = PrimaryButton(title: "Sortear novamente")

    // UIButton secundário: ação alternativa para iniciar uma nova decisão.
    private let newDecisionButton = UIButton(type: .system)

    // MARK: - Inicialização

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureActions()
        buildHierarchy()
        activateConstraints()
    }

    // Obrigatório em subclasses de UIView; usado com Storyboards/XIBs,
    // que não utilizamos neste projeto.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuração

    private func configureViews() {
        backgroundColor = Theme.Color.background

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        // Espaços extras para separar blocos (pergunta, resultado e ações).
        contentStack.setCustomSpacing(Theme.Spacing.large, after: questionLabel)
        contentStack.setCustomSpacing(Theme.Spacing.small, after: winnerTitleLabel)
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: winnerLabel)

        // Centraliza os textos para dar destaque ao resultado.
        questionTitleLabel.textAlignment = .center
        questionLabel.textAlignment = .center
        winnerTitleLabel.textAlignment = .center
        winnerLabel.textAlignment = .center

        // O resultado é o conteúdo principal desta tela.
        winnerLabel.accessibilityTraits = .header

        // Pilha de ações: botões um abaixo do outro, com largura consistente.
        actionsStack.axis = .vertical
        actionsStack.alignment = .fill
        actionsStack.spacing = Theme.Spacing.small

        tryAgainButton.accessibilityHint = "Realiza um novo sorteio com as mesmas opções."

        // Botão secundário com estilo do sistema, para não competir com a ação principal.
        newDecisionButton.setTitle("Nova decisão", for: .normal)
        newDecisionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        newDecisionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        newDecisionButton.tintColor = Theme.Color.accent
        newDecisionButton.accessibilityHint = "Volta ao início para criar uma nova decisão."
        // Altura mínima de toque confortável (padrão semelhante ao do app).
        newDecisionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }

    private func configureActions() {
        // UIAction conecta o toque do botão a um closure (sem acoplar navegação na View).
        // [weak self] evita ciclo de retenção entre a view e a action.
        tryAgainButton.addAction(UIAction { [weak self] _ in
            self?.onTryAgainTapped?()
        }, for: .touchUpInside)

        newDecisionButton.addAction(UIAction { [weak self] _ in
            self?.onNewDecisionTapped?()
        }, for: .touchUpInside)
    }

    private func buildHierarchy() {
        actionsStack.addArrangedSubview(tryAgainButton)
        actionsStack.addArrangedSubview(newDecisionButton)

        [questionTitleLabel, questionLabel, winnerTitleLabel, winnerLabel, actionsStack]
            .forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    private func activateConstraints() {
        // Com Auto Layout em código, desativamos a conversão automática de autoresizing masks.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // contentLayoutGuide = área rolável; frameLayoutGuide = área visível.
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        // No iPhone ocupa a largura disponível (menos margens).
        // Prioridade menor para permitir o limite máximo no iPad.
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        // Prioridade baixa: centraliza verticalmente quando sobra espaço,
        // mas permite rolar se o conteúdo for maior que a tela.
        let centerVertically = contentStack.centerYAnchor.constraint(equalTo: frame.centerYAnchor)
        centerVertically.priority = .defaultLow

        NSLayoutConstraint.activate([
            // A scroll view ocupa toda a área segura.
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            // Rolagem vertical: largura do conteúdo igual à largura visível.
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),

            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: Theme.Spacing.large),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -Theme.Spacing.large),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth,
            centerVertically
        ])
    }

    // MARK: - Atualização de conteúdo

    /// Preenche a tela com a pergunta e a opção vencedora (configuração inicial).
    func configure(question: String, winner: String) {
        questionLabel.text = question
        winnerLabel.text = winner
    }

    /// Atualiza o vencedor de um novo sorteio com feedback visual.
    /// Mesmo que o resultado seja igual ao anterior, a animação indica que houve um novo sorteio.
    /// (A animação completa com os frames será feita na Etapa 7.)
    func updateWinner(_ winner: String) {
        // Animação simples de "piscar" (fade out/in): dá percepção de atualização
        // inclusive quando o texto sorteado é o mesmo.
        UIView.animate(withDuration: 0.12, animations: {
            self.winnerLabel.alpha = 0.2
            self.winnerLabel.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }, completion: { _ in
            self.winnerLabel.text = winner
            UIView.animate(withDuration: 0.22) {
                self.winnerLabel.alpha = 1
                self.winnerLabel.transform = .identity
            }
        })
    }

    // MARK: - Helpers

    /// Cria labels com fonte dinâmica e configuração visual consistente.
    private static func makeLabel(
        text: String,
        textStyle: UIFont.TextStyle,
        color: UIColor,
        bold: Bool
    ) -> UILabel {
        let label = UILabel()
        label.text = text

        var font = UIFont.preferredFont(forTextStyle: textStyle)
        if bold, let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            // size 0 mantém o tamanho do text style (compatível com Dynamic Type).
            font = UIFont(descriptor: descriptor, size: 0)
        }

        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}
