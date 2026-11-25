import SwiftUI

/// Cobros (p7): lo cobrado del mes con la dona por medio de pago, lo que falta y tus precios.
struct CobrosNutri: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var todos = false

    var body: some View {
        PantallaBandaN(abajoBanda: 20) {
            CabeceraBanda(titulo: "Cobros", dato: Fecha.nombreMes(estado.hoy))
            TopeCobros()
            Leyenda()
        } cuerpo: {
            PorCobrar(todos: $todos)
            TituloSeccion(texto: "Tus precios", dato: "Editar\u{00A0}›") { nav.abrir(.precios) }
            Tarjeta {
                ForEach(Array(estado.nutri.servicios.enumerated()), id: \.element.id) { i, s in
                    if i > 0 { Divisor() }
                    Fila(alto: 52, vertical: 10) {
                        NomSub(nombre: s.nombre, sub: s.detalle)
                        Text(Formato.plata(s.monto)).tipo(.texto(15, 700)).monospacedDigit().foregroundStyle(Color.texto)
                    }
                }
            }
            PagosDelMes()
        }
    }
}

/// Cobrado, lo que falta y la dona (.cobro-top).
private struct TopeCobros: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let deudores = Set(estado.porCobrar.map(\.pacienteId)).count
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Etiqueta("Cobrado", color: .sobreBanda2)
                Text(Formato.plata(estado.cobradoMes)).tipo(.numero(36)).foregroundStyle(Color.mantecaFija).padding(.top, 6)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .contentTransition(.numericText(value: Double(estado.cobradoMes)))
                Group {
                    if estado.faltaCobrar > 0 {
                        Text("Faltan ") + Text(Formato.plata(estado.faltaCobrar)).font(Estilo.texto(14, 700).font()).foregroundColor(.durazno)
                            + Text(" de \(deudores) \(deudores == 1 ? "paciente" : "pacientes")")
                    } else {
                        Text("Todos pagaron. Bien ahí.")
                    }
                }
                .tipo(.texto(14, 400)).foregroundStyle(Color.sobreBanda2).padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Dona(segmentos: [(estado.pagosPorMedio(.mercadoPago), .durazno), (estado.pagosPorMedio(.transferencia), .enlozado300),
                             (estado.pagosPorMedio(.efectivo), .mantecaFija)],
                 porcentaje: estado.porcentajeCobrado)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 14)
    }
}

private struct Leyenda: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        HStack(spacing: 14) {
            item(.durazno, "Mercado Pago", estado.pagosPorMedio(.mercadoPago))
            item(.enlozado300, "Transferencia", estado.pagosPorMedio(.transferencia))
            item(.mantecaFija, "Efectivo", estado.pagosPorMedio(.efectivo))
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }
    private func item(_ c: Color, _ t: String, _ n: Int) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 10, height: 10)
            Text(t).tipo(.texto(13, 600)).foregroundStyle(Color.enlozado100).lineLimit(1)
            Text("\(n)").tipo(.texto(13, 700)).monospacedDigit().foregroundStyle(.white)
        }
        .fixedSize()
    }
}

/// Lo que falta cobrar, con el link de pago por WhatsApp.
private struct PorCobrar: View {
    @Binding var todos: Bool
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    /// Lo de hoy primero, después lo que vence pronto, después lo más reciente.
    private var lista: [Cobro] {
        estado.porCobrar.sorted { a, b in
            func numero(_ f: String) -> Int { Int(f.replacingOccurrences(of: "-", with: "")) ?? 0 }
            func clave(_ c: Cobro) -> (Int, Int) {
                if c.fecha == estado.hoy { return (0, 0) }
                if let v = c.vence, Fecha.dias(entre: estado.hoy, y: v) <= 2 { return (1, numero(v)) }
                return (2, -numero(c.fecha))
            }
            return clave(a) < clave(b)
        }
    }

