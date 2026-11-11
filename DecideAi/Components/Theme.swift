//
//  Theme.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

/// Central place for visual constants, so every screen shares the same look.
enum Theme {

    enum Color {
        // Cores do sistema se adaptam sozinhas ao modo escuro e ao contraste alto.
        // Mais tarde podemos trocar o accent por uma cor do Assets.xcassets.
        static let accent = UIColor.systemIndigo
        static let background = UIColor.systemBackground
        static let secondaryBackground = UIColor.secondarySystemBackground
        static let primaryText = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    enum Layout {
        static let cornerRadius: CGFloat = 14
        // Altura mínima confortável para toque (a Apple recomenda 44 pt ou mais).
        static let minimumTapHeight: CGFloat = 50
        // No iPad e no iPhone em paisagem o conteúdo não deve esticar até as bordas.
        // Vamos limitar a largura do conteúdo de cada tela a este valor.
        static let maxContentWidth: CGFloat = 560
    }
}
