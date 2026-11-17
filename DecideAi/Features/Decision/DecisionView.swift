//
//  DecisionView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View da tela de criação (identidade Figma)

/// Tela de criação com visual do protótipo: fundo canvas, campos estilizados,
/// opções em cartões com badge colorida e ações, contador, estado vazio e CTA.
/// Mantém a API pública usada pelo `DecisionViewController` (callbacks e métodos).
final class DecisionView: UIView {

    // MARK: - Callbacks (View -> Controller)

    var onQuestionChanged: ((String) -> Void)?
    var onAddOption: ((String) -> Void)?
    var onEditOption: ((Int) -> Void)?
    var onRemoveOption: ((Int) -> Void)?
    var onDrawTapped: (() -> Void)?

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let questionSectionLabel = makeSectionLabel("PERGUNTA")
    private let questionTextField = PaddedTextField()

    private let optionsHeaderStack = UIStackView()
    private let optionsTitleLabel = UILabel()
    private let optionsCountBadge = PaddingLabel()
    private let minLabel = UILabel()

    private let addRowStack = UIStackView()
    private let newOptionTextField = PaddedTextField()
    private let addOptionButton = UIButton(type: .system)

    private let emptyStateView = UIView()
    private let optionsListStack = UIStackView()

    private let hintLabel = UILabel()
    private let drawButton = PrimaryButton(title: "Sortear", style: .primary)

    private var keyboardObservers: [NSObjectProtocol] = []
    private weak var activeTextField: UITextField?
    private let keyboardScrollPadding: CGFloat = 48
    private var currentOptionCount = 0

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureActions()
        configureKeyboardHandling()
        buildHierarchy()
        activateConstraints()
        updateHint(enabled: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Configuração

    private func configureViews() {
        backgroundColor = Theme.Color.canvas

        titleLabel.text = "Nova decisão"
        titleLabel.font = Theme.Font.scaledDisplay(baseSize: 34, weight: .black, textStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Theme.Color.ink

        subtitleLabel.text = "Pergunte, adicione as opções e sorteie."
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = Theme.Color.ink2
        subtitleLabel.numberOfLines = 0

        styleField(questionTextField, placeholder: "O que você quer decidir?")
        questionTextField.accessibilityLabel = "Pergunta da decisão"
        questionTextField.returnKeyType = .done
        questionTextField.delegate = self

        // Cabeçalho de opções: "Opções" + mín + contador n/MAX
        optionsTitleLabel.text = "Opções"
        optionsTitleLabel.font = Theme.Font.scaledDisplay(baseSize: 22, weight: .black, textStyle: .title2)
        optionsTitleLabel.adjustsFontForContentSizeCategory = true
        optionsTitleLabel.textColor = Theme.Color.ink

        minLabel.text = "mín. 2"
        minLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        minLabel.adjustsFontForContentSizeCategory = true
        minLabel.textColor = Theme.Color.ink2

        optionsCountBadge.font = Theme.Font.display(size: 13, weight: .heavy)
        optionsCountBadge.textAlignment = .center
        optionsCountBadge.insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        optionsCountBadge.layer.cornerRadius = 12
        optionsCountBadge.clipsToBounds = true

        optionsHeaderStack.axis = .horizontal
        optionsHeaderStack.alignment = .center
        optionsHeaderStack.spacing = 8

        // Linha de adicionar
        addRowStack.axis = .horizontal
        addRowStack.alignment = .fill
        addRowStack.spacing = 10

        styleField(newOptionTextField, placeholder: "Nova opção")
        newOptionTextField.accessibilityLabel = "Nova alternativa"
        newOptionTextField.returnKeyType = .done
        newOptionTextField.delegate = self

        var addConfig = UIButton.Configuration.filled()
        addConfig.title = "Adicionar"
        addConfig.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        addConfig.imagePadding = 4
        addConfig.baseBackgroundColor = Theme.Color.accentSoft
        addConfig.baseForegroundColor = Theme.Color.accentText
        addConfig.cornerStyle = .fixed
        addConfig.background.cornerRadius = Theme.Layout.fieldRadius
        addConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 14)
        addConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var r = a; r.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: Theme.Font.display(size: 15, weight: .heavy)); return r
        }
        addOptionButton.configuration = addConfig
        addOptionButton.setContentHuggingPriority(.required, for: .horizontal)
        addOptionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addOptionButton.accessibilityHint = "Adiciona a alternativa digitada à lista."

