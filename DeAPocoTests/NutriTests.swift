import SwiftUI
import XCTest
@testable import DeAPoco

/// Humo del lado de la nutri: monta cada pantalla con DatosDeMuestra en una ventana de verdad y la dibuja.
/// Corre también en Release (`-configuration Release ENABLE_TESTABILITY=YES`).
@MainActor
final class NutriTests: XCTestCase {
    private var ventana: UIWindow?

    override func tearDown() {
        ventana?.isHidden = true
        ventana = nil
    }

    private func montar<V: View>(_ vista: V, segundos: Double = 0.5, oscuro: Bool = false, preparar: (Estado) -> Void = { _ in },
                                 file: StaticString = #filePath, line: UInt = #line) {
        let estado = Estado()
        preparar(estado)
        let raiz = vista
            .environment(estado)
            .environment(NavNutri())
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

    // Pantallas
    func testRaiz() { montar(RaizNutri(pantalla: "n-inicio")) }
    func testRaizOscuro() { montar(RaizNutri(pantalla: "n-agenda"), oscuro: true) }
    func testMenu() { montar(RaizNutri(pantalla: "n-menu")) }
    func testInicio() { montar(NavigationStack { InicioNutri() }) }
    func testInicioSinPendientes() {
        montar(NavigationStack { InicioNutri() }, preparar: { e in
            for i in e.nutri.registros.indices { e.nutri.registros[i].revisada = true }
            for i in e.nutri.pacientes.indices { e.nutri.pacientes[i].sinAnotar = 0 }
            for i in e.nutri.turnos.indices { e.nutri.turnos[i].estado = .confirmado }
        })
    }
    func testAgenda() { montar(NavigationStack { AgendaNutri() }) }
    func testPacientes() { montar(NavigationStack { ListaPacientes() }) }
    func testFicha() { for p in PestanaFicha.allCases { FichaPaciente.pestanaInicial = p; montar(NavigationStack { FichaPaciente(pacienteId: "sofia") }, segundos: 0.3) } }
    func testFichaNueva() { montar(NavigationStack { FichaPaciente(pacienteId: "julian") }) }
    func testFichaInexistente() { montar(NavigationStack { FichaPaciente(pacienteId: "nadie") }) }
    func testMedidas() { montar(NavigationStack { MedidasPaciente(pacienteId: "sofia") }) }
    func testMedidasVacias() { montar(NavigationStack { MedidasPaciente(pacienteId: "julian") }) }
    func testAnotarMedidas() { montar(HojaAnotarMedidas(pacienteId: "sofia")) }
    func testArmarPlan() { montar(ArmarPlan(pacienteId: "sofia", modeloId: nil)) }
    func testArmarPlanDesdeModelo() { montar(ArmarPlan(pacienteId: "julian", modeloId: "m-veg")) }
    func testRevisar() { montar(RevisarComidas()) }
    func testRevisarVacio() { montar(RevisarComidas(), preparar: { e in for i in e.nutri.registros.indices { e.nutri.registros[i].revisada = true } }) }
    func testCobros() { montar(NavigationStack { CobrosNutri() }) }
    func testCobrar() { montar(HojaCobrar(pacienteId: "julian")) }
    func testLinkPago() { montar(HojaLinkPago(cobroId: "co-rocio")) }
    func testPrecios() { montar(NavigationStack { EditarPrecios() }) }
    func testDarTurno() { montar(HojaDarTurno(pacienteId: nil, fecha: Fecha.sumar(2, a: DatosDeMuestra.hoy), hora: nil)) }
    func testTurno() { montar(HojaTurno(turnoId: "t-rocio")) }
    func testTurnoInexistente() { montar(HojaTurno(turnoId: "nada")) }
    func testPacienteNuevo() { montar(HojaPacienteNuevo()) }
    func testElegirPaciente() { montar(HojaElegirPaciente(accion: .plan)) }
    func testMensajeVarios() { montar(HojaMensajeVarios()) }
    func testMensajes() { montar(NavigationStack { BandejaMensajes() }) }
    func testChat() { montar(NavigationStack { ChatNutri(pacienteId: "sofia") }) }
    func testChatVacio() { montar(NavigationStack { ChatNutri(pacienteId: "julian") }) }
    func testAvisos() { montar(NavigationStack { AvisosNutri() }) }
    func testPerfil() { montar(NavigationStack { PerfilProfesional() }) }
    func testAsiTeVen() { montar(NavigationStack { AsiTeVen() }) }
    func testQR() { montar(HojaQR()) }
    func testEditarPerfil() { montar(EditarPerfilNutri()) }
    func testAjustes() { montar(NavigationStack { AjustesNutri() }) }
    func testTuPlanPrueba() { montar(NavigationStack { TuPlanDAP() }) }
    func testTuPlanGratis() { montar(NavigationStack { TuPlanDAP() }, preparar: { $0.vencerPrueba() }) }
    func testTuPlanPago() { montar(NavigationStack { TuPlanDAP() }, preparar: { $0.vencerPrueba(); $0.comprar(.profesional, .anual) }) }
    func testElegirPlan() { montar(ElegirPlanDAP()) }
    func testCompra() { montar(CompraAppStore(plan: .profesional, periodo: .mensual)) }
    func testTope() { montar(HojaTope(nombre: "Julieta Paz"), preparar: { $0.vencerPrueba() }) }

    // Lógica
    func testCobrosDelMes() {
        let e = Estado()
        XCTAssertEqual(Formato.plata(e.cobradoMes), "$1.284.000")
        XCTAssertEqual(Formato.plata(e.faltaCobrar), "$336.000")
        XCTAssertEqual(Formato.plata(e.esperadoMes), "$1.620.000")
        XCTAssertEqual(e.porcentajeCobrado, 79)
        XCTAssertEqual(e.pagadosDelMes.count, 27)
        XCTAssertEqual(e.pagosPorMedio(.mercadoPago), 19)
        XCTAssertEqual(e.pagosPorMedio(.transferencia), 6)
        XCTAssertEqual(e.pagosPorMedio(.efectivo), 2)
        XCTAssertEqual(Set(e.porCobrar.map(\.pacienteId)).count, 7)
        e.registrarPago("co-julian", medio: .efectivo)
        XCTAssertEqual(Formato.plata(e.cobradoMes), "$1.349.000")
        XCTAssertEqual(e.pagosPorMedio(.efectivo), 3)
        XCTAssertEqual(e.turno("t-julian")?.pagado, true)
    }

    func testRitmo() {
        let e = Estado()
        XCTAssertEqual(e.pacientesActivos.count, 42)
        XCTAssertEqual(e.pacientes(.bien).count, 31)
        XCTAssertEqual(e.pacientes(.medias).count, 7)
        XCTAssertEqual(e.pacientes(.aflojo).count, 4)
        XCTAssertEqual(e.pacientes(.aflojo).first?.id, "martin")
    }

    func testHoy() {
        let e = Estado()
        XCTAssertEqual(e.tituloHoy, "Hoy atendés a\u{00A0}seis.")
        XCTAssertEqual(e.atendidosHoy, 2)
        XCTAssertEqual(e.proximoTurno?.pacienteId, "sofia")
        XCTAssertEqual(e.minutosHasta(e.proximoTurno!), 18)
        XCTAssertEqual(e.porRevisar.count, 5)
        XCTAssertEqual(e.quienesPorRevisar, ["Sofía", "Ana", "Carla"])
        XCTAssertEqual(e.sinConfirmar.first?.pacienteId, "rocio")
    }

    func testAgendaYTurnos() {
        let e = Estado()
        let jueves = Fecha.sumar(4 - Fecha.diaSemana(e.hoy), a: e.hoy)
        let domingo = Fecha.sumar(7 - Fecha.diaSemana(e.hoy), a: e.hoy)
        XCTAssertFalse(e.libres(en: jueves).isEmpty)
        XCTAssertTrue(e.libres(en: domingo).isEmpty, "domingo")
        let t = e.darTurno(pacienteId: "julian", fecha: jueves, hora: e.libres(en: jueves)[0], modalidad: .enLinea)
        XCTAssertEqual(e.proximoTurno(de: "julian")?.id, t.id)
        let viernes = Fecha.sumar(1, a: jueves)
        e.cambiarTurno(t.id, fecha: viernes, hora: "19:00")
        XCTAssertEqual(e.turno(t.id)?.fecha, viernes)
        e.cancelarTurno(t.id)
        XCTAssertNil(e.proximoTurno(de: "julian"))
        // Ocupar un hueco libre lo saca de la agenda.
        e.darTurno(pacienteId: "lucas", fecha: e.hoy, hora: "13:00", modalidad: .consultorio)
        XCTAssertFalse(e.turnosHoy.contains { $0.pacienteId == nil })
    }

    func testRevisarYPlan() {
        let e = Estado()
        e.revisar("r-sofia-alm", respuesta: "¡Bien ahí!", bienAhi: true)
        XCTAssertEqual(e.porRevisar.count, 4)
        XCTAssertEqual(e.chat("sofia").last?.texto, "¡Bien ahí!")
        let p = e.planNuevo(para: "julian", modelo: "m-veg")
        XCTAssertEqual(p.pacienteId, "julian")
        XCTAssertEqual(p.comidas.count, 3)
        e.guardarPlan(p)
        e.enviarPlan(p.id)
        XCTAssertEqual(e.plan(de: "julian")?.enviado, true)
        XCTAssertEqual(e.planNuevo(para: "sofia", modelo: nil).id, "plan-sofia-3", "sin modelo, abre el plan que ya tiene")
    }

    func testLogicaMedidas() {
        let e = Estado()
        XCTAssertEqual(e.diferencia(.cintura, de: "sofia") ?? 0, -6, accuracy: 0.01)
        XCTAssertEqual(e.etiquetasMeses(e.mediciones(de: "sofia")), ["AGO", "", "SEP", "", "", "OCT", "", "", "NOV", ""])
        e.cambiarMostrarPeso("sofia", true)
        XCTAssertTrue(e.paciente("sofia")!.mostrarPeso)
        e.anotarMedicion(Medicion(pacienteId: "julian", fecha: e.hoy, modalidad: .consultorio, cintura: 90))
        XCTAssertEqual(e.mediciones(de: "julian").count, 1)
    }

    func testSuscripcion() {
        let e = Estado()
        XCTAssertTrue(e.enPrueba)
        XCTAssertEqual(e.diasDePrueba, Fecha.dias(entre: e.hoy, y: e.suscripcion.pruebaHasta!))
        XCTAssertEqual(e.planActual, .profesional)
        XCTAssertEqual(e.planQueAlcanza, .profesional)
        XCTAssertEqual(PlanDAP.profesional.precioAnual, 149_000)
        e.comprar(.profesional, .mensual)
        XCTAssertEqual(e.suscripcion.planElegido, .profesional)
        XCTAssertEqual(e.suscripcion.proximoCobro, e.suscripcion.pruebaHasta)
        XCTAssertTrue(e.suscripcion.facturas.isEmpty)
        let f = Estado()
        f.vencerPrueba()
        XCTAssertEqual(f.planActual, .gratis)
        XCTAssertEqual(f.activos, 10)
        XCTAssertEqual(f.nutri.pacientes.count, 42, "nadie se borra")
        XCTAssertFalse(f.puedeSumarPaciente)
        XCTAssertNil(f.crearPaciente(nombre: "Julieta Paz", telefono: "", servicioId: "control", objetivo: ""))
        f.comprar(.profesional, .mensual)
        XCTAssertEqual(f.suscripcion.facturas.first?.monto, 14_900)
        XCTAssertEqual(f.activos, 42)
        XCTAssertNotNil(f.crearPaciente(nombre: "Julieta Paz", telefono: "+54 223 555-0000", servicioId: "control", objetivo: "Comer mejor"))
        XCTAssertEqual(f.activos, 43)
    }

    func testCodigoQR() { XCTAssertNotNil(QRCodigo.imagen(DatosDeMuestra.perfilLaura.link.absoluteString)) }
}
