//
//  ResultView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View da tela de resultado

/// Parte visual da tela de resultado do sorteio.
/// Responsabilidades:
/// - exibir pergunta e o texto do resultado (durante a animação e no final);
/// - expor ações do usuário por callbacks ("Sortear novamente", "Nova decisão");
/// - oferecer APIs simples para o controller controlar conteúdo, acessibilidade e estado dos botões.
///
/// Não conhece navegação, não gera sorteios e não aplica regras de negócio.
final class ResultView: UIView {

    // MARK: - Callbacks (View -> Controller)

    /// Chamado quando o usuário toca em "Sortear novamente".
    var onTryAgainTapped: (() -> Void)?

    /// Chamado quando o usuário toca em "Nova decisão".
    var onNewDecisionTapped: (() -> Void)?

    // MARK: - Componentes de UI

    // Scroll view para suportar conteúdos maiores/fontes grandes.
    private let scrollView = UIScrollView()

    // Stack vertical que organiza todos os elementos com espaçamentos.
    private let contentStack = UIStackView()

    // Rótulo "Pergunta" (título da seção).
    private let questionTitleLabel = ResultView.makeLabel(
        text: "Pergunta",
        textStyle: .headline,
        color: Theme.Color.secondaryText,
        bold: true
    )

    // Texto da pergunta sorteada.
    private let questionLabel = ResultView.makeLabel(
        text: "",
        textStyle: .title3,
        color: Theme.Color.primaryText,
        bold: false
    )

    // Rótulo "Resultado" (título da seção).
    private let winnerTitleLabel = ResultView.makeLabel(
        text: "Resultado",
        textStyle: .headline,
        color: Theme.Color.secondaryText,
        bold: true
    )

    // Destaque do resultado: durante a animação mostra as opções trocando;
    // ao final mostra o vencedor.
    private let winnerLabel = ResultView.makeLabel(
        text: "",
        textStyle: .largeTitle,
        color: Theme.Color.accent,
        bold: true
    )

    // Pilha para os botões de ação.
    private let actionsStack = UIStackView()

    // Ação principal: refaz o sorteio com a mesma decisão.
    private let tryAgainButton = PrimaryButton(title: "Sortear novamente")

    // Ação secundária: volta ao início para criar outra decisão.
    private let newDecisionButton = UIButton(type: .system)

