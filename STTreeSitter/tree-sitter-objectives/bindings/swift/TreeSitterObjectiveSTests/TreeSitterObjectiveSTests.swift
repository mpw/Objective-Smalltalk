import XCTest
import SwiftTreeSitter
import TreeSitterObjectives

final class TreeSitterObjectivesTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_objectives())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Objective-S grammar")
    }
}
