//
//  DecisionView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View da tela de criação (protótipo v2)

/// Tela de criação da decisão (protótipo v2): pergunta multilinha com contador,
/// validação inline, lista de opções com edição/remoção imediata (deslize ou lixeira)
/// e toque na linha/lápis para editar, estado vazio, dica e CTA "Sortear".
///
/// A View expõe callbacks e APIs simples; regras ficam no `Decision` e coordenação no controller.
final class DecisionView: UIView {

    // MARK: - Callbacks (View -> Controller)

    var onQuestionChanged: ((String) -> Void)?
    var onDraftChanged: ((String) -> Void)?
    var onAddOption: (() -> Void)?
    var onEditOption: ((Int) -> Void)?
    var onRemoveOption: ((Int) -> Void)?
    var onDrawTapped: (() -> Void)?

    // MARK: - Estado visual

    private var optionCount = 0
    private var hasQuestionText = false
    private var options: [String] = []

    // MARK: - UI base

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    /// Barra inferior com gradiente e CTA fixo.
    private let bottomBar = UIView()
    private let bottomGradient = CAGradientLayer()

    // MARK: - Pergunta

    private let questionSectionLabel = makeSectionLabel("PERGUNTA")
    private let questionContainer = UIView()
    private let questionTextView = UITextView()
    private let questionPlaceholder = UILabel()
    private let questionErrorIcon = UIImageView()
    private var questionHeightConstraint: NSLayoutConstraint!
    private var questionTrailingToContainer: NSLayoutConstraint!
    private var questionTrailingToIcon: NSLayoutConstraint!
    private let questionMessageRow = UIStackView()
    private let questionMessageLabel = UILabel()
    private let questionCounterLabel = UILabel()

    // MARK: - Opções

    private let optionsHeaderRow = UIStackView()
    private let optionsSectionLabel = makeSectionLabel("OPÇÕES")
    private let optionsCountLabel = UILabel()

    private let addRow = UIStackView()
    private let draftContainer = UIView()
    private let draftField = UITextField()
    private let draftErrorIcon = UIImageView()
    private var draftTrailingToContainer: NSLayoutConstraint!
    private var draftTrailingToIcon: NSLayoutConstraint!
    private let addButton = UIButton(type: .system)
    private let draftMessageRow = UIStackView()
    private let draftMessageLabel = UILabel()
    private let draftCounterLabel = UILabel()

    private let emptyStateView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var tableHeightConstraint: NSLayoutConstraint!

    // MARK: - Dica e ação principal

    private let hintStack = UIStackView()
    private let hintIcon = UIImageView()
    private let hintLabel = UILabel()
    private let drawButton = PrimaryButton(title: "Sortear", style: .primary)

    // Teclado
    private var keyboardObservers: [NSObjectProtocol] = []
    private weak var activeInput: UIView?

    // Constantes
    private let maxQuestion = Decision.maxQuestionLength
    private let maxOption = Decision.maxOptionLength
    private static let questionErrorText = "Escreva o que você quer decidir."

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureActions()
        configureKeyboardHandling()
        buildHierarchy()
        activateConstraints()
        refreshDerivedUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Configuração

