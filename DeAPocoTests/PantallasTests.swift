import SwiftUI
import XCTest
@testable import DeAPoco

@MainActor
final class BaseTests: XCTestCase {
    func testFuentes() {
        XCTAssertTrue(Estilo.titulo(32).uiFont().fontName.hasPrefix("Fraunces"), Estilo.titulo(32).uiFont().fontName)
        XCTAssertTrue(Estilo.texto(15, 600).uiFont().fontName.hasPrefix("HankenGrotesk"), Estilo.texto(15, 600).uiFont().fontName)
    }
}
