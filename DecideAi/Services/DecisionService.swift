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
/// - `duration`: quanto tempo (em segundos) esse texto deve permanecer na tela.
struct DrawFrame: Equatable {
    let text: String
    let duration: TimeInterval
}

/// Resultado completo de um sorteio, calculado antes de iniciar a animação.
/// A UI deve apenas reproduzir os `frames` na ordem; o vencedor já está definido.
/// Garantia importante: o **último frame** corresponde ao `winner`.
struct DrawPlan {
    let winnerIndex: Int   // Índice do vencedor na lista de opções da decisão.
    let winner: String     // Texto da opção vencedora.
    let frames: [DrawFrame] // Sequência de passos da animação (com desaceleração).
}

// MARK: - Serviço de sorteio

/// Serviço responsável por validar a decisão, escolher o vencedor e montar o `DrawPlan`.
/// Não depende de UIKit: concentra apenas lógica/regra, facilitando testes.
struct DecisionService {

    // Configurações da animação (quantidade de passos e velocidades).
    // `private static` pois são detalhes internos do serviço.
    private static let minimumFrameCount = 18
    private static let fastestFrameDuration: TimeInterval = 0.06
    private static let slowestFrameDuration: TimeInterval = 0.45

    /// Ponto de entrada padrão: usa o gerador aleatório do sistema.
    /// - Parameter decision: decisão a ser sorteada.
    /// - Returns: plano com vencedor e frames de animação.
    /// - Throws: erros de validação/regra (`DecisionError`).
    func makeDrawPlan(for decision: Decision) throws -> DrawPlan {
        // Cria um gerador aleatório do sistema e delega para a versão injetável.
        var generator = SystemRandomNumberGenerator()
        return try makeDrawPlan(for: decision, using: &generator)
    }

    /// Versão que recebe o gerador aleatório como parâmetro.
    /// Isso permite testes determinísticos ou controlados quando necessário.
    ///
    /// - Parameters:
    ///   - decision: decisão a ser sorteada.
    ///   - generator: gerador de números aleatórios (genérico).
    /// - Returns: `DrawPlan` pronto para a UI reproduzir.
    func makeDrawPlan<G: RandomNumberGenerator>(
        for decision: Decision,
        using generator: inout G
    ) throws -> DrawPlan {
        // 1) Garante que a decisão é válida (pergunta ok e mínimo de opções).
        try decision.validate()

        let options = decision.options

        // 2) Escolhe o vencedor UMA única vez, com probabilidade uniforme entre as opções.
        // `randomElement` retorna nil se a coleção estiver vazia; tratamos como segurança extra.
        guard let winnerIndex = options.indices.randomElement(using: &generator) else {
            throw DecisionError.notEnoughOptions
        }

        // 3) Define quantos frames a animação terá (mínimo fixo ou proporcional às opções).
        let frameCount = max(Self.minimumFrameCount, options.count * 2)

        // 4) Monta os frames. Calculamos os índices "de trás para frente" para que:
        //    - a sequência percorra as opções em ordem circular (efeito de roleta em texto);
        //    - o último passo (position == frameCount - 1) aponte exatamente para `winnerIndex`.
        let frames = (0..<frameCount).map { position -> DrawFrame in
            // Quantos passos faltam até o final.
            let stepsBeforeEnd = frameCount - 1 - position

            // Índice relativo ao vencedor, andando para trás na lista circular.
            let rawIndex = winnerIndex - stepsBeforeEnd

            // Ajuste de módulo para lidar com valores negativos e manter o índice válido.
            let optionIndex = ((rawIndex % options.count) + options.count) % options.count

            // 5) Calcula a duração do frame para criar desaceleração:
            // `progress` vai de 0.0 (início) a 1.0 (fim).
            let progress = Double(position) / Double(frameCount - 1)

            // Interpolação entre duração mais rápida e mais lenta.
            let range = Self.slowestFrameDuration - Self.fastestFrameDuration

            // `pow(progress, 2.5)` faz a curva crescer devagar no início e mais rápido no fim,
            // resultando em: começa veloz e termina desacelerando.
            let duration = Self.fastestFrameDuration + range * pow(progress, 2.5)

            return DrawFrame(text: options[optionIndex], duration: duration)
        }

        // 6) Retorna o plano completo (UI não sorteia novamente).
        return DrawPlan(winnerIndex: winnerIndex, winner: options[winnerIndex], frames: frames)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 `DecisionService`, `DrawPlan` e `DrawFrame` são independentes de UI, então o código é o mesmo
 em um app SwiftUI. A diferença está em como a View consome o plano para animar.

 // Serviço e modelos: idênticos ao UIKit.
 // let plan = try DecisionService().makeDrawPlan(for: decision)

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
             // .task executa trabalho assíncrono quando a view aparece.
             // Podemos percorrer os frames aguardando cada duration.
             do {
                 let plan = try DecisionService().makeDrawPlan(for: decision)
                 for (index, frame) in plan.frames.enumerated() {
                     displayed = frame.text
                     // Haptics poderiam ser disparados aqui (via UIKit generators ou APIs auxiliares).
                     if index < plan.frames.count - 1 {
                         try? await Task.sleep(nanoseconds: UInt64(frame.duration * 1_000_000_000))
                     }
                 }
                 animating = false
             } catch { /* tratar erro */ }
         }
     }
 }

 Observação: em SwiftUI, `Task.sleep` + loop em `.task` é uma forma natural de reproduzir
 a sequência de frames; no UIKit usamos `DispatchQueue.main.asyncAfter`/`DispatchWorkItem`.
*/