    private func configureViews() {
        backgroundColor = Theme.Color.canvas

        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true

        // --- Pergunta (multilinha) ---
        styleFieldContainer(questionContainer)
        questionTextView.font = UIFont.preferredFont(forTextStyle: .body)
        questionTextView.adjustsFontForContentSizeCategory = true
        questionTextView.textColor = Theme.Color.ink
        questionTextView.backgroundColor = .clear
        questionTextView.isScrollEnabled = false
        questionTextView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        questionTextView.textContainer.lineFragmentPadding = 0
        questionTextView.delegate = self
        questionTextView.returnKeyType = .default
        questionTextView.accessibilityLabel = "Pergunta da decisão"

        questionPlaceholder.text = "O que você quer decidir?"
        questionPlaceholder.font = UIFont.preferredFont(forTextStyle: .body)
        questionPlaceholder.adjustsFontForContentSizeCategory = true
        questionPlaceholder.textColor = Theme.Color.ink2.withAlphaComponent(0.7)
        questionPlaceholder.isUserInteractionEnabled = false

        questionErrorIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        questionErrorIcon.tintColor = Theme.Color.danger
        questionErrorIcon.contentMode = .scaleAspectFit
        questionErrorIcon.isHidden = true

        questionMessageLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        questionMessageLabel.adjustsFontForContentSizeCategory = true
        questionMessageLabel.textColor = Theme.Color.danger
        questionMessageLabel.numberOfLines = 0
        questionMessageLabel.isHidden = true
        questionMessageLabel.text = Self.questionErrorText

        questionCounterLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        questionCounterLabel.adjustsFontForContentSizeCategory = true
        questionCounterLabel.textAlignment = .right
        questionCounterLabel.setContentHuggingPriority(.required, for: .horizontal)

        questionMessageRow.axis = .horizontal
        questionMessageRow.alignment = .top
        questionMessageRow.spacing = 8

        // --- Cabeçalho opções ---
        optionsSectionLabel.text = "OPÇÕES"
        optionsCountLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        optionsCountLabel.adjustsFontForContentSizeCategory = true
        optionsCountLabel.textColor = Theme.Color.ink2
        optionsCountLabel.textAlignment = .right
        optionsHeaderRow.axis = .horizontal
        optionsHeaderRow.alignment = .firstBaseline
        optionsHeaderRow.distribution = .equalSpacing

        // --- Campo nova opção ---
        styleFieldContainer(draftContainer)
        draftField.font = UIFont.preferredFont(forTextStyle: .body)
        draftField.adjustsFontForContentSizeCategory = true
        draftField.textColor = Theme.Color.ink
        // Placeholder com a mesma cor escura da pergunta (consistência visual).
        draftField.attributedPlaceholder = NSAttributedString(
            string: "Nova opção",
            attributes: [
                .foregroundColor: Theme.Color.ink2.withAlphaComponent(0.7),
                .font: draftField.font as Any
            ]
        )
        draftField.returnKeyType = .done
        draftField.delegate = self
        draftField.clearButtonMode = .whileEditing
        draftField.accessibilityLabel = "Nova alternativa"
        draftField.addTarget(self, action: #selector(draftEditingChanged), for: .editingChanged)

        draftErrorIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        draftErrorIcon.tintColor = Theme.Color.danger
        draftErrorIcon.contentMode = .scaleAspectFit
        draftErrorIcon.isHidden = true

        var addConfig = UIButton.Configuration.filled()
        addConfig.title = "Adicionar"
        addConfig.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        addConfig.imagePadding = 4
        addConfig.baseBackgroundColor = Theme.Color.accentSoft
        addConfig.baseForegroundColor = Theme.Color.accentText
        addConfig.cornerStyle = .fixed
        addConfig.background.cornerRadius = Theme.Layout.fieldRadius
        addConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        addConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var r = a
            r.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: Theme.Font.display(size: 15, weight: .heavy))
            return r
        }
        addButton.configuration = addConfig
        addButton.setContentHuggingPriority(.required, for: .horizontal)
        addButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addButton.accessibilityHint = "Adiciona a alternativa digitada à lista."

        addRow.axis = .horizontal
        addRow.alignment = .top
        addRow.spacing = 10

        draftMessageLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        draftMessageLabel.adjustsFontForContentSizeCategory = true
        draftMessageLabel.textColor = Theme.Color.danger
        draftMessageLabel.numberOfLines = 0
        draftMessageLabel.isHidden = true

        draftCounterLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        draftCounterLabel.adjustsFontForContentSizeCategory = true
        draftCounterLabel.textAlignment = .right
        draftCounterLabel.setContentHuggingPriority(.required, for: .horizontal)

