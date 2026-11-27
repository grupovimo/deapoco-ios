import SwiftUI

/// Los pasos del onboarding. El primero elige el lado; después cada lado tiene los suyos, una pregunta por pantalla.
enum PasoOnboarding: String, CaseIterable {
    case lado
    case nombre, matricula, especialidades, modalidades, pacientes, conectar
    case invitacion, sexo, edad, objetivo, comoCome, restricciones, horarios, salud
    case listo

    static func pasos(_ lado: Lado) -> [PasoOnboarding] {
        lado == .paciente
            ? [.lado, .invitacion, .nombre, .sexo, .edad, .objetivo, .comoCome, .restricciones, .horarios, .salud, .listo]
            : [.lado, .nombre, .matricula, .especialidades, .modalidades, .pacientes, .conectar, .listo]
    }

    /// Las tres etapas del pie (los puntos de `.pasos`).
    func etapa(_ lado: Lado) -> Int {
        switch self {
        case .lado, .invitacion, .nombre, .matricula, .especialidades: return lado == .paciente && self == .nombre ? 1 : 0
        case .modalidades, .pacientes, .conectar, .sexo, .edad, .objetivo, .comoCome, .restricciones, .horarios: return 1
        case .salud, .listo: return 2
        }
    }

    /// Los pasos con foto arriba (como la pantalla 1 del diseño).
    var conFoto: Bool { [.conectar, .listo].contains(self) }
}

/// Onboarding: una pregunta por pantalla sobre crema, Nunito grande, y al pie los puntos y «Seguir».
struct Onboarding: View {
    var terminar: (Perfil) -> Void
    @State private var perfil: Perfil
    @State private var indice: Int
    @State private var adelante = true
    @State private var respondidos: Set<PasoOnboarding> = []

    init(lado: Lado = .nutri, paso: Int = 0, perfil: Perfil? = nil, terminar: @escaping (Perfil) -> Void) {
        self.terminar = terminar
        _perfil = State(initialValue: perfil ?? Perfil(lado: lado))
        _indice = State(initialValue: min(paso, PasoOnboarding.pasos(lado).count - 1))
        // Si arranca en un paso intermedio (capturas), lo anterior cuenta como respondido.
        _respondidos = State(initialValue: Set(PasoOnboarding.pasos(lado).prefix(paso)).union(perfil == nil ? [] : Set(PasoOnboarding.allCases)))
    }

    private var pasos: [PasoOnboarding] { PasoOnboarding.pasos(perfil.lado) }
    private var paso: PasoOnboarding { pasos[indice] }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.fondo.ignoresSafeArea()
            VStack(spacing: 0) {
                if !paso.conFoto && paso != .invitacion && paso != .lado { barra }
                ScrollView {
                    PasoVista(paso: paso, perfil: $perfil, respondidos: $respondidos, elegirLado: elegirLado, seguir: siguiente)
                        .id(paso)
                        .transition(.asymmetric(
                            insertion: .move(edge: adelante ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: adelante ? .leading : .trailing).combined(with: .opacity)))
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            if paso != .lado { pie }
        }
        .barraClara(false)
        .animation(.spring(duration: 0.42, bounce: 0.12), value: indice)
    }

    // MARK: Arriba: Atrás y los gajos que se llenan

    private var barra: some View {
        HStack(spacing: 12) {
            Redondo(icono: .atras, variante: .claro, etiqueta: "Atrás") { atras() }
            Spacer()
            Gajos(partes: pasos.count - 1, llenas: indice, chico: true).frame(width: 28, height: 28)
            Text("\(indice) de \(pasos.count - 1)").tipo(.texto(14, 600)).monospacedDigit().foregroundStyle(Color.texto2)
                .contentTransition(.numericText(value: Double(indice)))
        }
        .padding(.leading, 14).padding(.trailing, Espacio.margen)
        .frame(height: 52)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Paso \(indice) de \(pasos.count - 1)")
    }

    // MARK: Pie: las etapas y Seguir

