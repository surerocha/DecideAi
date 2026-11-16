//
//  Decision.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import Foundation

// MARK: - Erros de domínio (regras da decisão)

/// Representa tudo o que pode dar errado ao montar ou sortear uma decisão.
/// Cada caso carrega uma mensagem amigável (`userMessage`) pronta para exibição na UI
/// (ex.: em um `UIAlertController`), evitando duplicar textos/regras fora do Model.
///
/// Conformidades:
/// - `Error`: permite usar com `throw`/`do-catch`.
/// - `Equatable`: facilita comparações em testes (ex.: `XCTAssertEqual`).
enum DecisionError: Error, Equatable {
    case emptyQuestion      // Pergunta vazia (ou só espaços).
    case questionTooLong    // Pergunta acima do limite de caracteres.
    case emptyOption        // Alternativa vazia (ou só espaços).
    case optionTooLong      // Alternativa acima do limite de caracteres.
    case duplicateOption    // Alternativa repetida (considerando acentos/maiúsculas).
    case tooManyOptions     // Ultrapassou o número máximo de alternativas.
    case optionNotFound     // Índice/opção não encontrada para edição/remoção.
    case notEnoughOptions   // Menos alternativas do que o mínimo para sortear.

    /// Mensagem orientada ao usuário, associada a cada erro de validação.
    var userMessage: String {
        switch self {
        case .emptyQuestion:
            return "Escreva o que você quer decidir antes de começar."
        case .questionTooLong:
            return "A pergunta pode ter no máximo \(Decision.maxQuestionLength) caracteres."
        case .emptyOption:
            return "Escreva uma alternativa antes de adicionar."
        case .optionTooLong:
            return "Cada alternativa pode ter no máximo \(Decision.maxOptionLength) caracteres."
        case .duplicateOption:
            return "Essa alternativa já está na lista."
        case .tooManyOptions:
            return "Você pode ter no máximo \(Decision.maxOptions) alternativas."
        case .optionNotFound:
            return "Não encontrei essa alternativa. Tente novamente."
        case .notEnoughOptions:
            return "Adicione pelo menos \(Decision.minOptions) alternativas para sortear."
        }
    }
}

// MARK: - Modelo da decisão

/// Representa uma decisão: uma pergunta e a lista de alternativas possíveis.
///
/// É uma `struct` (tipo por valor/value type):
/// - ao atribuir ou passar como parâmetro, ela é copiada;
/// - isso é desejável para "Tentar novamente" reaproveitar as mesmas opções sem
///   compartilhar/alterar acidentalmente o estado de outra tela.
struct Decision {

    // MARK: - Limites e regras

    // Regras centralizadas aqui para serem usadas pelo Model, UI e testes.
    static let minOptions = 2        // Mínimo necessário para poder sortear.
    static let maxOptions = 10       // Máximo de alternativas permitidas.
    static let maxOptionLength = 40  // Tamanho máximo de cada alternativa.
    static let maxQuestionLength = 80 // Tamanho máximo da pergunta.

    // MARK: - Estado

    /// Texto da pergunta (pode ser editado livremente; a validação ocorre quando necessário).
    var question: String

    /// Lista de alternativas.
    /// `private(set)` significa: visível para leitura fora do tipo, mas só pode ser
    /// modificada pelos métodos deste `struct` (`add/update/remove`), que validam os dados.
    /// Assim evitamos estados inválidos (vazio, duplicado, acima do limite etc.).
    private(set) var options: [String] = []

    /// Inicializador com pergunta opcional (padrão vazia).
    init(question: String = "") {
        self.question = question
    }

    /// Pergunta sem espaços/quebras no início e fim, pronta para exibição/uso.
    var displayQuestion: String { question.trimmed }

    /// Indica se já há alternativas suficientes para sortear.
    /// Usado pela UI para habilitar/desabilitar o botão "Sortear".
    var canDraw: Bool { options.count >= Self.minOptions }

    // MARK: - Operações nas opções

    /// Adiciona uma nova alternativa após validar conteúdo, tamanho, duplicidade e limite.
    /// `mutating` porque altera o estado (`options`) de uma `struct`.
    /// `throws` para sinalizar erros de validação ao chamador.
    mutating func addOption(_ text: String) throws {
        // Impede ultrapassar o limite máximo de opções.
        guard options.count < Self.maxOptions else { throw DecisionError.tooManyOptions }

        // Valida e normaliza o texto (trim) sem ignorar nenhum índice existente.
        let clean = try validatedOption(text, ignoringIndex: nil)

        // Armazena a versão normalizada.
        options.append(clean)
    }

