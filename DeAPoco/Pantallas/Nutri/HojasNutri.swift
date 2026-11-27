import SwiftUI

/// Esqueleto de una hoja: crema, cruz para cerrar, título Nunito, cuerpo con scroll y un pie fijo.
struct HojaBaseN<Cuerpo: View, PieC: View>: View {
    let titulo: String
    var bajada: String? = nil
    @ViewBuilder var cuerpo: () -> Cuerpo
    @ViewBuilder var pie: () -> PieC
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { Haptico.seleccion(); cerrar() } label: {
                    IconoVista(.x, tamano: 20).foregroundStyle(Color.texto2)
                        .frame(width: 36, height: 36).background(Color.superficie2, in: Circle())
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("Cerrar")
            }
            .padding(.horizontal, 12).padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Titulo(titulo, tamano: 28)
                    if let bajada {
                        Text(bajada).tipo(.texto(15, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
                    }
                    cuerpo().padding(.top, 4)
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            pie()
        }
        .background(Color.fondo.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radio.hoja)
    }
}

extension HojaBaseN where PieC == EmptyView {
    init(titulo: String, bajada: String? = nil, @ViewBuilder cuerpo: @escaping () -> Cuerpo) {
        self.titulo = titulo; self.bajada = bajada; self.cuerpo = cuerpo; self.pie = { EmptyView() }
    }
}

/// El pie de una hoja: un botón grande (y otro opcional).
struct PieHojaN<Contenido: View>: View {
    @ViewBuilder var contenido: () -> Contenido
    var body: some View {
        VStack(spacing: 8) { contenido() }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.fondo.shadow(color: Color.salvia.opacity(0.08), radius: 8, y: -6).ignoresSafeArea())
    }
}

/// Campo de texto del diseño (.campo-l): blanco, borde salvia-200, 48 de alto.
struct CampoN: View {
    let etiqueta: String
    @Binding var texto: String
    var prompt: String = ""
    var icono: Icono? = nil
    var teclado: UIKeyboardType = .default
    var multilinea = false
    @FocusState private var foco: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !etiqueta.isEmpty { Etiqueta(etiqueta) }
            HStack(spacing: 8) {
                if let icono { IconoVista(icono, tamano: 20).foregroundStyle(Color.texto2) }
                TextField("", text: $texto, prompt: Text(prompt).foregroundColor(.salvia400), axis: multilinea ? .vertical : .horizontal)
                    .font(Estilo.texto(15, 400).font())
                    .foregroundStyle(Color.texto)
                    .keyboardType(teclado)
                    .lineLimit(multilinea ? 3...6 : 1...1)
                    .focused($foco)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, multilinea ? 12 : 0)
            .frame(minHeight: 48)
            .background(Color.superficie, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous)
                .strokeBorder(foco ? Color.marca : Color.borde, lineWidth: foco ? 2 : 1))
            .accessibilityLabel(etiqueta.isEmpty ? prompt : etiqueta)
        }
    }
}

/// Elegir un paciente de la lista (con búsqueda).
struct SelectorPacienteN: View {
    @Binding var elegido: String?
    @Environment(Estado.self) private var estado
    @State private var busca = ""