    private var pie: some View {
        Pie {
            if paso == .invitacion {
                Boton(titulo: "Empezar", variante: .prim, alto: .alto, ancho: true) { siguiente() }
            } else {
                HStack {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule().fill(i == paso.etapa(perfil.lado) ? Color.marca : Color.crema400)
                                .frame(width: i == paso.etapa(perfil.lado) ? 34 : 22, height: 6)
                        }
                    }
                    .accessibilityHidden(true)
                    if paso.conFoto || indice <= 1 {
                        Spacer()
                    } else {
                        Button { atras() } label: {
                            Text("Atrás").tipo(.texto(15, 600)).foregroundStyle(Color.texto2).frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(Apretable()).padding(.leading, 8)
                        Spacer()
                    }
                    Boton(titulo: tituloBoton, iconoDerecha: paso == .listo ? nil : .flecha, variante: .prim, alto: .alto,
                          habilitado: puedeSeguir) { siguiente() }
                }
            }
        }
    }

    private var tituloBoton: String {
        if paso == .listo { return "Empezar" }
        if paso == .matricula && perfil.matricula.isEmpty { return "Ahora no" }
        if paso == .salud && !perfil.saludConectada { return "Ahora no" }
        return "Seguir"
    }

    private var puedeSeguir: Bool {
        switch paso {
        case .nombre: return perfil.nombre.trimmingCharacters(in: .whitespaces).count >= 2
        case .especialidades: return !perfil.especialidades.isEmpty
        case .modalidades: return !perfil.modalidades.isEmpty
        case .sexo: return respondidos.contains(.sexo)
        case .objetivo: return perfil.objetivo != nil
        case .comoCome: return !perfil.comoCome.isEmpty
        case .restricciones: return respondidos.contains(.restricciones)
        case .horarios: return !perfil.horarios.isEmpty
        default: return true
        }
    }

    private func siguiente() {
        guard puedeSeguir else { return }
        if paso == .listo {
            Haptico.exito()
            perfil.nombre = perfil.nombre.trimmingCharacters(in: .whitespaces)
            terminar(perfil)
            return
        }
        Haptico.suave()
        adelante = true
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) { indice = min(indice + 1, pasos.count - 1) }
    }

    private func atras() {
        guard indice > 0 else { return }
        Haptico.seleccion()
        adelante = false
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) { indice -= 1 }
    }

    private func elegirLado(_ l: Lado) {
        Haptico.seleccion()
        if perfil.lado != l { let n = perfil.nombre; perfil = Perfil(lado: l); perfil.nombre = n }
        respondidos.insert(.lado)
        siguiente()
    }
}

// MARK: - Cada paso

private struct PasoVista: View {
    let paso: PasoOnboarding
    @Binding var perfil: Perfil
    @Binding var respondidos: Set<PasoOnboarding>
    var elegirLado: (Lado) -> Void
    var seguir: () -> Void

    var body: some View {
        switch paso {
        case .lado: SelectorLado(elegir: elegirLado)
        case .conectar: PasoConectar(perfil: $perfil)
        case .invitacion: PasoInvitacion(perfil: $perfil)
        case .listo: PasoListo(perfil: perfil)
        case .salud: PasoSalud(perfil: $perfil)
        default: PasoPregunta(paso: paso, perfil: $perfil, respondidos: $respondidos, seguir: seguir)
        }
    }
}

/// Elegir el lado: dos tarjetas con foto.
struct SelectorLado: View {
    var elegir: (Lado) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image("horizontal-color").resizable().scaledToFit().frame(height: 30)
                .padding(.top, 18).accessibilityLabel("De a Poco")
            Titulo("Comer mejor se hace de\u{00A0}a\u{00A0}poco.", tamano: 34).padding(.top, 10)
            Text("¿Desde qué lado entrás?").tipo(.texto(15, 400)).foregroundStyle(Color.texto2).padding(.top, -4)
            TarjetaLado(foto: "foto-consultorio", foco: UnitPoint(x: 0.4, y: 0.3), titulo: "Soy nutri",
                        bajada: "Turnos, planes, fotos de tus pacientes y cobros.") { elegir(.nutri) }
            TarjetaLado(foto: "foto-cocina", foco: UnitPoint(x: 0.5, y: 0.35), titulo: "Soy paciente",
                        bajada: "Mi nutri me invitó. Mi plan y mis turnos, en un lugar.") { elegir(.paciente) }
        }
        .padding(.horizontal, Espacio.margen)
    }
}

