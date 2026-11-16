//
//  HomeView.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - View da Home (UI)

/// Parte visual da tela inicial (Home).
/// Responsabilidades:
/// - montar e configurar os componentes de interface;
/// - definir o layout (Auto Layout);
/// - expor eventos de interação via callback.
///
/// Não é responsável por navegação nem por regras de negócio.
/// (Quem navega é o `HomeViewController`.)
final class HomeView: UIView {

    // MARK: - Callback de interação

    /// Closure chamada quando o usuário toca em "Nova decisão".
    /// O controller atribui essa closure para reagir ao toque (ex.: fazer push).
    var onStartTapped: (() -> Void)?

    // MARK: - Componentes de UI

    // Scroll view permite rolar o conteúdo em telas menores ou com fontes grandes.
    private let scrollView = UIScrollView()

    // Stack view organiza os elementos verticalmente e calcula espaçamentos/posições.
    private let contentStack = UIStackView()

    // Ícone ilustrativo (SF Symbol).
    private let iconView = UIImageView()

    // Labels de texto (título, convite, explicação, slogan).
    private let titleLabel = HomeView.makeLabel(textStyle: .largeTitle, color: Theme.Color.primaryText, bold: true)
    private let invitationLabel = HomeView.makeLabel(textStyle: .title2, color: Theme.Color.primaryText, bold: true)
    private let explanationLabel = HomeView.makeLabel(textStyle: .body, color: Theme.Color.secondaryText)
    private let sloganLabel = HomeView.makeLabel(textStyle: .footnote, color: Theme.Color.secondaryText)

    // Botão principal reutilizável do app.
    private let startButton = PrimaryButton(title: "Nova decisão")

    // MARK: - Inicialização

    /// Inicializador programático da view.
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Ordem comum: configurar aparências -> montar hierarquia -> aplicar constraints.
        configureViews()
        buildHierarchy()
        activateConstraints()
    }

    /// Inicializador exigido para Storyboard/XIB (não usado neste projeto).
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuração dos componentes

    /// Define conteúdo, estilos e comportamentos dos componentes.
    private func configureViews() {
        // Cor de fundo da tela.
        backgroundColor = Theme.Color.background

        // Configura um SF Symbol (ícone vetorial do sistema) com tamanho e peso.
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72, weight: .semibold)
        iconView.image = UIImage(systemName: "die.face.5.fill", withConfiguration: symbolConfiguration)
        iconView.tintColor = Theme.Color.accent
        iconView.contentMode = .scaleAspectFit
        // Ícone puramente decorativo: oculto para leitores de tela (VoiceOver).
        iconView.isAccessibilityElement = false

        // Textos exibidos na tela.
        titleLabel.text = "Decide Aí"
        // Marca o título como cabeçalho para navegação por acessibilidade.
        titleLabel.accessibilityTraits = .header

        invitationLabel.text = "Não consegue escolher? Deixa comigo!"
        explanationLabel.text = "Crie uma decisão, adicione suas alternativas e deixe o sorteio escolher por você."
        sloganLabel.text = "Você tem opções. A gente resolve."

        // Dica de acessibilidade explicando o efeito do botão.
        startButton.accessibilityHint = "Abre a tela para criar uma nova decisão."

        // `UIAction` (iOS 14+) associa um evento a uma closure.
        // `[weak self]` evita ciclo de retenção: a view possui o botão; o botão
        // armazena a action; sem `weak`, a action capturaria `self` fortemente.
        startButton.addAction(UIAction { [weak self] _ in
            self?.onStartTapped?()
        }, for: .touchUpInside)

        // Configuração da pilha vertical.
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Theme.Spacing.medium
        // Espaçamentos customizados após elementos específicos.
        contentStack.setCustomSpacing(Theme.Spacing.extraLarge, after: explanationLabel)
        contentStack.setCustomSpacing(Theme.Spacing.large, after: startButton)
    }

    // MARK: - Hierarquia de views

    /// Adiciona as views na hierarquia (quem é filho de quem).
    private func buildHierarchy() {
        // Adiciona os elementos como filhos organizados pela stack.
        [iconView, titleLabel, invitationLabel, explanationLabel, startButton, sloganLabel]
            .forEach { contentStack.addArrangedSubview($0) }

        // A stack vai dentro da scroll view; a scroll view vai dentro da view principal.
        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }

    // MARK: - Auto Layout (constraints)

    /// Define as constraints que posicionam e dimensionam os elementos.
    private func activateConstraints() {
        // Necessário ao usar Auto Layout programático.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Layout guides da UIScrollView:
        // - contentLayoutGuide: representa a área do conteúdo rolável.
        // - frameLayoutGuide: representa a área visível da scroll.
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        // Largura "preenchendo" com margens laterais (boa no iPhone).
        // Prioridade menor que required para permitir que, no iPad, o limite de largura vença.
        let fillWidth = contentStack.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -2 * Theme.Spacing.large
        )
        fillWidth.priority = .defaultHigh

        // Tenta centralizar verticalmente quando houver espaço sobrando.
        // Prioridade baixa para que, se o conteúdo for maior, a rolagem funcione.
        let centerVertically = contentStack.centerYAnchor.constraint(equalTo: frame.centerYAnchor)
        centerVertically.priority = .defaultLow

        // Ativa todas as constraints de uma vez.
        NSLayoutConstraint.activate([
            // Scroll view ocupando a área segura.
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),

            // Impede rolagem horizontal: conteúdo tem a mesma largura da área visível.
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),

            // Posicionamento da stack dentro do conteúdo rolável.
            contentStack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: Theme.Spacing.large),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Theme.Spacing.large),

            // Limite de largura em telas grandes e preenchimento no iPhone.
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            fillWidth,
            centerVertically
        ])
    }

    // MARK: - Helpers

    /// Cria e configura uma `UILabel` com estilo consistente (fonte dinâmica, cor, alinhamento).
    /// - Parameters:
    ///   - textStyle: estilo tipográfico do sistema (suporta Dynamic Type).
    ///   - color: cor do texto.
    ///   - bold: se deve aplicar negrito ao estilo.
    private static func makeLabel(textStyle: UIFont.TextStyle, color: UIColor, bold: Bool = false) -> UILabel {
        let label = UILabel()

        // Fonte baseada em text style para escalar com as preferências do usuário.
        var font = UIFont.preferredFont(forTextStyle: textStyle)
        if bold, let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            // size 0 mantém o tamanho associado ao estilo (importante para Dynamic Type).
            font = UIFont(descriptor: descriptor, size: 0)
        }

        label.font = font
        // Atualiza automaticamente quando o tamanho de fonte do sistema muda.
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.textAlignment = .center
        // 0 = número ilimitado de linhas (permite quebra de linha).
        label.numberOfLines = 0
        return label
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
