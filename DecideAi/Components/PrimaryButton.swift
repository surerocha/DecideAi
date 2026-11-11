//
//  PrimaryButton.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// The app's main call-to-action button.
/// Reusable: Home, Decision and Result will all use it.
final class PrimaryButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)

        // UIButton.Configuration é a forma moderna de estilizar botões (iOS 15+).
        // O estilo "filled" já cuida de cor de fundo, cor do texto, estado
        // desabilitado e feedback ao toque, sem precisarmos desenhar nada.
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = Theme.Color.accent
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)

        // Fonte baseada em text style, para respeitar o Dynamic Type.
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = UIFont.preferredFont(forTextStyle: .headline)
            return updated
        }

        self.configuration = configuration

        translatesAutoresizingMaskIntoConstraints = false
        // Área de toque confortável. "greaterThanOrEqual" permite o botão crescer
        // quando o texto ficar maior com Dynamic Type.
        heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Layout.minimumTapHeight).isActive = true
    }

    // Obrigatório em subclasses de UIView; só é usado com storyboards,
    // que não usamos neste projeto.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
