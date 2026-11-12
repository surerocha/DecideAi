//
//  DecisionView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Parte visual da tela de criação da decisão.
/// Responsabilidade: montar a interface e avisar o controller sobre as ações do usuário.
/// Não conhece navegação, não aplica regras de negócio e não altera o Model diretamente.
final class DecisionView: UIView {

    // MARK: - Callbacks (View -> Controller)

    /// Chamado sempre que o texto da pergunta muda.
    /// O controller usa isso para manter `Decision.question` atualizado.
    var onQuestionChanged: ((String) -> Void)?

    /// Chamado quando o usuário toca em "Adicionar".
    /// Envia o texto digitado no campo de nova alternativa.
    var onAddOption: ((String) -> Void)?

    /// Chamado quando o usuário toca em "Editar" em uma opção da lista.
    /// Envia o índice da opção no Model.
    var onEditOption: ((Int) -> Void)?

    /// Chamado quando o usuário toca em "Remover" em uma opção da lista.
    /// Envia o índice da opção no Model.
    var onRemoveOption: ((Int) -> Void)?

    /// Chamado quando o usuário toca em "Sortear".
    /// Nesta etapa o controller apenas exibe um alerta informativo (Etapa 5 integra o sorteio).
    var onDrawTapped: (() -> Void)?

    // MARK: - Componentes de UI

    // UIScrollView: permite rolar o conteúdo quando ele não couber na tela
    // (ex.: muitas opções, textos grandes com Dynamic Type ou teclado visível).
    private let scrollView = UIScrollView()

    // UIStackView (vertical): empilha os elementos na ordem e calcula o layout
    // entre eles, reduzindo a quantidade de constraints manuais.
    private let contentStack = UIStackView()

    // UILabel: exibe textos estáticos/informativos na tela.
    private let promptLabel = DecisionView.makeLabel(
        text: "O que você quer decidir?",
        textStyle: .title2,
        color: Theme.Color.primaryText,
        bold: true
    )

    // UITextField: entrada de texto em uma única linha, adequada para a pergunta.
    private let questionTextField = UITextField()

    private let optionsTitleLabel = DecisionView.makeLabel(
        text: "Opções",
        textStyle: .headline,
        color: Theme.Color.primaryText,
        bold: true
    )

    // UIStackView (vertical): lista de opções. Cada item é uma linha horizontal
    // com o texto da opção e botões de editar/remover (até 10 itens, simples de manter).
    private let optionsListStack = UIStackView()

    // UIStackView (horizontal): coloca o campo de nova opção e o botão "Adicionar"
    // lado a lado na mesma linha.
    private let addOptionRowStack = UIStackView()

    // UITextField: entrada de texto em uma única linha para a nova alternativa.
    private let newOptionTextField = UITextField()

    // UIButton: ação secundária para adicionar a alternativa digitada.
    private let addOptionButton = UIButton(type: .system)

    // PrimaryButton: componente reutilizável do app para a ação principal.
    // O estado (habilitado/desabilitado) é controlado pelo controller conforme o Model.
    // A integração real do sorteio será feita na Etapa 5.
    private let drawButton = PrimaryButton(title: "Sortear")

    // Tokens dos observadores de teclado, para removê-los ao desalocar a view.
    private var keyboardObservers: [NSObjectProtocol] = []

