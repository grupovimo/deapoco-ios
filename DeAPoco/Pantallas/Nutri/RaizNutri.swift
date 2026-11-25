import SwiftUI

enum PestanaNutri: String, CaseIterable, Hashable {
    case hoy, agenda, pacientes, cobros
}

/// A dónde se navega dentro de una pestaña.
enum DestinoNutri: Hashable {
    case ficha(String)
    case medidas(String)
    case chat(String)
    case mensajes, avisos, perfil, ajustes, suscripcion, precios, asiTeVen
}

/// Hojas (sheets) del lado de la nutri.
enum HojaNutri: Identifiable, Hashable {
    case darTurno(paciente: String?, fecha: String?, hora: String?)
    case turno(String)
    case cobrar(String?)
    case linkPago(String)
    case nuevoPaciente
    case anotarMedidas(String)
    case elegirPlanDAP
    case tope(String)
    case qr
    case editarPerfil
    case mensajeVarios
    case elegirPaciente(AccionRapida)

    var id: String {
        switch self {
        case .darTurno(let p, let f, let h): return "turno-\(p ?? "")-\(f ?? "")-\(h ?? "")"
        case .turno(let t): return "ver-\(t)"
        case .cobrar(let p): return "cobrar-\(p ?? "")"
        case .linkPago(let c): return "link-\(c)"
        case .nuevoPaciente: return "nuevo"
        case .anotarMedidas(let p): return "medidas-\(p)"
        case .elegirPlanDAP: return "elegir-plan"
        case .tope(let n): return "tope-\(n)"
        case .qr: return "qr"
        case .editarPerfil: return "editar-perfil"
        case .mensajeVarios: return "mensaje-varios"
        case .elegirPaciente(let a): return "elegir-\(a.rawValue)"
        }
    }
}

/// Lo que se abre a pantalla completa.
enum CubiertaNutri: Identifiable, Hashable {
    case revisar
    case armarPlan(paciente: String, modelo: String?)
    var id: String {
        switch self {
        case .revisar: return "revisar"
        case .armarPlan(let p, let m): return "plan-\(p)-\(m ?? "")"
        }
    }
}

/// Las acciones del plato del centro.
enum AccionRapida: String, Hashable {
    case turno, cobrar, paciente, plan, medidas, mensaje
}

/// Navegación del lado de la nutri: pestaña, pilas de cada pestaña, hojas, cubiertas y el menú del plato.
@MainActor
@Observable
final class NavNutri {
    var pestana: PestanaNutri = .hoy
    var hoy: [DestinoNutri] = []
    var agenda: [DestinoNutri] = []
    var pacientes: [DestinoNutri] = []
    var cobros: [DestinoNutri] = []
    var hoja: HojaNutri?
    var cubierta: CubiertaNutri?
    var menuAbierto = false

    func ir(_ p: PestanaNutri) {
        withAnimation(.spring(duration: 0.3)) { menuAbierto = false }
        pestana = p
    }

    /// Empuja un destino en la pestaña actual.
    func abrir(_ d: DestinoNutri) {
        switch pestana {
        case .hoy: hoy.append(d)
        case .agenda: agenda.append(d)
        case .pacientes: pacientes.append(d)
        case .cobros: cobros.append(d)
        }
    }

    func abrirFicha(_ id: String) {
        pestana = .pacientes
        pacientes = [.ficha(id)]
    }

    func volverARaiz(_ p: PestanaNutri) {
        switch p {
        case .hoy: hoy = []
        case .agenda: agenda = []
        case .pacientes: pacientes = []
        case .cobros: cobros = []
        }
    }

    var pilaActual: [DestinoNutri] {
        switch pestana { case .hoy: return hoy; case .agenda: return agenda; case .pacientes: return pacientes; case .cobros: return cobros }
    }

    /// Las pantallas con su propia caja de abajo (chat, medidas…) esconden la barra.
    var barraVisible: Bool {
        guard let ultimo = pilaActual.last else { return true }
        switch ultimo {
        case .ficha, .mensajes, .avisos: return true
        default: return false
        }
    }
}

struct RaizNutri: View {
    var pantalla: String?
    @Environment(Estado.self) private var estado
    @State private var nav = NavNutri()

