//
//  DecisionService.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import Foundation

// MARK: - Estruturas de apoio à animação do sorteio

/// Representa um "frame" (passo) da animação de sorteio.
/// - `text`: opção exibida naquele instante.
/// - `duration`: quanto tempo (em segundos) esse texto deve permanecer na tela antes da próxima troca.
struct DrawFrame: Equatable {
    let text: String
    let duration: TimeInterval
}

/// Resultado completo de um sorteio, calculado antes de iniciar a animação.
/// A UI deve apenas reproduzir os `frames` na ordem; o vencedor já está definido.
/// Garantia importante: o **último frame** corresponde ao `winner`.
struct DrawPlan {
    let winnerIndex: Int    // Índice do vencedor na lista de opções da decisão.
    let winner: String      // Texto da opção vencedora.
    let frames: [DrawFrame] // Sequência de passos da animação (com desaceleração e pausa final).
}

// MARK: - Serviço de sorteio

/// Serviço responsável por validar a decisão, escolher o vencedor e montar o `DrawPlan`.
/// Não depende de UIKit: concentra apenas lógica/regra, facilitando testes.
///
/// Parâmetros alinhados ao protótipo v2:
/// - 20 trocas (frames), intervalo 60ms → 450ms (ease-in cúbico), pausa final de 300ms com o vencedor.
struct DecisionService {

    // Configurações da animação (alinhadas ao protótipo v2).
    static let tickCount = 20
    static let fastestFrameDuration: TimeInterval = 0.060 // 60ms
    static let slowestFrameDuration: TimeInterval = 0.450 // 450ms
    /// Pausa com o vencedor exibido antes da revelação do resultado.
    static let endPauseDuration: TimeInterval = 0.300 // 300ms
    /// Trocas com intervalo a partir deste valor recebem háptico leve (referência para a UI).
    static let hapticFromDuration: TimeInterval = 0.250 // 250ms

    /// Intervalo entre trocas para o passo `i` (0-based), ease-in cúbico: 60ms → 450ms.
    static func tickDelay(for index: Int, count: Int = tickCount) -> TimeInterval {
        guard count > 1 else { return fastestFrameDuration }
        let progress = Double(index) / Double(count - 1)
        let range = slowestFrameDuration - fastestFrameDuration
        return fastestFrameDuration + range * pow(progress, 3)
    }

    /// Ponto de entrada padrão: usa o gerador aleatório do sistema.
    /// - Parameter decision: decisão a ser sorteada.
    /// - Returns: plano com vencedor e frames de animação.
    /// - Throws: erros de validação/regra (`DecisionError`).
    func makeDrawPlan(for decision: Decision) throws -> DrawPlan {
        var generator = SystemRandomNumberGenerator()
        return try makeDrawPlan(for: decision, using: &generator)
    }

    /// Versão que recebe o gerador aleatório como parâmetro.
    /// Isso permite testes determinísticos ou controlados quando necessário.
    func makeDrawPlan<G: RandomNumberGenerator>(
        for decision: Decision,
        using generator: inout G
    ) throws -> DrawPlan {
        // 1) Garante que a decisão é válida (pergunta ok e mínimo de opções).
        try decision.validate()

        let options = decision.options

        // 2) Escolhe o vencedor UMA única vez, com probabilidade uniforme entre as opções.
        guard let winnerIndex = options.indices.randomElement(using: &generator) else {
            throw DecisionError.notEnoughOptions
        }

        // 3) Monta os frames (TICKS trocas) em sequência circular terminando no vencedor.
        //    Índices calculados de trás para frente: o último passo aponta para `winnerIndex`.
        let frameCount = Self.tickCount
        let frames = (0..<frameCount).map { position -> DrawFrame in
            let stepsBeforeEnd = frameCount - 1 - position
            let rawIndex = winnerIndex - stepsBeforeEnd
            let optionIndex = ((rawIndex % options.count) + options.count) % options.count

            // Duração: intervalos crescentes (desaceleração) nas trocas; o último frame
            // mantém o vencedor visível pela pausa final antes da revelação.
            let duration: TimeInterval
            if position == frameCount - 1 {
                duration = Self.endPauseDuration
            } else {
                duration = Self.tickDelay(for: position, count: frameCount)
            }

            return DrawFrame(text: options[optionIndex], duration: duration)
        }

        return DrawPlan(winnerIndex: winnerIndex, winner: options[winnerIndex], frames: frames)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 `DecisionService`, `DrawPlan` e `DrawFrame` são independentes de UI, então o código é o mesmo
 em um app SwiftUI. A diferença está em como a View consome o plano para animar.

 import SwiftUI

 struct ResultView: View {
     let decision: Decision
     @State private var displayed = ""
     @State private var animating = true

     var body: some View {
         VStack {
             Text(displayed).font(.largeTitle).bold()
             Button("Sortear novamente") { /* gerar novo plano e animar */ }
                 .disabled(animating)
         }
         .task {
             do {
                 let plan = try DecisionService().makeDrawPlan(for: decision)
                 for (index, frame) in plan.frames.enumerated() {
                     displayed = frame.text
                     // Háptico leve nas trocas mais lentas (>= 250ms).
                     if index < plan.frames.count - 1, frame.duration >= 0.25 {
                         UIImpactFeedbackGenerator(style: .light).impactOccurred()
                     }
                     try? await Task.sleep(nanoseconds: UInt64(frame.duration * 1_000_000_000))
                 }
                 animating = false
             } catch { /* tratar erro */ }
         }
     }
 }
*/
