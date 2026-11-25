import SwiftUI

enum PestanaPaciente: String, Hashable {
    case hoy, plan, avance, laura
}

enum DestinoPaciente: Hashable {
    case turno, semana, logros, resumen, perfil, pagos, avisos, salud, privacidad, tusDatos, compras, historial
}

enum HojaPaciente: Identifiable, Hashable {
    case turno(cambiar: Bool)
    case registro(String)
    case pagar(String)
    var id: String {
        switch self {
        case .turno(let c): return "turno-\(c)"
        case .registro(let r): return "registro-\(r)"
        case .pagar(let s): return "pagar-\(s)"
        }
    }
}

enum CubiertaPaciente: Identifiable, Hashable {
    case foto(Momento?, muestra: Bool)
    case fiesta(semana: Bool)
    var id: String {
        switch self {
        case .foto(let m, let s): return "foto-\(m?.rawValue ?? "")-\(s)"
        case .fiesta(let s): return "fiesta-\(s)"
        }
    }
}

/// Navegación del paciente: la pestaña, la pila de cada una, las hojas y las cubiertas (cámara, celebración).
@MainActor
@Observable
final class NavPaciente {
    var pestana: PestanaPaciente = .hoy
    /// La pestaña de la que se vino al chat (para volver con «‹»).
    var anterior: PestanaPaciente = .hoy
    var hoy: [DestinoPaciente] = []
    var plan: [DestinoPaciente] = []
    var avance: [DestinoPaciente] = []
    var hoja: HojaPaciente?
    var cubierta: CubiertaPaciente?
    /// Para abrir «Tu avance» desplazado hasta abajo (capturas).
    var avanceAbajo = false

    func ir(_ p: PestanaPaciente) {
        if p == .laura && pestana != .laura { anterior = pestana }
        pestana = p
    }

    func volverDelChat() { pestana = anterior == .laura ? .hoy : anterior }

    func empujar(_ d: DestinoPaciente) {
        switch pestana {
        case .hoy, .laura: if pestana == .laura { pestana = .hoy }; hoy.append(d)
        case .plan: plan.append(d)
        case .avance: avance.append(d)
        }
    }

    func volverARaiz(_ p: PestanaPaciente) {
        switch p {
        case .hoy: hoy = []
        case .plan: plan = []
        case .avance: avance = []
        case .laura: break
        }
    }

    /// La barra se ve en las raíces y en Tu semana y Logros (como en el diseño).
    var muestraBarra: Bool {
        let pila: [DestinoPaciente]
        switch pestana {
        case .hoy: pila = hoy
        case .plan: pila = plan
        case .avance: pila = avance
        case .laura: return false
        }
        guard let ultimo = pila.last else { return true }
        return ultimo == .semana || ultimo == .logros
    }
}

/// La app del paciente: Hoy · Plan · [foto] · Avance · Laura, con la barra «la mesa».
struct RaizPaciente: View {
    var pantalla: String?
    @Environment(Estado.self) private var estado
    @State private var nav = NavPaciente()

