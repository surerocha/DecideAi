//
//  PrimaryButton.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Botões do app (estilos do protótipo)

/// Botão de ação reutilizável com variantes visuais inspiradas no protótipo Figma.
/// Mantém API compatível: `PrimaryButton(title:)` cria o estilo principal (accent).
///
/// Variantes:
/// - `primary`: preenchido roxo (accent), texto branco — ação principal em fundos claros.
/// - `lime`: preenchido lima, texto escuro — CTA forte sobre fundos de marca/gradiente.
/// - `glass`: translúcido sobre fundo escuro/gradiente.
/// - `tonal`: suave (accent soft) para ações secundárias em fundos claros.
final class PrimaryButton: UIButton {

    /// Estilo visual do botão.
    enum Style {
        case primary
        case lime
        case glass
        case tonal
    }

    private let style: Style

    /// Cria o botão com título e estilo (padrão: primary, para compatibilidade).
    init(title: String, style: Style = .primary) {
        self.style = style
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .fixed
        config.background.cornerRadius = Theme.Layout.buttonRadius
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)

        // Fonte forte no estilo "display" do protótipo, mas com suporte a Dynamic Type.
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            let base = Theme.Font.display(size: 18, weight: .heavy)
            a.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: base)
            return a
        }

        switch style {
        case .primary:
            config.baseBackgroundColor = Theme.Color.brand
            config.baseForegroundColor = .white
        case .lime:
            config.baseBackgroundColor = Theme.Color.lime
            config.baseForegroundColor = Theme.Color.limeInk
        case .glass:
            config = UIButton.Configuration.plain()
            config.title = title
            config.cornerStyle = .fixed
            config.background.cornerRadius = Theme.Layout.buttonRadius
            config.background.backgroundColor = UIColor.white.withAlphaComponent(0.14)
            config.background.strokeColor = UIColor.white.withAlphaComponent(0.30)
            config.background.strokeWidth = 1
            config.baseForegroundColor = .white
            config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                var a = attrs
                let base = Theme.Font.display(size: 18, weight: .heavy)
                a.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: base)
                return a
            }
        case .tonal:
            config.baseBackgroundColor = Theme.Color.accentSoft
            config.baseForegroundColor = Theme.Color.accentText
        }

        self.configuration = config

        // Atualiza cores de estado (desabilitado) conforme o estilo.
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            var c = button.configuration
            if !button.isEnabled {
                switch self.style {
                case .lime:
                    c?.baseBackgroundColor = UIColor.white.withAlphaComponent(0.16)
                    c?.background.backgroundColor = UIColor.white.withAlphaComponent(0.16)
                    c?.baseForegroundColor = UIColor.white.withAlphaComponent(0.7)
                case .glass:
                    c?.background.backgroundColor = UIColor.white.withAlphaComponent(0.08)
                    c?.background.strokeColor = UIColor.white.withAlphaComponent(0.12)
                    c?.baseForegroundColor = UIColor.white.withAlphaComponent(0.4)
                case .primary, .tonal:
                    // Usa cor explícita de fundo desabilitado (evita "sobras" ao reabilitar).
                    c?.baseBackgroundColor = Theme.Color.surface2
                    c?.background.backgroundColor = Theme.Color.surface2
                    c?.baseForegroundColor = Theme.Color.ink2.withAlphaComponent(0.6)
                }
            } else {
                switch self.style {
                case .primary:
                    c?.baseBackgroundColor = Theme.Color.brand
                    c?.background.backgroundColor = Theme.Color.brand
                    c?.baseForegroundColor = .white
                case .lime:
                    c?.baseBackgroundColor = Theme.Color.lime
                    c?.background.backgroundColor = Theme.Color.lime
                    c?.baseForegroundColor = Theme.Color.limeInk
                case .glass:
                    c?.background.backgroundColor = UIColor.white.withAlphaComponent(0.14)
                    c?.background.strokeColor = UIColor.white.withAlphaComponent(0.30)
                    c?.baseForegroundColor = .white
                case .tonal:
                    c?.baseBackgroundColor = Theme.Color.accentSoft
                    c?.background.backgroundColor = Theme.Color.accentSoft
                    c?.baseForegroundColor = Theme.Color.accentText
                }
            }
            button.configuration = c
            button.alpha = (button.isHighlighted && button.isEnabled) ? 0.9 : 1.0
        }

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Layout.minimumTapHeight).isActive = true
    }

    /// Atualiza o título mantendo o estilo.
    func setTitleText(_ title: String) {
        var c = configuration
        c?.title = title
        configuration = c
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Em SwiftUI, um botão estilizado pode ser um `Button` com modificadores ou um `ButtonStyle`
 reutilizável. A fonte dinâmica e o estado desabilitado são tratados de forma declarativa.

 import SwiftUI

 /// Estilo reutilizável equivalente ao PrimaryButton.
 struct PrimaryButtonStyle: ButtonStyle {
     // `isEnabled` vem do ambiente; permite ajustar aparência quando desabilitado.
     @Environment(\.isEnabled) private var isEnabled

     func makeBody(configuration: Configuration) -> some View {
         configuration.label
             .font(.headline) // text style: suporta Dynamic Type
             .foregroundStyle(.white)
             .frame(maxWidth: .infinity)
             .frame(minHeight: 50) // altura mínima de toque
             .padding(.vertical, 14)
             .padding(.horizontal, 24)
             .background(.indigo) // equivalente ao accent
             .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
             .opacity(configuration.isPressed ? 0.85 : 1) // feedback de toque
             .opacity(isEnabled ? 1 : 0.5) // estado desabilitado
     }
 }

 // Uso:
 // Button("Nova decisão") { iniciar() }
 //     .buttonStyle(PrimaryButtonStyle())
 //     .disabled(!podeSortear)

 // Alternativa (iOS 15+), parecida com .filled():
 // Button("Nova decisão") { iniciar() }
 //     .buttonStyle(.borderedProminent)
 //     .tint(.indigo)
 //     .controlSize(.large)
*/
