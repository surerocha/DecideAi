//
//  HomeView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// The visual part of the Home screen. It knows nothing about navigation:
/// it only tells whoever is listening that the button was tapped.
final class HomeView: UIView {

    /// Set by the view controller. Called when "Nova decisão" is tapped.
    var onStartTapped: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let iconView = UIImageView()
    private let titleLabel = HomeView.makeLabel(textStyle: .largeTitle, color: Theme.Color.primaryText, bold: true)
    private let invitationLabel = HomeView.makeLabel(textStyle: .title2, color: Theme.Color.primaryText, bold: true)
    private let explanationLabel = HomeView.makeLabel(textStyle: .body, color: Theme.Color.secondaryText)
    private let sloganLabel = HomeView.makeLabel(textStyle: .footnote, color: Theme.Color.secondaryText)
    private let startButton = PrimaryButton(title: "Nova decisão")

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        buildHierarchy()
        activateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func configureViews() {
        backgroundColor = Theme.Color.background

        // SF Symbol: ícone vetorial da Apple, que escala e muda de cor como texto.
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72, weight: .semibold)
        iconView.image = UIImage(systemName: "die.face.5.fill", withConfiguration: symbolConfiguration)
        iconView.tintColor = Theme.Color.accent
        iconView.contentMode = .scaleAspectFit
        // Ícone decorativo: o VoiceOver não precisa anunciá-lo.
        iconView.isAccessibilityElement = false

        titleLabel.text = "Decide Aí"
        // Traço "header" ajuda quem usa VoiceOver a navegar entre títulos.
        titleLabel.accessibilityTraits = .header

        invitationLabel.text = "Não consegue escolher? Deixa comigo!"
        explanationLabel.text = "Crie uma decisão, adicione suas alternativas e deixe o sorteio escolher por você."
        sloganLabel.text = "Você tem opções. A gente resolve."

        startButton.accessibilityHint = "Abre a tela para criar uma nova decisão."
        // UIAction é a forma moderna de ligar um evento a um closure.
        // [weak self] evita ciclo de retenção: a view guarda o botão, o botão guarda
        // o closure e, sem o weak, o closure guardaria a view de volta.
        startButton.addAction(UIAction { [weak self] _ in
            self?.onStartTapped?()
        }, for: .touchUpInside)

        // UIStackView empilha as views e calcula as posições para nós.
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: explanationLabel)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: startButton)
    }

    private func buildHierarchy() {
        [iconView, titleLabel, invitationLabel, explanationLabel, startButton, sloganLabel]
            .forEach { contentStack.addArrangedSubview($0) }

        // Dentro de um ScrollView, a tela continua usável com textos muito
        // grandes (Dynamic Type de acessibilidade): o conteúdo rola.
        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    private func activateConstraints() {
        // Com Auto Layout em código, toda view precisa desligar esta conversão automática.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let content = scrollView.contentLayoutGuide   // área rolável
        let frame = scrollView.frameLayoutGuide       // área visível

        // No iPhone o conteúdo ocupa a largura toda (menos as margens).
        // Prioridade 750 (< 1000) porque no iPad o limite de largura abaixo vence.
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        // Prioridade baixa: "se der, centralize na vertical". Se o conteúdo for
        // maior que a tela, as outras constraints vencem e a tela rola.
        let centerVertically = contentStack.centerYAnchor.constraint(equalTo: frame.centerYAnchor)
        centerVertically.priority = .defaultLow

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            // Rolagem só na vertical: a largura do conteúdo = largura visível.
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),

            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: Theme.Spacing.large),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Theme.Spacing.large),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth,
            centerVertically
        ])
    }

    // MARK: - Helpers

    private static func makeLabel(textStyle: UIFont.TextStyle, color: UIColor, bold: Bool = false) -> UILabel {
        let label = UILabel()
        var font = UIFont.preferredFont(forTextStyle: textStyle)
        if bold, let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            font = UIFont(descriptor: descriptor, size: 0)   // size 0 = manter o tamanho do descriptor
        }
        label.font = font
        label.adjustsFontForContentSizeCategory = true        // atualiza se o usuário mudar o tamanho do texto
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0                               // 0 = quantas linhas precisar
        return label
    }
}