    // MARK: - Inicialização

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Pipeline padrão: configurar -> conectar ações -> montar hierarquia -> layout.
        configureViews()
        configureActions()
        buildHierarchy()
        activateConstraints()
    }

    /// Inicializador de storyboard/XIB (não suportado).
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuração

    /// Configura aparência e propriedades dos componentes.
    private func configureViews() {
        backgroundColor = Theme.Color.background

        // Stack principal: coluna, preenchendo largura.
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        // Espaçamentos extras para separar blocos lógicos.
        contentStack.setCustomSpacing(Theme.Spacing.large, after: questionLabel)
        contentStack.setCustomSpacing(Theme.Spacing.small, after: winnerTitleLabel)
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: winnerLabel)

        // Centralização dos textos para destacar a pergunta e o resultado.
        questionTitleLabel.textAlignment = .center
        questionLabel.textAlignment = .center
        winnerTitleLabel.textAlignment = .center
        winnerLabel.textAlignment = .center

        // Marca o resultado como cabeçalho para acessibilidade.
        winnerLabel.accessibilityTraits = .header

        // Stack de ações (botões).
        actionsStack.axis = .vertical
        actionsStack.alignment = .fill
        actionsStack.spacing = Theme.Spacing.small

        // Dica de acessibilidade do botão principal.
        tryAgainButton.accessibilityHint = "Realiza um novo sorteio com as mesmas opções."

        // Botão secundário em estilo de sistema (menos destaque que o primário).
        newDecisionButton.setTitle("Nova decisão", for: .normal)
        newDecisionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        newDecisionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        newDecisionButton.tintColor = Theme.Color.accent
        newDecisionButton.accessibilityHint = "Volta ao início para criar uma nova decisão."
        // Altura mínima de toque confortável.
        newDecisionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }

    /// Associa interações dos botões aos callbacks.
    private func configureActions() {
        // UIAction com captura fraca de self para evitar ciclos de retenção.
        tryAgainButton.addAction(UIAction { [weak self] _ in
            self?.onTryAgainTapped?()
        }, for: .touchUpInside)

        newDecisionButton.addAction(UIAction { [weak self] _ in
            self?.onNewDecisionTapped?()
        }, for: .touchUpInside)
    }

    /// Monta a hierarquia de subviews.
    private func buildHierarchy() {
        actionsStack.addArrangedSubview(tryAgainButton)
        actionsStack.addArrangedSubview(newDecisionButton)

        [questionTitleLabel, questionLabel, winnerTitleLabel, winnerLabel, actionsStack]
            .forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    /// Define constraints de layout.
    private func activateConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Guides da scroll: conteúdo rolável x área visível.
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        // Largura preenchida com margens (prioridade alta, não obrigatória).
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        // Centraliza verticalmente quando possível; permite rolar se necessário.
        let centerVertically = contentStack.centerYAnchor.constraint(equalTo: frame.centerYAnchor)
        centerVertically.priority = .defaultLow

        NSLayoutConstraint.activate([
            // Scroll ocupa a área segura.
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            // Evita rolagem horizontal.
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),

            // Posicionamento e limites do conteúdo.
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: Theme.Spacing.large),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -Theme.Spacing.large),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth,
            centerVertically
        ])
    }

    // MARK: - API para o controller

    /// Define o texto da pergunta exibida.
    func setQuestion(_ question: String) {
        questionLabel.text = question
    }

    /// Mostra um texto no destaque do resultado (usado a cada frame da animação).
    /// Não aplica animação extra para manter a troca rápida e fluida.
    func showOption(_ text: String) {
        winnerLabel.text = text
    }

    /// Habilita/desabilita botões de ação (ex.: durante a animação).
    func setActionsEnabled(_ enabled: Bool) {
        tryAgainButton.isEnabled = enabled
        newDecisionButton.isEnabled = enabled
    }

    /// Oculta/exibe o resultado para tecnologias assistivas.
    /// Usado para evitar que o VoiceOver anuncie cada troca rápida durante a animação.
    func setWinnerAccessibilityHidden(_ hidden: Bool) {
        winnerLabel.accessibilityElementsHidden = hidden
    }

    // MARK: - Helpers

    /// Cria um `UILabel` configurado com fonte dinâmica, cor e alinhamento padrão.
    private static func makeLabel(
        text: String,
        textStyle: UIFont.TextStyle,
        color: UIColor,
        bold: Bool
    ) -> UILabel {
        let label = UILabel()
        label.text = text

        // Aplica text style e, opcionalmente, negrito, preservando suporte a Dynamic Type.
        var font = UIFont.preferredFont(forTextStyle: textStyle)
        if bold, let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            font = UIFont(descriptor: descriptor, size: 0)
        }

        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 import SwiftUI

 struct ResultViewUI: View {
     let question: String
     let displayedOption: String
     let isAnimating: Bool
     let onTryAgain: () -> Void
     let onNewDecision: () -> Void

     var body: some View {
         ScrollView {
             VStack(spacing: 16) {
                 Text("Pergunta")
                     .font(.headline)
                     .foregroundStyle(.secondary)

                 Text(question)
                     .font(.title3)

                 Text("Resultado")
                     .font(.headline)
                     .foregroundStyle(.secondary)

                 Text(displayedOption)
                     .font(.largeTitle.bold())
                     .foregroundStyle(.indigo)
                     .accessibilityAddTraits(.isHeader)
                     // Durante animação, podemos evitar anúncios repetidos focando só no final.
                     .accessibilityHidden(isAnimating)

                 VStack(spacing: 8) {
                     Button("Sortear novamente", action: onTryAgain)
                         .buttonStyle(PrimaryButtonStyle())
                         .disabled(isAnimating)

                     Button("Nova decisão", action: onNewDecision)
                         .disabled(isAnimating)
                 }
             }
             .multilineTextAlignment(.center)
             .padding(24)
             .frame(maxWidth: 560)
             .frame(maxWidth: .infinity)
         }
         .navigationTitle("Resultado")
     }
 }

 Diferenças principais:
 - Estado (texto exibido, animando) vem por propriedades/bindings.
 - Habilitar/desabilitar é declarativo com `.disabled(isAnimating)`.
 - Acessibilidade pode ser ajustada declarativamente (`.accessibilityHidden`).
*/