    // MARK: - Inicialização

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureActions()
        configureKeyboardHandling()
        buildHierarchy()
        activateConstraints()
    }

    // Obrigatório em subclasses de UIView; usado com Storyboards/XIBs,
    // que não utilizamos neste projeto.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Remove observadores do NotificationCenter para evitar chamadas após a view sair de memória.
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Configuração

    private func configureViews() {
        backgroundColor = Theme.Color.background

        // Campo da pergunta
        questionTextField.placeholder = "Digite sua pergunta"
        questionTextField.font = .preferredFont(forTextStyle: .body)
        questionTextField.adjustsFontForContentSizeCategory = true
        questionTextField.textColor = Theme.Color.primaryText
        questionTextField.borderStyle = .roundedRect
        questionTextField.returnKeyType = .done
        questionTextField.clearButtonMode = .whileEditing
        questionTextField.accessibilityLabel = "Pergunta da decisão"
        // Delegate para tratar a tecla "Done/Concluído" e fechar o teclado.
        questionTextField.delegate = self

        // Pilha principal de conteúdo
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        // Espaço extra antes do botão principal para separar a área de ação.
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: addOptionRowStack)

        // Lista de opções
        optionsListStack.axis = .vertical
        optionsListStack.alignment = .fill
        optionsListStack.spacing = Theme.Spacing.small

        // Linha para adicionar nova opção (campo + botão lado a lado)
        addOptionRowStack.axis = .horizontal
        addOptionRowStack.alignment = .fill
        addOptionRowStack.spacing = Theme.Spacing.small

        // Campo da nova alternativa
        newOptionTextField.placeholder = "Nova alternativa"
        newOptionTextField.font = .preferredFont(forTextStyle: .body)
        newOptionTextField.adjustsFontForContentSizeCategory = true
        newOptionTextField.textColor = Theme.Color.primaryText
        newOptionTextField.borderStyle = .roundedRect
        newOptionTextField.returnKeyType = .done
        newOptionTextField.clearButtonMode = .whileEditing
        newOptionTextField.accessibilityLabel = "Nova alternativa"
        newOptionTextField.delegate = self

        // Botão "Adicionar" (ação secundária)
        addOptionButton.setTitle("Adicionar", for: .normal)
        addOptionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        addOptionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        addOptionButton.tintColor = Theme.Color.accent
        addOptionButton.accessibilityHint = "Adiciona a alternativa digitada à lista."
        // Impede que o botão estique horizontalmente; ele mantém o tamanho do título.
        addOptionButton.setContentHuggingPriority(.required, for: .horizontal)
        addOptionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Botão principal "Sortear": estado controlado pelo controller (ex.: canDraw).
        // A ação real de sorteio/navegação será integrada na Etapa 5.
        drawButton.accessibilityHint = "Realiza o sorteio quando houver opções suficientes."
    }

    private func configureActions() {
        // UIAction (iOS 14+): forma moderna de responder a eventos com closures,
        // sem precisar de métodos @objc/target-action para casos simples.
        // [weak self] evita ciclo de retenção (a view guarda o controle; o controle
        // guarda a action; a action não deve segurar a view fortemente).

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

    private func configureKeyboardHandling() {
        // Gesto de toque para dispensar o teclado ao tocar fora dos campos.
        // cancelsTouchesInView = false garante que botões e outros controles
        // continuem recebendo seus toques normalmente.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)

        // Observa mudanças no frame do teclado (abrir, fechar, mudar altura,
        // ex.: barra de sugestões/correção aparecendo ou sumindo) para ajustar
        // o conteúdo rolável e manter o campo em edição visível.
        let changeObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.adjustForKeyboard(notification: notification)
        }

        keyboardObservers = [changeObserver]
    }

    private func buildHierarchy() {
        // Monta a linha "campo + botão"
        addOptionRowStack.addArrangedSubview(newOptionTextField)
        addOptionRowStack.addArrangedSubview(addOptionButton)

        // Monta a pilha principal na ordem em que os elementos aparecem na tela
        [promptLabel, questionTextField, optionsTitleLabel, optionsListStack, addOptionRowStack, drawButton]
            .forEach { contentStack.addArrangedSubview($0) }

        // O conteúdo rolável fica dentro da UIScrollView.
        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    private func activateConstraints() {
        // Com Auto Layout em código, desativamos a conversão automática de autoresizing
        // masks em constraints para cada view que vamos posicionar manualmente.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Layout guides da scroll view:
        // - contentLayoutGuide: define a área rolável (tamanho do conteúdo).
        // - frameLayoutGuide: define a área visível da scroll view na tela.
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        // No iPhone o conteúdo ocupa a largura disponível (menos margens).
        // Prioridade menor que "required" para, no iPad, o limite de largura máxima vencer.
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // A scroll view ocupa toda a área segura da tela.
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            // Rolagem vertical: a largura do conteúdo é igual à largura visível.
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),

            // Posicionamento da pilha dentro da área rolável.
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: Theme.Spacing.large),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Theme.Spacing.large),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth
        ])
    }

    // MARK: - Atualização da interface (chamada pelo controller)

    /// Atualiza a lista visual de opções.
    /// Cada linha mostra o texto da opção e botões para editar/remover.
    /// O controller chama este método após qualquer alteração no Model.
    func displayOptions(_ options: [String]) {
        // Remove as views antigas da pilha para recriar a lista do estado atual.
        optionsListStack.arrangedSubviews.forEach { view in
            optionsListStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, option) in options.enumerated() {
            optionsListStack.addArrangedSubview(makeOptionRow(text: option, index: index))
        }

        // Esconde a pilha quando não há opções, evitando espaço vazio desnecessário.
        optionsListStack.isHidden = options.isEmpty
    }

    /// Limpa o campo de nova alternativa após uma adição bem-sucedida.
    func clearNewOptionField() {
        newOptionTextField.text = ""
    }

    /// Define se o botão "Sortear" está habilitado (controlado pelo controller/Model).
    func setDrawEnabled(_ enabled: Bool) {
        drawButton.isEnabled = enabled
    }

    // MARK: - Linhas de opção (editar/remover)

    /// Cria uma linha horizontal: [texto da opção] [Editar] [Remover].
    private func makeOptionRow(text: String, index: Int) -> UIView {
        // UIStackView horizontal: alinha texto e botões na mesma linha.
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = Theme.Spacing.small

        // Texto da opção (ocupa o espaço disponível).
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.Color.primaryText
        label.numberOfLines = 0
        // Prioridade menor para ceder espaço aos botões quando necessário.
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Botão "Editar" com ícone SF Symbol (vetorial, integra com o sistema).
        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.tintColor = Theme.Color.accent
        editButton.accessibilityLabel = "Editar opção"
        editButton.accessibilityValue = text
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        // Captura o índice atual desta linha para informar o controller.
        editButton.addAction(UIAction { [weak self] _ in
            self?.onEditOption?(index)
        }, for: .touchUpInside)

        // Botão "Remover" com ícone SF Symbol.
        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage(systemName: "trash"), for: .normal)
        // Cor destrutiva do sistema para indicar ação de remoção.
        removeButton.tintColor = .systemRed
        removeButton.accessibilityLabel = "Remover opção"
        removeButton.accessibilityValue = text
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        removeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        removeButton.addAction(UIAction { [weak self] _ in
            self?.onRemoveOption?(index)
        }, for: .touchUpInside)

        rowStack.addArrangedSubview(label)
        rowStack.addArrangedSubview(editButton)
        rowStack.addArrangedSubview(removeButton)

        return rowStack
    }

    // MARK: - Teclado

    // Guarda qual campo está em edição para podermos rolar até ele quando o teclado aparecer/mudar.
    private weak var activeTextField: UITextField?

    // Margem extra ao rolar até o campo, para ele não ficar colado/coberto pelo teclado
    // (inclui casos com barra de sugestões/correção acima das teclas).
    private let keyboardScrollPadding: CGFloat = 48

    /// Fecha o teclado ao tocar fora dos campos.
    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    /// Ajusta os insets da scroll view quando o frame do teclado muda
    /// (abrir, fechar, alterar altura por sugestões/correção) e mantém o campo ativo visível.
    private func adjustForKeyboard(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        // Converte o frame final do teclado (coordenadas da tela) para as coordenadas desta view.
        let keyboardFrameInView = convert(keyboardFrameValue.cgRectValue, from: nil)
        // Interseção entre o teclado e a scroll view = quanto da scroll view está coberto.
        // Quando o teclado está oculto, essa interseção fica vazia/zero.
        let intersection = scrollView.frame.intersection(keyboardFrameInView)
        let bottomInset = max(0, intersection.height - safeAreaInsets.bottom)

        // Lê duração e curva da animação do teclado para sincronizar o ajuste visual.
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            // Espaço inferior reserva a área do teclado, permitindo rolar o conteúdo.
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.layoutIfNeeded()
        } completion: { _ in
            // Após ajustar o espaço, garante que o campo em edição esteja visível.
            if bottomInset > 0 {
                self.scrollActiveFieldIntoViewIfNeeded(animated: true)
            }
        }
    }

    /// Rola a scroll view para manter o campo de texto em edição visível,
    /// com folga extra para não ficar parcialmente coberto.
    private func scrollActiveFieldIntoViewIfNeeded(animated: Bool = true) {
        guard let activeTextField else { return }

        // Converte o frame do campo para o sistema de coordenadas da scroll view.
        let fieldFrameInScrollView = activeTextField.convert(activeTextField.bounds, to: scrollView)
        // Expande a área alvo (acima e abaixo) para criar uma margem confortável.
        let paddedFrame = fieldFrameInScrollView.insetBy(dx: 0, dy: -keyboardScrollPadding)

        // scrollRectToVisible respeita os insets e rola o mínimo necessário para mostrar o retângulo.
        scrollView.scrollRectToVisible(paddedFrame, animated: animated)
    }

    // MARK: - Helpers

    /// Cria labels configuradas de forma consistente (fonte dinâmica, cor e acessibilidade).
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
            // size 0 mantém o tamanho definido pelo text style (compatível com Dynamic Type).
            font = UIFont(descriptor: descriptor, size: 0)
        }

        label.font = font
        // Atualiza a fonte automaticamente se o usuário mudar o tamanho do texto no sistema.
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0 // 0 = quantas linhas forem necessárias
        return label
    }
}

// MARK: - UITextFieldDelegate

extension DecisionView: UITextFieldDelegate {

    /// Guarda o campo que começou a edição e garante que ele fique visível.
    /// Isso cobre casos em que o teclado já está aberto (ex.: troca de campo
    /// ou variação de altura pela barra de sugestões/correção).
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField

        // Adia levemente para o layout/insets atuais serem considerados antes de rolar.
        DispatchQueue.main.async { [weak self] in
            self?.scrollActiveFieldIntoViewIfNeeded(animated: true)
        }
    }

    /// Limpa a referência quando o campo deixa de ser o editor ativo.
    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeTextField == textField {
            activeTextField = nil
        }
    }

    /// Chamado quando o usuário toca em "Done/Concluído" no teclado.
    /// Fecha o teclado para os campos de texto desta tela.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
