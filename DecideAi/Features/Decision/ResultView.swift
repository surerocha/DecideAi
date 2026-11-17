//
//  ResultView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View do sorteio/resultado (identidade Figma)

/// Tela de sorteio com fundo gradiente de marca, cartão central de resultado e ações.
/// Mantém a API usada pelo `ResultViewController` (`setQuestion`, `showOption`,
/// `setActionsEnabled`, `setWinnerAccessibilityHidden`) para não quebrar a lógica/animação.
final class ResultView: UIView {

    // MARK: - Callbacks

    var onTryAgainTapped: (() -> Void)?
    var onNewDecisionTapped: (() -> Void)?

    // MARK: - UI

    private let gradientLayer = CAGradientLayer()
    private let glowLime = UIView()
    private let glowPink = UIView()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let questionCaptionLabel = UILabel()
    private let questionLabel = UILabel()

    private let statusLabel = UILabel()
    private let resultCard = UIView()
    private let optionLabel = UILabel()

    private let actionsStack = UIStackView()
    private let tryAgainButton = PrimaryButton(title: "Sortear novamente", style: .lime)
    private let newDecisionButton = PrimaryButton(title: "Nova decisão", style: .glass)

    // Indica se estamos exibindo o estado final (para realçar o cartão).
    private var isFinalState = false

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
        glowLime.layer.cornerRadius = glowLime.bounds.height / 2
        glowPink.layer.cornerRadius = glowPink.bounds.height / 2
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)
        }
    }

    // MARK: - Configuração

    private func configureViews() {
        layer.insertSublayer(gradientLayer, at: 0)
        Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)

        glowLime.backgroundColor = Theme.Color.lime.withAlphaComponent(0.20)
        glowPink.backgroundColor = Theme.Color.coral.withAlphaComponent(0.22)
        glowLime.isUserInteractionEnabled = false
        glowPink.isUserInteractionEnabled = false

        questionCaptionLabel.text = "SUA PERGUNTA"
        questionCaptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.bold)
        questionCaptionLabel.adjustsFontForContentSizeCategory = true
        questionCaptionLabel.textColor = Theme.Color.onBrandMuted
        questionCaptionLabel.textAlignment = .center

        questionLabel.font = Theme.Font.scaledDisplay(baseSize: 22, weight: .heavy, textStyle: .title3)
        questionLabel.adjustsFontForContentSizeCategory = true
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0

        statusLabel.text = "Sorteando..."
        statusLabel.font = Theme.Font.scaledDisplay(baseSize: 24, weight: .black, textStyle: .title2)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center

        // Cartão central onde a opção anima/aparece.
        resultCard.backgroundColor = Theme.Color.surface
        resultCard.layer.cornerRadius = 32
        resultCard.layer.cornerCurve = .continuous
        resultCard.layer.shadowColor = UIColor.black.cgColor
        resultCard.layer.shadowOpacity = 0.25
        resultCard.layer.shadowRadius = 24
        resultCard.layer.shadowOffset = CGSize(width: 0, height: 16)

        optionLabel.font = Theme.Font.scaledDisplay(baseSize: 40, weight: .black, textStyle: .largeTitle)
        optionLabel.adjustsFontForContentSizeCategory = true
        optionLabel.textColor = Theme.Color.ink
        optionLabel.textAlignment = .center
        optionLabel.numberOfLines = 0
        optionLabel.accessibilityTraits = .header

        actionsStack.axis = .vertical
        actionsStack.alignment = .fill
        actionsStack.spacing = 10

        // Ícones nos botões para aproximar do protótipo.
        if var c = tryAgainButton.configuration {
            c.image = UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            c.imagePadding = 8
            tryAgainButton.configuration = c
        }
        if var c = newDecisionButton.configuration {
            c.image = UIImage(systemName: "house", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            c.imagePadding = 8
            newDecisionButton.configuration = c
        }
        tryAgainButton.accessibilityHint = "Realiza um novo sorteio com as mesmas opções."
        newDecisionButton.accessibilityHint = "Volta ao início para criar uma nova decisão."

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        contentStack.setCustomSpacing(4, after: questionCaptionLabel)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: questionLabel)
        contentStack.setCustomSpacing(12, after: statusLabel)
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: resultCard)
    }

    private func configureActions() {
        tryAgainButton.addAction(UIAction { [weak self] _ in self?.onTryAgainTapped?() }, for: .touchUpInside)
        newDecisionButton.addAction(UIAction { [weak self] _ in self?.onNewDecisionTapped?() }, for: .touchUpInside)
    }

    private func buildHierarchy() {
        addSubview(glowLime)
        addSubview(glowPink)

        resultCard.addSubview(optionLabel)
        optionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            optionLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 24),
            optionLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -24),
            optionLabel.centerYAnchor.constraint(equalTo: resultCard.centerYAnchor),
            optionLabel.topAnchor.constraint(greaterThanOrEqualTo: resultCard.topAnchor, constant: 28),
            optionLabel.bottomAnchor.constraint(lessThanOrEqualTo: resultCard.bottomAnchor, constant: -28),
            resultCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
        ])

        actionsStack.addArrangedSubview(tryAgainButton)
        actionsStack.addArrangedSubview(newDecisionButton)

        [questionCaptionLabel, questionLabel, statusLabel, resultCard, actionsStack]
            .forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    private func activateConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        glowLime.translatesAutoresizingMaskIntoConstraints = false
        glowPink.translatesAutoresizingMaskIntoConstraints = false

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor, constant: -2 * 20
        )
        fillWidth.priority = .defaultHigh
        let centerY = contentStack.centerYAnchor.constraint(equalTo: frame.centerYAnchor)
        centerY.priority = .defaultLow

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            fillWidth, centerY,

            glowLime.widthAnchor.constraint(equalToConstant: 300),
            glowLime.heightAnchor.constraint(equalToConstant: 300),
            glowLime.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -100),
            glowLime.topAnchor.constraint(equalTo: topAnchor, constant: 140),
            glowPink.widthAnchor.constraint(equalToConstant: 280),
            glowPink.heightAnchor.constraint(equalToConstant: 280),
            glowPink.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 80),
            glowPink.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -120),
        ])
    }

    // MARK: - API para o controller

    func setQuestion(_ question: String) {
        questionLabel.text = question
    }

    /// Mostra um texto no destaque do resultado (chamado a cada frame da animação).
    /// Aplica uma transição sutil de "slot" para dar sensação de troca.
    func showOption(_ text: String) {
        // Se o texto mudou, anima uma queda leve (inspira o slotIn do protótipo).
        if optionLabel.text != text {
            let transition = CATransition()
            transition.type = .push
            transition.subtype = .fromBottom
            transition.duration = 0.08
            transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
            optionLabel.layer.add(transition, forKey: "slot")
        }
        optionLabel.text = text

        // Heurística visual: enquanto ações estiverem desabilitadas o controller está animando;
        // aqui apenas atualizamos estilo se já marcado como final via setActionsEnabled.
    }

    /// Habilita/desabilita ações e alterna estado visual (sorteando x decidido).
    func setActionsEnabled(_ enabled: Bool) {
        tryAgainButton.isEnabled = enabled
        newDecisionButton.isEnabled = enabled
        isFinalState = enabled
        updateStateAppearance()
    }

    func setWinnerAccessibilityHidden(_ hidden: Bool) {
        optionLabel.accessibilityElementsHidden = hidden
    }

    private func updateStateAppearance() {
        if isFinalState {
            statusLabel.text = "E a escolha é…"
            statusLabel.textColor = Theme.Color.lime
            resultCard.layer.borderWidth = 3
            resultCard.layer.borderColor = Theme.Color.lime.resolvedColor(with: traitCollection).cgColor
        } else {
            statusLabel.text = "Sorteando..."
            statusLabel.textColor = .white
            resultCard.layer.borderWidth = 0
            resultCard.layer.borderColor = nil
        }
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let d = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: d, size: pointSize)
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