    var body: some View {
        let lista = estado.pacientesActivos.filter { busca.isEmpty || $0.nombre.localizedCaseInsensitiveContains(busca) }
        VStack(alignment: .leading, spacing: 8) {
            CampoN(etiqueta: "Paciente", texto: $busca, prompt: "Buscar por nombre", icono: .buscar)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(lista.prefix(20)) { p in
                        let on = elegido == p.id
                        Button {
                            Haptico.seleccion()
                            withAnimation(.snappy(duration: 0.2)) { elegido = p.id }
                        } label: {
                            VStack(spacing: 6) {
                                Avatar(foto: p.foto, iniciales: p.iniciales, tono: p.tono, tamano: 48,
                                       anillo: on ? Color.marca : nil, anilloAncho: 2.5)
                                Text(p.primerNombre).tipo(.texto(12.5, on ? 700 : 600)).foregroundStyle(on ? Color.titulo : Color.texto2).lineLimit(1)
                            }
                            .frame(width: 64)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(Apretable())
                        .accessibilityLabel(p.nombre)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                    if lista.isEmpty {
                        Text("No hay nadie con ese nombre.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Dar un turno

struct HojaDarTurno: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var pacienteId: String?
    @State private var fecha: String
    @State private var hora: String?
    @State private var modalidad: Modalidad = .consultorio
    @State private var primeraVez = false

    init(pacienteId: String?, fecha: String?, hora: String?) {
        _pacienteId = State(initialValue: pacienteId)
        _fecha = State(initialValue: fecha ?? DatosDeMuestra.hoy)
        _hora = State(initialValue: hora)
    }

    var body: some View {
        HojaBaseN(titulo: "Dar un turno", bajada: "Le llega por WhatsApp para que lo confirme.") {
            SelectorPacienteN(elegido: $pacienteId)
            ElegirDiaYHoraN(fecha: $fecha, hora: $hora)
            Etiqueta("Cómo").padding(.top, 4)
            Pastillas(opciones: Modalidad.allCases.map { ($0, $0.titulo) }, elegida: $modalidad)
            Tarjeta {
                Fila(alto: 56) {
                    NomSub(nombre: "Primera consulta", sub: "Una hora, \(Formato.plata(estado.servicio("primera")?.monto ?? 65_000))")
                    Interruptor(prendido: $primeraVez, etiqueta: "Primera consulta")
                }
            }
        } pie: {
            PieHojaN {
                Boton(titulo: textoBoton, variante: .prim, alto: .alto, ancho: true, habilitado: pacienteId != nil && hora != nil) {
                    guard let p = pacienteId, let h = hora else { return }
                    estado.darTurno(pacienteId: p, fecha: fecha, hora: h, modalidad: modalidad, tipo: primeraVez ? "Primera vez" : "Control")
                    cerrar()
                }
            }
        }
    }

    private var textoBoton: String {
        guard let h = hora else { return "Elegí un horario" }
        let n = estado.paciente(pacienteId)?.primerNombre
        return "Darle el \(Fecha.diaCorto(fecha)) \(Fecha.dia(fecha)) a las \(h)\(n.map { " a \($0)" } ?? "")"
    }
}

/// Los próximos 14 días y los horarios libres del día elegido.
struct ElegirDiaYHoraN: View {
    @Binding var fecha: String
    @Binding var hora: String?
    @Environment(Estado.self) private var estado

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Etiqueta("Día")
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(0..<21, id: \.self) { i in
                        let f = Fecha.sumar(i, a: estado.hoy)
                        let on = f == fecha
                        let libres = estado.libres(en: f).count
                        Button {
                            Haptico.seleccion()
                            withAnimation(.snappy(duration: 0.2)) { fecha = f; hora = nil }
                        } label: {
                            VStack(spacing: 2) {
                                Text(Fecha.diaCorto(f)).tipo(.texto(12, 600))
                                Text("\(Fecha.dia(f))").tipo(.numero(17))
                                Text(libres == 0 ? "—" : "\(libres)").tipo(.texto(11, 600)).opacity(0.8)
                            }
                            .foregroundStyle(on ? Color.sobreMarca : (libres == 0 ? Color.salvia400 : Color.texto))
                            .frame(width: 48, height: 68)
                            .background(on ? Color.marca : Color.superficie2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(Apretable())
                        .disabled(libres == 0)
                        .accessibilityLabel("\(Fecha.diaLargo(f)) \(Fecha.dia(f)), \(libres) horarios libres")
                    }
                }
            }
            .scrollIndicators(.hidden)
            Etiqueta("Horario").padding(.top, 4)
            let libres = estado.libres(en: fecha)
            if libres.isEmpty {
                Text("Ese día no tenés horarios libres.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            } else {
                Fluir(espacio: 8) {
                    ForEach(libres, id: \.self) { h in
                        ChipOpcion(titulo: h, elegido: hora == h) { withAnimation(.snappy(duration: 0.2)) { hora = h } }
                    }
                }
            }
        }
    }
}

// MARK: - Ver un turno: confirmar, recordar, cambiar, cancelar, cobrar

struct HojaTurno: View {
    let turnoId: String
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @Environment(\.dismiss) private var cerrar
    @Environment(\.openURL) private var abrir
    @State private var cambiando = false
    @State private var fecha = ""
    @State private var hora: String?
    @State private var confirmarCancelar = false

    var body: some View {
        if let t = estado.turno(turnoId), let p = estado.paciente(t.pacienteId) {
            HojaBaseN(titulo: p.nombre, bajada: "\(Fecha.larga(t.fecha)) · \(t.hora) · \(t.modalidad.titulo.lowercased())") {
                Tarjeta {
                    Fila {
                        Avatar(foto: p.foto, iniciales: p.iniciales, tono: p.tono, tamano: 48)
                        NomSub(nombre: t.tipo, sub: "\(t.modalidad.titulo) · \(Formato.plata(t.monto))")
                        estadoChip(t)
                    }
                    Divisor()
                    Fila(alto: 52) {
                        IconoVista(.wa, tamano: 20).foregroundStyle(Color.whatsapp)
                        Text(t.estado == .confirmado ? "Le avisamos el día anterior por WhatsApp." : "Todavía no confirmó.")
                            .tipo(.texto(14, 400)).foregroundStyle(Color.texto)
                        Spacer()
                    }
                }
                if cambiando {
                    ElegirDiaYHoraN(fecha: $fecha, hora: $hora).transition(.opacity)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        if t.estado == .sinConfirmar {
                            AccesoN(icono: .check, titulo: "Confirmar", sub: "Me avisó por otro lado", tono: .ok) { estado.confirmarTurno(t.id) }
                            AccesoN(icono: .campana, titulo: "Recordar", sub: "Le escribimos", tono: .aviso) { estado.recordarTurnos([t.id]) }
                        }
                        AccesoN(icono: .turno, titulo: "Cambiar", sub: "Otro día u hora", tono: .az) {
                            fecha = t.fecha; hora = nil
                            withAnimation(.snappy) { cambiando = true }
                        }
                        AccesoN(icono: .pago, titulo: "Cobrar", sub: Formato.plata(t.monto), tono: .dur) { nav.hoja = .cobrar(p.id) }
                        AccesoN(icono: .persona, titulo: "Ficha", sub: "Todo de \(p.primerNombre)", tono: .az) { cerrar(); nav.abrirFicha(p.id) }
                        AccesoN(icono: .wa, titulo: "WhatsApp", sub: p.telefono, tono: .ok) {
                            if let u = estado.whatsapp(p.telefono, "Hola \(p.primerNombre), te escribo por el turno del \(Fecha.diaLargo(t.fecha)) a las \(t.hora).") { abrir(u) }
                        }
                    }
                    Boton(titulo: "Cancelar el turno", icono: .x, variante: .peligro, alto: .medio, ancho: true) { confirmarCancelar = true }
                        .padding(.top, 4)
                }
            } pie: {
                if cambiando {
                    PieHojaN {
                        Boton(titulo: hora.map { "Pasarlo al \(Fecha.diaCorto(fecha)) \(Fecha.dia(fecha)) a las \($0)" } ?? "Elegí el horario nuevo",
                              variante: .prim, alto: .alto, ancho: true, habilitado: hora != nil) {
                            if let h = hora { estado.cambiarTurno(t.id, fecha: fecha, hora: h); cerrar() }
                        }
                        Boton(titulo: "Dejarlo como estaba", variante: .texto) { withAnimation(.snappy) { cambiando = false } }
                    }
                }
            }
            .confirmationDialog("¿Cancelar el turno de \(p.primerNombre)?", isPresented: $confirmarCancelar, titleVisibility: .visible) {
                Button("Cancelar y avisarle", role: .destructive) { estado.cancelarTurno(t.id, avisarPaciente: true); cerrar() }
                Button("Cancelar sin avisar", role: .destructive) { estado.cancelarTurno(t.id, avisarPaciente: false); cerrar() }
                Button("Volver", role: .cancel) {}
            } message: {
                Text("Le ofrecemos el hueco a la lista de espera.")
            }
        } else {
            HojaBaseN(titulo: "Ese turno ya no está") {
                Vacio(titulo: "Se canceló o se movió", texto: "Mirá la agenda para ver cómo quedó.", icono: .turno)
            }
        }
    }

    @ViewBuilder private func estadoChip(_ t: Turno) -> some View {
        if estado.yaPaso(t) {
            if t.pagado == true { ChipEstado(texto: "Pagó", icono: .check, tipo: .ok) } else { ChipEstado(texto: "A cobrar", icono: .pago, tipo: .aviso) }
        } else if t.estado == .confirmado {
            ChipEstado(texto: "Confirmó", icono: .check, tipo: .ok)
        } else {
            ChipEstado(texto: "Sin confirmar", icono: .reloj, tipo: .aviso)
        }
    }
}