private struct TarjetaLado: View {
    let foto: String
    var foco: UnitPoint
    let titulo: String
    let bajada: String
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            ZStack(alignment: .bottomLeading) {
                FotoRecortada(nombre: foto, foco: foco)
                LinearGradient(colors: [Color.verde950.opacity(0), Color.verde950.opacity(0.75)], startPoint: .center, endPoint: .bottom)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titulo).font(Estilo.titulo(26).font()).foregroundStyle(Color.crema)
                        Text(bajada).tipo(.texto(14, 500)).foregroundStyle(Color.crema.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    IconoVista(.flecha, tamano: 20).foregroundStyle(Color.verde900)
                        .frame(width: 44, height: 44).background(Color.crema, in: Circle())
                }
                .padding(16)
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("\(titulo). \(bajada)")
    }
}

/// La foto grande de arriba (`.bien-foto`) con el sello del paso.
private struct FotoConSello: View {
    let foto: String
    var foco: UnitPoint = UnitPoint(x: 0.4, y: 0.3)
    let paso: Int
    let titulo: String
    let bajada: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            FotoRecortada(nombre: foto, foco: foco)
            LinearGradient(stops: [.init(color: Color.verde950.opacity(0), location: 0.55), .init(color: Color.verde950.opacity(0.55), location: 1)],
                           startPoint: .top, endPoint: .bottom)
            HStack(spacing: 10) {
                Gajos(partes: 3, llenas: paso).frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text(titulo).tipo(.texto(14, 700)).foregroundStyle(Color.verde900)
                    Text(bajada).tipo(.texto(12.5, 400)).foregroundStyle(Color.salvia)
                }
            }
            .padding(.vertical, 10).padding(.leading, 10).padding(.trailing, 14)
            .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .sombraFlotante()
            .padding(16)
        }
        .frame(height: 352)
        .clipShape(RoundedRectangle(cornerRadius: Radio.foto, style: .continuous))
        .padding(.horizontal, 12)
        .environment(\.colorScheme, .light)
    }
}

/// Pantalla 1 del diseño: «Traé lo que ya usás.»
private struct PasoConectar: View {
    @Binding var perfil: Perfil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FotoConSello(foto: "foto-consultorio", paso: 1, titulo: "Paso 2 de 3", bajada: "Tu consultorio, armado")
            VStack(alignment: .leading, spacing: 14) {
                Titulo("Traé lo que ya usás.", tamano: 32)
                Text("Se conecta en un minuto. Lo podés cambiar cuando quieras.")
                    .tipo(.texto(15, 400)).foregroundStyle(Color.texto2).padding(.top, -6)
                Tarjeta {
                    fila("gcal", "Google Calendar", perfil.nombre.isEmpty ? "Tus turnos en tu calendario" : correo,
                         logo: AnyView(IconoVista(.gcal, tamano: 22).foregroundStyle(Color(hex: 0x1A73E8))), fondo: Color(hex: 0xE8F0FE))
                    Divisor()
                    fila("mp", "Mercado Pago", "Cobrás consultas y planes", logo: AnyView(LogoMP(ancho: 26)), fondo: Color(hex: 0xE6F7FD))
                    Divisor()
                    fila("wa", "WhatsApp", "Recordatorios desde tu número",
                         logo: AnyView(IconoVista(.wa, tamano: 22).foregroundStyle(Color.whatsappClaro)), fondo: Color(hex: 0xE7F8EE))
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 22)
        }
    }

    private var correo: String {
        perfil.nombre.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .split(separator: " ").joined(separator: ".") + "@gmail.com"
    }

    private func fila(_ id: String, _ nombre: String, _ sub: String, logo: AnyView, fondo: Color) -> some View {
        let listo = perfil.conectadas.contains(id)
        return Fila(alto: 60, vertical: 10, horizontal: 14) {
            logo.frame(width: 38, height: 38).background(fondo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            NomSub(nombre: nombre, sub: sub)
            if listo {
                ChipEstado(texto: "Listo", icono: .check, tipo: .ok)
            } else {
                Boton(titulo: "Conectar", variante: .suave, alto: .chico) {
                    Haptico.exito()
                    withAnimation(.snappy) { perfil.conectadas.append(id) }
                }
            }
        }
    }
}