        // Lista e estado vazio
        optionsListStack.axis = .vertical
        optionsListStack.alignment = .fill
        optionsListStack.spacing = 10
        buildEmptyState()

        // Hint + CTA
        hintLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        hintLabel.adjustsFontForContentSizeCategory = true
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        if var c = drawButton.configuration {
            c.image = UIImage(systemName: "die.face.5", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            c.imagePadding = 8
            drawButton.configuration = c
        }
        drawButton.accessibilityHint = "Realiza o sorteio quando houver opções suficientes."

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: subtitleLabel)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: questionTextField)
        contentStack.setCustomSpacing(10, after: addRowStack)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: optionsListStack)
    }

    private func styleField(_ field: PaddedTextField, placeholder: String) {
        field.placeholder = placeholder
        field.font = UIFont.preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = Theme.Color.ink
        field.backgroundColor = Theme.Color.surface
        field.layer.cornerRadius = Theme.Layout.fieldRadius
        field.layer.cornerCurve = .continuous
        field.layer.borderWidth = 1.5
        field.layer.borderColor = Theme.Color.line.resolvedColor(with: traitCollection).cgColor
        field.clearButtonMode = .whileEditing
    }

    private func buildEmptyState() {
        // Cartão vazio tracejado com ilustração simples (cartas/?), como no protótipo.
        emptyStateView.layer.cornerRadius = Theme.Layout.cardRadius
        emptyStateView.layer.borderWidth = 1.5
        emptyStateView.layer.borderColor = Theme.Color.ink2.withAlphaComponent(0.35).cgColor

        let q = UILabel()
        q.text = "?"
        q.font = Theme.Font.display(size: 34, weight: .black)
        q.textColor = Theme.Color.limeInk
        q.textAlignment = .center
        q.backgroundColor = Theme.Color.lime
        q.layer.cornerRadius = 14
        q.clipsToBounds = true

        let t = UILabel()
        t.text = "Nenhuma opção ainda"
        t.font = Theme.Font.display(size: 20, weight: .heavy)
        t.textColor = Theme.Color.ink
        t.textAlignment = .center
        let s = UILabel()
        s.text = "Adicione suas opções e deixe o sorteio escolher."
        s.font = UIFont.preferredFont(forTextStyle: .subheadline)
        s.textColor = Theme.Color.ink2
        s.textAlignment = .center
        s.numberOfLines = 0

        [q, t, s].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; emptyStateView.addSubview($0) }
        NSLayoutConstraint.activate([
            q.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 20),
            q.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            q.widthAnchor.constraint(equalToConstant: 48), q.heightAnchor.constraint(equalToConstant: 56),
            t.topAnchor.constraint(equalTo: q.bottomAnchor, constant: 12),
            t.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            t.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            s.topAnchor.constraint(equalTo: t.bottomAnchor, constant: 4),
            s.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            s.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: -20),
        ])
    }

    private func configureActions() {
        questionTextField.addAction(UIAction { [weak self] _ in
            self?.onQuestionChanged?(self?.questionTextField.text ?? "")
        }, for: .editingChanged)

        addOptionButton.addAction(UIAction { [weak self] _ in
            self?.onAddOption?(self?.newOptionTextField.text ?? "")
        }, for: .touchUpInside)

        drawButton.addAction(UIAction { [weak self] _ in
            self?.onDrawTapped?()
        }, for: .touchUpInside)
    }

    // MARK: - Hierarquia e layout

    private func buildHierarchy() {
        let spacer = UIView()
        optionsHeaderStack.addArrangedSubview(optionsTitleLabel)
        optionsHeaderStack.addArrangedSubview(spacer)
        optionsHeaderStack.addArrangedSubview(minLabel)
        optionsHeaderStack.addArrangedSubview(optionsCountBadge)

        addRowStack.addArrangedSubview(newOptionTextField)
        addRowStack.addArrangedSubview(addOptionButton)

        [titleLabel, subtitleLabel,
         questionSectionLabel, questionTextField,
         optionsHeaderStack, addRowStack, emptyStateView, optionsListStack,
         hintLabel, drawButton
        ].forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    private func activateConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor, constant: -2 * 20
        )
        fillWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth,
            questionTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            newOptionTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            addOptionButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    // MARK: - API pública (compatível com controller)

    func displayOptions(_ options: [String]) {
        optionsListStack.arrangedSubviews.forEach { v in
            optionsListStack.removeArrangedSubview(v); v.removeFromSuperview()
        }
        for (index, option) in options.enumerated() {
            optionsListStack.addArrangedSubview(makeOptionRow(text: option, index: index))
        }
        currentOptionCount = options.count
        emptyStateView.isHidden = !options.isEmpty
        optionsListStack.isHidden = options.isEmpty
        optionsCountBadge.text = "\(options.count)/\(Decision.maxOptions)"

        // Cor do badge conforme estado (como no protótipo).
        if options.count >= Decision.maxOptions {
            optionsCountBadge.backgroundColor = Theme.Color.dangerSoft
            optionsCountBadge.textColor = Theme.Color.danger
        } else if options.count >= Decision.minOptions {
            optionsCountBadge.backgroundColor = Theme.Color.accentSoft
            optionsCountBadge.textColor = Theme.Color.accentText
        } else {
            optionsCountBadge.backgroundColor = Theme.Color.surface2
            optionsCountBadge.textColor = Theme.Color.ink2
        }
    }

    func clearNewOptionField() { newOptionTextField.text = "" }

    func setDrawEnabled(_ enabled: Bool) {
        drawButton.isEnabled = enabled
        // Garante atualização visual do botão (configuração/estado).
        drawButton.setNeedsUpdateConfiguration()
        updateHint(enabled: enabled)
    }

    private func updateHint(enabled: Bool) {
        let n = currentOptionCount
        if n == 0 {
            hintLabel.text = "Adicione pelo menos \(Decision.minOptions) opções para sortear"
            hintLabel.textColor = Theme.Color.ink2
        } else if n < Decision.minOptions {
            hintLabel.text = "Falta 1 opção para sortear"
            hintLabel.textColor = Theme.Color.ink2
        } else if n >= Decision.maxOptions {
            hintLabel.text = "Limite de \(Decision.maxOptions) opções atingido"
            hintLabel.textColor = Theme.Color.danger
        } else {
            hintLabel.text = "\(n) opções prontas para o sorteio"
            hintLabel.textColor = enabled ? Theme.Color.accentText : Theme.Color.ink2
        }
    }

    // MARK: - Linha de opção (cartão)

    private func makeOptionRow(text: String, index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = Theme.Color.surface
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Theme.Color.line.resolvedColor(with: traitCollection).cgColor

        let badge = UILabel()
        badge.text = "\(index + 1)"
        badge.font = Theme.Font.display(size: 15, weight: .black)
        badge.textColor = Theme.Color.limeInk
        badge.textAlignment = .center
        badge.backgroundColor = Theme.Color.optionPalette[index % Theme.Color.optionPalette.count]
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true

        let label = UILabel()
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .body).withWeight(.semibold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.Color.ink
        label.numberOfLines = 0

        let editButton = makeIconAction(system: "pencil", tint: Theme.Color.accentText, bg: Theme.Color.accentSoft, a11y: "Editar opção", value: text) { [weak self] in
            self?.onEditOption?(index)
        }
        let removeButton = makeIconAction(system: "trash", tint: Theme.Color.danger, bg: Theme.Color.dangerSoft, a11y: "Remover opção", value: text) { [weak self] in
            self?.onRemoveOption?(index)
        }

        [badge, label, editButton, removeButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0) }
        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            badge.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 32), badge.heightAnchor.constraint(equalToConstant: 32),

            label.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            removeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
            removeButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -2),
            editButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -8),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
        return card
    }

    private func makeIconAction(system: String, tint: UIColor, bg: UIColor, a11y: String, value: String, action: @escaping () -> Void) -> UIButton {
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: system, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        cfg.baseForegroundColor = tint
        cfg.background.backgroundColor = bg
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        b.configuration = cfg
        b.accessibilityLabel = a11y
        b.accessibilityValue = value
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        b.widthAnchor.constraint(equalToConstant: 36).isActive = true
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return b
    }

    // MARK: - Teclado

    private func configureKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
        let obs = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main
        ) { [weak self] n in self?.adjustForKeyboard(notification: n) }
        keyboardObservers = [obs]
    }

    @objc private func dismissKeyboard() { endEditing(true) }

    private func adjustForKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let kbFrame = convert(frameValue.cgRectValue, from: nil)
        let intersection = scrollView.frame.intersection(kbFrame)
        let bottomInset = max(0, intersection.height - safeAreaInsets.bottom)
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.layoutIfNeeded()
        } completion: { _ in
            if bottomInset > 0 { self.scrollActiveFieldIntoViewIfNeeded() }
        }
    }

    private func scrollActiveFieldIntoViewIfNeeded(animated: Bool = true) {
        guard let activeTextField else { return }
        let rect = activeTextField.convert(activeTextField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -keyboardScrollPadding), animated: animated)
    }

    // MARK: - Helpers

    private static func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.bold)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = Theme.Color.ink2
        return l
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            [questionTextField, newOptionTextField].forEach {
                $0.layer.borderColor = Theme.Color.line.resolvedColor(with: traitCollection).cgColor
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension DecisionView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        DispatchQueue.main.async { [weak self] in self?.scrollActiveFieldIntoViewIfNeeded() }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeTextField == textField { activeTextField = nil }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}

