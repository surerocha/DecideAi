//
//  ResultView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View do sorteio/resultado (protótipo v2)

/// Tela unificada de sorteio e resultado: anima a alternância das opções e revela o vencedor,
/// com mensagem, badge de repetição, lista "Concorreram" e ações fixas na parte inferior.
/// A View é controlada pelo `ResultViewController` (animação, háptica e acessibilidade).
final class ResultView: UIView {

    // MARK: - Callbacks

    var onTryAgainTapped: (() -> Void)?
    var onNewDecisionTapped: (() -> Void)?

    // MARK: - UI base

    private let gradientLayer = CAGradientLayer()
    private let glowLime = UIView()
    private let glowPink = UIView()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let questionCaptionLabel = UILabel()
    private let questionLabel = UILabel()

    private let statusLabel = UILabel()
    private let card = UIView()
    private let cardBadge = PaddingLabel()
    private let optionLabel = UILabel()
    private let leftMarker = UIImageView()
    private let rightMarker = UIImageView()
    private let repeatedBadge = PaddingLabel()

    private let messageLabel = UILabel()

    private let competedCaption = UILabel()
    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()

    /// Barra inferior fixa com as ações (fora da rolagem).
    private let bottomBar = UIView()
    private let actionsStack = UIStackView()
    private let tryAgainButton = PrimaryButton(title: "Tentar novamente", style: .lime)
    private let newDecisionButton = PrimaryButton(title: "Ir para tela inicial", style: .glass)

    // MARK: - Estado

    private var options: [String] = []
    private var chipViews: [PaddingLabel] = []
    private var isResult = false
    private var currentHighlightIndex: Int?