/// Pantalla 9 del diseño: «Laura te sumó a De a Poco.»
private struct PasoInvitacion: View {
    @Binding var perfil: Perfil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                FotoRecortada(nombre: "foto-online", foco: UnitPoint(x: 0.32, y: 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: Radio.foto, style: .continuous))
                HStack(spacing: 12) {
                    Avatar(foto: "av-laura")
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Lic. Laura Ferreyra").tipo(.texto(15, 700)).foregroundStyle(Color.texto)
                        Text("Nutricionista · MP 2174").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                    Spacer(minLength: 4)
                    ChipEstado(texto: "Tu nutri", icono: .check, tipo: .ok)
                }
                .padding(14)
                .background(Color.superficie, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .sombraFlotante()
                .padding(.horizontal, 14)
                .offset(y: 26)
            }
            .frame(height: 330)
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 4)
            VStack(alignment: .leading, spacing: 14) {
                Titulo("Laura te sumó a\u{00A0}De\u{00A0}a\u{00A0}Poco.", tamano: 34)
                Text("Tu plan, tus turnos y los mensajes con ella, en un lugar.")
                    .tipo(.texto(15, 400)).foregroundStyle(Color.texto2).padding(.top, -4)
                Tarjeta {
                    Fila(alto: 58) {
                        IconoCirculo(icono: .campana, tono: .az)
                        NomSub(nombre: "Avisos", sub: "Turnos y comidas")
                        Interruptor(prendido: $perfil.avisos, etiqueta: "Avisos")
                    }
                    Divisor()
                    Fila(alto: 58) {
                        IconoCirculo(icono: .salud, tono: .salud)
                        NomSub(nombre: "Apple Salud", sub: "Pasos y sueño, sólo para Laura")
                        Interruptor(prendido: $perfil.saludConectada, etiqueta: "Apple Salud")
                    }
                }
                HStack(alignment: .top, spacing: 8) {
                    IconoVista(.candado, tamano: 16).foregroundStyle(Color.marca).padding(.top, 1)
                    Text("Tus fotos y medidas las ve sólo tu nutri.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 44)
        }
    }
}

