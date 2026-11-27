import SwiftUI
import XCTest
@testable import DeAPoco

/// Humo de lo común: monta cada pantalla con DatosDeMuestra en una ventana de verdad y la dibuja. Si algo se cae al
/// abrirla (como el `async let` que cerraba Tu Local Web en Release), salta acá. Corre también en Release:
/// `xcodebuild test -configuration Release ENABLE_TESTABILITY=YES …`.
@MainActor
final class BaseTests: XCTestCase {
    private var ventana: UIWindow?

    override func tearDown() {
        ventana?.isHidden = true
        ventana = nil
    }

    func montar<V: View>(_ vista: V, segundos: Double = 0.4, oscuro: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        let raiz = vista.environment(Estado()).preferredColorScheme(oscuro ? .dark : .light)
        let escena = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let v = escena.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        let host = UIHostingController(rootView: raiz)
        v.rootViewController = host
        v.makeKeyAndVisible()
        ventana = v
        RunLoop.main.run(until: Date().addingTimeInterval(segundos))
        host.view.layoutIfNeeded()
        XCTAssertGreaterThan(host.view.bounds.width, 0, file: file, line: line)
        XCTAssertNotNil(ImageRenderer(content: raiz.frame(width: 390, height: 844)).uiImage, file: file, line: line)
    }

    func testFuentes() {
        XCTAssertTrue(Estilo.titulo(32).uiFont().fontName.hasPrefix("Nunito-"), Estilo.titulo(32).uiFont().fontName)
        XCTAssertTrue(Estilo.texto(15, 600).uiFont().fontName.hasPrefix("NunitoSans"), Estilo.texto(15, 600).uiFont().fontName)
        // Peso variable aplicado: 700 más ancho que 400.
        let a = ("Hoy atendés" as NSString).size(withAttributes: [.font: Estilo.texto(15, 400).uiFont()]).width
        let b = ("Hoy atendés" as NSString).size(withAttributes: [.font: Estilo.texto(15, 700).uiFont()]).width
        XCTAssertGreaterThan(b, a)
    }

    func testOnboardingNutri() {
        for i in 0..<PasoOnboarding.pasos(.nutri).count {
            montar(Onboarding(lado: .nutri, paso: i, perfil: i == 0 ? nil : DatosDeMuestra.perfilNutri) { _ in }, segundos: 0.2)
        }
    }
    func testOnboardingPaciente() {
        for i in 0..<PasoOnboarding.pasos(.paciente).count {
            montar(Onboarding(lado: .paciente, paso: i, perfil: i == 0 ? nil : DatosDeMuestra.perfilPaciente) { _ in }, segundos: 0.2)
        }
    }
    func testOnboardingOscuro() { montar(Onboarding(lado: .paciente, paso: 1, perfil: DatosDeMuestra.perfilPaciente) { _ in }, oscuro: true) }
    func testCarga() { montar(CargaInicial(tip: DatosDeMuestra.tipsPaciente[0])) }
    func testCuenta() { montar(ScrollView { SeccionCuenta() }) }
    func testBanner() { montar(ScrollView { BannerGrupo(.movimiento, titulo: "¿Querés sumar movimiento?", texto: "Entrená con un profe.") }) }

    func testPerfilSeGuarda() {
        let d = UserDefaults(suiteName: "prueba-perfil")!
        DatosDeMuestra.perfilPaciente.guardar(d)
        XCTAssertEqual(Perfil.guardado(d), DatosDeMuestra.perfilPaciente)
        Perfil.borrar(d)
        XCTAssertNil(Perfil.guardado(d))
    }

    func testIconos() {
        for i in Icono.allCases { XCTAssertNotNil(ImageRenderer(content: IconoVista(i).foregroundStyle(.black)).uiImage, "\(i)") }
    }

    func testFormato() {
        XCTAssertEqual(Formato.plata(1_284_000), "$1.284.000")
        XCTAssertEqual(Formato.decimal(89.2), "89,2")
        XCTAssertEqual(Fecha.larga("2026-11-24"), "Martes 24 de noviembre")
        XCTAssertEqual(Formato.lista(["Sofía", "Ana", "Carla"]), "Sofía, Ana y Carla")
    }
}
