import SwiftUI

/// Ajustes de la nutri: tu perfil y tu plan, integraciones, avisos automáticos, ayuda y la cuenta.
struct AjustesNutri: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @AppStorage("nutri-recordar-dia-antes") private var recordar = true
    @AppStorage("nutri-resumen-diario") private var resumen = true
    @AppStorage("nutri-aviso-aflojo") private var aflojo = true
    @Environment(\.openURL) private var abrir

    var body: some View {
        PantallaClaraN(abajo: Espacio.bajoBarra) {
            NavAtras(atras: "Hoy")
            Titulo("Ajustes", tamano: 30).padding(.horizontal, Espacio.margen)
            VStack(alignment: .leading, spacing: 12) {
                Tarjeta {
                    fila(.persona, .dur, estado.perfilNutri.nombre, "Tu perfil · \(estado.perfilNutri.completitud)% completo") { nav.abrir(.perfil) }
                    Divisor()
                    fila(.estrella, .az, "Tu plan: \(estado.enPrueba ? "Profesional (prueba)" : estado.planActual.nombre)",
                         estado.enPrueba ? "Te quedan \(estado.diasDePrueba) días · \(estado.activos) de \(estado.tope) pacientes" : "\(estado.activos) de \(estado.tope) pacientes") {
                        nav.abrir(.suscripcion)
                    }
                    Divisor()
                    fila(.pago, .az, "Tus precios", "\(estado.nutri.servicios.count) servicios") { nav.ir(.cobros); nav.cobros = [.precios] }
                }
                TituloSeccion(texto: "Lo que ya usás")
                Tarjeta {
                    ForEach(Array(estado.nutri.integraciones.enumerated()), id: \.element.id) { i, x in
                        if i > 0 { Divisor() }
                        FilaIntegracion(integracion: x)
                    }
                }
                TituloSeccion(texto: "Avisos automáticos")
                Tarjeta {
                    interruptor("Recordar el turno el día anterior", "Por WhatsApp, con el link de pago", $recordar)
                    Divisor()
                    interruptor("Resumen del día a las 8", "Turnos, comidas para mirar y cobros", $resumen)
                    Divisor()
                    interruptor("Avisarme si alguien afloja", "Después de 5 días sin anotar", $aflojo)
                }
                TituloSeccion(texto: "Ayuda y privacidad")
                Tarjeta {
                    fila(.ayuda, .az, "Centro de ayuda", "Preguntas frecuentes y tutoriales") {
                        if let u = URL(string: "https://deapoco.com.ar/ayuda") { abrir(u) }
                    }
                    Divisor()
                    fila(.wa, .ok, "Escribinos", "Te responde una persona, no un robot") {
                        if let u = estado.whatsapp("+54 223 592-6772", "Hola, uso De a Poco y tengo una consulta.") { abrir(u) }
                    }
                    Divisor()
                    fila(.escudo, .az, "Privacidad", "Los datos de salud de tus pacientes, protegidos (Ley 25.326)") {
                        if let u = URL(string: "https://deapoco.com.ar/privacidad") { abrir(u) }
                    }
                }
                SeccionCuenta()
            }
            .padding(.horizontal, Espacio.margen)
        }
    }

    private func fila(_ i: Icono, _ tono: IconoCirculo.Tono, _ t: String, _ s: String, _ accion: @escaping () -> Void) -> some View {
        Button { Haptico.seleccion(); accion() } label: {
            Fila(alto: 60) {
                IconoCirculo(icono: i, tono: tono)
                NomSub(nombre: t, sub: s)
                IconoVista(.chev, tamano: 16).foregroundStyle(Color.corteza400)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
    }

    private func interruptor(_ t: String, _ s: String, _ b: Binding<Bool>) -> some View {
        Fila(alto: 60) {
            NomSub(nombre: t, sub: s, lineas: 2)
            Interruptor(prendido: b, etiqueta: t)
        }
    }
}

/// Una integración (Google Calendar, Mercado Pago, WhatsApp, Apple Salud) con su logo y conectar/desconectar.
struct FilaIntegracion: View {
    let integracion: Integracion
    @Environment(Estado.self) private var estado
    @State private var preguntar = false

    var body: some View {
        let x = integracion
        Fila(alto: 60, vertical: 10, horizontal: 14) {
            LogoIntegracion(id: x.id)
            NomSub(nombre: x.nombre, sub: x.conectada ? (x.cuenta ?? "Conectado") : x.detalle)
            if x.conectada {
                Button { preguntar = true } label: { ChipEstado(texto: "Listo", icono: .check, tipo: .ok).frame(minHeight: 44) }
                    .accessibilityLabel("\(x.nombre) conectado. Tocá para desconectar")
            } else {
                Boton(titulo: "Conectar", variante: .suave, alto: .chico) { estado.conectar(x.id, true) }
            }
        }
        .confirmationDialog("¿Desconectar \(x.nombre)?", isPresented: $preguntar, titleVisibility: .visible) {
            Button("Desconectar", role: .destructive) { estado.conectar(x.id, false) }
            Button("Dejarlo", role: .cancel) {}
        }
    }
}

/// El logo de cada integración (.logo-int): 38 con radio 12.
struct LogoIntegracion: View {
    let id: String
    var body: some View {
        Group {
            switch id {
            case "gcal": IconoVista(.gcal, tamano: 22).foregroundStyle(Color(hex: 0x1A73E8))
            case "mp": LogoMP(ancho: 26)
            case "wa": IconoVista(.wa, tamano: 22).foregroundStyle(Color.whatsappClaro)
            default: IconoVista(.salud, tamano: 22).foregroundStyle(Color(hex: 0xD5223F))
            }
        }
        .frame(width: 38, height: 38)
        .background(fondo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
    private var fondo: Color {
        switch id {
        case "gcal": return Color(hex: 0xE8F0FE)
        case "mp": return Color(hex: 0xE6F7FD)
        case "wa": return Color(hex: 0xE7F8EE)
        default: return Color(hex: 0xFDE7EA)
        }
    }
}
