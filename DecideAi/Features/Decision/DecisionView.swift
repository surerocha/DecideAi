//
//  DecisionView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View da tela de criação da decisão

/// Parte visual da tela de criação da decisão.
/// Responsabilidades:
/// - construir e configurar a interface (campos, lista de opções, botões);
/// - aplicar layout com Auto Layout e suportar rolagem/Dynamic Type;
/// - tratar aspectos de UI do teclado (insets e rolagem até o campo ativo);
/// - expor interações do usuário via callbacks para o controller.
///
/// Não conhece navegação, não altera o Model diretamente e não aplica regras de negócio.
final class DecisionView: UIView {

    // MARK: - Callbacks (View -> Controller)

    /// Chamado quando o texto da pergunta muda (a cada edição).
    var onQuestionChanged: ((String) -> Void)?

    /// Chamado quando o usuário toca em "Adicionar", enviando o texto digitado.
    var onAddOption: ((String) -> Void)?

    /// Chamado quando o usuário toca em "Editar" em uma opção (envia o índice).
    var onEditOption: ((Int) -> Void)?

    /// Chamado quando o usuário toca em "Remover" em uma opção (envia o índice).
    var onRemoveOption: ((Int) -> Void)?

    /// Chamado quando o usuário toca em "Sortear".
    var onDrawTapped: (() -> Void)?

    // MARK: - Componentes de UI

    // Scroll view: permite rolar quando o conteúdo excede a área visível (ex.: teclado, muitas opções).
    private let scrollView = UIScrollView()

    // Stack principal vertical: organiza os elementos na ordem com espaçamentos consistentes.
    private let contentStack = UIStackView()

    // Rótulo/prompt da pergunta.
    private let promptLabel = DecisionView.makeLabel(
        text: "O que você quer decidir?",
        textStyle: .title2,
        color: Theme.Color.primaryText,
        bold: true
    )

    // Campo de texto da pergunta (entrada de uma linha).
    private let questionTextField = UITextField()

    // Rótulo da seção de opções.
    private let optionsTitleLabel = DecisionView.makeLabel(
        text: "Opções",
        textStyle: .headline,
        color: Theme.Color.primaryText,
        bold: true
    )

    // Stack vertical que contém as linhas de opções (cada linha: texto + editar + remover).
    private let optionsListStack = UIStackView()

    // Linha horizontal para adicionar opção: [campo de texto] + [botão Adicionar].
    private let addOptionRowStack = UIStackView()

    // Campo de texto para digitar uma nova alternativa.
    private let newOptionTextField = UITextField()

    // Botão secundário para confirmar adição da alternativa.
    private let addOptionButton = UIButton(type: .system)

    // Botão principal para iniciar o sorteio (habilitado conforme regras do Model).
    private let drawButton = PrimaryButton(title: "Sortear")

    // Tokens dos observadores de notificação do teclado (para remoção no deinit).
    private var keyboardObservers: [NSObjectProtocol] = []

    // MARK: - Inicialização