    var body: some View {
        let lista = self.lista
        TituloSeccion(texto: "Por cobrar", dato: lista.isEmpty ? nil : Formato.plata(estado.faltaCobrar))
        if lista.isEmpty {
            Tarjeta { Vacio(titulo: "Nadie te debe", texto: "Todo cobrado este mes. Bien ahí.", accion: "Cobrar algo nuevo") { nav.hoja = .cobrar(nil) } }
        } else {
            Tarjeta {
                let visibles = todos ? lista : Array(lista.prefix(3))
                ForEach(Array(visibles.enumerated()), id: \.element.id) { i, c in
                    if i > 0 { Divisor() }
                    FilaCobro(cobro: c)
                }
                if lista.count > 3 {
                    Divisor()
                    Button { Haptico.seleccion(); withAnimation(.snappy) { todos.toggle() } } label: {
                        HStack {
                            Text(todos ? "Ver menos" : "Ver los otros \(lista.count - 3)").tipo(.texto(14, 700))
                            IconoVista(.abajo, tamano: 16).rotationEffect(.degrees(todos ? 180 : 0))
                        }
                        .foregroundStyle(Color.enlace).frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                    }
                    .buttonStyle(Apretable())
                }
            }
            Boton(titulo: "Recordar a \(lista.count == 1 ? "1" : "los \(lista.count)")", icono: .wa, variante: .prim, alto: .medio, ancho: true,
                  colorIcono: .durazno) { estado.recordarCobros(lista.map(\.id)) }
        }
        Boton(titulo: "Cobrar algo", icono: .pago, variante: .suave, alto: .medio, ancho: true) { nav.hoja = .cobrar(nil) }
    }
}

