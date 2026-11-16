//
//  DecisionTests.swift
//  DecideAiTests
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import XCTest
@testable import DecideAi

// MARK: - Testes do Model (Decision)

/// Testes unitários para a `struct Decision` e suas regras de negócio.
/// Objetivo: garantir que validações e operações (adicionar, editar, remover)
/// funcionem corretamente sem depender de UI.
///
/// `@testable import` permite acessar tipos internos do módulo do app nos testes.
final class DecisionTests: XCTestCase {

    /// Adicionar uma opção deve remover espaços extras nas extremidades (trim).
    func testAddOptionTrimsSpaces() throws {
        // Arrange: cria uma decisão com pergunta válida.
        var decision = Decision(question: "O que comer?")
        // Act: adiciona uma opção com espaços ao redor.
        try decision.addOption("  Pizza  ")
        // Assert: a opção armazenada deve estar sem espaços extras.
        XCTAssertEqual(decision.options, ["Pizza"])
    }

    /// Não deve permitir adicionar opções vazias ou compostas apenas por espaços.
    func testAddOptionRejectsEmptyAndWhitespace() {
        var decision = Decision(question: "O que comer?")

        // String vazia deve lançar erro .emptyOption.
        XCTAssertThrowsError(try decision.addOption("")) { error in
            XCTAssertEqual(error as? DecisionError, .emptyOption)
        }
        // Apenas espaços também deve lançar .emptyOption.
        XCTAssertThrowsError(try decision.addOption("   ")) { error in
            XCTAssertEqual(error as? DecisionError, .emptyOption)
        }
    }

    /// Duplicatas devem ser detectadas ignorando maiúsculas/minúsculas e acentos.
    func testAddOptionRejectsDuplicatesIgnoringCaseAndAccents() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("Açaí")

        // "acai" (sem acento e caixa diferente) deve ser considerada duplicata.
        XCTAssertThrowsError(try decision.addOption(" acai ")) { error in
            XCTAssertEqual(error as? DecisionError, .duplicateOption)
        }
        // Garante que a lista não foi alterada indevidamente.
        XCTAssertEqual(decision.options.count, 1)
    }

    /// Não deve permitir opção com tamanho acima do limite definido no Model.
    func testAddOptionRejectsTooLongText() {
        var decision = Decision(question: "O que comer?")
        // Cria uma string com (limite + 1) caracteres.
        let tooLong = String(repeating: "a", count: Decision.maxOptionLength + 1)

        XCTAssertThrowsError(try decision.addOption(tooLong)) { error in
            XCTAssertEqual(error as? DecisionError, .optionTooLong)
        }
    }

    /// Não deve permitir adicionar mais opções do que o máximo permitido.
    func testAddOptionRejectsMoreThanMaximum() throws {
        var decision = Decision(question: "O que comer?")
        // Preenche até o máximo permitido.
        for number in 1...Decision.maxOptions {
            try decision.addOption("Opção \(number)")
        }

        // Tentativa além do limite deve falhar com .tooManyOptions.
        XCTAssertThrowsError(try decision.addOption("Opção extra")) { error in
            XCTAssertEqual(error as? DecisionError, .tooManyOptions)
        }
    }

    /// Editar uma opção deve atualizar o texto, permitir variação da própria opção
    /// e impedir conflito com outras opções existentes.
    func testUpdateOptionChangesTextAndAllowsSameValue() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("Pizza")
        try decision.addOption("Sushi")

        // Alterar apenas a caixa da mesma opção é permitido (ignoringIndex).
        try decision.updateOption(at: 0, to: "pizza")
        XCTAssertEqual(decision.options[0], "pizza")

        // Alterar para texto que colide com outra opção deve falhar.
        XCTAssertThrowsError(try decision.updateOption(at: 0, to: "Sushi")) { error in
            XCTAssertEqual(error as? DecisionError, .duplicateOption)
        }
    }

    /// Remover uma opção deve tirá-la da lista e manter as demais.
    func testRemoveOption() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("Pizza")
        try decision.addOption("Sushi")

        decision.removeOption(at: 0)

        XCTAssertEqual(decision.options, ["Sushi"])
    }

    /// `canDraw` só deve ser verdadeiro quando houver pelo menos o mínimo de opções.
    func testCanDrawNeedsAtLeastTwoOptions() throws {
        var decision = Decision(question: "O que comer?")
        XCTAssertFalse(decision.canDraw)

        try decision.addOption("Pizza")
        XCTAssertFalse(decision.canDraw)

        try decision.addOption("Sushi")
        XCTAssertTrue(decision.canDraw)
    }

    /// `validate()` exige pergunta válida e pelo menos duas opções.
    func testValidateRequiresQuestionAndTwoOptions() throws {
        var decision = Decision(question: "   ") // pergunta inválida (só espaços)
        try decision.addOption("Pizza")
        try decision.addOption("Sushi")

        // Pergunta vazia deve falhar.
        XCTAssertThrowsError(try decision.validate()) { error in
            XCTAssertEqual(error as? DecisionError, .emptyQuestion)
        }

        // Com pergunta válida, deve passar.
        decision.question = "O que comer?"
        XCTAssertNoThrow(try decision.validate())

        // Com menos de duas opções, deve falhar.
        decision.removeOption(at: 1)
        XCTAssertThrowsError(try decision.validate()) { error in
            XCTAssertEqual(error as? DecisionError, .notEnoughOptions)
        }
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Estes testes validam o Model (`Decision`) e continuam IGUAIS em um projeto SwiftUI,
 pois o Model não depende de UIKit/SwiftUI. A camada de UI muda, mas as regras permanecem.

 // Exemplo equivalente usando o framework Swift Testing (alternativa moderna ao XCTest):
 //
 // import Testing
 // @testable import DecideAi
 //
 // @Suite("Decision")
 // struct DecisionSwiftTests {
 //     @Test func addOptionTrimsSpaces() throws {
 //         var decision = Decision(question: "O que comer?")
 //         try decision.addOption("  Pizza  ")
 //         #expect(decision.options == ["Pizza"])
 //     }
 // }
 //
 // Para UI em SwiftUI, usaríamos testes de UI (XCUITest) ou previews/testes específicos,
 // mas os testes de regra de negócio do Model continuam os mesmos.
*/