/// Las preguntas de una pantalla (título, bajada y respuestas).
private struct PasoPregunta: View {
    let paso: PasoOnboarding
    @Binding var perfil: Perfil
    @Binding var respondidos: Set<PasoOnboarding>
    var seguir: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Titulo(titulo, tamano: 32)
            Text(bajada).tipo(.texto(15, 400)).foregroundStyle(Color.texto2)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 10)
            Respuestas(paso: paso, perfil: $perfil, respondidos: $respondidos, seguir: seguir).padding(.top, 24)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 12)
    }

    private var nutri: Bool { perfil.lado == .nutri }

    private var titulo: String {
        switch paso {
        case .nombre: return nutri ? "¿Cómo te llaman tus\u{00A0}pacientes?" : "¿Cómo te\u{00A0}llamás?"
        case .matricula: return "¿Cuál es tu\u{00A0}matrícula?"
        case .especialidades: return "¿Con qué trabajás\u{00A0}más?"
        case .modalidades: return "¿Dónde\u{00A0}atendés?"
        case .pacientes: return "¿Cuántos pacientes\u{00A0}tenés?"
        case .sexo: return "¿Con qué te\u{00A0}identificás?"
        case .edad: return "¿Cuántos años\u{00A0}tenés?"
        case .objetivo: return "¿Qué te gustaría\u{00A0}lograr?"
        case .comoCome: return "¿Cómo comés\u{00A0}hoy?"
        case .restricciones: return "¿Algo que no\u{00A0}comas?"
        case .horarios: return "¿A qué hora\u{00A0}comés?"
        default: return ""
        }
    }

    private var bajada: String {
        switch paso {
        case .nombre: return nutri ? "Así te ven en tu página y en sus mensajes." : "Así te saluda Laura."
        case .matricula: return "Les da confianza a los pacientes nuevos. La ven en tu página."
        case .especialidades: return "Elegí todas las que correspondan. Así te encuentran."
        case .modalidades: return "Elegí una o las dos."
        case .pacientes: return "Más o menos. Hasta 10, De a Poco es gratis para siempre."
        case .sexo: return "Para que tu plan tenga las porciones justas."
        case .edad: return "Deslizá la regla."
        case .objetivo: return "Elegí lo más importante. Lo charlás con Laura en la consulta."
        case .comoCome: return "Sin culpa: es para saber de dónde arrancamos. Elegí todas las que van."
        case .restricciones: return "Restricciones, alergias o algo de salud. Laura lo tiene en cuenta."
        case .horarios: return "Te avisamos un ratito antes. Si no hacés alguna, apagala."
        default: return ""
        }
    }
}

private struct Respuestas: View {
    let paso: PasoOnboarding
    @Binding var perfil: Perfil
    @Binding var respondidos: Set<PasoOnboarding>
    var seguir: () -> Void

    var body: some View {
        switch paso {
        case .nombre:
            CampoGrande(texto: $perfil.nombre, ejemplo: perfil.lado == .nutri ? "Laura Ferreyra" : "Sofía", contenido: .name, alEnviar: seguir)
        case .matricula:
            VStack(alignment: .leading, spacing: 10) {
                CampoGrande(texto: $perfil.matricula, ejemplo: "MP 2174", contenido: nil, mayusculas: true, alEnviar: seguir)
                Text("Si no la tenés a mano, la sumás después en tu perfil.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
            }
        case .especialidades:
            ChipsMultiples(opciones: especialidadesComunes, elegidas: Set(perfil.especialidades)) { o in
                alternar(&perfil.especialidades, o)
            }
        case .modalidades:
            VStack(spacing: 10) {
                ForEach(Modalidad.allCases, id: \.self) { m in
                    OpcionOnb(titulo: m == .consultorio ? "En consultorio" : "En línea",
                              bajada: m == .consultorio ? "Con dirección y horarios" : "Videollamada desde la app",
                              icono: m.icono, elegido: perfil.modalidades.contains(m), multiple: true) {
                        elegir { alternar(&perfil.modalidades, m) }
                    }
                }
            }
        case .pacientes: CantidadPacientes(cantidad: $perfil.cantidadPacientes)
        case .sexo:
            VStack(spacing: 10) {
                ForEach(Sexo.allCases, id: \.self) { s in
                    OpcionOnb(titulo: s.titulo, elegido: respondidos.contains(.sexo) && perfil.sexo == s) {
                        elegir { perfil.sexo = s; respondidos.insert(.sexo) }
                    }
                }
            }
        case .edad:
            Regla(valor: Binding(get: { Double(perfil.edad) }, set: { perfil.edad = Int($0) }), rango: 14...90, unidad: "años", cadaLarga: 10)
                .padding(.horizontal, -Espacio.margen)
        case .objetivo:
            VStack(spacing: 10) {
                ForEach(ObjetivoNutri.allCases, id: \.self) { o in
                    OpcionOnb(titulo: o.titulo, bajada: o.bajada, elegido: perfil.objetivo == o) { elegir { perfil.objetivo = o } }
                }
            }
        case .comoCome:
            ChipsMultiples(opciones: ComoCome.allCases.map(\.titulo), elegidas: Set(perfil.comoCome.map(\.titulo))) { t in
                if let c = ComoCome.allCases.first(where: { $0.titulo == t }) { alternar(&perfil.comoCome, c) }
            }
        case .restricciones:
            VStack(alignment: .leading, spacing: 16) {
                ChipsMultiples(opciones: ["Ninguna"] + restriccionesComunes,
                               elegidas: Set(perfil.restricciones.isEmpty && respondidos.contains(.restricciones) ? ["Ninguna"] : perfil.restricciones)) { o in
                    respondidos.insert(.restricciones)
                    if o == "Ninguna" { perfil.restricciones = [] } else { alternar(&perfil.restricciones, o) }
                }
                CampoGrande(texto: $perfil.otraRestriccion, ejemplo: "Otra cosa (opcional)", contenido: nil, alto: 52, tamano: 16,
                            alEnviar: { respondidos.insert(.restricciones) })
            }
        case .horarios: Horarios(horarios: $perfil.horarios)
        default: EmptyView()
        }
    }

    private func elegir(_ cambio: () -> Void) {
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.2)) { cambio() }
    }

    private func alternar<T: Equatable>(_ lista: inout [T], _ v: T) {
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.2)) {
            if let i = lista.firstIndex(of: v) { lista.remove(at: i) } else { lista.append(v) }
        }
    }
}

