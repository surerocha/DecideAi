//
//  Theme.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Tema visual (identidade "Decide Aí")

/// `Theme` centraliza tokens visuais (cores, gradientes, tipografia, espaçamentos e raios)
/// inspirados no protótipo do Figma. Usamos `enum` como *namespace* (sem instâncias).
///
/// Mantemos compatibilidade com os nomes usados antes (`Color.accent/background/...`,
/// `Spacing`, `Layout`) para não quebrar telas existentes, e adicionamos tokens da nova
/// identidade. Cores dinâmicas se adaptam a Light/Dark Mode.
enum Theme {

    // MARK: - Cores base (tokens do protótipo)

    /// Paleta semântica da identidade visual (baseada em `index.css` do protótipo).
    enum Color {
        // --- Tokens legados (compatibilidade) ---
        static let accent = brand
        static let background = canvas
        static let secondaryBackground = surface2
        static let primaryText = ink
        static let secondaryText = ink2

        // --- Canvas / superfícies ---
        /// Fundo principal das telas claras de conteúdo.
        static let canvas = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0x0F0B24)
                : UIColor(hex: 0xF3F1FA)
        }
        static let surface = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0x1B1640)
                : UIColor.white
        }
        static let surface2 = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0x282156)
                : UIColor(hex: 0xEAE6F8)
        }

        // --- Tinta (texto) ---
        static let ink = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0xF4F2FF)
                : UIColor(hex: 0x16113A)
        }
        static let ink2 = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0xA8A3D3)
                : UIColor(hex: 0x5B5683)
        }
        static let line = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.12)
                : UIColor(hex: 0x16113A).withAlphaComponent(0.10)
        }
        /// Borda de campos de texto (protótipo v2: `fieldLine`).
        static let fieldLine = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0x6F69A8)
                : UIColor(hex: 0x847FA6)
        }
        /// Realce do texto vencedor (protótipo v2: `--hl`).
        static let highlight = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0xC8F53C).withAlphaComponent(0.40)
                : UIColor(hex: 0xC8F53C)
        }

        // --- Marca / destaque ---
        static let brand = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0x6C4BFF)
                : UIColor(hex: 0x5B3DF5)
        }
        static let accentText = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0xA99BFF)
                : UIColor(hex: 0x4A2FD6)
        }
        static let accentSoft = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0xA99BFF).withAlphaComponent(0.16)
                : UIColor(hex: 0x5B3DF5).withAlphaComponent(0.12)
        }
        static let lime = UIColor(hex: 0xC8F53C)
        static let limeInk = UIColor(hex: 0x16113A)
        static let coral = UIColor(hex: 0xFF6F91)

        // --- Perigo/erro ---
        static let danger = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0xFF6B87)
                : UIColor(hex: 0xC21C3E)
        }
        static let dangerSoft = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(hex: 0x3A1530)
                : UIColor(hex: 0xFDE6EB)
        }

        // --- Gradiente de marca (Home/Resultado) ---
        static let brand1 = UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: 0x4D31DE) : UIColor(hex: 0x6A4BFF)
        }
        static let brand2 = UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: 0x281B92) : UIColor(hex: 0x3F26D4)
        }
        static let brand3 = UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: 0x120B3F) : UIColor(hex: 0x230F86)
        }

        /// Texto sobre fundos de marca/gradiente.
        static let onBrand = UIColor.white
        static let onBrandMuted = UIColor.white.withAlphaComponent(0.75)

        /// Tinta do alerta nativo no tema (aproximação dos tokens de alerta do protótipo).
        static let alertTint = accentText

        /// Cores para badges numeradas das opções (inspiradas no protótipo).
        static let optionPalette: [UIColor] = [
            UIColor(hex: 0xC8F53C), UIColor(hex: 0xFF8FA8), UIColor(hex: 0x8FD3FF),
            UIColor(hex: 0xFFC857), UIColor(hex: 0xB9A6FF), UIColor(hex: 0x7BE0B5),
            UIColor(hex: 0xFFA07A), UIColor(hex: 0xE3A6FF), UIColor(hex: 0x9BE564),
            UIColor(hex: 0x7FB5FF)
        ]
    }

    // MARK: - Espaçamentos

    /// Escala de espaçamento reutilizável.
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    // MARK: - Layout

    /// Medidas e raios de layout.
    enum Layout {
        static let cornerRadius: CGFloat = 14
        static let cardRadius: CGFloat = 22
        static let fieldRadius: CGFloat = 14
        static let buttonRadius: CGFloat = 18
        static let minimumTapHeight: CGFloat = 50
        static let maxContentWidth: CGFloat = 560
    }

    // MARK: - Tipografia

    /// Helpers de fonte. Priorizamos Dynamic Type (text styles) para acessibilidade.
    /// Onde o protótipo usa fonte "display" pesada, aproximamos com SF Pro arredondada/black.
    enum Font {
        static func display(size: CGFloat, weight: UIFont.Weight = .black) -> UIFont {
            if let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
                .withDesign(.rounded) {
                return UIFont(descriptor: descriptor, size: size)
            }
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        static func scaledDisplay(baseSize: CGFloat, weight: UIFont.Weight = .black, textStyle: UIFont.TextStyle) -> UIFont {
            let base = display(size: baseSize, weight: weight)
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
        }
    }

    // MARK: - Gradientes

    /// Cria/atualiza um `CAGradientLayer` com o gradiente de marca (roxo) do protótipo.
    /// - Parameters:
    ///   - layer: camada a configurar (reutilize para evitar acumular camadas).
    ///   - trait: trait collection para resolver cores dinâmicas (light/dark).
    /// - Returns: a camada configurada.
    @discardableResult
    static func applyBrandGradient(to layer: CAGradientLayer, trait: UITraitCollection) -> CAGradientLayer {
        layer.colors = [
            Color.brand1.resolvedColor(with: trait).cgColor,
            Color.brand2.resolvedColor(with: trait).cgColor,
            Color.brand3.resolvedColor(with: trait).cgColor
        ]
        layer.startPoint = CGPoint(x: 0.1, y: 0.0)
        layer.endPoint = CGPoint(x: 0.9, y: 1.0)
        return layer
    }
}

// MARK: - Utilitário de cor (hex)

extension UIColor {
    /// Cria uma cor a partir de um inteiro hexadecimal RGB (ex.: 0x5B3DF5).
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
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
