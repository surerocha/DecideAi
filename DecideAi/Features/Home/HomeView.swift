//
//  HomeView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View da Home (identidade Figma)

/// Tela inicial com a identidade visual do protótipo:
/// fundo em gradiente de marca, composição hero, título expressivo e CTA em lima.
/// Mantém o callback `onStartTapped` para navegação (controller não muda).
final class HomeView: UIView {

    // MARK: - Callback

    /// Chamado quando o usuário toca em "Nova decisão".
    var onStartTapped: (() -> Void)?

    // MARK: - Camadas e componentes

    private let gradientLayer = CAGradientLayer()
    private let glowLime = UIView()
    private let glowPink = UIView()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let heroContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let explanationLabel = UILabel()
    private let stepsStack = UIStackView()

    // CTA principal no estilo "lime" do protótipo.
    private let startButton = PrimaryButton(title: "Nova decisão", style: .lime)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        buildHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Gradiente precisa acompanhar o tamanho da view.
        gradientLayer.frame = bounds
        Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)
        layoutGlows()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)
        }
    }

    // MARK: - Configuração

    private func configureViews() {
        // Fundo gradiente de marca.
        layer.insertSublayer(gradientLayer, at: 0)
        Theme.applyBrandGradient(to: gradientLayer, trait: traitCollection)

        // Glows decorativos (blobs desfocados via alpha grande; aproxima o protótipo).
        glowLime.backgroundColor = Theme.Color.lime.withAlphaComponent(0.22)
        glowPink.backgroundColor = Theme.Color.coral.withAlphaComponent(0.22)
        glowLime.layer.cornerRadius = 160
        glowPink.layer.cornerRadius = 160
        glowLime.isUserInteractionEnabled = false
        glowPink.isUserInteractionEnabled = false

        // Hero: ícone/cartas simplificado com SF Symbols e composição leve.
        heroContainer.isAccessibilityElement = false

        // Título "Decide Aí" com "Aí" em lima (estilo do protótipo).
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        let title = NSMutableAttributedString(
            string: "Decide ",
            attributes: [
                .font: Theme.Font.scaledDisplay(baseSize: 56, weight: .black, textStyle: .largeTitle),
                .foregroundColor: UIColor.white
            ]
        )
        title.append(NSAttributedString(
            string: "Aí",
            attributes: [
                .font: Theme.Font.scaledDisplay(baseSize: 56, weight: .black, textStyle: .largeTitle),
                .foregroundColor: Theme.Color.lime
            ]
        ))
        titleLabel.attributedText = title
        titleLabel.accessibilityLabel = "Decide Aí"
        titleLabel.accessibilityTraits = .header

        // Subtítulo e explicação.
        subtitleLabel.text = "Não consegue escolher? A gente decide com você."
        subtitleLabel.font = Theme.Font.scaledDisplay(baseSize: 22, weight: .heavy, textStyle: .title2)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        explanationLabel.text = "Adicione suas opções e deixe o sorteio escolher. Sem drama, em poucos toques."
        explanationLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        explanationLabel.adjustsFontForContentSizeCategory = true
        explanationLabel.textColor = Theme.Color.onBrandMuted
        explanationLabel.textAlignment = .center
        explanationLabel.numberOfLines = 0

        // Chips de passos (Pergunte / Adicione / Sorteie).
        stepsStack.axis = .horizontal
        stepsStack.alignment = .center
        stepsStack.spacing = 8
        stepsStack.distribution = .fillProportionally
        let steps = ["Pergunte", "Adicione", "Sorteie"]
        for (i, text) in steps.enumerated() {
            stepsStack.addArrangedSubview(makeStepChip(index: i + 1, text: text))
        }

        // Botão CTA.
        startButton.accessibilityHint = "Abre a tela para criar uma nova decisão."
        // Ícone de "+" como no protótipo.
        if var config = startButton.configuration {
            config.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            config.imagePadding = 8
            startButton.configuration = config
        }
        startButton.addAction(UIAction { [weak self] _ in
            self?.onStartTapped?()
        }, for: .touchUpInside)

        // Stack principal.
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        contentStack.setCustomSpacing(Theme.Spacing.large, after: heroContainer)
        contentStack.setCustomSpacing(Theme.Spacing.small, after: subtitleLabel)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: stepsStack)
    }

    private func buildHierarchy() {
        addSubview(glowLime)
        addSubview(glowPink)

        buildHero()

        [heroContainer, titleLabel, subtitleLabel, explanationLabel, stepsStack, startButton]
            .forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    /// Monta uma composição hero simples (marca/cartas) inspirada no protótipo.
    private func buildHero() {
        // Três "cartas" e uma carta destaque com "?" para remeter ao hero do Figma.
        let back1 = makeHeroCard(text: "03", bg: UIColor(hex: 0xB9A6FF), rotation: -0.05)
        let back2 = makeHeroCard(text: "01", bg: .white, rotation: -0.26)
        let back3 = makeHeroCard(text: "02", bg: Theme.Color.coral, rotation: 0.22)
        let front = makeHeroFrontCard()

        [back2, back1, back3, front].forEach { heroContainer.addSubview($0) }

        // Posicionamento manual simples dentro do container (tamanho fixo).
        [back1, back2, back3, front, heroContainer].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            heroContainer.heightAnchor.constraint(equalToConstant: 220),

            back2.widthAnchor.constraint(equalToConstant: 90), back2.heightAnchor.constraint(equalToConstant: 120),
            back2.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor, constant: -55),
            back2.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor, constant: 10),

            back3.widthAnchor.constraint(equalToConstant: 90), back3.heightAnchor.constraint(equalToConstant: 120),
            back3.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor, constant: 55),
            back3.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor, constant: 6),

            back1.widthAnchor.constraint(equalToConstant: 90), back1.heightAnchor.constraint(equalToConstant: 120),
            back1.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            back1.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor, constant: -12),

            front.widthAnchor.constraint(equalToConstant: 96), front.heightAnchor.constraint(equalToConstant: 132),
            front.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor, constant: 6),
            front.centerYAnchor.constraint(equalTo: heroContainer.centerYAnchor, constant: 18),
        ])
    }

    private func makeHeroCard(text: String, bg: UIColor, rotation: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        v.transform = CGAffineTransform(rotationAngle: rotation)
        let label = UILabel()
        label.text = text
        label.font = Theme.Font.display(size: 20, weight: .black)
        label.textColor = Theme.Color.limeInk.withAlphaComponent(0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10)
        ])
        return v
    }

    private func makeHeroFrontCard() -> UIView {
        let v = UIView()
        v.backgroundColor = Theme.Color.lime
        v.layer.cornerRadius = 22
        v.layer.cornerCurve = .continuous
        v.transform = CGAffineTransform(rotationAngle: 0.08)
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.25
        v.layer.shadowRadius = 18
        v.layer.shadowOffset = CGSize(width: 0, height: 12)

        let q = UILabel()
        q.text = "?"
        q.font = Theme.Font.display(size: 72, weight: .black)
        q.textColor = Theme.Color.limeInk
        q.textAlignment = .center
        let cap = UILabel()
        cap.text = "E A ESCOLHA É…"
        cap.font = Theme.Font.display(size: 9, weight: .heavy)
        cap.textColor = Theme.Color.limeInk
        cap.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [q, cap])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        return v
    }

    private func makeStepChip(index: Int, text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor

        let badge = UILabel()
        badge.text = "\(index)"
        badge.font = Theme.Font.display(size: 11, weight: .black)
        badge.textColor = Theme.Color.limeInk
        badge.textAlignment = .center
        badge.backgroundColor = Theme.Color.lime
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true

        let label = UILabel()
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.bold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white

        [badge, label].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; container.addSubview($0) }
        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            badge.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 20),
            label.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)
        ])
        return container
    }

    private func activateConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        glowLime.translatesAutoresizingMaskIntoConstraints = false
        glowPink.translatesAutoresizingMaskIntoConstraints = false

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor, constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: Theme.Spacing.extraLarge),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -Theme.Spacing.extraLarge),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            fillWidth,

            glowLime.widthAnchor.constraint(equalToConstant: 320),
            glowLime.heightAnchor.constraint(equalToConstant: 320),
            glowLime.topAnchor.constraint(equalTo: topAnchor, constant: -120),
            glowLime.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 80),

            glowPink.widthAnchor.constraint(equalToConstant: 300),
            glowPink.heightAnchor.constraint(equalToConstant: 300),
            glowPink.topAnchor.constraint(equalTo: topAnchor, constant: 260),
            glowPink.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -140),
        ])
    }

    private func layoutGlows() {
        // cantos grandes garantem aparência suave sem blur real (aproximação leve).
        glowLime.layer.cornerRadius = glowLime.bounds.height / 2
        glowPink.layer.cornerRadius = glowPink.bounds.height / 2
    }
}

