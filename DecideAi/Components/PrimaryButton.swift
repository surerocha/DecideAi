//
//  PrimaryButton.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import UIKit

// MARK: - Botão principal (reutilizável)

/// Botão de ação principal do app (call-to-action).
/// Reutilizado em telas como Home, Criação e Resultado para manter consistência visual.
///
/// Herdamos de `UIButton` para encapsular a configuração padrão em um único componente.
/// `final` impede subclassing adicional (não precisamos estender este componente).
final class PrimaryButton: UIButton {

    /// Cria o botão com um título.
    /// - Parameter title: texto exibido no botão.
    init(title: String) {
        // Inicializa a parte UIKit do botão com frame zero (o tamanho virá do Auto Layout).
        super.init(frame: .zero)

        // `UIButton.Configuration` (iOS 15+) é a API moderna para configurar aparência/comportamento.
        // `.filled()` cria um estilo preenchido: o sistema cuida de fundo, cor do título,
        // estados (normal, desabilitado, highlighted) e feedback visual.
        var configuration = UIButton.Configuration.filled()

        // Texto do botão.
        configuration.title = title

        // Cor de fundo baseada no tema (cor de destaque do app).
        configuration.baseBackgroundColor = Theme.Color.accent

        // Estilo de cantos arredondados fornecido pelo sistema.
        configuration.cornerStyle = .large

        // Espaçamento interno (padding) do conteúdo do botão.
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)

        // Ajusta atributos do título. Usamos uma fonte com "text style" (.headline)
        // para suportar Dynamic Type: se o usuário aumentar o tamanho da fonte no sistema,
        // o botão acompanha.
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = UIFont.preferredFont(forTextStyle: .headline)
            return updated
        }

        // Aplica a configuração ao botão.
        self.configuration = configuration

        // Desativa a conversão automática de autoresizing mask em constraints,
        // pois vamos posicionar/tamanho com Auto Layout.
        translatesAutoresizingMaskIntoConstraints = false

        // Garante altura mínima confortável para toque.
        // "greaterThanOrEqualTo" permite que o botão cresça se o texto (Dynamic Type) exigir.
        // `isActive = true` ativa a constraint diretamente.
        heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Layout.minimumTapHeight).isActive = true
    }

    /// Inicializador exigido por `UIView` quando há init customizado.
    /// É chamado ao criar views a partir de Storyboards/XIBs; como este projeto
    /// constrói UI em código, não damos suporte a esse caminho.
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