    var body: some View {
        @Bindable var nav = nav
        ZStack(alignment: .bottom) {
            Group {
                switch nav.pestana {
                case .hoy: NavigationStack(path: $nav.hoy) { HoyPaciente().destinosPaciente() }
                case .plan: NavigationStack(path: $nav.plan) { PlanPaciente().destinosPaciente() }
                case .avance: NavigationStack(path: $nav.avance) { AvancePaciente().destinosPaciente() }
                case .laura: ChatPaciente()
                }
            }
            if nav.muestraBarra {
                BarraMesa(izquierda: [ItemMesa(id: PestanaPaciente.hoy, titulo: "Hoy", icono: .inicio),
                                      ItemMesa(id: .plan, titulo: "Plan", icono: .plan)],
                          derecha: [ItemMesa(id: .avance, titulo: "Avance", icono: .pesaje),
                                    ItemMesa(id: .laura, titulo: estado.paciente.nutri.nombre, icono: .mensaje, badge: estado.noLeidosPaciente)],
                          elegida: Binding(get: { nav.pestana }, set: { nav.ir($0) }),
                          iconoPlato: .foto, etiquetaPlato: "Sacar foto de la comida",
                          alTocarPlato: { nav.cubierta = .foto(estado.proximaComida, muestra: false) },
                          alTocarActual: { p in withAnimation { nav.volverARaiz(p) } })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: nav.muestraBarra)
        .background(Color.fondo.ignoresSafeArea())
        .environment(nav)
        .sheet(item: $nav.hoja) { h in
            switch h {
            case .turno(let c): HojaSacarTurno(cambiar: c)
            case .registro(let id): DetalleRegistro(registroId: id)
            case .pagar(let s): HojaPagoMP(servicioId: s)
            }
        }
        .fullScreenCover(item: $nav.cubierta) { c in
            Group {
                switch c {
                case .foto(let m, let muestra): RegistrarComida(momento: m ?? estado.proximaComida ?? .almuerzo, conMuestra: muestra)
                case .fiesta(let s): Celebracion(semana: s)
                }
            }
            .environment(estado)
            .environment(nav)
        }
        .onAppear { aplicar(pantalla) }
    }

    private func aplicar(_ p: String?) {
        guard let p else { return }
        switch p {
        case "p-plan": nav.pestana = .plan
        case "p-compras": nav.pestana = .plan; nav.plan = [.compras]
        case "p-avance": nav.pestana = .avance
        case "p-avance-abajo": nav.pestana = .avance; nav.avanceAbajo = true
        case "p-semana": nav.pestana = .avance; nav.avance = [.semana]
        case "p-logros": nav.pestana = .avance; nav.avance = [.logros]
        case "p-resumen": nav.pestana = .avance; nav.avance = [.resumen]
        case "p-celebracion": nav.pestana = .avance; nav.cubierta = .fiesta(semana: true)
        case "p-mensajes": nav.pestana = .laura
        case "p-foto": estado.paciente.registros.removeAll { $0.fecha == estado.paciente.hoy && $0.momento == .almuerzo }
            nav.cubierta = .foto(.almuerzo, muestra: true)
        case "p-turno": nav.hoy = [.turno]
        case "p-sacar-turno": nav.hoy = [.turno]; nav.hoja = .turno(cambiar: true)
        case "p-sin-turno": estado.paciente.turno = nil; nav.hoy = [.turno]
        case "p-pago-mp": nav.hoy = [.turno]; nav.hoja = .pagar("plan3")
        case "p-perfil": nav.hoy = [.perfil]
        case "p-pagos": nav.hoy = [.perfil, .pagos]
        case "p-avisos": nav.hoy = [.avisos]
        case "p-salud": nav.hoy = [.perfil, .salud]
        case "p-privacidad": nav.hoy = [.perfil, .privacidad]
        case "p-tus-datos": nav.hoy = [.perfil, .tusDatos]
        case "p-historial": nav.hoy = [.historial]
        case "p-registro": nav.hoja = .registro("p-alm")
        case "p-hoy-vacio":
            estado.paciente.registros.removeAll { $0.fecha == estado.paciente.hoy }
            estado.paciente.agua = 0
        default: break
        }
    }
}

private struct DestinosPaciente: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: DestinoPaciente.self) { d in
            Group {
                switch d {
                case .turno: TurnoYPago()
                case .semana: TuSemana()
                case .logros: TusLogros()
                case .resumen: ResumenCompartir()
                case .perfil: PerfilPaciente()
                case .pagos: PagosPaciente()
                case .avisos: AvisosPaciente()
                case .salud: SaludPaciente()
                case .privacidad: PrivacidadPaciente()
                case .tusDatos: TusDatos()
                case .compras: ListaCompras()
                case .historial: HistorialComidas()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

extension View {
    fileprivate func destinosPaciente() -> some View { modifier(DestinosPaciente()) }
}

/// Esqueleto de una pantalla del paciente: manteca, cuerpo con margen 20, aire para la barra.
struct PantallaPaciente<Arriba: View, Cuerpo: View>: View {
    var abajo: CGFloat = Espacio.bajoBarra
    @ViewBuilder var arriba: () -> Arriba
    @ViewBuilder var cuerpo: () -> Cuerpo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                arriba()
                VStack(alignment: .leading, spacing: 12) { cuerpo() }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 14)
                    .padding(.bottom, abajo)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.fondo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .barraClara(false)
    }
}