        draftMessageRow.axis = .horizontal
        draftMessageRow.alignment = .top
        draftMessageRow.spacing = 8

        // --- Lista / vazio ---
        buildEmptyState()

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OptionCell.self, forCellReuseIdentifier: OptionCell.reuseId)
        tableView.accessibilityLabel = "Lista de opções"

        // --- Hint e Sortear ---
        hintIcon.image = UIImage(systemName: "info.circle")
        hintIcon.contentMode = .scaleAspectFit
        hintIcon.setContentHuggingPriority(.required, for: .horizontal)

        hintLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        hintLabel.adjustsFontForContentSizeCategory = true
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center

        hintStack.axis = .horizontal
        hintStack.alignment = .center
        hintStack.spacing = 6

        if var c = drawButton.configuration {
            c.image = UIImage(systemName: "die.face.5", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            c.imagePadding = 8
            drawButton.configuration = c
        }
        drawButton.accessibilityHint = "Realiza o sorteio quando houver opções suficientes."

        bottomBar.backgroundColor = .clear
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1)
        bottomBar.layer.insertSublayer(bottomGradient, at: 0)
    }

    private func styleFieldContainer(_ v: UIView) {
        v.backgroundColor = Theme.Color.surface
        v.layer.cornerRadius = Theme.Layout.fieldRadius
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 1.5
        v.layer.borderColor = Theme.Color.fieldLine.resolvedColor(with: traitCollection).cgColor
    }

    private func buildEmptyState() {
        // Estado vazio sem moldura tracejada (protótipo v2): ilustração, título e texto centralizados.
        let illustration = UIView()
        let c1 = UIView(); c1.backgroundColor = UIColor(hex: 0xFF8FA8); c1.layer.cornerRadius = 12
        let c2 = UIView(); c2.backgroundColor = UIColor(hex: 0x8FD3FF); c2.layer.cornerRadius = 12
        let qCard = UIView(); qCard.backgroundColor = Theme.Color.lime; qCard.layer.cornerRadius = 12
        let q = UILabel(); q.text = "?"; q.font = Theme.Font.display(size: 28, weight: .black); q.textColor = Theme.Color.limeInk; q.textAlignment = .center
        c1.transform = CGAffineTransform(rotationAngle: -0.21)
        c2.transform = CGAffineTransform(rotationAngle: 0.21)
        qCard.transform = CGAffineTransform(rotationAngle: 0.03)
        [c1, c2, qCard, q].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        illustration.addSubview(c1); illustration.addSubview(c2); illustration.addSubview(qCard); qCard.addSubview(q)
        NSLayoutConstraint.activate([
            c1.widthAnchor.constraint(equalToConstant: 44), c1.heightAnchor.constraint(equalToConstant: 56),
            c1.leadingAnchor.constraint(equalTo: illustration.leadingAnchor, constant: 4), c1.topAnchor.constraint(equalTo: illustration.topAnchor, constant: 12),
            c2.widthAnchor.constraint(equalToConstant: 44), c2.heightAnchor.constraint(equalToConstant: 56),
            c2.trailingAnchor.constraint(equalTo: illustration.trailingAnchor, constant: -4), c2.topAnchor.constraint(equalTo: illustration.topAnchor, constant: 8),
            qCard.widthAnchor.constraint(equalToConstant: 44), qCard.heightAnchor.constraint(equalToConstant: 64),
            qCard.centerXAnchor.constraint(equalTo: illustration.centerXAnchor), qCard.topAnchor.constraint(equalTo: illustration.topAnchor),
            q.centerXAnchor.constraint(equalTo: qCard.centerXAnchor), q.centerYAnchor.constraint(equalTo: qCard.centerYAnchor),
            illustration.widthAnchor.constraint(equalToConstant: 96), illustration.heightAnchor.constraint(equalToConstant: 72),
        ])
        illustration.isAccessibilityElement = false

        let t = UILabel()
        t.text = "Nenhuma opção ainda"
        t.font = Theme.Font.scaledDisplay(baseSize: 20, weight: .heavy, textStyle: .headline)
        t.adjustsFontForContentSizeCategory = true
        t.textColor = Theme.Color.ink
        t.textAlignment = .center
        let s = UILabel()
        s.text = "Adicione suas opções e deixe o sorteio escolher."
        s.font = UIFont.preferredFont(forTextStyle: .subheadline)
        s.adjustsFontForContentSizeCategory = true
        s.textColor = Theme.Color.ink2
        s.textAlignment = .center
        s.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [illustration, t, s])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(16, after: illustration)
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
        ])
    }

    private func configureActions() {
        addButton.addAction(UIAction { [weak self] _ in self?.onAddOption?() }, for: .touchUpInside)
        drawButton.addAction(UIAction { [weak self] _ in self?.onDrawTapped?() }, for: .touchUpInside)
    }

    private func buildHierarchy() {
        questionContainer.addSubview(questionTextView)
        questionContainer.addSubview(questionPlaceholder)
        questionContainer.addSubview(questionErrorIcon)
        let qSpacer = UIView(); qSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        questionMessageRow.addArrangedSubview(questionMessageLabel)
        questionMessageRow.addArrangedSubview(qSpacer)
        questionMessageRow.addArrangedSubview(questionCounterLabel)

        optionsHeaderRow.addArrangedSubview(optionsSectionLabel)
        optionsHeaderRow.addArrangedSubview(optionsCountLabel)

        draftContainer.addSubview(draftField)
        draftContainer.addSubview(draftErrorIcon)
        addRow.addArrangedSubview(draftContainer)
        addRow.addArrangedSubview(addButton)
        let dSpacer = UIView(); dSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        draftMessageRow.addArrangedSubview(draftMessageLabel)
        draftMessageRow.addArrangedSubview(dSpacer)
        draftMessageRow.addArrangedSubview(draftCounterLabel)

        let hintCenter = UIView()
        hintStack.translatesAutoresizingMaskIntoConstraints = false
        hintCenter.addSubview(hintStack)
        NSLayoutConstraint.activate([
            hintStack.centerXAnchor.constraint(equalTo: hintCenter.centerXAnchor),
            hintStack.topAnchor.constraint(equalTo: hintCenter.topAnchor),
            hintStack.bottomAnchor.constraint(equalTo: hintCenter.bottomAnchor),
            hintStack.leadingAnchor.constraint(greaterThanOrEqualTo: hintCenter.leadingAnchor),
            hintStack.trailingAnchor.constraint(lessThanOrEqualTo: hintCenter.trailingAnchor),
        ])
        hintStack.addArrangedSubview(hintIcon)
        hintStack.addArrangedSubview(hintLabel)

        [questionSectionLabel, questionContainer, questionMessageRow,
         optionsHeaderRow, addRow, draftMessageRow, emptyStateView, tableView
        ].forEach { contentView.addSubview($0) }

        scrollView.addSubview(contentView)
        addSubview(scrollView)

        bottomBar.addSubview(hintCenter)
        bottomBar.addSubview(drawButton)
        addSubview(bottomBar)

        [questionTextView, questionPlaceholder, questionErrorIcon,
         draftField, draftErrorIcon, contentView, scrollView,
         hintCenter, drawButton, bottomBar, addButton,
         questionSectionLabel, questionContainer, questionMessageRow,
         optionsHeaderRow, addRow, draftMessageRow, emptyStateView, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func activateConstraints() {
        questionHeightConstraint = questionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            questionSectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            questionSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 21),
            questionSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -21),

            questionContainer.topAnchor.constraint(equalTo: questionSectionLabel.bottomAnchor, constant: 8),
            questionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            questionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            questionTextView.topAnchor.constraint(equalTo: questionContainer.topAnchor),
            questionTextView.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 4),
            questionTextView.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor),
            questionHeightConstraint,
            questionContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),

            // Placeholder alinhado ao recuo do texto (textContainerInset.left = 10) para não colar na borda.
            questionPlaceholder.leadingAnchor.constraint(equalTo: questionTextView.leadingAnchor, constant: 10),
            questionPlaceholder.topAnchor.constraint(equalTo: questionTextView.topAnchor, constant: 14),
            questionPlaceholder.trailingAnchor.constraint(equalTo: questionTextView.trailingAnchor, constant: -10),

            questionErrorIcon.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -12),
            questionErrorIcon.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 16),
            questionErrorIcon.widthAnchor.constraint(equalToConstant: 20),
            questionErrorIcon.heightAnchor.constraint(equalToConstant: 20),

            questionMessageRow.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 6),
            questionMessageRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            questionMessageRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            optionsHeaderRow.topAnchor.constraint(equalTo: questionMessageRow.bottomAnchor, constant: 18),
            optionsHeaderRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 21),
            optionsHeaderRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -21),

            addRow.topAnchor.constraint(equalTo: optionsHeaderRow.bottomAnchor, constant: 10),
            addRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            draftContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            addButton.heightAnchor.constraint(equalToConstant: 52),
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 116),

            draftField.topAnchor.constraint(equalTo: draftContainer.topAnchor),
            draftField.bottomAnchor.constraint(equalTo: draftContainer.bottomAnchor),
            draftField.leadingAnchor.constraint(equalTo: draftContainer.leadingAnchor, constant: 14),

            draftErrorIcon.trailingAnchor.constraint(equalTo: draftContainer.trailingAnchor, constant: -12),
            draftErrorIcon.centerYAnchor.constraint(equalTo: draftContainer.centerYAnchor),
            draftErrorIcon.widthAnchor.constraint(equalToConstant: 20),
            draftErrorIcon.heightAnchor.constraint(equalToConstant: 20),

            draftMessageRow.topAnchor.constraint(equalTo: addRow.bottomAnchor, constant: 6),
            draftMessageRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            draftMessageRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            emptyStateView.topAnchor.constraint(equalTo: draftMessageRow.bottomAnchor, constant: 6),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: draftMessageRow.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableHeightConstraint,

            // Garante que o conteúdo role acima da barra inferior.
            tableView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -170),
            emptyStateView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -170),

            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            drawButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            drawButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            drawButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),

            hintStack.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            hintStack.leadingAnchor.constraint(greaterThanOrEqualTo: bottomBar.leadingAnchor, constant: 20),
            hintStack.trailingAnchor.constraint(lessThanOrEqualTo: bottomBar.trailingAnchor, constant: -20),
            hintStack.bottomAnchor.constraint(equalTo: drawButton.topAnchor, constant: -10),
            hintStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 36),
        ])

        // Trailing dinâmico: sem erro o campo vai até a borda (clear "x" visível); com erro abre espaço para o ícone.
        questionTrailingToContainer = questionTextView.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -14)
        questionTrailingToIcon = questionTextView.trailingAnchor.constraint(equalTo: questionErrorIcon.leadingAnchor, constant: -4)
        draftTrailingToContainer = draftField.trailingAnchor.constraint(equalTo: draftContainer.trailingAnchor, constant: -14)
        draftTrailingToIcon = draftField.trailingAnchor.constraint(equalTo: draftErrorIcon.leadingAnchor, constant: -8)
        questionTrailingToContainer.isActive = true
        questionTrailingToIcon.isActive = false
        draftTrailingToContainer.isActive = true
        draftTrailingToIcon.isActive = false

        updateTableHeight()
    }

    // MARK: - API pública

    func displayOptions(_ options: [String]) {
        self.options = options
        optionCount = options.count
        optionsCountLabel.text = "\(options.count) de \(Decision.maxOptions) · mínimo \(Decision.minOptions)"
        emptyStateView.isHidden = !options.isEmpty
        tableView.isHidden = options.isEmpty
        tableView.reloadData()
        refreshDerivedUI()
        // Garante cálculo correto da altura após o reload.
        DispatchQueue.main.async { [weak self] in
            self?.tableView.layoutIfNeeded()
            self?.updateTableHeight()
        }
    }

    func clearDraft() {
        draftField.text = ""
        draftEditingChanged()
    }

    func setDraftMessage(_ message: String?) {
        draftMessageLabel.text = message
        let hasError = !(message == nil || message?.isEmpty == true)
        draftMessageLabel.isHidden = !hasError
        draftErrorIcon.isHidden = !hasError
        applyFieldState(container: draftContainer, hasError: hasError)
        // Com erro, reserva espaço para o ícone; sem erro, o campo vai até a borda (clear "x" correto).
        draftTrailingToContainer.isActive = !hasError
        draftTrailingToIcon.isActive = hasError
    }

    func setQuestionErrorVisible(_ visible: Bool) {
        questionMessageLabel.isHidden = !visible
        questionErrorIcon.isHidden = !visible
        applyFieldState(container: questionContainer, hasError: visible)
        questionTrailingToContainer.isActive = !visible
        questionTrailingToIcon.isActive = visible
        if visible {
            questionMessageLabel.text = Self.questionErrorText
        }
    }

    func focusQuestion() {
        questionTextView.becomeFirstResponder()
        scrollToVisible(questionContainer)
    }

    func focusDraft() {
        draftField.becomeFirstResponder()
    }

    /// Texto atual do rascunho (para o controller ao adicionar).
    var draftText: String { draftField.text ?? "" }

    // MARK: - Estado derivado (dica, botão, contadores)

    private func refreshDerivedUI() {
        let hasQuestion = !(questionTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        hasQuestionText = hasQuestion
        let canDraw = optionCount >= Decision.minOptions

        if optionCount == 0 {
            hintLabel.text = "Adicione pelo menos \(Decision.minOptions) opções para sortear"
            hintLabel.textColor = Theme.Color.ink2
            hintIcon.tintColor = Theme.Color.ink2
            hintIcon.image = UIImage(systemName: "info.circle")
        } else if optionCount < Decision.minOptions {
            hintLabel.text = "Falta 1 opção para sortear"
            hintLabel.textColor = Theme.Color.ink2
            hintIcon.tintColor = Theme.Color.ink2
            hintIcon.image = UIImage(systemName: "info.circle")
        } else if !hasQuestion {
            hintLabel.text = "Escreva a pergunta para sortear"
            hintLabel.textColor = Theme.Color.ink2
            hintIcon.tintColor = Theme.Color.ink2
            hintIcon.image = UIImage(systemName: "info.circle")
        } else if optionCount >= Decision.maxOptions {
            hintLabel.text = "Limite de \(Decision.maxOptions) opções atingido"
            hintLabel.textColor = Theme.Color.danger
            hintIcon.tintColor = Theme.Color.danger
            hintIcon.image = UIImage(systemName: "exclamationmark.circle")
        } else {
            hintLabel.text = "\(optionCount) opções prontas para o sorteio"
            hintLabel.textColor = Theme.Color.accentText
            hintIcon.tintColor = Theme.Color.accentText
            hintIcon.image = UIImage(systemName: "checkmark.circle")
        }

        drawButton.isEnabled = canDraw
        drawButton.setNeedsUpdateConfiguration()
        updateQuestionCounter()
        updateDraftCounter()
    }

    private func updateQuestionCounter() {
        let count = (questionTextView.text ?? "").count
        let threshold = Int(ceil(Double(maxQuestion) * 0.8))
        if count >= threshold {
            questionCounterLabel.isHidden = false
            questionCounterLabel.text = "\(count)/\(maxQuestion)"
            questionCounterLabel.textColor = count >= maxQuestion ? Theme.Color.danger : Theme.Color.ink2
        } else {
            questionCounterLabel.isHidden = true
        }
    }

    private func updateDraftCounter() {
        let count = (draftField.text ?? "").count
        let threshold = Int(ceil(Double(maxOption) * 0.8))
        if count >= threshold {
            draftCounterLabel.isHidden = false
            draftCounterLabel.text = "\(count)/\(maxOption)"
            draftCounterLabel.textColor = count >= maxOption ? Theme.Color.danger : Theme.Color.ink2
        } else {
            draftCounterLabel.isHidden = true
        }
    }

    private func applyFieldState(container: UIView, hasError: Bool) {
        if hasError {
            container.layer.borderColor = Theme.Color.danger.resolvedColor(with: traitCollection).cgColor
            container.layer.borderWidth = 1.5
        } else {
            container.layer.borderColor = Theme.Color.fieldLine.resolvedColor(with: traitCollection).cgColor
            container.layer.borderWidth = 1.5
        }
    }

    private func updateTableHeight() {
        tableView.layoutIfNeeded()
        let h = options.isEmpty ? 0 : tableView.contentSize.height
        if abs(tableHeightConstraint.constant - h) > 0.5 {
            tableHeightConstraint.constant = h
        }
    }

    private func scrollToVisible(_ view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let rect = view.convert(view.bounds, to: self.scrollView).insetBy(dx: 0, dy: -24)
            self.scrollView.scrollRectToVisible(rect, animated: true)
        }
    }

    // MARK: - Ações internas

    @objc private func draftEditingChanged() {
        onDraftChanged?(draftField.text ?? "")
        updateDraftCounter()
    }

    private func questionEditingChanged() {
        let text = questionTextView.text ?? ""
        questionPlaceholder.isHidden = !text.isEmpty
        onQuestionChanged?(text)
        // Ao digitar, limpa erro da pergunta (feedback inline).
        if !questionMessageLabel.isHidden {
            setQuestionErrorVisible(false)
        }
        refreshDerivedUI()
        // Ajusta altura do text view.
        let size = questionTextView.sizeThatFits(CGSize(width: questionTextView.frame.width, height: .greatestFiniteMagnitude))
        questionHeightConstraint.constant = max(24, size.height)
        updateTableHeight()
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
        let extra: CGFloat = bottomInset > 0 ? 120 : 170
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = bottomInset + extra
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        } completion: { _ in
            if bottomInset > 0, let active = self.activeInput { self.scrollToVisible(active) }
        }
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

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomGradient.frame = bottomBar.bounds
        let bg = Theme.Color.canvas.resolvedColor(with: traitCollection)
        bottomGradient.colors = [bg.withAlphaComponent(0).cgColor, bg.cgColor, bg.cgColor]
        bottomGradient.locations = [0, 0.32, 1]
        updateTableHeight()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            let errQ = !questionMessageLabel.isHidden
            let errD = !draftMessageLabel.isHidden
            applyFieldState(container: questionContainer, hasError: errQ)
            applyFieldState(container: draftContainer, hasError: errD)
            tableView.reloadData()
            setNeedsLayout()
        }
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            // Em tamanhos de acessibilidade, empilha campo e botão para evitar aperto.
            let isAX = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            addRow.axis = isAX ? .vertical : .horizontal
            addRow.alignment = isAX ? .fill : .top
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension DecisionView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { options.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionCell.reuseId, for: indexPath) as! OptionCell
        let index = indexPath.row
        let text = options[index]
        cell.configure(index: index, text: text, total: options.count)
        cell.onEdit = { [weak self] in self?.onEditOption?(index) }
        cell.onRemove = { [weak self] in self?.onRemoveOption?(index) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Toque na linha edita (além do lápis).
        onEditOption?(indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Remover") { [weak self] _, _, completion in
            self?.onRemoveOption?(indexPath.row)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = Theme.Color.danger
        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
}

// MARK: - UITextViewDelegate

extension DecisionView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeInput = textView
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if activeInput == textView { activeInput = nil }
    }
    func textViewDidChange(_ textView: UITextView) {
        questionEditingChanged()
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let current = textView.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: stringRange, with: text)
        // Limita ao máximo de caracteres da pergunta.
        return updated.count <= maxQuestion
    }
}