    var body: some View {
        @Bindable var nav = nav
        ZStack(alignment: .bottom) {
            pilas
                .blur(radius: nav.menuAbierto ? 7 : 0)
                .allowsHitTesting(!nav.menuAbierto)

            if nav.menuAbierto {
                Color.enlozado950.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { nav.menuAbierto = false } }
                    .transition(.opacity)
                    .accessibilityHidden(true)
                MenuRapido()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 110 - 34)
                    .transition(.scale(scale: 0.94, anchor: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }

            if nav.barraVisible || nav.menuAbierto {
                BarraMesa(izquierda: [ItemMesa(id: PestanaNutri.hoy, titulo: "Hoy", icono: .inicio),
                                      ItemMesa(id: PestanaNutri.agenda, titulo: "Agenda", icono: .turno)],
                          derecha: [ItemMesa(id: PestanaNutri.pacientes, titulo: "Pacientes", icono: .gente),
                                    ItemMesa(id: PestanaNutri.cobros, titulo: "Cobros", icono: .pago)],
                          elegida: Binding(get: { nav.pestana }, set: { nav.ir($0) }),
                          iconoPlato: .mas, etiquetaPlato: "Acción rápida", cerrar: nav.menuAbierto,
                          alTocarPlato: { withAnimation(.spring(duration: 0.35, bounce: 0.2)) { nav.menuAbierto.toggle() } },
                          alTocarActual: { p in withAnimation { nav.volverARaiz(p) } })
                    .transition(.move(edge: .bottom))
                    .zIndex(3)
            }
        }
        .animation(.snappy(duration: 0.25), value: nav.barraVisible)
        .environment(nav)
        .sheet(item: $nav.hoja) { h in hoja(h).environment(nav) }
        .fullScreenCover(item: $nav.cubierta) { c in cubierta(c).environment(estado).environment(nav) }
        .onAppear { aplicar(pantalla) }
    }

    @ViewBuilder private var pilas: some View {
        @Bindable var nav = nav
        switch nav.pestana {
        case .hoy: NavigationStack(path: $nav.hoy) { InicioNutri().destinosNutri() }
        case .agenda: NavigationStack(path: $nav.agenda) { AgendaNutri().destinosNutri() }
        case .pacientes: NavigationStack(path: $nav.pacientes) { ListaPacientes().destinosNutri() }
        case .cobros: NavigationStack(path: $nav.cobros) { CobrosNutri().destinosNutri() }
        }
    }

    @ViewBuilder private func hoja(_ h: HojaNutri) -> some View {
        switch h {
        case .darTurno(let p, let f, let hr): HojaDarTurno(pacienteId: p, fecha: f, hora: hr)
        case .turno(let id): HojaTurno(turnoId: id)
        case .cobrar(let p): HojaCobrar(pacienteId: p)
        case .linkPago(let c): HojaLinkPago(cobroId: c)
        case .nuevoPaciente: HojaPacienteNuevo()
        case .anotarMedidas(let p): HojaAnotarMedidas(pacienteId: p)
        case .elegirPlanDAP: ElegirPlanDAP()
        case .tope(let n): HojaTope(nombre: n)
        case .qr: HojaQR()
        case .editarPerfil: EditarPerfilNutri()
        case .mensajeVarios: HojaMensajeVarios()
        case .elegirPaciente(let a): HojaElegirPaciente(accion: a)
        }
    }

    @ViewBuilder private func cubierta(_ c: CubiertaNutri) -> some View {
        switch c {
        case .revisar: RevisarComidas()
        case .armarPlan(let p, let m): ArmarPlan(pacienteId: p, modeloId: m)
        }
    }

