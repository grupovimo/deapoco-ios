import SwiftUI
import XCTest
@testable import DeAPoco

/// Humo del lado del paciente: monta cada pantalla con DatosDeMuestra en una ventana de verdad y la dibuja.
/// Corre también en Release (`-configuration Release ENABLE_TESTABILITY=YES`).
@MainActor
final class PacienteTests: XCTestCase {
    private var ventana: UIWindow?

    override func tearDown() {
        ventana?.isHidden = true
        ventana = nil
    }

    private func montar<V: View>(_ vista: V, segundos: Double = 0.4, oscuro: Bool = false, preparar: (Estado) -> Void = { _ in },
                                 file: StaticString = #filePath, line: UInt = #line) {
        let estado = Estado()
        preparar(estado)
        let raiz = vista
            .environment(estado)
            .environment(NavPaciente())
            .preferredColorScheme(oscuro ? .dark : .light)
        let escena = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let v = escena.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        let host = UIHostingController(rootView: raiz)
        v.rootViewController = host
        v.makeKeyAndVisible()
        ventana = v
        RunLoop.main.run(until: Date().addingTimeInterval(segundos))
        host.view.layoutIfNeeded()
        XCTAssertGreaterThan(host.view.bounds.width, 0, file: file, line: line)
        let r = ImageRenderer(content: raiz.frame(width: 390, height: 844))
        r.scale = 1
        XCTAssertNotNil(r.uiImage, "No se pudo dibujar la pantalla", file: file, line: line)
    }

    func testRaiz() {
        for p in ["p-hoy", "p-plan", "p-avance", "p-mensajes", "p-semana", "p-logros", "p-turno", "p-perfil"] {
            montar(RaizPaciente(pantalla: p), segundos: 0.3)
        }
    }
    func testHoy() { montar(NavigationStack { HoyPaciente() }) }
    func testHoyOscuro() { montar(NavigationStack { HoyPaciente() }, oscuro: true) }
    func testHoyVacio() { montar(NavigationStack { HoyPaciente() }, preparar: { $0.paciente.registros = []; $0.paciente.turno = nil }) }
    func testFoto() { montar(RegistrarComida(momento: .almuerzo, conMuestra: true)) }
    func testFotoSinFoto() { montar(RegistrarComida(momento: .merienda)) }
    func testPlan() { montar(NavigationStack { PlanPaciente() }) }
    func testCompras() { montar(NavigationStack { ListaCompras() }) }
    func testAvance() { montar(NavigationStack { AvancePaciente() }) }
    func testAvanceSinSalud() { montar(NavigationStack { AvancePaciente() }, preparar: { $0.paciente.saludConectada = false; $0.paciente.mediciones = [] }) }
    func testSemana() { montar(NavigationStack { TuSemana() }) }
    func testLogros() { montar(NavigationStack { TusLogros() }) }
    func testFiesta() { montar(Celebracion(semana: true)); montar(Celebracion(semana: false)) }
    func testResumen() { montar(NavigationStack { ResumenCompartir() }) }
    func testTarjetaSemanaSeDibuja() {
        let r = ImageRenderer(content: TarjetaSemana(racha: 12, fotos: 21, paraImagen: true))
        r.scale = 2
        XCTAssertEqual(r.uiImage?.size.width ?? 0, 262, accuracy: 2)
    }
    func testChat() { montar(ChatPaciente()) }
    func testChatVacio() { montar(ChatPaciente(), preparar: { $0.paciente.mensajes = [] }) }
    func testTurno() { montar(NavigationStack { TurnoYPago() }) }
    func testSinTurno() { montar(NavigationStack { TurnoYPago() }, preparar: { $0.paciente.turno = nil }) }
    func testSacarTurno() { montar(HojaSacarTurno(cambiar: false)) }
    func testPagoMP() { montar(HojaPagoMP(servicioId: "plan3")) }
    func testPerfil() { montar(NavigationStack { PerfilPaciente() }) }
    func testPagos() { montar(NavigationStack { PagosPaciente() }) }
    func testAvisos() { montar(NavigationStack { AvisosPaciente() }) }
    func testSalud() { montar(NavigationStack { SaludPaciente() }) }
    func testPrivacidad() { montar(NavigationStack { PrivacidadPaciente() }) }
    func testTusDatos() { montar(NavigationStack { TusDatos() }) }
    func testHistorial() { montar(NavigationStack { HistorialComidas() }) }
    func testRegistro() { montar(DetalleRegistro(registroId: "p-alm")); montar(DetalleRegistro(registroId: "nada")) }

    // MARK: Lógica

