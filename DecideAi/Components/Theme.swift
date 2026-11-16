//
//  Theme.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Tema visual (constantes compartilhadas)

/// `Theme` centraliza constantes visuais para manter consistência entre as telas.
/// Usamos `enum` sem casos (e `enum`s aninhados) como *namespace*: ele agrupa valores
/// estáticos e não precisa (nem deve) ser instanciado.
///
/// Benefício: se quisermos ajustar uma cor ou espaçamento, mudamos em um lugar só.
enum Theme {

    // MARK: - Cores

    /// Paleta de cores do app.
    /// Preferimos cores semânticas do sistema (`UIColor.system*`, `.label`, etc.)
    /// porque elas se adaptam automaticamente a:
    /// - modo claro/escuro (Light/Dark Mode);
    /// - configurações de acessibilidade (ex.: aumentar contraste);
    /// - diferentes contextos do iOS.
    enum Color {
        // Cor de destaque principal (botões, tint, ícones de destaque).
        // Pode ser substituída futuramente por uma cor nomeada no Assets.xcassets.
        static let accent = UIColor.systemIndigo

        // Fundo principal das telas.
        static let background = UIColor.systemBackground

        // Fundo secundário (útil para cartões/áreas agrupadas, se necessário).
        static let secondaryBackground = UIColor.secondarySystemBackground

        // Cor de texto principal.
        static let primaryText = UIColor.label

        // Cor de texto secundário/apoio.
        static let secondaryText = UIColor.secondaryLabel
    }

    // MARK: - Espaçamentos

    /// Valores de espaçamento reutilizáveis (margens, espaços em stacks, etc.).
    /// Manter uma escala consistente ajuda no ritmo visual da interface.
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    // MARK: - Layout

    /// Constantes relacionadas a medidas e limites de layout.
    enum Layout {
        // Raio de canto padrão para elementos com bordas arredondadas (quando aplicável).
        static let cornerRadius: CGFloat = 14

        // Altura mínima confortável para áreas tocáveis.
        // A Apple recomenda pelo menos 44pt; usamos 50pt para conforto.
        static let minimumTapHeight: CGFloat = 50

        // Largura máxima do conteúdo. Em iPad ou iPhone landscape, evita que o conteúdo
        // estique demais e fique difícil de ler/tocar; o conteúdo fica centralizado/limitado.
        static let maxContentWidth: CGFloat = 560
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, cores e espaçamentos também podem ser centralizados. Podemos usar `Color`
 (SwiftUI), extensões, ou constantes. Muitas cores do sistema têm equivalentes diretos.

 import SwiftUI

 enum Theme {
     enum AppColor {
         static let accent = Color.indigo                 // ~ systemIndigo
         static let background = Color(.systemBackground) // usa UIColor do sistema via bridge
         static let secondaryBackground = Color(.secondarySystemBackground)
         static let primaryText = Color.primary
         static let secondaryText = Color.secondary
     }

     enum Spacing {
         static let small: CGFloat = 8
         static let medium: CGFloat = 16
         static let large: CGFloat = 24
         static let extraLarge: CGFloat = 32
     }

     enum Layout {
         static let cornerRadius: CGFloat = 14
         static let minimumTapHeight: CGFloat = 50
         static let maxContentWidth: CGFloat = 560
     }
 }

 // Uso em uma View SwiftUI:
 // Text("Olá")
 //     .foregroundStyle(Theme.AppColor.primaryText)
 //     .padding(Theme.Spacing.medium)
 //     .frame(maxWidth: Theme.Layout.maxContentWidth)
 //     .tint(Theme.AppColor.accent)

 Observação: SwiftUI já favorece semântica (Color.primary/secondary, .background),
 mas manter um Theme ajuda quando queremos uma identidade visual específica do app.
*/