// MARK: - Piezas

/// Campo de texto grande sobre blanco (.campo-l, más alto).
struct CampoGrande: View {
    @Binding var texto: String
    let ejemplo: String
    var contenido: UITextContentType?
    var mayusculas = false
    var alto: CGFloat = 64
    var tamano: CGFloat = 22
    var alEnviar: () -> Void = {}
    @FocusState private var foco: Bool

    var body: some View {
        TextField("", text: $texto, prompt: Text(ejemplo).foregroundColor(.salvia400))
            .font(Estilo.texto(tamano, 600).font())
            .foregroundStyle(Color.texto)
            .tint(Color.marca)
            .textContentType(contenido)
            .textInputAutocapitalization(mayusculas ? .characters : .words)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused($foco)
            .onSubmit(alEnviar)
            .padding(.horizontal, 16)
            .frame(height: alto)
            .background(Color.superficie, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous)
                .strokeBorder(foco ? Color.marca : Color.borde, lineWidth: foco ? 2 : 1))
    }
}

/// Respuesta en tarjeta (.opc): blanca; elegida, con borde verde y el círculo lleno.
struct OpcionOnb: View {
    let titulo: String
    var bajada: String? = nil
    var icono: Icono? = nil
    var elegido: Bool
    var multiple = false
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                if let icono { IconoCirculo(icono: icono, tono: elegido ? .az : .crema, tamano: 44) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo).tipo(.texto(16, 600)).foregroundStyle(Color.texto)
                    if let bajada { Text(bajada).tipo(.texto(13, 400)).foregroundStyle(Color.texto2) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                marca
            }
            .padding(.horizontal, 16)
            .frame(minHeight: bajada == nil ? 60 : 68)
            .background(elegido ? Color.infoSuave : Color.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                .strokeBorder(elegido ? Color.marca : Color.borde, lineWidth: elegido ? 2.5 : 1.5))
            .contentShape(RoundedRectangle(cornerRadius: Radio.tarjeta))
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }

    private var marca: some View {
        ZStack {
            if multiple {
                RoundedRectangle(cornerRadius: 7, style: .continuous).fill(elegido ? Color.marca : .clear)
                RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(elegido ? Color.marca : Color.salvia400, lineWidth: 2)
            } else {
                Circle().fill(elegido ? Color.marca : .clear)
                Circle().strokeBorder(elegido ? Color.marca : Color.salvia400, lineWidth: 2)
            }
            if elegido { IconoVista(.check, tamano: 14, grosor: 2.8).foregroundStyle(Color.sobreMarca) }
        }
        .frame(width: 22, height: 22)
    }
}