    func testRegistrarComidaSumaAlPlato() {
        let e = Estado()
        XCTAssertEqual(e.comidasHechasHoy, 2)
        XCTAssertEqual(e.proximaComida, .merienda)
        XCTAssertEqual(e.fraseDelDia, "Sacale una foto a la merienda. Con eso alcanza.")
        let antes = e.paciente.mensajes.count
        e.registrarComida(momento: .merienda, foto: UIImage(named: "taza")?.jpegData(compressionQuality: 0.5), sensacion: .bien, nota: "")
        XCTAssertEqual(e.comidasHechasHoy, 3)
        XCTAssertEqual(e.proximaComida, .cena)
        XCTAssertEqual(e.paciente.mensajes.count, antes + 1, "la foto le llega a la nutri")
        e.registrarComida(momento: .cena, foto: nil, sensacion: .lleno, nota: "Guiso")
        XCTAssertEqual(e.comidasHechasHoy, 4)
        XCTAssertNil(e.proximaComida)
        XCTAssertEqual(e.semanaPaciente.first { $0.esHoy }?.llenas, 4)
    }

    func testAgua() {
        let e = Estado()
        XCTAssertEqual(e.paciente.agua, 5)
        e.tomarAgua(3)
        XCTAssertEqual(e.paciente.agua, 8)
        e.tomarAgua(-10)
        XCTAssertEqual(e.paciente.agua, 0)
    }

    func testPagarPlan() {
        let e = Estado()
        XCTAssertNil(e.pagoDeHoy)
        e.pagar(servicioId: "plan3")
        XCTAssertEqual(e.paciente.contratado, "plan3")
        XCTAssertEqual(e.pagoDeHoy?.monto, 45_000)
        let f = Estado()
        f.pagar(servicioId: "control")
        XCTAssertNil(f.paciente.contratado)
        XCTAssertEqual(f.pagoDeHoy?.monto, 48_000)
    }

    func testLogicaTurno() {
        let e = Estado()
        let dia = Fecha.diaLargo(e.paciente.hoy).capitalized
        XCTAssertEqual(e.fechaCabeceraHoy, "\(dia) 25 · turno el \(Fecha.diaLargo("2026-11-27")) 11:30")
        XCTAssertEqual(e.diasParaTurno.count, 10)
        XCTAssertTrue(e.diasParaTurno.allSatisfy { Fecha.diaSemana($0) <= 5 })
        XCTAssertFalse(e.horariosLibres("2026-12-01").isEmpty)
        e.cambiarTurnoPaciente(fecha: "2026-12-01", hora: "10:00")
        XCTAssertEqual(e.paciente.turno?.fecha, "2026-12-01")
        e.cancelarTurnoPaciente()
        XCTAssertNil(e.paciente.turno)
        XCTAssertEqual(e.fechaCabeceraHoy, "\(dia) 25")
        e.sacarTurnoPaciente(fecha: "2026-12-02", hora: "16:30", modalidad: .consultorio)
        XCTAssertEqual(e.paciente.turno?.modalidad, .consultorio)
    }

    func testSemanaYCompras() {
        let e = Estado()
        XCTAssertTrue(e.textoSemanaPaciente.hasPrefix("Del "))
        XCTAssertEqual(e.semanaPaciente.count, 7)
        XCTAssertEqual(e.semanaPaciente.first { $0.esHoy }?.llenas, 2)
        XCTAssertEqual(e.semanaPaciente.first { $0.fecha == Fecha.sumar(-1, a: e.paciente.hoy) }?.llenas ?? 4, 4)
        XCTAssertEqual(e.semanaPaciente.filter(\.futuro).count, 7 - Fecha.diaSemana(e.paciente.hoy))
        XCTAssertTrue(e.listaCompras.contains("Guiso de lentejas"))
        XCTAssertEqual(Set(e.listaCompras.map { $0.lowercased() }).count, e.listaCompras.count, "sin repetidos")
        XCTAssertEqual(e.paciente.dias14.count, 14)
        XCTAssertEqual(e.logrosConseguidos.count, 6)
        XCTAssertEqual(e.paciente.logros.count, 14)
    }

    func testMensajes() {
        let e = Estado()
        XCTAssertEqual(e.noLeidosPaciente, 1)
        e.leerMensajesPaciente()
        XCTAssertEqual(e.noLeidosPaciente, 0)
        e.enviarMensajePaciente(texto: "¡Gracias!")
        XCTAssertEqual(e.paciente.mensajes.last?.texto, "¡Gracias!")
        XCTAssertFalse(e.paciente.mensajes.last?.deNutri ?? true)
    }
}
