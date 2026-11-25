import SwiftUI

@main
struct DeAPocoApp: App {
    @State private var estado: Estado
    @AppStorage("apariencia") private var apariencia = Apariencia.sistema.rawValue

    init() {
        // Con `-pantalla x` (capturas y pruebas) se abre directo esa pantalla, en su lado.
        if let p = Arranque.pantalla {
            if p == "onboarding" {
                Perfil.borrar()
                UserDefaults.standard.set("", forKey: "lado")
            } else if let l = Arranque.lado {
                (l == .nutri ? DatosDeMuestra.perfilNutri : DatosDeMuestra.perfilPaciente).guardar()
                UserDefaults.standard.set(l.rawValue, forKey: "lado")
            }
            // Las capturas arrancan siempre igual: sin promos cerradas.
            for promo in PromoGrupo.allCases { UserDefaults.standard.removeObject(forKey: "banner-\(promo.rawValue)") }
            UserDefaults.standard.set(Arranque.oscuro ? Apariencia.oscuro.rawValue : Apariencia.claro.rawValue, forKey: "apariencia")
        }
        // Después de acomodar el perfil: Estado lo lee al crearse.
        _estado = State(initialValue: Estado())
    }

    var body: some Scene {
        WindowGroup {
            Raiz()
                .environment(estado)
                .preferredColorScheme(Apariencia(rawValue: apariencia)?.esquema)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .tint(Color.marca)
                .task { await estado.cargar() }
        }
    }
}

/// Claro, oscuro o lo que diga el teléfono.
enum Apariencia: String, CaseIterable {
    case sistema, claro, oscuro
    var titulo: String { self == .sistema ? "Automático" : self == .claro ? "Claro" : "Oscuro" }
    var esquema: ColorScheme? { self == .sistema ? nil : self == .claro ? .light : .dark }
}

/// Sin perfil, el onboarding (que arranca eligiendo el lado). Con perfil, la app de ese lado, con una carga breve.
struct Raiz: View {
    @AppStorage("lado") private var ladoGuardado = ""
    @Environment(Estado.self) private var estado
    @State private var cargando: Bool

    init() {
        let p = Arranque.pantalla
        _cargando = State(initialValue: p == nil || p == "carga" || p == "n-carga")
    }

    private var lado: Lado? { Lado(rawValue: ladoGuardado) }

    var body: some View {
        ZStack(alignment: .top) {
            if estado.perfil == nil || lado == nil {
                Onboarding(lado: Arranque.ladoOnboarding, paso: Arranque.pasoOnboarding,
                           perfil: Arranque.pasoOnboarding > 0
                               ? (Arranque.ladoOnboarding == .nutri ? DatosDeMuestra.perfilNutri : DatosDeMuestra.perfilPaciente) : nil) { p in
                    estado.guardarPerfil(p)
                    withAnimation(.easeInOut(duration: 0.35)) { ladoGuardado = p.lado.rawValue }
                }
                .transition(.opacity)
            } else if lado == .paciente {
                RaizPaciente(pantalla: Arranque.pantalla).transition(.opacity)
            } else {
                RaizNutri(pantalla: Arranque.pantalla).transition(.opacity)
            }
            if cargando && estado.perfil != nil && lado != nil {
                CargaInicial(lado: lado ?? .paciente, tip: estado.tip(lado ?? .paciente),
                             foto: estado.paciente.nutri.foto, nutri: estado.paciente.nutri.nombre)
                    .transition(.opacity)
                    .zIndex(50)
                    .task {
                        guard Arranque.pantalla != "carga" && Arranque.pantalla != "n-carga" else { return }
                        try? await Task.sleep(for: .seconds(1.6))
                        withAnimation(.easeOut(duration: 0.35)) { cargando = false }
                    }
            }
            if let aviso = estado.aviso {
                AvisoFlotante(texto: aviso)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .onTapGesture { withAnimation { estado.aviso = nil } }
            }
        }
    }
}

/// Qué pantalla abrir al arrancar (`-pantalla n-inicio`, `-pantalla onboarding -paso 3 -ladoOnb paciente`…).
/// Sólo para capturas y pruebas. Las de la nutri empiezan con «n-»; las del paciente, con «p-».
enum Arranque {
    static var pantalla: String? {
        let p = UserDefaults.standard.string(forKey: "pantalla")
        return p?.isEmpty == true ? nil : p
    }
    static var lado: Lado? {
        guard let p = pantalla else { return nil }
        if p.hasPrefix("n-") { return .nutri }
        if p.hasPrefix("p-") || p == "carga" { return .paciente }
        return nil
    }
    static var oscuro: Bool { UserDefaults.standard.bool(forKey: "oscuro") }
    static var pasoOnboarding: Int { pantalla == "onboarding" ? UserDefaults.standard.integer(forKey: "paso") : 0 }
    static var ladoOnboarding: Lado {
        UserDefaults.standard.string(forKey: "ladoOnb").flatMap(Lado.init(rawValue:)) ?? .nutri
    }
}