private struct FilaCobro: View {
    let cobro: Cobro
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let p = estado.paciente(cobro.pacienteId)
        let e = estado.estadoCobro(cobro)
        HStack(spacing: 12) {
            Button { Haptico.seleccion(); nav.hoja = .linkPago(cobro.id) } label: {
                HStack(spacing: 12) {
                    Avatar(foto: p?.foto, iniciales: p?.iniciales ?? "", tono: p?.tono ?? .durazno)
                    NomSub(nombre: p?.nombre ?? "Paciente", sub: e.texto, colorSub: e.aviso ? .aviso : .texto2, pesoSub: e.aviso ? 600 : 400)
                    Text(Formato.plata(cobro.monto)).tipo(.texto(15, 700)).monospacedDigit().foregroundStyle(Color.texto)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
            BotonWA(titulo: "", etiqueta: "Mandar link de pago por WhatsApp a \(p?.primerNombre ?? "")") { estado.recordarCobros([cobro.id]) }
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .frame(minHeight: 64)
    }
}

/// Los pagos que entraron este mes.
private struct PagosDelMes: View {
    @Environment(Estado.self) private var estado
    @State private var todos = false

    var body: some View {
        let pagos = estado.pagadosDelMes.sorted { ($0.pagadoEl ?? "") > ($1.pagadoEl ?? "") }
        TituloSeccion(texto: "Entraron", dato: "\(pagos.count) pagos")
        Tarjeta {
            ForEach(Array((todos ? pagos : Array(pagos.prefix(5))).enumerated()), id: \.element.id) { i, c in
                if i > 0 { Divisor() }
                let p = estado.paciente(c.pacienteId)
                Fila(alto: 56, vertical: 10) {
                    Avatar(foto: p?.foto, iniciales: p?.iniciales ?? "", tono: p?.tono ?? .durazno, tamano: 32)
                    NomSub(nombre: p?.nombre ?? "", sub: "\(Fecha.corta(c.pagadoEl ?? c.fecha)) · \(c.medio?.rawValue ?? "")")
                    Text(Formato.plata(c.monto)).tipo(.texto(15, 600)).monospacedDigit().foregroundStyle(Color.texto)
                }
            }
            if pagos.count > 5 {
                Divisor()
                Button { Haptico.seleccion(); withAnimation(.snappy) { todos.toggle() } } label: {
                    Text(todos ? "Ver menos" : "Ver los \(pagos.count)").tipo(.texto(14, 700)).foregroundStyle(Color.enlace)
                        .frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
            }
        }
    }
}

// MARK: - Cobrar

/// Cobrar a un paciente: qué, cuánto y cómo (link de Mercado Pago o registrar un pago a mano).
struct HojaCobrar: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @Environment(\.dismiss) private var cerrar
    @State private var pacienteId: String?
    @State private var servicioId = "control"
    @State private var aMano = false
    @State private var medio: MedioPago = .transferencia

    init(pacienteId: String?) { _pacienteId = State(initialValue: pacienteId) }

    var body: some View {
        let deuda = pacienteId.map { estado.deuda(de: $0) } ?? []
        HojaBaseN(titulo: "Cobrar", bajada: "Le llega un link de Mercado Pago por WhatsApp. O anotás que te pagó.") {
            SelectorPacienteN(elegido: $pacienteId)
            if !deuda.isEmpty {
                Etiqueta("Ya te debe").padding(.top, 4)
                Tarjeta {
                    ForEach(Array(deuda.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Divisor() }
                        Fila(alto: 56) {
                            NomSub(nombre: c.concepto, sub: estado.estadoCobro(c).texto)
                            Text(Formato.plata(c.monto)).tipo(.numero(15))
                            Boton(titulo: "Cobrar", variante: .suave, alto: .chico) { nav.hoja = .linkPago(c.id) }
                        }
                    }
                }
            }
            Etiqueta(deuda.isEmpty ? "Qué cobrás" : "O algo nuevo").padding(.top, 4)
            VStack(spacing: 8) {
                ForEach(estado.nutri.servicios) { s in OpcionServicioN(servicio: s, elegido: servicioId == s.id) { servicioId = s.id } }
            }
            Tarjeta {
                Fila(alto: 56) {
                    NomSub(nombre: "Ya me pagó", sub: "Anotalo sin mandar link")
                    Interruptor(prendido: $aMano, etiqueta: "Ya me pagó")
                }
            }
            if aMano {
                Pastillas(opciones: [(MedioPago.transferencia, "Transferencia"), (.efectivo, "Efectivo"), (.mercadoPago, "Mercado Pago")], elegida: $medio)
            }
        } pie: {
            PieHojaN {
                Boton(titulo: textoBoton, icono: aMano ? .check : .wa, variante: .prim, alto: .alto, ancho: true,
                      colorIcono: aMano ? nil : .durazno, habilitado: pacienteId != nil) { cobrar() }
            }
        }
    }

    private var monto: Int { estado.servicio(servicioId).map { $0.meses > 0 ? $0.precioMes : $0.monto } ?? 0 }

    private var textoBoton: String {
        aMano ? "Anotar pago de \(Formato.plata(monto))" : "Mandar link de \(Formato.plata(monto))"
    }

    private func cobrar() {
        guard let p = pacienteId, let s = estado.servicio(servicioId) else { return }
        let c = estado.crearCobro(pacienteId: p, concepto: s.meses > 0 ? "\(s.nombre) · cuota 1" : s.nombre, monto: monto)
        if aMano { estado.registrarPago(c.id, medio: medio) } else { estado.recordarCobros([c.id]) }
        cerrar()
    }
}

/// Un cobro pendiente: el link de pago para mandar o copiar, y registrar el pago a mano.
struct HojaLinkPago: View {
    let cobroId: String
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var medio: MedioPago = .transferencia

    var body: some View {
        if let c = estado.cobro(cobroId), let p = estado.paciente(c.pacienteId) {
            let link = "mpago.la/\(String(c.id.suffix(6)).replacingOccurrences(of: "-", with: ""))"
            HojaBaseN(titulo: "Cobrarle a \(p.primerNombre)", bajada: "\(c.concepto) · \(estado.estadoCobro(c).texto.lowercased())") {
                Tarjeta(relleno: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Etiqueta("Hoy paga")
                            Text(Formato.plata(c.monto)).tipo(.numero(32)).foregroundStyle(Color.titulo)
                        }
                        Spacer()
                        LogoMP(ancho: 40)
                    }
                    Divisor().padding(.vertical, 12)
                    HStack(spacing: 8) {
                        IconoVista(.link, tamano: 16).foregroundStyle(Color.texto2)
                        Text(link).tipo(.texto(14, 600)).foregroundStyle(Color.texto)
                        Spacer()
                        Boton(titulo: "Copiar", icono: .copiar, variante: .loza, alto: .chico) {
                            UIPasteboard.general.string = "https://\(link)"
                            estado.avisar("Link copiado.")
                        }
                    }
                }
                Boton(titulo: "Mandárselo por WhatsApp", icono: .wa, variante: .prim, alto: .alto, ancho: true, colorIcono: .durazno) {
                    estado.recordarCobros([c.id]); cerrar()
                }
                Etiqueta("¿Te pagó por otro lado?").padding(.top, 12)
                Pastillas(opciones: [(MedioPago.transferencia, "Transferencia"), (.efectivo, "Efectivo"), (.mercadoPago, "Mercado Pago")], elegida: $medio)
                Boton(titulo: "Anotar que pagó", icono: .check, variante: .suave, alto: .medio, ancho: true) {
                    estado.registrarPago(c.id, medio: medio); cerrar()
                }
            }
        } else {
            HojaBaseN(titulo: "Ya está cobrado") {
                Vacio(titulo: "Este cobro ya entró", texto: "Lo ves en «Entraron».", icono: .check)
            }
        }
    }
}