    /// Atualiza a alternativa em um índice específico.
    /// - Parameters:
    ///   - index: posição da alternativa a ser alterada.
    ///   - text: novo texto.
    mutating func updateOption(at index: Int, to text: String) throws {
        // Garante que o índice existe na lista atual.
        guard options.indices.contains(index) else { throw DecisionError.optionNotFound }

        // Valida o novo texto ignorando o próprio índice na checagem de duplicata.
        // Ex.: mudar "Pizza" para "pizza" não deve ser considerado duplicado de si mesmo.
        let clean = try validatedOption(text, ignoringIndex: index)

        // Substitui pelo texto validado/normalizado.
        options[index] = clean
    }

    /// Remove a alternativa no índice, se existir (operação segura).
    mutating func removeOption(at index: Int) {
        // Se o índice for inválido, não faz nada.
        guard options.indices.contains(index) else { return }
        options.remove(at: index)
    }

    // MARK: - Validação da decisão completa

    /// Valida se a decisão está pronta para ser sorteada.
    /// Lança erro caso a pergunta esteja inválida ou não haja opções suficientes.
    func validate() throws {
        let clean = question.trimmed

        // Pergunta não pode ser vazia.
        guard !clean.isEmpty else { throw DecisionError.emptyQuestion }

        // Pergunta deve respeitar o limite de tamanho.
        guard clean.count <= Self.maxQuestionLength else { throw DecisionError.questionTooLong }

        // Deve haver pelo menos o mínimo de opções.
        guard canDraw else { throw DecisionError.notEnoughOptions }
    }

    // MARK: - Validação interna de alternativa

    /// Valida e normaliza o texto de uma alternativa.
    /// - Parameters:
    ///   - text: texto informado pelo usuário.
    ///   - ignoringIndex: índice a ser ignorado na checagem de duplicata (usado na edição).
    /// - Returns: texto "limpo" (trim) pronto para armazenar.
    private func validatedOption(_ text: String, ignoringIndex: Int?) throws -> String {
        // Normaliza removendo espaços/quebras nas extremidades.
        let clean = text.trimmed

        // Não aceita alternativa vazia.
        guard !clean.isEmpty else { throw DecisionError.emptyOption }

        // Respeita o limite de caracteres.
        guard clean.count <= Self.maxOptionLength else { throw DecisionError.optionTooLong }

        // Chave de comparação que ignora maiúsculas/minúsculas e acentos.
        let key = clean.comparisonKey

        // Verifica se já existe outra opção com a mesma chave, ignorando o índice informado.
        let isDuplicate = options.enumerated().contains { offset, existing in
            offset != ignoringIndex && existing.comparisonKey == key
        }
        guard !isDuplicate else { throw DecisionError.duplicateOption }

        return clean
    }
}

// MARK: - Helpers de String (uso interno do arquivo)

/// Extensão privada: disponível apenas neste arquivo, pois só o `Decision` precisa desses helpers.
private extension String {

    /// Remove espaços em branco e quebras de linha do início e do fim.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Chave normalizada para comparação.
    /// Exemplos equivalentes: "Açaí", "acai", "ACAI" -> mesma chave.
    /// Isso evita duplicatas "disfarçadas" por acentuação ou caixa.
    var comparisonKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 O `Decision`, `DecisionError` e as regras NÃO dependem de UIKit, então podem ser reutilizados
 praticamente iguais em um app SwiftUI. A diferença está em como a UI observa e chama o modelo.

 // 1) Reuso direto do modelo (mesma lógica):
 // struct Decision { ... }  // igual ao atual
 // enum DecisionError { ... }

 // 2) Em SwiftUI, o estado exibido na tela costuma ficar em @State (View) ou em um
 //    objeto observável (ViewModel). Como Decision é struct (value type), é comum manter
 //    em @State na própria View:

 import SwiftUI

 struct DecisionCreateView: View {
     // Estado da tela: cada mudança atualiza a UI automaticamente.
     @State private var decision = Decision()
     @State private var newOptionText = ""
     @State private var errorMessage: String?

     var body: some View {
         Form {
             TextField("Pergunta", text: $decision.question) // binding direto

             Section("Opções") {
                 ForEach(decision.options, id: \.self) { option in
                     Text(option)
                 }
             }

             HStack {
                 TextField("Nova alternativa", text: $newOptionText)
                 Button("Adicionar") {
                     do {
                         try decision.addOption(newOptionText) // mesma regra do Model
                         newOptionText = ""
                     } catch let error as DecisionError {
                         errorMessage = error.userMessage
                     } catch { errorMessage = "Erro ao adicionar." }
                 }
             }

             Button("Sortear") { /* gerar plano e navegar */ }
                 .disabled(!decision.canDraw) // usa canDraw do Model
         }
         .alert("Erro", isPresented: .constant(errorMessage != nil)) {
             Button("OK") { errorMessage = nil }
         } message: { Text(errorMessage ?? "") }
     }
 }

 Observação: em arquiteturas SwiftUI mais elaboradas, poderíamos mover `decision` para um
 @Observable/@StateObject, mas as regras de validação continuam no mesmo `Decision`.
*/