    /// `-pantalla n-xxx` abre directo una pantalla (capturas y pruebas).
    private func aplicar(_ p: String?) {
        guard let p else { return }
        switch p {
        case "n-inicio", "n-carga": nav.pestana = .hoy
        case "n-agenda": nav.pestana = .agenda
        case "n-pacientes": nav.pestana = .pacientes
        case "n-cobros": nav.pestana = .cobros
        case "n-menu": nav.pestana = .hoy; nav.menuAbierto = true
        case "n-ficha": nav.abrirFicha("sofia")
        case "n-ficha-comidas": nav.abrirFicha("sofia"); FichaPaciente.pestanaInicial = .comidas
        case "n-ficha-pagos": nav.abrirFicha("sofia"); FichaPaciente.pestanaInicial = .pagos
        case "n-ficha-notas": nav.abrirFicha("sofia"); FichaPaciente.pestanaInicial = .notas
        case "n-ficha-vacia": nav.abrirFicha("julian")
        case "n-medidas": nav.pestana = .pacientes; nav.pacientes = [.ficha("sofia"), .medidas("sofia")]
        case "n-anotar-medidas": nav.pestana = .pacientes; nav.pacientes = [.ficha("sofia"), .medidas("sofia")]; nav.hoja = .anotarMedidas("sofia")
        case "n-plan": nav.abrirFicha("sofia"); nav.cubierta = .armarPlan(paciente: "sofia", modelo: nil)
        case "n-revisar": RevisarComidas.empezarEn = 1; nav.cubierta = .revisar
        case "n-chat": nav.pestana = .hoy; nav.hoy = [.mensajes, .chat("sofia")]
        case "n-mensajes": nav.pestana = .hoy; nav.hoy = [.mensajes]
        case "n-avisos": nav.pestana = .hoy; nav.hoy = [.avisos]
        case "n-perfil": nav.pestana = .hoy; nav.hoy = [.perfil]
        case "n-editar-perfil": nav.pestana = .hoy; nav.hoy = [.perfil]; nav.hoja = .editarPerfil
        case "n-asi-te-ven": nav.pestana = .hoy; nav.hoy = [.perfil, .asiTeVen]
        case "n-qr": nav.pestana = .hoy; nav.hoy = [.perfil]; nav.hoja = .qr
        case "n-ajustes": nav.pestana = .hoy; nav.hoy = [.ajustes]
        case "n-suscripcion": nav.pestana = .hoy; nav.hoy = [.ajustes, .suscripcion]
        case "n-suscripcion-gratis": estado.vencerPrueba(); nav.pestana = .hoy; nav.hoy = [.ajustes, .suscripcion]
        case "n-elegir-plan": nav.pestana = .hoy; nav.hoy = [.ajustes, .suscripcion]; nav.hoja = .elegirPlanDAP
        case "n-compra": nav.pestana = .hoy; nav.hoy = [.ajustes, .suscripcion]; ElegirPlanDAP.abrirCompra = true; nav.hoja = .elegirPlanDAP
        case "n-tope": estado.vencerPrueba(); nav.pestana = .pacientes; nav.hoja = .tope("Julieta Paz")
        case "n-precios": nav.pestana = .cobros; nav.cobros = [.precios]
        case "n-cobrar": nav.pestana = .cobros; nav.hoja = .cobrar("julian")
        case "n-link-pago": nav.pestana = .cobros; nav.hoja = .linkPago("co-rocio")
        case "n-dar-turno": nav.pestana = .agenda; nav.hoja = .darTurno(paciente: nil, fecha: "2026-11-27", hora: nil)
        case "n-turno": nav.pestana = .agenda; nav.hoja = .turno("t-rocio")
        case "n-nuevo-paciente": nav.pestana = .pacientes; nav.hoja = .nuevoPaciente
        default: break
        }
    }
}

private struct DestinosNutri: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: DestinoNutri.self) { d in
            switch d {
            case .ficha(let id): FichaPaciente(pacienteId: id)
            case .medidas(let id): MedidasPaciente(pacienteId: id)
            case .chat(let id): ChatNutri(pacienteId: id)
            case .mensajes: BandejaMensajes()
            case .avisos: AvisosNutri()
            case .perfil: PerfilProfesional()
            case .ajustes: AjustesNutri()
            case .suscripcion: TuPlanDAP()
            case .precios: EditarPrecios()
            case .asiTeVen: AsiTeVen()
            }
        }
    }
}

extension View {
    func destinosNutri() -> some View { modifier(DestinosNutri()) }
}

/// Esqueleto de una pantalla de la nutri con banda: la banda arriba, el cuerpo con margen 20 y aire para la barra.
struct PantallaBandaN<BandaC: View, Cuerpo: View>: View {
    var abajoBanda: CGFloat = 20
    var arribaCuerpo: CGFloat = 16
    @ViewBuilder var banda: () -> BandaC
    @ViewBuilder var cuerpo: () -> Cuerpo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Banda(abajo: abajoBanda) { banda() }
                VStack(alignment: .leading, spacing: 12) { cuerpo() }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, arribaCuerpo)
                    .padding(.bottom, Espacio.bajoBarra)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.fondo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .barraClara()
    }
}

/// Esqueleto de una pantalla sobre manteca (sin banda): navegación propia, título y cuerpo.
struct PantallaClaraN<Cuerpo: View>: View {
    var abajo: CGFloat = Espacio.bajoBarra
    @ViewBuilder var cuerpo: () -> Cuerpo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) { cuerpo() }
                .padding(.bottom, abajo)
        }
        .scrollIndicators(.hidden)
        .background(Color.fondo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .barraClara(false)
    }
}