// MARK: - Precios

/// Tus precios: se editan de a $1.000, se suman servicios nuevos y se guardan.
struct EditarPrecios: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var servicios: [Servicio] = []
    @State private var avisarAumento = true

    var body: some View {
        PantallaClaraN(abajo: 120) {
            NavAtras(atras: "Cobros")
            Titulo("Tus precios", tamano: 30).padding(.horizontal, Espacio.margen)
            Text("Se ven en tu página y en el link de pago. Los planes se cobran por mes.")
                .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.horizontal, Espacio.margen)
            VStack(spacing: 10) {
                ForEach($servicios) { $s in FilaPrecio(servicio: $s) }
                Boton(titulo: "Sumar un servicio", icono: .mas, variante: .suave, alto: .medio, ancho: true) {
                    withAnimation(.snappy) {
                        servicios.append(Servicio(id: "s-\(UUID().uuidString.prefix(4))", nombre: "Consulta familiar", detalle: "Hasta 3 personas", monto: 70_000))
                    }
                }
                Tarjeta {
                    Fila(alto: 60) {
                        NomSub(nombre: "Avisarles del cambio", sub: "Un mensaje un mes antes, por WhatsApp", lineas: 2)
                        Interruptor(prendido: $avisarAumento, etiqueta: "Avisarles del cambio")
                    }
                }
            }
            .padding(.horizontal, Espacio.margen)
        }
        .safeAreaInset(edge: .bottom) {
            Pie {
                Boton(titulo: "Guardar precios", variante: .prim, alto: .alto, ancho: true, habilitado: servicios != estado.nutri.servicios) {
                    estado.guardarServicios(servicios)
                    cerrar()
                }
            }
        }
        .onAppear { if servicios.isEmpty { servicios = estado.nutri.servicios } }
    }
}

private struct FilaPrecio: View {
    @Binding var servicio: Servicio
    var body: some View {
        Tarjeta(relleno: 16) {
            TextField("Nombre", text: $servicio.nombre).font(Estilo.texto(16, 700).font()).foregroundStyle(Color.texto)
            TextField("Detalle", text: $servicio.detalle).font(Estilo.texto(13, 400).font()).foregroundStyle(Color.texto2).padding(.top, 2)
            HStack(spacing: 8) {
                Text(Formato.plata(servicio.monto)).tipo(.numero(24)).foregroundStyle(Color.titulo)
                    .contentTransition(.numericText(value: Double(servicio.monto)))
                if servicio.meses > 0 {
                    Text("\(Formato.plata(servicio.precioMes))/mes").tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                }
                Spacer()
                Redondo(icono: .menos, variante: .claro, tamano: 40, tamanoIcono: 20, etiqueta: "Bajar mil pesos") {
                    withAnimation(.snappy) { servicio.monto = max(0, servicio.monto - 1_000) }
                }
                Redondo(icono: .mas, variante: .marca, tamano: 40, tamanoIcono: 20, etiqueta: "Subir mil pesos") {
                    withAnimation(.snappy) { servicio.monto += 1_000 }
                }
            }
            .padding(.top, 10)
        }
    }
}