// MARK: - UITextFieldDelegate

extension DecisionView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeInput = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeInput == textField { activeInput = nil }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // "Done" no campo de opção: tenta adicionar.
        onAddOption?()
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == draftField else { return true }
        let current = textField.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: stringRange, with: string)
        // Limita ao máximo de caracteres da opção.
        return updated.count <= maxOption
    }
}

// MARK: - Célula de opção

private final class OptionCell: UITableViewCell {
    static let reuseId = "OptionCell"

    var onEdit: (() -> Void)?
    var onRemove: (() -> Void)?

    private let card = UIView()
    private let badge = UILabel()
    private let nameLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let removeButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = Theme.Color.surface
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Theme.Color.line.cgColor

        badge.font = Theme.Font.display(size: 15, weight: .black)
        badge.textColor = Theme.Color.limeInk
        badge.textAlignment = .center
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true

        nameLabel.font = UIFont.preferredFont(forTextStyle: .body).withWeight(.semibold)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = Theme.Color.ink
        nameLabel.numberOfLines = 0

        configureIconButton(editButton, system: "pencil", tint: Theme.Color.accentText, bg: Theme.Color.accentSoft)
        configureIconButton(removeButton, system: "trash", tint: Theme.Color.danger, bg: Theme.Color.dangerSoft)
        editButton.addAction(UIAction { [weak self] _ in self?.onEdit?() }, for: .touchUpInside)
        removeButton.addAction(UIAction { [weak self] _ in self?.onRemove?() }, for: .touchUpInside)

