//
//  Decision.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import Foundation

/// Everything that can go wrong while building or drawing a decision.
/// Each case has a friendly message ready to show in an alert.
enum DecisionError: Error, Equatable {
    case emptyQuestion
    case questionTooLong
    case emptyOption
    case optionTooLong
    case duplicateOption
    case tooManyOptions
    case optionNotFound
    case notEnoughOptions

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

/// A question plus the options to choose from.
/// It is a struct (value type): copying a Decision gives an independent copy,
/// which is exactly what we want when "Tentar novamente" reuses the same options.
struct Decision {

    static let minOptions = 2
    static let maxOptions = 10
    static let maxOptionLength = 40
    static let maxQuestionLength = 80

    var question: String

    // private(set): quem está de fora pode ler, mas só muda as opções pelos
    // métodos abaixo, que sempre validam. Assim nunca existe opção inválida.
    private(set) var options: [String] = []

    init(question: String = "") {
        self.question = question
    }

    /// The question without leading/trailing spaces, ready to display.
    var displayQuestion: String { question.trimmed }

    /// Used to enable/disable the "Decide Aí" button.
    var canDraw: Bool { options.count >= Self.minOptions }

    // MARK: - Options

    mutating func addOption(_ text: String) throws {
        guard options.count < Self.maxOptions else { throw DecisionError.tooManyOptions }
        let clean = try validatedOption(text, ignoringIndex: nil)
        options.append(clean)
    }

    mutating func updateOption(at index: Int, to text: String) throws {
        guard options.indices.contains(index) else { throw DecisionError.optionNotFound }
        // ignoringIndex: editar "Pizza" para "pizza" não conta como duplicata de si mesma.
        let clean = try validatedOption(text, ignoringIndex: index)
        options[index] = clean
    }

    mutating func removeOption(at index: Int) {
        guard options.indices.contains(index) else { return }
        options.remove(at: index)
    }

    // MARK: - Validation

    /// Throws if the decision is not ready to be drawn.
    func validate() throws {
        let clean = question.trimmed
        guard !clean.isEmpty else { throw DecisionError.emptyQuestion }
        guard clean.count <= Self.maxQuestionLength else { throw DecisionError.questionTooLong }
        guard canDraw else { throw DecisionError.notEnoughOptions }
    }

    private func validatedOption(_ text: String, ignoringIndex: Int?) throws -> String {
        let clean = text.trimmed
        guard !clean.isEmpty else { throw DecisionError.emptyOption }
        guard clean.count <= Self.maxOptionLength else { throw DecisionError.optionTooLong }

        let key = clean.comparisonKey
        let isDuplicate = options.enumerated().contains { offset, existing in
            offset != ignoringIndex && existing.comparisonKey == key
        }
        guard !isDuplicate else { throw DecisionError.duplicateOption }

        return clean
    }
}

// fileprivate: só este arquivo usa estes helpers.
private extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// "Açaí", "acai" and "ACAI" produce the same key, so they count as duplicates.
    var comparisonKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