// MARK: - Componentes auxiliares

/// UITextField com padding interno para combinar com o estilo do protótipo.
private final class PaddedTextField: UITextField {
    var insets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: insets) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: insets) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: insets) }
}

/// UILabel com padding (usada no badge de contagem).
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

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, formulários e listas são declarativos e o gerenciamento de teclado/scroll é,
 em muitos casos, mais automático. A edição de estado também é mais direta com bindings.

 import SwiftUI

 struct DecisionCreateView: View {
     @State private var question = ""
     @State private var options: [String] = []
     @State private var newOption = ""
     @FocusState private var focusedField: Field?

     enum Field { case question, newOption }

     var body: some View {
         Form {
             Section("O que você quer decidir?") {
                 TextField("Digite sua pergunta", text: $question)
                     .focused($focusedField, equals: .question)
                     .submitLabel(.done)
             }

             Section("Opções") {
                 // Lista editável: cada linha com texto e ações.
                 ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                     HStack {
                         Text(option)
                         Spacer()
                         Button { /* editar (ex.: sheet/alert) */ } label: {
                             Image(systemName: "pencil")
                         }
                         .buttonStyle(.borderless)

                         Button(role: .destructive) { options.remove(at: index) } label: {
                             Image(systemName: "trash")
                         }
                         .buttonStyle(.borderless)
                     }
                 }

                 HStack {
                     TextField("Nova alternativa", text: $newOption)
                         .focused($focusedField, equals: .newOption)
                         .submitLabel(.done)
                     Button("Adicionar") {
                         let clean = newOption.trimmingCharacters(in: .whitespacesAndNewlines)
                         guard !clean.isEmpty else { return }
                         options.append(clean)
                         newOption = ""
                     }
                 }
             }

             Section {
                 Button("Sortear") { /* validar, gerar plano, navegar */ }
                     .disabled(options.count < 2 || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
             }
         }
         .navigationTitle("Nova decisão")
         .scrollDismissesKeyboard(.interactively) // ajuda a dispensar teclado ao rolar
         .onSubmit { focusedField = nil } // "Done" fecha/avança conforme o caso
     }
 }

 Diferenças principais:
 - `Form`/`List` + `ForEach` substituem stacks manuais e reconstrução de linhas.
 - `@FocusState` e `.focused(...)` controlam foco/teclado declarativamente.
 - Ajustes de teclado/rolagem frequentemente exigem menos código (e o sistema lida melhor).
 - Bindings (`$question`, `$newOption`) eliminam callbacks manuais de mudança de texto.
 - No UIKit fizemos tudo com UIView/Auto Layout/Notifications; no SwiftUI declaramos estado e UI.
*/