        [card, badge, nameLabel, editButton, removeButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        contentView.addSubview(card)
        [badge, nameLabel, editButton, removeButton].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            badge.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 32),
            badge.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            removeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
            removeButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -2),
            editButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -8),

            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])

        // Acessibilidade: ações customizadas para editar/remover (além do toque na linha).
        isAccessibilityElement = false
        card.isAccessibilityElement = true
        card.accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(index: Int, text: String, total: Int) {
        badge.text = "\(index + 1)"
        badge.backgroundColor = Theme.Color.optionPalette[index % Theme.Color.optionPalette.count]
        nameLabel.text = text
        editButton.accessibilityLabel = "Editar opção"
        editButton.accessibilityValue = text
        removeButton.accessibilityLabel = "Remover opção"
        removeButton.accessibilityValue = text
        card.accessibilityLabel = "\(text), opção \(index + 1) de \(total)"
        card.accessibilityHint = "Toque para editar. Deslize para remover."
        card.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Editar \(text)") { [weak self] _ in self?.onEdit?(); return true },
            UIAccessibilityCustomAction(name: "Remover \(text)") { [weak self] _ in self?.onRemove?(); return true },
        ]
        // Atualiza cor de borda conforme tema atual.
        card.layer.borderColor = Theme.Color.line.resolvedColor(with: traitCollection).cgColor
    }

    private func configureIconButton(_ b: UIButton, system: String, tint: UIColor, bg: UIColor) {
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: system, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        cfg.baseForegroundColor = tint
        cfg.background.backgroundColor = bg
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        b.configuration = cfg
        b.widthAnchor.constraint(equalToConstant: 36).isActive = true
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        card.layer.borderColor = Theme.Color.line.resolvedColor(with: traitCollection).cgColor
    }
}

// MARK: - Helpers

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let d = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: d, size: pointSize)
    }
}