    /// Inicializador programático.
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureActions()
        configureKeyboardHandling()
        buildHierarchy()
        activateConstraints()
    }

    /// Inicializador de storyboard/XIB (não suportado).
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Remove observadores ao desalocar a view, evitando callbacks inválidos.
    deinit {
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Configuração dos componentes

    /// Define propriedades visuais e comportamentais dos componentes.
    private func configureViews() {
        backgroundColor = Theme.Color.background

        // --- Campo da pergunta ---
        questionTextField.placeholder = "Digite sua pergunta"
        questionTextField.font = .preferredFont(forTextStyle: .body)
        questionTextField.adjustsFontForContentSizeCategory = true
        questionTextField.textColor = Theme.Color.primaryText
        questionTextField.borderStyle = .roundedRect
        questionTextField.returnKeyType = .done
        questionTextField.clearButtonMode = .whileEditing
        questionTextField.accessibilityLabel = "Pergunta da decisão"
        // Define delegate para tratar "Done" e acompanhar foco (teclado/acessibilidade de rolagem).
        questionTextField.delegate = self

        // --- Stack principal ---
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        // Espaço maior antes do botão principal.
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: addOptionRowStack)

        // --- Lista de opções ---
        optionsListStack.axis = .vertical
        optionsListStack.alignment = .fill
        optionsListStack.spacing = Theme.Spacing.small

        // --- Linha de adicionar opção ---
        addOptionRowStack.axis = .horizontal
        addOptionRowStack.alignment = .fill
        addOptionRowStack.spacing = Theme.Spacing.small

        // --- Campo de nova alternativa ---
        newOptionTextField.placeholder = "Nova alternativa"
        newOptionTextField.font = .preferredFont(forTextStyle: .body)
        newOptionTextField.adjustsFontForContentSizeCategory = true
        newOptionTextField.textColor = Theme.Color.primaryText
        newOptionTextField.borderStyle = .roundedRect
        newOptionTextField.returnKeyType = .done
        newOptionTextField.clearButtonMode = .whileEditing
        newOptionTextField.accessibilityLabel = "Nova alternativa"
        newOptionTextField.delegate = self

        // --- Botão Adicionar ---
        addOptionButton.setTitle("Adicionar", for: .normal)
        addOptionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        addOptionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        addOptionButton.tintColor = Theme.Color.accent
        addOptionButton.accessibilityHint = "Adiciona a alternativa digitada à lista."
        // Mantém o botão no tamanho do conteúdo (não estica horizontalmente).
        addOptionButton.setContentHuggingPriority(.required, for: .horizontal)
        addOptionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // --- Botão Sortear ---
        drawButton.accessibilityHint = "Realiza o sorteio quando houver opções suficientes."
    }

    // MARK: - Ações

    /// Conecta eventos de UI aos callbacks expostos.
    private func configureActions() {
        // UIAction: associa evento a closure (alternativa moderna a target-action/Selector em muitos casos).
        // [weak self] evita retenção cíclica entre a view e as closures armazenadas nos controles.

        questionTextField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onQuestionChanged?(self.questionTextField.text ?? "")
        }, for: .editingChanged)

        addOptionButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let text = self.newOptionTextField.text ?? ""
            self.onAddOption?(text)
        }, for: .touchUpInside)

        drawButton.addAction(UIAction { [weak self] _ in
            self?.onDrawTapped?()
        }, for: .touchUpInside)
    }

    // MARK: - Teclado (configuração)

    /// Configura gesto para dispensar teclado e observação de mudanças do frame do teclado.
    private func configureKeyboardHandling() {
        // Toque fora dos campos fecha o teclado.
        // `cancelsTouchesInView = false` permite que botões continuem recebendo toques.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)

        // Observa mudanças de frame do teclado (abrir/fechar/alterar altura, ex.: sugestões).
        // Usamos closure com [weak self] para evitar reter a view indevidamente.
        let changeObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.adjustForKeyboard(notification: notification)
        }

        keyboardObservers = [changeObserver]
    }

    // MARK: - Hierarquia

    /// Monta a árvore de subviews.
    private func buildHierarchy() {
        // Linha de adição: campo + botão.
        addOptionRowStack.addArrangedSubview(newOptionTextField)
        addOptionRowStack.addArrangedSubview(addOptionButton)

        // Conteúdo principal na ordem vertical.
        [promptLabel, questionTextField, optionsTitleLabel, optionsListStack, addOptionRowStack, drawButton]
            .forEach { contentStack.addArrangedSubview($0) }

        // Scroll contém a stack; a view contém a scroll.
        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    // MARK: - Layout (Auto Layout)

    /// Cria e ativa as constraints.
    private func activateConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Guides: conteúdo rolável vs área visível.
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        // Largura preenchendo com margens (prioridade alta, permitindo limite no iPad).
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Scroll view na área segura.
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            // Somente rolagem vertical.
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),

            // Posicionamento e limites da stack.
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: Theme.Spacing.large),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Theme.Spacing.large),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth
        ])
    }

    // MARK: - API para o controller (atualização de UI)

    /// Reconstroi a lista visual de opções com base no estado atual do Model.
    /// Cada linha contém o texto e botões de editar/remover.
    func displayOptions(_ options: [String]) {
        // Remove linhas antigas para evitar duplicação/estado inconsistente.
        optionsListStack.arrangedSubviews.forEach { view in
            optionsListStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Cria uma linha por opção, preservando o índice correspondente no Model.
        for (index, option) in options.enumerated() {
            optionsListStack.addArrangedSubview(makeOptionRow(text: option, index: index))
        }

        // Oculta a lista quando vazia.
        optionsListStack.isHidden = options.isEmpty
    }

    /// Limpa o campo de nova alternativa (após adição bem-sucedida).
    func clearNewOptionField() {
        newOptionTextField.text = ""
    }

    /// Atualiza o estado habilitado do botão "Sortear".
    func setDrawEnabled(_ enabled: Bool) {
        drawButton.isEnabled = enabled
    }

    // MARK: - Construção de linhas de opção

    /// Cria uma linha horizontal: [texto] [editar] [remover].
    private func makeOptionRow(text: String, index: Int) -> UIView {
        // Container horizontal da linha.
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        // Alinha ao topo para ficar correto quando o texto ocupa múltiplas linhas.
        rowStack.alignment = .top
        rowStack.spacing = Theme.Spacing.small

        // Label da opção: expande e pode quebrar em várias linhas.
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.Color.primaryText
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Botão editar (ícone SF Symbol).
        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.tintColor = Theme.Color.accent
        editButton.accessibilityLabel = "Editar opção"
        editButton.accessibilityValue = text
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        // Captura o índice atual desta linha ao tocar.
        editButton.addAction(UIAction { [weak self] _ in
            self?.onEditOption?(index)
        }, for: .touchUpInside)

        // Botão remover (ícone SF Symbol, cor destrutiva).
        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage(systemName: "trash"), for: .normal)
        removeButton.tintColor = .systemRed
        removeButton.accessibilityLabel = "Remover opção"
        removeButton.accessibilityValue = text
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        removeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        removeButton.addAction(UIAction { [weak self] _ in
            self?.onRemoveOption?(index)
        }, for: .touchUpInside)

        // Ordem: texto à esquerda, ações à direita.
        rowStack.addArrangedSubview(label)
        rowStack.addArrangedSubview(editButton)
        rowStack.addArrangedSubview(removeButton)

        return rowStack
    }

    // MARK: - Teclado (comportamento)

    /// Campo atualmente em edição (referência fraca para não reter a view indevidamente).
    private weak var activeTextField: UITextField?

    /// Folga extra ao rolar até o campo ativo, evitando que fique colado ao teclado.
    private let keyboardScrollPadding: CGFloat = 48

    /// Fecha o teclado (encerra edição) ao tocar fora dos campos.
    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    /// Ajusta insets da scroll conforme o frame do teclado e mantém o campo ativo visível.
    private func adjustForKeyboard(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        // Converte o frame do teclado para coordenadas desta view.
        let keyboardFrameInView = convert(keyboardFrameValue.cgRectValue, from: nil)

        // Calcula a área de interseção com a scroll view (quanto está coberto).
        let intersection = scrollView.frame.intersection(keyboardFrameInView)
        let bottomInset = max(0, intersection.height - safeAreaInsets.bottom)

        // Obtém parâmetros de animação do teclado para sincronizar o movimento.
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        // Anima ajuste de insets; ao final, garante visibilidade do campo ativo.
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.layoutIfNeeded()
        } completion: { _ in
            if bottomInset > 0 {
                self.scrollActiveFieldIntoViewIfNeeded(animated: true)
            }
        }
    }

    /// Rola a scroll view para tornar o campo ativo visível com margem confortável.
    private func scrollActiveFieldIntoViewIfNeeded(animated: Bool = true) {
        guard let activeTextField else { return }

        // Converte o retângulo do campo para o sistema de coordenadas da scroll view.
        let fieldFrameInScrollView = activeTextField.convert(activeTextField.bounds, to: scrollView)
        // Expande o retângulo para criar folga acima/abaixo.
        let paddedFrame = fieldFrameInScrollView.insetBy(dx: 0, dy: -keyboardScrollPadding)

        // Solicita à scroll que torne o retângulo visível.
        scrollView.scrollRectToVisible(paddedFrame, animated: animated)
    }

    // MARK: - Helpers

    /// Cria labels com fonte dinâmica e estilo consistente.
    private static func makeLabel(
        text: String,
        textStyle: UIFont.TextStyle,
        color: UIColor,
        bold: Bool = false
    ) -> UILabel {
        let label = UILabel()
        label.text = text

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

// MARK: - UITextFieldDelegate

extension DecisionView: UITextFieldDelegate {

    /// Ao iniciar edição, guarda o campo ativo e garante que ele fique visível.
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        // Agenda para o próximo ciclo da run loop, após ajustes de layout/insets.
        DispatchQueue.main.async { [weak self] in
            self?.scrollActiveFieldIntoViewIfNeeded(animated: true)
        }
    }

    /// Ao encerrar edição, limpa a referência se for o campo ativo.
    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeTextField == textField {
            activeTextField = nil
        }
    }

    /// Trata a tecla "Return/Done" fechando o teclado.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