    // Mensagens (protótipo v2), sem repetição imediata.
    static let messages = [
        "Foi decidido. Não questione! 😌",
        "O universo escolheu por você!",
        "Pronto! Uma preocupação a menos.",
        "Essa é a sua escolha de hoje!"
    ]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureActions()
        buildHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)
        glowLime.layer.cornerRadius = max(glowLime.bounds.height / 2, 1)
        glowPink.layer.cornerRadius = max(glowPink.bounds.height / 2, 1)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)
            updateCardAppearance()
            refreshChips()
        }
    }

    // MARK: - Configuração

    private func configureViews() {
        layer.insertSublayer(gradientLayer, at: 0)
        Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)

        glowLime.backgroundColor = Theme.Color.lime.withAlphaComponent(0.10)
        glowPink.backgroundColor = Theme.Color.coral.withAlphaComponent(0.15)
        glowLime.isUserInteractionEnabled = false
        glowPink.isUserInteractionEnabled = false

        questionCaptionLabel.text = "SUA PERGUNTA"
        questionCaptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.bold)
        questionCaptionLabel.adjustsFontForContentSizeCategory = true
        questionCaptionLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        questionCaptionLabel.numberOfLines = 0

        questionLabel.font = Theme.Font.scaledDisplay(baseSize: 24, weight: .heavy, textStyle: .title2)
        questionLabel.adjustsFontForContentSizeCategory = true
        questionLabel.textColor = .white
        questionLabel.numberOfLines = 0

        statusLabel.text = "Sorteando..."
        statusLabel.font = Theme.Font.scaledDisplay(baseSize: 24, weight: .black, textStyle: .title2)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center

        // Cartão central
        card.backgroundColor = Theme.Color.surface
        card.layer.cornerRadius = 32
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.35
        card.layer.shadowRadius = 30
        card.layer.shadowOffset = CGSize(width: 0, height: 20)

        cardBadge.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.heavy)
        cardBadge.adjustsFontForContentSizeCategory = true
        cardBadge.textAlignment = .center
        cardBadge.insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        cardBadge.layer.cornerRadius = 12
        cardBadge.clipsToBounds = true

        optionLabel.font = Theme.Font.scaledDisplay(baseSize: 40, weight: .black, textStyle: .largeTitle)
        optionLabel.adjustsFontForContentSizeCategory = true
        optionLabel.textColor = Theme.Color.ink
        optionLabel.textAlignment = .center
        optionLabel.numberOfLines = 0
        optionLabel.adjustsFontSizeToFitWidth = true
        optionLabel.minimumScaleFactor = 0.5
        optionLabel.accessibilityTraits = [.header]

        // Marcadores laterais (aproximação das setas do protótipo).
        leftMarker.image = UIImage(systemName: "arrowtriangle.right.fill")
        leftMarker.tintColor = Theme.Color.lime
        rightMarker.image = UIImage(systemName: "arrowtriangle.left.fill")
        rightMarker.tintColor = Theme.Color.lime
        [leftMarker, rightMarker].forEach {
            $0.contentMode = .scaleAspectFit
            $0.isAccessibilityElement = false
        }

        repeatedBadge.text = "↻ Saiu de novo!"
        repeatedBadge.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.heavy)
        repeatedBadge.adjustsFontForContentSizeCategory = true
        repeatedBadge.textColor = Theme.Color.limeInk
        repeatedBadge.backgroundColor = .white
        repeatedBadge.textAlignment = .center
        repeatedBadge.insets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        repeatedBadge.layer.cornerRadius = 14
        repeatedBadge.clipsToBounds = true
        repeatedBadge.layer.shadowColor = UIColor.black.cgColor
        repeatedBadge.layer.shadowOpacity = 0.2
        repeatedBadge.layer.shadowRadius = 8
        repeatedBadge.layer.shadowOffset = CGSize(width: 0, height: 4)
        repeatedBadge.isHidden = true

        messageLabel.font = Theme.Font.scaledDisplay(baseSize: 19, weight: .heavy, textStyle: .headline)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = " " // reserva espaço para não pular layout

        competedCaption.text = "CONCORRERAM"
        competedCaption.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.bold)
        competedCaption.adjustsFontForContentSizeCategory = true
        competedCaption.textColor = UIColor.white.withAlphaComponent(0.8)

        chipsScroll.showsHorizontalScrollIndicator = false
        chipsStack.axis = .horizontal
        chipsStack.alignment = .center
        chipsStack.spacing = 8

        actionsStack.axis = .vertical
        actionsStack.alignment = .fill
        actionsStack.spacing = 10

        bottomBar.backgroundColor = .clear

        if var c = tryAgainButton.configuration {
            c.image = UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            c.imagePadding = 8
            tryAgainButton.configuration = c
        }
        if var c = newDecisionButton.configuration {
            c.title = "Ir para tela inicial"
            c.image = UIImage(systemName: "house", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            c.imagePadding = 8
            newDecisionButton.configuration = c
        }
        tryAgainButton.accessibilityHint = "Realiza um novo sorteio com as mesmas opções."
        newDecisionButton.accessibilityHint = "Volta à tela inicial."

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 10
    }

    private func configureActions() {
        tryAgainButton.addAction(UIAction { [weak self] _ in self?.onTryAgainTapped?() }, for: .touchUpInside)
        newDecisionButton.addAction(UIAction { [weak self] _ in self?.onNewDecisionTapped?() }, for: .touchUpInside)
    }

    private func buildHierarchy() {
        addSubview(glowLime)
        addSubview(glowPink)

        [cardBadge, optionLabel, leftMarker, rightMarker].forEach { card.addSubview($0) }

        actionsStack.addArrangedSubview(tryAgainButton)
        actionsStack.addArrangedSubview(newDecisionButton)
        bottomBar.addSubview(actionsStack)

        chipsScroll.addSubview(chipsStack)

        [questionCaptionLabel, questionLabel, statusLabel, card, repeatedBadge, messageLabel, competedCaption, chipsScroll]
            .forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        addSubview(scrollView)
        addSubview(bottomBar)
    }

    private func activateConstraints() {
        [scrollView, contentStack, bottomBar, actionsStack, glowLime, glowPink, cardBadge, optionLabel, leftMarker, rightMarker, repeatedBadge, chipsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let content = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        let fillWidth = contentStack.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -40)
        fillWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Barra inferior fixa com as ações.
            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            actionsStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            actionsStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            actionsStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            actionsStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            content.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -24),
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            fillWidth,

            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),

            cardBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardBadge.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            optionLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
            optionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
            optionLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 8),
            optionLabel.topAnchor.constraint(greaterThanOrEqualTo: cardBadge.bottomAnchor, constant: 12),
            optionLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -28),

            leftMarker.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            leftMarker.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            leftMarker.widthAnchor.constraint(equalToConstant: 14),
            leftMarker.heightAnchor.constraint(equalToConstant: 22),

            rightMarker.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            rightMarker.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            rightMarker.widthAnchor.constraint(equalToConstant: 14),
            rightMarker.heightAnchor.constraint(equalToConstant: 22),

            // Selo "Saiu de novo!" sobreposto à base do cartão.
            repeatedBadge.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            repeatedBadge.centerYAnchor.constraint(equalTo: card.bottomAnchor),

            chipsScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            chipsStack.topAnchor.constraint(equalTo: chipsScroll.contentLayoutGuide.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScroll.contentLayoutGuide.bottomAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScroll.contentLayoutGuide.leadingAnchor),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScroll.contentLayoutGuide.trailingAnchor),
            chipsStack.heightAnchor.constraint(equalTo: chipsScroll.frameLayoutGuide.heightAnchor),

            glowLime.widthAnchor.constraint(equalToConstant: 280),
            glowLime.heightAnchor.constraint(equalToConstant: 280),
            glowLime.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -96),
            glowLime.centerYAnchor.constraint(equalTo: centerYAnchor),

            glowPink.widthAnchor.constraint(equalToConstant: 300),
            glowPink.heightAnchor.constraint(equalToConstant: 300),
            glowPink.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 96),
            glowPink.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -120),
        ])

        contentStack.setCustomSpacing(4, after: questionCaptionLabel)
        contentStack.setCustomSpacing(16, after: questionLabel)
        contentStack.setCustomSpacing(12, after: statusLabel)
        // Espaçamento maior entre o cartão/selo, a mensagem e "Concorreram".
        contentStack.setCustomSpacing(28, after: repeatedBadge)
        contentStack.setCustomSpacing(28, after: messageLabel)
        contentStack.setCustomSpacing(10, after: competedCaption)
    }

    // MARK: - API para o controller

    func configure(question: String, options: [String]) {
        questionLabel.text = question
        self.options = options
        buildChips()
    }

    /// Mostra a opção atual durante a animação de sorteio.
    func showSpinningOption(_ text: String, index: Int, total: Int, reducedMotion: Bool) {
        isResult = false
        statusLabel.text = "Sorteando..."
        statusLabel.textColor = .white

        applyOptionText(text, highlight: false, animate: !reducedMotion, duration: 0.08)

        cardBadge.isHidden = false
        cardBadge.text = "Opção \(index + 1) de \(total)"
        cardBadge.backgroundColor = Theme.Color.surface2
        cardBadge.textColor = Theme.Color.ink2

        repeatedBadge.isHidden = true
        messageLabel.text = " " // mantém espaço

        // Durante o sorteio, destaca o chip da opção atual (sem ícone de concluído).
        highlightChip(index: index)

        updateCardAppearance()
    }

    /// Revela o resultado final.
    func showResult(option: String, index: Int, repeated: Bool, message: String, reducedMotion: Bool) {
        isResult = true
        statusLabel.text = "E a escolha é…"
        statusLabel.textColor = Theme.Color.lime

        applyOptionText(option, highlight: true, animate: !reducedMotion, duration: 0.12)

        cardBadge.isHidden = false
        cardBadge.text = "✓ Decidido"
        cardBadge.backgroundColor = Theme.Color.lime
        cardBadge.textColor = Theme.Color.limeInk

        repeatedBadge.isHidden = !repeated
        messageLabel.text = message

        // No resultado, destaca o vencedor com marca de concluído.
        highlightChip(index: index)
        updateCardAppearance()
    }

    /// Habilita/desabilita ações (durante a animação).
    func setActionsEnabled(_ enabled: Bool) {
        tryAgainButton.isEnabled = enabled
        newDecisionButton.isEnabled = enabled
    }

    /// Oculta o texto do vencedor para tecnologias assistivas (evita anunciar cada troca).
    func setWinnerAccessibilityHidden(_ hidden: Bool) {
        optionLabel.accessibilityElementsHidden = hidden
    }

    // MARK: - Visual interno

    private func applyOptionText(_ text: String, highlight: Bool, animate: Bool, duration: TimeInterval) {
        let changed = optionLabel.text != text
        if animate && changed {
            if UIAccessibility.isReduceMotionEnabled {
                UIView.transition(with: optionLabel, duration: 0.12, options: .transitionCrossDissolve) {
                    self.optionLabel.attributedText = self.styledOption(text, highlight: highlight)
                }
            } else {
                let transition = CATransition()
                transition.type = .push
                transition.subtype = .fromBottom
                transition.duration = min(duration, 0.12)
                transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
                optionLabel.layer.add(transition, forKey: "slot")
                optionLabel.attributedText = styledOption(text, highlight: highlight)
            }
        } else {
            optionLabel.attributedText = styledOption(text, highlight: highlight)
        }
    }

    private func styledOption(_ text: String, highlight: Bool) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        var attrs: [NSAttributedString.Key: Any] = [
            .font: optionLabel.font as Any,
            .foregroundColor: Theme.Color.ink,
            .paragraphStyle: paragraph
        ]
        if highlight {
            attrs[.backgroundColor] = Theme.Color.highlight
        }
        return NSAttributedString(string: text, attributes: attrs)
    }

    private func updateCardAppearance() {
        if isResult {
            card.layer.borderWidth = 3
            card.layer.borderColor = Theme.Color.lime.resolvedColor(with: traitCollection).cgColor
            leftMarker.isHidden = true
            rightMarker.isHidden = true
        } else {
            card.layer.borderWidth = 1
            card.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
            leftMarker.isHidden = false
            rightMarker.isHidden = false
        }
    }

    private func buildChips() {
        chipViews.forEach { $0.removeFromSuperview() }
        chipsStack.arrangedSubviews.forEach { chipsStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        chipViews = options.enumerated().map { i, text in
            let chip = PaddingLabel()
            chip.text = text
            chip.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.bold)
            chip.adjustsFontForContentSizeCategory = true
            chip.insets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            chip.layer.cornerRadius = 16
            chip.clipsToBounds = true
            chip.lineBreakMode = .byTruncatingTail
            chip.setContentCompressionResistancePriority(.required, for: .horizontal)
            chipsStack.addArrangedSubview(chip)
            return chip
        }
        highlightChip(index: nil)
        chipsStack.layoutIfNeeded()
    }

    private func highlightChip(index: Int?) {
        currentHighlightIndex = index
        for (i, chip) in chipViews.enumerated() {
            let on = (index != nil && i == index)
            if on {
                chip.backgroundColor = Theme.Color.lime
                chip.textColor = Theme.Color.limeInk
                // "Concorreram": vencedor no resultado ganha marca de concluído.
                if isResult {
                    chip.text = "✓ \(options[i])"
                } else {
                    chip.text = options[i]
                }
            } else {
                chip.backgroundColor = UIColor.black.withAlphaComponent(0.25)
                chip.textColor = .white
                if i < options.count { chip.text = options[i] }
            }
        }
    }

    /// Reaplica o destaque dos chips (ex.: ao mudar tema).
    private func refreshChips() {
        highlightChip(index: currentHighlightIndex)
    }

    /// Atualiza o chip ativo durante o sorteio sem revelar vencedor (sem destaque lime de resultado).
    func highlightSpinningIndex(_ index: Int) {
        _ = index
    }
}

private final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right, height: s.height + insets.top + insets.bottom)
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let d = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: d, size: pointSize)
    }
}