// MARK: - Helper de peso de fonte
private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, a hierarquia é declarativa: descrevemos "o que" mostrar e o framework cuida
 de criar/atualizar as views. ScrollView, VStack, Image (SF Symbols), Text e Button
 substituem UIScrollView, UIStackView, UIImageView, UILabel e UIButton.

 import SwiftUI

 struct HomeView: View {
     // Ação injetada pelo pai (equivalente ao callback onStartTapped).
     var onStartTapped: () -> Void

     var body: some View {
         ScrollView {
             VStack(spacing: 16) {
                 Image(systemName: "die.face.5.fill")
                     .font(.system(size: 72, weight: .semibold))
                     .foregroundStyle(.indigo)
                     .accessibilityHidden(true) // ícone decorativo

                 Text("Decide Aí")
                     .font(.largeTitle.bold())
                     .accessibilityAddTraits(.isHeader)

                 Text("Não consegue escolher? Deixa comigo!")
                     .font(.title2.bold())

                 Text("Crie uma decisão, adicione suas alternativas e deixe o sorteio escolher por você.")
                     .font(.body)
                     .foregroundStyle(.secondary)

                 Spacer().frame(height: 16)

                 Button("Nova decisão", action: onStartTapped)
                     .buttonStyle(PrimaryButtonStyle())
                     .accessibilityHint("Abre a tela para criar uma nova decisão.")

                 Text("Você tem opções. A gente resolve.")
                     .font(.footnote)
                     .foregroundStyle(.secondary)
             }
             .multilineTextAlignment(.center)
             .padding(24)
             .frame(maxWidth: 560) // limite de largura (maxContentWidth)
             .frame(maxWidth: .infinity) // centraliza dentro da área disponível
         }
         .background(Color(.systemBackground))
     }
 }

 Diferenças principais:
 - Não há Auto Layout manual: stacks, padding e frame declaram intenção de layout.
 - Dynamic Type é natural com fontes como .body/.title.
 - Estado e ações fluem por parâmetros/bindings, sem target-action manual.
*/