/// Chips que fluyen en varios renglones, con varias elegidas.
struct ChipsMultiples: View {
    let opciones: [String]
    let elegidas: Set<String>
    var tocar: (String) -> Void

    var body: some View {
        Fluir(espacio: 8) {
            ForEach(opciones, id: \.self) { o in
                ChipOpcion(titulo: o, icono: elegidas.contains(o) ? .check : nil, elegido: elegidas.contains(o), alto: 44) { tocar(o) }
            }
        }
    }
}

private struct CantidadPacientes: View {
    @Binding var cantidad: Int

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 24) {
                boton(.menos, "Menos pacientes") { cambiar(-5) }
                Text("\(cantidad)").tipo(.numero(72)).foregroundStyle(Color.titulo)
                    .contentTransition(.numericText(value: Double(cantidad))).frame(minWidth: 130)
                boton(.mas, "Más pacientes") { cambiar(5) }
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                ForEach([10, 20, 40, 60, 100], id: \.self) { n in
                    ChipOpcion(titulo: "\(n)", elegido: cantidad == n, alto: 44) {
                        withAnimation(.snappy) { cantidad = n }
                    }
                }
            }
            Text(cantidad <= 10 ? "Entran en el plan Gratis." : "Arrancás con 14 días de Profesional, sin tarjeta.")
                .tipo(.texto(14, 600)).foregroundStyle(Color.acentoTexto)
                .contentTransition(.opacity)
        }
    }

    private func cambiar(_ d: Int) {
        Haptico.seleccion()
        withAnimation(.snappy) { cantidad = max(1, min(400, cantidad + d)) }
    }

    private func boton(_ i: Icono, _ e: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            IconoVista(i, tamano: 24).foregroundStyle(Color.sobreSuave).frame(width: 56, height: 56).background(Color.suave, in: Circle())
        }
        .buttonStyle(Apretable()).accessibilityLabel(e)
    }
}

/// Los horarios de cada comida: prendida o apagada, y la hora de a media hora.
private struct Horarios: View {
    @Binding var horarios: [Momento: String]

    var body: some View {
        Tarjeta {
            ForEach(Array(Momento.principales.enumerated()), id: \.offset) { i, m in
                if i > 0 { Divisor() }
                fila(m)
            }
        }
    }

    private func fila(_ m: Momento) -> some View {
        let hora = horarios[m]
        return Fila(alto: 64) {
            Interruptor(prendido: Binding(get: { hora != nil }, set: { horarios[m] = $0 ? m.horaSugerida : nil }), etiqueta: m.titulo)
            Text(m.titulo).tipo(.texto(16, 600)).foregroundStyle(hora == nil ? Color.texto2 : Color.texto)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let hora {
                HStack(spacing: 4) {
                    paso(.menos, m, -30)
                    Text(hora).tipo(.numero(17)).foregroundStyle(Color.titulo).frame(width: 54)
                        .contentTransition(.numericText())
                    paso(.mas, m, 30)
                }
                .transition(.opacity)
            }
        }
    }

