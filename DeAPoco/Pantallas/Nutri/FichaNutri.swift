import SwiftUI

enum PestanaFicha: String, CaseIterable, Hashable {
    case resumen, comidas, pagos, notas
    var titulo: String {
        switch self { case .resumen: return "Resumen"; case .comidas: return "Comidas"; case .pagos: return "Pagos"; case .notas: return "Notas" }
    }
}

/// Ficha del paciente (p4): la banda con sus acciones y cuatro pestañas.
struct FichaPaciente: View {
    let pacienteId: String
    nonisolated(unsafe) static var pestanaInicial: PestanaFicha = .resumen
    @Environment(Estado.self) private var estado
    @State private var pestana: PestanaFicha = FichaPaciente.pestanaInicial

    var body: some View {
        if let p = estado.paciente(pacienteId) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Banda(abajo: 16) { BandaFicha(paciente: p) }
                    PestanasFicha(pestana: $pestana).padding(.top, 4)
                    VStack(alignment: .leading, spacing: 12) {
                        switch pestana {
                        case .resumen: ResumenFicha(paciente: p, pestana: $pestana)
                        case .comidas: ComidasFicha(paciente: p)
                        case .pagos: PagosFicha(paciente: p)
                        case .notas: NotasFicha(paciente: p)
                        }
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 14)
                    .padding(.bottom, Espacio.bajoBarra)
                    .id(pestana)
                    .transition(.opacity)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.fondo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .barraClara()
            .onDisappear { FichaPaciente.pestanaInicial = .resumen }
        } else {
            VStack {
                NavAtras(atras: "Pacientes")
                Vacio(titulo: "No encontramos a ese paciente", texto: "Puede que lo hayan dado de alta.", icono: .persona)
                Spacer()
            }
            .background(Color.fondo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct BandaFicha: View {
    let paciente: Paciente
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @Environment(\.openURL) private var abrir

    var body: some View {
        let p = paciente
        NavAtras(atras: "Pacientes") {
            if let t = estado.proximoTurno(de: p.id), t.fecha == estado.hoy, estado.minutosHasta(t) <= 30 {
                ChipEstado(texto: "En consulta", icono: .video, tipo: .banda, alto: 32, tamano: 15)
            }
        }
        HStack(spacing: 14) {
            Avatar(foto: p.foto, iniciales: p.iniciales, tono: p.tono, tamano: 64, anillo: .mantecaFija, anilloAncho: 3)
            VStack(alignment: .leading, spacing: 4) {
                Titulo(p.nombre, tamano: 28, color: .mantecaFija)
                Text(estado.resumenFicha(p)).tipo(.texto(14, 400)).foregroundStyle(Color.sobreBanda2).lineLimit(1).minimumScaleFactor(0.85)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 2)
        HStack(spacing: 8) {
            AccionBanda(icono: .wa, titulo: "WhatsApp") {
                if let u = estado.whatsapp(p.telefono, "Hola \(p.primerNombre)!") { abrir(u) }
            }
            AccionBanda(icono: .plan, titulo: "Plan") { nav.cubierta = .armarPlan(paciente: p.id, modelo: nil) }
            AccionBanda(icono: .turno, titulo: "Turno") { nav.hoja = .darTurno(paciente: p.id, fecha: nil, hora: nil) }
            AccionBanda(icono: .pago, titulo: "Cobrar") { nav.hoja = .cobrar(p.id) }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }
}

/// Una acción sobre la banda (.acciones span): 58 de alto, vidrio.
private struct AccionBanda: View {
    let icono: Icono
    let titulo: String
    var accion: () -> Void
    var body: some View {
        Button { Haptico.seleccion(); accion() } label: {
            VStack(spacing: 4) {
                IconoVista(icono, tamano: 20)
                Text(titulo).tipo(.texto(12, 600))
            }
            .foregroundStyle(Color.mantecaFija)
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(Color.vidrio12, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(titulo)
    }
}

/// Las pestañas (.pestanas): subrayado enlozado de 3 en la elegida.
private struct PestanasFicha: View {
    @Binding var pestana: PestanaFicha
    @Namespace private var ns
    var body: some View {
        HStack(spacing: 20) {
            ForEach(PestanaFicha.allCases, id: \.self) { p in
                let on = p == pestana
                Button {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.25)) { pestana = p }
                } label: {
                    Text(p.titulo).tipo(.texto(15, on ? 700 : 600))
                        .foregroundStyle(on ? Color.titulo : Color.texto2)
                        .padding(.top, 12).padding(.bottom, 10)
                        .overlay(alignment: .bottom) {
                            if on { Capsule().fill(Color.marca).frame(height: 3).offset(y: 1).matchedGeometryEffect(id: "sub", in: ns) }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.horizontal, Espacio.margen)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.borde).frame(height: 1) }
    }
}

// MARK: - Resumen

private struct ResumenFicha: View {
    let paciente: Paciente
    @Binding var pestana: PestanaFicha
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let p = paciente
        EvolucionCardN(pacienteId: p.id)
        HStack(spacing: 12) {
            Tarjeta(relleno: 14) {
                HStack(spacing: 10) {
                    Plato(partes: 7, llenas: p.diasSemana, hoy: p.diasSemana < 7 ? p.diasSemana : nil).frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(p.diasSemana) de 7 días").tipo(.texto(15, 700)).foregroundStyle(Color.texto).lineLimit(1)
                        Text("esta semana").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                }
            }
            let deuda = estado.deuda(de: p.id)
            Button { Haptico.seleccion(); pestana = .pagos } label: {
                Tarjeta(relleno: 14) {
                    HStack(spacing: 10) {
                        IconoCirculo(icono: deuda.isEmpty ? .check : .pago, tono: deuda.isEmpty ? .ok : .aviso)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(deuda.isEmpty ? "Pagos al día" : "Debe \(Formato.plata(deuda.reduce(0) { $0 + $1.monto }))")
                                .tipo(.texto(15, 700)).foregroundStyle(Color.texto).lineLimit(1).minimumScaleFactor(0.8)
                            Text(Fecha.meses[Fecha.mes(estado.hoy) - 1]).tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        }
                    }
                }
            }
            .buttonStyle(Apretable())
        }
        let comidas = estado.registros(de: p.id)
        TituloSeccion(texto: "Lo que comió", dato: comidas.isEmpty ? nil : "Ver todo\u{00A0}›") { pestana = .comidas }
        if comidas.isEmpty {
            Tarjeta { Vacio(titulo: "Todavía no anotó comidas", texto: "Cuando mande la primera foto, la ves acá.", icono: .foto) }
        } else {
            TiraComidas(registros: comidas) { pestana = .comidas }
        }
        if !p.meta.isEmpty {
            Tarjeta(relleno: 16) {
                Etiqueta("Meta de la semana")
                HStack {
                    Text(p.meta).tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                    Spacer(minLength: 8)
                    Porciones(hechas: p.metaHechas, total: p.metaTotal)
                }
                .padding(.top, 4)
            }
        }
        PlanYTurno(paciente: p)
        Tarjeta(relleno: 16) {
            Etiqueta("Lo que quiere lograr")
            Text(p.objetivo).tipo(.texto(15, 600)).foregroundStyle(Color.texto).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            if !p.restricciones.isEmpty {
                Fluir(espacio: 6) {
                    ForEach(p.restricciones, id: \.self) { ChipEstado(texto: $0, icono: .aviso, tipo: .dur) }
                }
                .padding(.top, 10)
            }
            if !p.comoCome.isEmpty {
                Text(p.comoCome).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 8).fixedSize(horizontal: false, vertical: true)
            }
        }
        if p.saludConectada {
            Tarjeta(relleno: 16) {
                HStack {
                    Etiqueta("Su día a día")
                    Spacer()
                    HStack(spacing: 4) { IconoVista(.salud, tamano: 12).foregroundStyle(Color.salud); Text("De Apple Salud").tipo(.texto(12, 600)) }
                        .foregroundStyle(Color.texto2)
                }
                Numero(valor: Formato.entero(p.pasos ?? 0), tamano: 22, color: .texto, unidad: " pasos por día").padding(.top, 4)
            }
        }
    }
}

/// La curva de cintura o peso (.evo-cab + svg.curva). Tocarla abre las medidas.
struct EvolucionCardN: View {
    let pacienteId: String
    var alto: CGFloat = 92
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var tipo: TipoMedida = .cintura

    var body: some View {
        let m = estado.mediciones(de: pacienteId)
        let valores = m.compactMap { tipo.valor($0) }
        Tarjeta(relleno: 16) {
            if valores.count < 2 {
                Vacio(titulo: "Sin medidas todavía", texto: "Anotalas en la próxima consulta y vas a ver la curva.", accion: "Anotar medidas") {
                    nav.hoja = .anotarMedidas(pacienteId)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiqueta(tipo.titulo)
                        let d = (valores.last ?? 0) - (valores.first ?? 0)
                        Numero(valor: Formato.diferencia(d), tamano: 26, color: .titulo,
                               unidad: " \(tipo.unidad) desde \(Fecha.meses[Fecha.mes(m[0].fecha) - 1])", tamanoUnidad: 15)
                    }
                    Spacer(minLength: 0)
                    MiniSeg(opciones: [(TipoMedida.cintura, "Cintura"), (.peso, "Peso")], elegida: $tipo)
                }
                Curva(valores: valores, etiquetas: estado.etiquetasMeses(m.filter { tipo.valor($0) != nil }), alto: alto)
                    .padding(.top, 6)
                    .contentShape(Rectangle())
                    .onTapGesture { Haptico.seleccion(); nav.abrir(.medidas(pacienteId)) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Abre todas las medidas")
            }
        }
    }
}

/// La tira de fotos (.tira): las tres últimas con su día y «+N».
private struct TiraComidas: View {
    let registros: [Registro]
    var verTodo: () -> Void
    @Environment(Estado.self) private var estado

    var body: some View {
        let conFoto = registros.filter { $0.foto != nil }
        HStack(spacing: 8) {
            ForEach(conFoto.prefix(3)) { r in
                FotoRecortada(nombre: r.foto ?? "")
                    .frame(width: 72, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        Text(dia(r.fecha)).tipo(.texto(11, 700)).foregroundStyle(Color.tinta)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            .padding(6)
                    }
                    .accessibilityLabel("\(r.momento.titulo) del \(Fecha.diaLargo(r.fecha)): \(r.descripcion)")
            }
            if registros.count > 3 {
                Button(action: verTodo) {
                    Text("+\(registros.count - 3)").tipo(.texto(15, 700)).foregroundStyle(Color.sobreSuave)
                        .frame(width: 72, height: 64)
                        .background(Color.suave, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("Ver las \(registros.count) comidas")
            }
            Spacer(minLength: 0)
        }
    }

    private func dia(_ f: String) -> String {
        f == estado.hoy ? "Hoy" : Fecha.diaCorto(f).prefix(1).uppercased() + Fecha.diaCorto(f).dropFirst()
    }
}

/// El plan vigente y el próximo turno.
private struct PlanYTurno: View {
    let paciente: Paciente
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        Tarjeta {
            let plan = estado.plan(de: paciente.id)
            Fila {
                IconoCirculo(icono: .plan, tono: .dur)
                NomSub(nombre: plan?.nombre.replacingOccurrences(of: "\u{00A0}", with: " ") ?? "Sin plan todavía",
                       sub: plan.map { $0.enviado ? "Se lo mandaste" : "Borrador, sin mandar" } ?? "Armalo desde un modelo")
                Boton(titulo: plan == nil ? "Armar" : "Abrir", variante: .suave, alto: .chico) {
                    nav.cubierta = .armarPlan(paciente: paciente.id, modelo: nil)
                }
            }
            Divisor()
            let t = estado.proximoTurno(de: paciente.id)
            Fila {
                IconoCirculo(icono: .turno, tono: .az)
                NomSub(nombre: t.map { "\(Fecha.relativa($0.fecha, hoy: estado.hoy).capitalized) a las \($0.hora)" } ?? "Sin próximo turno",
                       sub: t.map { "\($0.modalidad.titulo) · \($0.estado == .confirmado ? "confirmó" : "sin confirmar")" } ?? "Dale uno para seguir")
                Boton(titulo: t == nil ? "Dar" : "Ver", variante: .suave, alto: .chico) {
                    if let t { nav.hoja = .turno(t.id) } else { nav.hoja = .darTurno(paciente: paciente.id, fecha: nil, hora: nil) }
                }
            }
            Divisor()
            Fila {
                IconoCirculo(icono: .cinta, tono: .az)
                NomSub(nombre: "Medidas", sub: "\(estado.mediciones(de: paciente.id).count) consultas anotadas")
                Boton(titulo: "Ver", variante: .suave, alto: .chico) { nav.abrir(.medidas(paciente.id)) }
            }
        }
    }
}

// MARK: - Comidas

private struct ComidasFicha: View {
    let paciente: Paciente
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let regs = estado.registros(de: paciente.id)
        let pendientes = regs.filter { !$0.revisada }.count
        if pendientes > 0 {
            Boton(titulo: "Mirar \(pendientes) sin revisar", icono: .foto, variante: .prim, alto: .medio, ancho: true) { nav.cubierta = .revisar }
        }
        if regs.isEmpty {
            Tarjeta { Vacio(titulo: "Todavía no anotó comidas", texto: "Mandale un mensaje para que arranque con una foto.", icono: .foto) }
        }
        let dias = Array(Set(regs.map(\.fecha))).sorted(by: >)
        ForEach(dias, id: \.self) { d in
            TituloSeccion(texto: d == estado.hoy ? "Hoy" : Fecha.larga(d), dato: "\(regs.filter { $0.fecha == d }.count) de 4")
            Tarjeta {
                let delDia = regs.filter { $0.fecha == d }.sorted { $0.hora < $1.hora }
                ForEach(Array(delDia.enumerated()), id: \.element.id) { i, r in
                    if i > 0 { Divisor() }
                    FilaRegistroN(registro: r)
                }
            }
        }
    }
}

struct FilaRegistroN: View {
    let registro: Registro
    var body: some View {
        let r = registro
        HStack(spacing: 12) {
            FotoComida(foto: r.foto, lado: 52, radio: 14, icono: .plan)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(r.momento.titulo).tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                    Text(r.hora).tipo(.texto(13, 600)).monospacedDigit().foregroundStyle(Color.texto2)
                }
                Text(r.descripcion).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(2)
                HStack(spacing: 6) {
                    if r.comoElPlan == true { ChipEstado(texto: "Como el plan", icono: .check, tipo: .ok, alto: 22, tamano: 11.5) }
                    if let s = r.sensacion { ChipEstado(texto: s.titulo, tipo: .loza, alto: 22, tamano: 11.5) }
                    if r.bienAhi { ChipEstado(texto: "Bien ahí", icono: .bocado, tipo: .dur, alto: 22, tamano: 11.5) }
                    if !r.revisada { ChipEstado(texto: "Sin mirar", tipo: .aviso, alto: 22, tamano: 11.5) }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pagos

private struct PagosFicha: View {
    let paciente: Paciente
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let deuda = estado.deuda(de: paciente.id)
        let pagos = estado.cobros(de: paciente.id).filter(\.pagado)
        Tarjeta(relleno: 16) {
            Etiqueta("Contrató")
            HStack {
                Text(estado.servicio(paciente.servicioId)?.nombre ?? "Consulta").tipo(.texto(17, 700)).foregroundStyle(Color.texto)
                Spacer()
                Text(Formato.plata(estado.servicio(paciente.servicioId)?.monto ?? 0)).tipo(.numero(17)).foregroundStyle(Color.titulo)
            }
            .padding(.top, 4)
        }
        TituloSeccion(texto: "Por cobrar", dato: deuda.isEmpty ? nil : Formato.plata(deuda.reduce(0) { $0 + $1.monto }))
        Tarjeta {
            if deuda.isEmpty {
                Fila { IconoCirculo(icono: .check, tono: .ok); NomSub(nombre: "Está al día", sub: "No te debe nada") }
            }
            ForEach(Array(deuda.enumerated()), id: \.element.id) { i, c in
                if i > 0 { Divisor() }
                Fila {
                    NomSub(nombre: c.concepto, sub: estado.estadoCobro(c).texto, colorSub: estado.estadoCobro(c).aviso ? .aviso : .texto2,
                           pesoSub: estado.estadoCobro(c).aviso ? 600 : 400)
                    Text(Formato.plata(c.monto)).tipo(.numero(15))
                    Boton(titulo: "Cobrar", variante: .suave, alto: .chico) { nav.hoja = .linkPago(c.id) }
                }
            }
        }
        Boton(titulo: "Cobrar otra cosa", icono: .mas, variante: .loza, alto: .medio, ancho: true) { nav.hoja = .cobrar(paciente.id) }
        TituloSeccion(texto: "Pagó", dato: "\(pagos.count)")
        Tarjeta {
            if pagos.isEmpty { Fila { NomSub(nombre: "Todavía no hay pagos", sub: "Aparecen acá apenas paga") } }
            ForEach(Array(pagos.enumerated()), id: \.element.id) { i, c in
                if i > 0 { Divisor() }
                Fila(alto: 56) {
                    NomSub(nombre: c.concepto, sub: "\(Fecha.diaMes(c.pagadoEl ?? c.fecha)) · \(c.medio?.rawValue ?? "")")
                    Text(Formato.plata(c.monto)).tipo(.numero(15)).foregroundStyle(Color.texto)
                }
            }
        }
    }
}

// MARK: - Notas

private struct NotasFicha: View {
    let paciente: Paciente
    @Environment(Estado.self) private var estado
    @State private var nueva = ""
    @State private var confirmarAlta = false

    var body: some View {
        CampoN(etiqueta: "Nota nueva", texto: $nueva, prompt: "Lo que charlaron hoy, lo que querés probar…", multilinea: true)
        Boton(titulo: "Guardar nota", variante: .prim, alto: .medio, ancho: true, habilitado: !nueva.trimmingCharacters(in: .whitespaces).isEmpty) {
            estado.agregarNota(paciente.id, nueva); nueva = ""
        }
        if paciente.notas.isEmpty {
            Tarjeta { Vacio(titulo: "Sin notas todavía", texto: "Sólo las ves vos. Sirven para la próxima consulta.", icono: .lapiz) }
        }
        ForEach(paciente.notas) { n in
            Tarjeta(relleno: 16) {
                Etiqueta(Fecha.larga(n.fecha))
                Text(n.texto).tipo(.texto(15, 400)).foregroundStyle(Color.texto).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            }
        }
        TituloSeccion(texto: "Datos")
        Tarjeta {
            Fila(alto: 52) { IconoVista(.wa, tamano: 20).foregroundStyle(Color.whatsapp); NomSub(nombre: paciente.telefono, sub: "WhatsApp") }
            Divisor()
            Fila(alto: 52) { IconoVista(.mensaje, tamano: 20).foregroundStyle(Color.texto2); NomSub(nombre: paciente.email, sub: "Correo") }
            Divisor()
            Fila(alto: 52) { IconoVista(.turno, tamano: 20).foregroundStyle(Color.texto2); NomSub(nombre: Fecha.larga(paciente.desde), sub: "Se atiende desde") }
        }
        Boton(titulo: paciente.estado == .activo ? "Pausar o dar de alta" : "Volver a activo", variante: paciente.estado == .activo ? .peligro : .suave,
              alto: .medio, ancho: true) {
            if paciente.estado == .activo { confirmarAlta = true } else {
                var p = paciente; p.estado = .activo; estado.guardarPaciente(p, aviso: "\(p.primerNombre) volvió a activo.")
            }
        }
        .confirmationDialog("¿Qué hacemos con \(paciente.primerNombre)?", isPresented: $confirmarAlta, titleVisibility: .visible) {
            Button("Pausar (vuelve cuando quiera)") { var p = paciente; p.estado = .pausado; estado.guardarPaciente(p, aviso: "\(p.primerNombre) quedó en pausa.") }
            Button("Dar de alta", role: .destructive) { var p = paciente; p.estado = .alta; estado.guardarPaciente(p, aviso: "Alta de \(p.primerNombre). ¡Bien ahí!") }
            Button("Volver", role: .cancel) {}
        } message: {
            Text("No se borra nada: su historia queda guardada.")
        }
    }
}
