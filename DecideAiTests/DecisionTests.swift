//
//  DecisionTests.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import XCTest
@testable import DecideAi

final class DecisionTests: XCTestCase {

    func testAddOptionTrimsSpaces() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("  Pizza  ")
        XCTAssertEqual(decision.options, ["Pizza"])
    }

    func testAddOptionRejectsEmptyAndWhitespace() {
        var decision = Decision(question: "O que comer?")
        XCTAssertThrowsError(try decision.addOption("")) {
            XCTAssertEqual($0 as? DecisionError, .emptyOption)
        }
        XCTAssertThrowsError(try decision.addOption("   ")) {
            XCTAssertEqual($0 as? DecisionError, .emptyOption)
        }
    }

    func testAddOptionRejectsDuplicatesIgnoringCaseAndAccents() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("Açaí")
        XCTAssertThrowsError(try decision.addOption(" acai ")) {
            XCTAssertEqual($0 as? DecisionError, .duplicateOption)
        }
        XCTAssertEqual(decision.options.count, 1)
    }

    func testAddOptionRejectsTooLongText() {
        var decision = Decision(question: "O que comer?")
        let tooLong = String(repeating: "a", count: Decision.maxOptionLength + 1)
        XCTAssertThrowsError(try decision.addOption(tooLong)) {
            XCTAssertEqual($0 as? DecisionError, .optionTooLong)
        }
    }

    func testAddOptionRejectsMoreThanMaximum() throws {
        var decision = Decision(question: "O que comer?")
        for number in 1...Decision.maxOptions {
            try decision.addOption("Opção \(number)")
        }
        XCTAssertThrowsError(try decision.addOption("Opção extra")) {
            XCTAssertEqual($0 as? DecisionError, .tooManyOptions)
        }
    }

    func testUpdateOptionChangesTextAndAllowsSameValue() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("Pizza")
        try decision.addOption("Sushi")

        try decision.updateOption(at: 0, to: "pizza")   // própria opção, não é duplicata
        XCTAssertEqual(decision.options[0], "pizza")

        XCTAssertThrowsError(try decision.updateOption(at: 0, to: "Sushi")) {
            XCTAssertEqual($0 as? DecisionError, .duplicateOption)
        }
    }

    func testRemoveOption() throws {
        var decision = Decision(question: "O que comer?")
        try decision.addOption("Pizza")
        try decision.addOption("Sushi")
        decision.removeOption(at: 0)
        XCTAssertEqual(decision.options, ["Sushi"])
    }

    func testCanDrawNeedsAtLeastTwoOptions() throws {
        var decision = Decision(question: "O que comer?")
        XCTAssertFalse(decision.canDraw)
        try decision.addOption("Pizza")
        XCTAssertFalse(decision.canDraw)
        try decision.addOption("Sushi")
        XCTAssertTrue(decision.canDraw)
    }

    func testValidateRequiresQuestionAndTwoOptions() throws {
        var decision = Decision(question: "   ")
        try decision.addOption("Pizza")
        try decision.addOption("Sushi")
        XCTAssertThrowsError(try decision.validate()) {
            XCTAssertEqual($0 as? DecisionError, .emptyQuestion)
        }

        decision.question = "O que comer?"
        XCTAssertNoThrow(try decision.validate())

        decision.removeOption(at: 1)
        XCTAssertThrowsError(try decision.validate()) {
            XCTAssertEqual($0 as? DecisionError, .notEnoughOptions)
        }
    }
}
