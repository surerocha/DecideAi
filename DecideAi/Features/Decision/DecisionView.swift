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

    // MARK: - Componentes de UI

    // UIScrollView: permite rolar o conteúdo quando ele não couber na tela
    // (ex.: muitas opções ou textos grandes com Dynamic Type).
    // O ajuste fino para o teclado será tratado em uma etapa futura.
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

    // UIStackView (vertical): lista somente leitura das opções já adicionadas.
    // Nesta etapa não há edição/remoção; cada opção vira um UILabel aqui dentro.
    private let optionsListStack = UIStackView()

    // UIStackView (horizontal): coloca o campo de nova opção e o botão "Adicionar"
    // lado a lado na mesma linha.
    private let addOptionRowStack = UIStackView()

    // UITextField: entrada de texto em uma única linha para a nova alternativa.
    private let newOptionTextField = UITextField()

    // UIButton: ação secundária para adicionar a alternativa digitada.
    private let addOptionButton = UIButton(type: .system)

    // PrimaryButton: componente reutilizável do app para a ação principal.
    // Nesta etapa ele fica visível, mas desabilitado e sem ação de sorteio
    // (estados do botão e integração do sorteio vêm nas Etapas 4 e 5).
    private let drawButton = PrimaryButton(title: "Sortear")

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

        // Campo da pergunta
        questionTextField.placeholder = "Digite sua pergunta"
        questionTextField.font = .preferredFont(forTextStyle: .body)
        questionTextField.adjustsFontForContentSizeCategory = true
        questionTextField.textColor = Theme.Color.primaryText
        questionTextField.borderStyle = .roundedRect
        questionTextField.returnKeyType = .done
        questionTextField.clearButtonMode = .whileEditing
        questionTextField.accessibilityLabel = "Pergunta da decisão"

        // Pilha principal de conteúdo
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        // Espaço extra antes do botão principal para separar a área de ação.
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: addOptionRowStack)

        // Lista de opções (somente leitura nesta etapa)
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

        // Botão "Adicionar" (ação secundária)
        addOptionButton.setTitle("Adicionar", for: .normal)
        addOptionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        addOptionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        addOptionButton.tintColor = Theme.Color.accent
        addOptionButton.accessibilityHint = "Adiciona a alternativa digitada à lista."
        // Impede que o botão estique horizontalmente; ele mantém o tamanho do título.
        addOptionButton.setContentHuggingPriority(.required, for: .horizontal)
        addOptionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Botão principal "Sortear": presente na tela, mas sem comportamento nesta etapa.
        // Etapa 4: controlar estados (ex.: habilitar conforme regras).
        // Etapa 5: integrar o sorteio e a navegação.
        drawButton.isEnabled = false
        drawButton.accessibilityHint = "Disponível nas próximas etapas, após adicionar opções."
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

    /// Atualiza a lista visual de opções (somente leitura).
    /// O controller chama este método após alterar o Model com sucesso.
    func displayOptions(_ options: [String]) {
        // Remove as views antigas da pilha para recriar a lista do estado atual.
        optionsListStack.arrangedSubviews.forEach { view in
            optionsListStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for option in options {
            let label = UILabel()
            label.text = "• \(option)"
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = Theme.Color.primaryText
            label.numberOfLines = 0 // permite quebrar em várias linhas se necessário
            optionsListStack.addArrangedSubview(label)
        }

        // Esconde a pilha quando não há opções, evitando espaço vazio desnecessário.
        optionsListStack.isHidden = options.isEmpty
    }

    /// Limpa o campo de nova alternativa após uma adição bem-sucedida.
    func clearNewOptionField() {
        newOptionTextField.text = ""
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