    private func paso(_ i: Icono, _ m: Momento, _ d: Int) -> some View {
        Button {
            Haptico.seleccion()
            let actual = Fecha.minutos(horarios[m] ?? m.horaSugerida)
            withAnimation(.snappy) { horarios[m] = Fecha.hora(max(5 * 60, min(23 * 60 + 30, actual + d))) }
        } label: {
            IconoVista(i, tamano: 16).foregroundStyle(Color.sobreSuave).frame(width: 32, height: 32).background(Color.suave, in: Circle())
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("\(d < 0 ? "Antes" : "Después") el \(m.titulo.lowercased())")
    }
}

/// Apple Salud: qué se lee, quién lo ve y el botón.
private struct PasoSalud: View {
    @Binding var perfil: Perfil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Titulo("Sumá tus pasos y tu\u{00A0}sueño", tamano: 32)
            Text("Conectá Apple Salud y Laura ve cómo dormís y cuánto caminás. Sirve para ajustar tu plan.")
                .tipo(.texto(15, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true).padding(.top, 10)
            ZStack {
                Circle().fill(Color.logroSuave).frame(width: 168, height: 168)
                Circle().fill(Color.superficie).frame(width: 116, height: 116).sombraMedia()
                IconoVista(.salud, tamano: 56).foregroundStyle(Color.salud)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 28)
            VStack(alignment: .leading, spacing: 12) {
                linea("Sólo leemos pasos y horas de sueño.")
                linea("Lo ve tu nutri, nadie más. Nunca el peso.")
                linea("Lo apagás cuando quieras desde Ajustes.")
            }
            Group {
                if perfil.saludConectada {
                    HStack(spacing: 8) {
                        IconoVista(.check, tamano: 20)
                        Text("Listo, Apple Salud conectada").tipo(.texto(16, 600))
                    }
                    .foregroundStyle(Color.ok)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.okFondo, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Boton(titulo: "Conectar Apple Salud", icono: .salud, variante: .crema, alto: .alto, ancho: true, colorIcono: .salud) {
                        Haptico.exito()
                        withAnimation(.snappy) { perfil.saludConectada = true }
                    }
                }
            }
            .padding(.top, 24)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 12)
    }

    private func linea(_ t: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconoVista(.check, tamano: 20).foregroundStyle(Color.acentoTexto)
            Text(t).tipo(.texto(15, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// El cierre: la foto con el plato completo y el resumen de lo respondido.
private struct PasoListo: View {
    let perfil: Perfil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FotoConSello(foto: perfil.lado == .nutri ? "foto-nutri-celu" : "foto-mate-desayuno", foco: UnitPoint(x: 0.5, y: 0.35),
                         paso: 3, titulo: "Paso 3 de 3", bajada: perfil.lado == .nutri ? "Listo para atender" : "Tu día, armado")
            VStack(alignment: .leading, spacing: 14) {
                Titulo("¡Listo, \(perfil.primerNombre.isEmpty ? "ya está" : perfil.primerNombre)!", tamano: 32)
                Text(perfil.lado == .nutri ? "Sumá a tus pacientes y armá el primer plan. Lo demás, de a poco."
                                           : "Laura ya sabe por dónde arrancar. Sacale una foto a tu próxima comida.")
                    .tipo(.texto(15, 400)).foregroundStyle(Color.texto2).padding(.top, -6)
                    .fixedSize(horizontal: false, vertical: true)
                Tarjeta {
                    ForEach(Array(resumen.enumerated()), id: \.offset) { i, r in
                        if i > 0 { Divisor() }
                        HStack(alignment: .firstTextBaseline) {
                            Text(r.0).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                            Spacer(minLength: 12)
                            Text(r.1).tipo(.texto(14, 600)).foregroundStyle(Color.texto).multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 11)
                    }
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 22)
        }
    }

    private var resumen: [(String, String)] {
        if perfil.lado == .nutri {
            return [
                ("Matrícula", perfil.matricula.isEmpty ? "Más adelante" : perfil.matricula),
                ("Trabajás con", perfil.especialidades.isEmpty ? "—" : perfil.especialidades.prefix(3).joined(separator: ", ")),
                ("Atendés", perfil.modalidades.map { $0 == .consultorio ? "En consultorio" : "En línea" }.joined(separator: " y ")),
                ("Pacientes", "\(perfil.cantidadPacientes)"),
            ]
        }
        let comidas = Momento.principales.filter { perfil.horarios[$0] != nil }.map(\.titulo)
        return [
            ("Objetivo", perfil.objetivo?.titulo ?? "—"),
            ("Comidas", comidas.isEmpty ? "—" : comidas.joined(separator: ", ")),
            ("No comés", perfil.restricciones.isEmpty ? (perfil.otraRestriccion.isEmpty ? "Nada en especial" : perfil.otraRestriccion) : perfil.restricciones.joined(separator: ", ")),
            ("Apple Salud", perfil.saludConectada ? "Conectada" : "Más adelante"),
        ]
    }
}
