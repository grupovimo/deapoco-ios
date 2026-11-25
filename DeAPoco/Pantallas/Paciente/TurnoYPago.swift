import SwiftUI

/// Tu próxima consulta (p14): el turno con confirmar, cambiar o cancelar; y el pago como carrito:
/// Consulta o Plan 3 meses, el ticket con «Hoy pagás» y «Después…», y Pagar.
struct TurnoYPago: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @State private var elegido = "plan3"
    @State private var preguntarCancelar = false

    var body: some View {
        let pagado = estado.pagoDeHoy
        ZStack(alignment: .bottom) {
            PantallaPaciente(abajo: pagado == nil && estado.paciente.contratado == nil ? 150 : 40) {
                NavAtras(atras: "Hoy")
                Cabecera(titulo: "Tu próxima consulta", tamano: 30).padding(.top, -6)
            } cuerpo: {
                if let t = estado.paciente.turno {
                    TarjetaTurno(turno: t, cambiar: { nav.hoja = .turno(cambiar: true) }, cancelar: { preguntarCancelar = true })
                } else {
                    Tarjeta {
                        Vacio(titulo: "No tenés turno todavía", texto: "Elegí día y hora con \(estado.paciente.nutri.nombre). Te avisamos un día antes.",
                              accion: "Sacar turno", icono: .turno) { nav.hoja = .turno(cambiar: false) }
                    }
                }
                if let pagado {
                    PagoListo(cobro: pagado, turno: estado.paciente.turno)
                } else if let c = estado.paciente.contratado, let s = estado.paciente.servicios.first(where: { $0.id == c }) {
                    PlanVigente(servicio: s)
                } else {
                    OpcionesPago(elegido: $elegido)
                    if let s = estado.paciente.servicios.first(where: { $0.id == elegido }) {
                        Ticket(servicio: s, nutri: estado.paciente.nutri.nombre, desde: estado.paciente.turno?.fecha ?? estado.paciente.hoy)
                    }
                }
            }
            if pagado == nil && estado.paciente.contratado == nil, let s = estado.paciente.servicios.first(where: { $0.id == elegido }) {
                Pie {
                    VStack(spacing: 10) {
                        Boton(titulo: "Pagar \(Formato.plata(s.precioMes))", variante: .prim, alto: .alto, ancho: true) { nav.hoja = .pagar(s.id) }
                        Text(s.meses > 0 ? "Se cobra solo cada mes. Lo cancelás cuando quieras." : "Pagás una vez. Si no podés ir, avisá un día antes.")
                            .tipo(.texto(12, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
                    }
                }
            }
        }
        .confirmationDialog("¿Cancelar el turno?", isPresented: $preguntarCancelar, titleVisibility: .visible) {
            Button("Cancelar el turno", role: .destructive) { estado.cancelarTurnoPaciente() }
            Button("Mejor lo cambio") { nav.hoja = .turno(cambiar: true) }
            Button("Volver", role: .cancel) {}
        } message: {
            Text("Le avisamos a \(estado.paciente.nutri.nombre). Si lo pagaste, queda a favor para el próximo.")
        }
    }
}

/// El turno (.turno-g): el día en un cuadrado enlozado, la hora, la modalidad y el estado.
private struct TarjetaTurno: View {
    let turno: Turno
    var cambiar: () -> Void
    var cancelar: () -> Void
    @Environment(Estado.self) private var estado

    var body: some View {
        Tarjeta {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(Fecha.diaCorto(turno.fecha).uppercased()).font(Estilo.texto(11, 700).font()).tracking(0.66).foregroundStyle(Color.durazno)
                    Text("\(Fecha.dia(turno.fecha))").font(Estilo.numero(28).font()).foregroundStyle(Color.mantecaFija)
                }
                .frame(width: 64, height: 70)
                .background(Color.enlozado800, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(turno.hora) con \(estado.paciente.nutri.nombre)").tipo(.texto(17, 700)).foregroundStyle(Color.texto)
                    Text("\(turno.modalidad.titulo) · \(turno.duracion) minutos").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    if turno.estado == .confirmado {
                        ChipEstado(texto: "Confirmado", icono: .check, tipo: .ok).padding(.top, 6)
                    } else {
                        HStack(spacing: 8) {
                            ChipEstado(texto: "Sin confirmar", icono: .reloj, tipo: .aviso)
                            Boton(titulo: "Confirmar", variante: .prim, alto: .chico) { estado.confirmarTurnoPaciente() }
                        }
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .accessibilityElement(children: .combine)
            HStack(spacing: 12) {
                IconoVista(.wa, tamano: 20).foregroundStyle(Color.whatsapp)
                Text("Te avisamos el \(Fecha.diaLargo(Fecha.sumar(-1, a: turno.fecha))) por WhatsApp.")
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Menu {
                    Button("Cambiar día u hora", action: cambiar)
                    if turno.modalidad == .enLinea {
                        Button("Agendar en el calendario") { estado.avisar("Listo, quedó en tu calendario.") }
                    }
                    Button("Cancelar el turno", role: .destructive, action: cancelar)
                } label: {
                    Text("Cambiar").tipo(.texto(14, 700)).foregroundStyle(Color.enlace).frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
        }
    }
}

/// Las dos opciones (.opc): Consulta y Plan 3 meses, con «Ahorrás».
private struct OpcionesPago: View {
    @Binding var elegido: String
    @Environment(Estado.self) private var estado

    var body: some View {
        let servicios = estado.paciente.servicios
        let consulta = servicios.first { $0.meses == 0 }?.monto ?? 0
        HStack(alignment: .top, spacing: 10) {
            ForEach(servicios) { s in
                let on = s.id == elegido
                Button { Haptico.seleccion(); withAnimation(.snappy(duration: 0.2)) { elegido = s.id } } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(s.meses > 0 ? s.nombre : "Consulta").tipo(.texto(15, 700)).foregroundStyle(Color.texto).padding(.trailing, 24)
                        Text(Formato.plata(s.precioMes)).font(Estilo.numero(24).font()).tracking(-0.48).foregroundStyle(Color.titulo).padding(.top, 10)
                        Text(s.meses > 0 ? "por mes, \(s.controles) controles" : "Sólo este control").tipo(.texto(12.5, 400)).foregroundStyle(Color.texto2).padding(.top, 4)
                        if s.meses > 0, consulta * s.controles > s.monto {
                            ChipEstado(texto: "Ahorrás \(Formato.plata(consulta * s.controles - s.monto))", tipo: .dur).padding(.top, 8)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
                    .background(on ? Color.infoSuave : Color.superficie, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(on ? Color.marca : Color.borde, lineWidth: on ? 2.5 : 1.5))
                    .overlay(alignment: .topTrailing) {
                        ZStack {
                            if on {
                                Circle().fill(Color.marca)
                                IconoVista(.check, tamano: 14, grosor: 2.8).foregroundStyle(Color.sobreMarca)
                            } else {
                                Circle().strokeBorder(Color.bordeCampo, lineWidth: 2)
                            }
                        }
                        .frame(width: 22, height: 22).padding(12)
                    }
                }
                .buttonStyle(Apretable())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// El ticket (.ticket): qué es, qué viene después, con qué se paga y «Hoy pagás».
private struct Ticket: View {
    let servicio: Servicio
    let nutri: String
    let desde: String

    var body: some View {
        Tarjeta {
            VStack(spacing: 0) {
                linea("\(servicio.meses > 0 ? servicio.nombre : "Consulta") con \(nutri)", Formato.plata(servicio.monto))
                if servicio.meses > 1 {
                    Linea()
                    let despues = (1..<servicio.meses).map { Fecha.corta(Fecha.sumarMeses($0, a: desde)) }
                    linea("Después, el \(despues.joined(separator: " y el "))", Formato.plata(servicio.precioMes))
                }
                Linea()
                HStack {
                    Text("Con").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    Spacer()
                    HStack(spacing: 8) { LogoMP(ancho: 22); Text("Mercado Pago").tipo(.texto(14, 600)).foregroundStyle(Color.texto3) }
                }
                .padding(.vertical, 9)
                HStack(alignment: .lastTextBaseline) {
                    Etiqueta("Hoy pagás").padding(.bottom, 4)
                    Spacer()
                    Text(Formato.plata(servicio.precioMes)).font(Estilo.numero(32).font()).tracking(-0.64).foregroundStyle(Color.titulo)
                        .contentTransition(.numericText(value: Double(servicio.precioMes)))
                }
                .padding(.top, 12)
                .overlay(alignment: .top) { Rectangle().fill(Color.texto).frame(height: 1.5) }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 16)
        }
    }

    private func linea(_ t: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(t).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            Spacer()
            Text(v).tipo(.texto(14, 600)).monospacedDigit().foregroundStyle(Color.texto)
        }
        .padding(.vertical, 9)
    }
}

private struct Linea: View {
    var body: some View {
        Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3])).foregroundStyle(Color.borde).frame(height: 1)
    }
}

/// Ya pagó: la confirmación con el recibo.
private struct PagoListo: View {
    let cobro: Cobro
    let turno: Turno?
    var body: some View {
        Tarjeta(relleno: 16) {
            HStack(spacing: 12) {
                IconoCirculo(icono: .check, tono: .ok, tamano: 48, tamanoIcono: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Listo, pagaste la consulta.").tipo(.texto(17, 700)).foregroundStyle(Color.texto)
                    Text(turno.map { "Nos vemos el \(Fecha.diaLargo($0.fecha))." } ?? "Te llegó el recibo por mail.")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                }
            }
            Divisor().padding(.vertical, 12)
            HStack {
                Text(cobro.concepto).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                Spacer()
                Text(Formato.plata(cobro.monto)).tipo(.texto(14, 600)).monospacedDigit().foregroundStyle(Color.texto)
            }
            HStack {
                Text("Con").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                Spacer()
                Text(cobro.medio?.rawValue ?? "").tipo(.texto(14, 600)).foregroundStyle(Color.texto)
            }
            .padding(.top, 6)
        }
    }
}

/// Con un plan contratado: lo que está pago y cuándo se cobra lo próximo.
private struct PlanVigente: View {
    let servicio: Servicio
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        Tarjeta(relleno: 16) {
            Etiqueta("Tu plan")
            Text(servicio.nombre).tipo(.texto(17, 700)).foregroundStyle(Color.texto).padding(.top, 4)
            Text("Cuota de \(Formato.plata(servicio.precioMes)) por mes. Se cobra sola; la cancelás cuando quieras.")
                .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true).padding(.top, 2)
            Boton(titulo: "Ver tus pagos", variante: .suave, alto: .medio) { nav.empujar(.pagos) }.padding(.top, 10)
        }
    }
}

// MARK: - Sacar o cambiar el turno

/// Elegir día (los próximos diez hábiles), horario libre y modalidad.
struct HojaSacarTurno: View {
    var cambiar: Bool
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var dia: String = ""
    @State private var hora: String?
    @State private var modalidad: Modalidad = .enLinea

    var body: some View {
        let dias = estado.diasParaTurno
        let elegido = dia.isEmpty ? (estado.paciente.turno?.fecha ?? dias.first ?? estado.paciente.hoy) : dia
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    NavAtras(atras: nil, icono: .x) { cerrar() }.padding(.horizontal, -Espacio.margen)
                    Titulo(cambiar && estado.paciente.turno != nil ? "Cambiá tu turno" : "Sacá un turno", tamano: 30)
                    Text("Con \(estado.paciente.nutri.nombre). Te avisamos un día antes por WhatsApp.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2)
                    Etiqueta("Cómo").padding(.top, 6)
                    MiniSeg(opciones: [(Modalidad.enLinea, "En línea"), (.consultorio, "Consultorio")], elegida: $modalidad)
                    if modalidad == .consultorio {
                        Label(estado.paciente.nutri.lugar, systemImage: "mappin").labelStyle(.titleOnly)
                            .tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                    Etiqueta("Día").padding(.top, 6)
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(dias, id: \.self) { d in
                                let on = d == elegido
                                Button { Haptico.seleccion(); dia = d; hora = nil } label: {
                                    VStack(spacing: 2) {
                                        Text(Fecha.diaCorto(d)).tipo(.texto(12, 600)).foregroundStyle(on ? Color.sobreBanda2 : Color.texto2)
                                        Text("\(Fecha.dia(d))").font(Estilo.texto(17, 600).font()).monospacedDigit().foregroundStyle(on ? Color.mantecaFija : Color.texto)
                                    }
                                    .frame(width: 52, height: 60)
                                    .background(on ? Color.banda : Color.loza, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(Apretable())
                                .accessibilityLabel(Fecha.larga(d))
                                .accessibilityAddTraits(on ? .isSelected : [])
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                    Etiqueta("Horarios libres").padding(.top, 6)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(estado.horariosLibres(elegido), id: \.self) { h in
                            let on = h == hora
                            Button { Haptico.seleccion(); hora = h } label: {
                                Text(h).font(Estilo.texto(15, 600).font()).monospacedDigit()
                                    .foregroundStyle(on ? Color.sobreMarca : Color.texto)
                                    .frame(maxWidth: .infinity).frame(height: 44)
                                    .background(on ? Color.marca : Color.superficie, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(on ? .clear : Color.borde, lineWidth: 1))
                            }
                            .buttonStyle(Apretable())
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.bottom, 24)
            }
            Pie {
                Boton(titulo: hora.map { "Confirmar el \(Fecha.diaLargo(elegido)) \(Fecha.dia(elegido)) a las \($0)" } ?? "Elegí un horario",
                      variante: .prim, alto: .alto, ancho: true, habilitado: hora != nil) {
                    guard let hora else { return }
                    if cambiar && estado.paciente.turno != nil {
                        estado.cambiarTurnoPaciente(fecha: elegido, hora: hora)
                    } else {
                        estado.sacarTurnoPaciente(fecha: elegido, hora: hora, modalidad: modalidad)
                    }
                    cerrar()
                }
            }
        }
        .background(Color.fondo.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .onAppear { if let t = estado.paciente.turno { modalidad = t.modalidad } }
    }
}

// MARK: - Pagar con Mercado Pago

/// El paso de pago: el resumen y el botón de Mercado Pago (en la app real abre el checkout).
struct HojaPagoMP: View {
    let servicioId: String
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var medio: MedioPago = .mercadoPago
    @State private var pagando = false

    var body: some View {
        let s = estado.paciente.servicios.first { $0.id == servicioId }
        VStack(alignment: .leading, spacing: 14) {
            NavAtras(atras: nil, icono: .x) { cerrar() }.padding(.horizontal, -Espacio.margen)
            HStack(spacing: 10) { LogoMP(ancho: 40); Titulo("Pagar", tamano: 30) }
            if let s {
                Tarjeta(relleno: 16) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.meses > 0 ? "\(s.nombre) · cuota 1 de \(s.meses)" : "Consulta con \(estado.paciente.nutri.nombre)")
                                .tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                            Text("A \(estado.paciente.nutri.nombreCompleto)").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        }
                        Spacer()
                        Text(Formato.plata(s.precioMes)).font(Estilo.numero(24).font()).foregroundStyle(Color.titulo)
                    }
                }
                Etiqueta("Cómo pagás")
                Tarjeta {
                    ForEach([MedioPago.mercadoPago, .transferencia], id: \.self) { m in
                        if m == .transferencia { Divisor() }
                        Button { Haptico.seleccion(); medio = m } label: {
                            Fila(alto: 56) {
                                if m == .mercadoPago { LogoMP(ancho: 28) } else { IconoVista(.pago, tamano: 22).foregroundStyle(Color.texto2) }
                                NomSub(nombre: m == .mercadoPago ? "Mercado Pago" : "Transferencia", sub: m == .mercadoPago ? "Tarjeta, débito o dinero en cuenta" : "Al alias de \(estado.paciente.nutri.nombre)")
                                Circle().strokeBorder(medio == m ? Color.marca : Color.bordeCampo, lineWidth: medio == m ? 7 : 2).frame(width: 22, height: 22)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(medio == m ? .isSelected : [])
                    }
                }
                if s.meses > 0 {
                    Text("Las cuotas que siguen se cobran solas cada mes. Las cancelás cuando quieras desde Tus pagos.")
                        .tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Boton(titulo: pagando ? "Pagando…" : "Pagar \(Formato.plata(s.precioMes))", variante: .prim, alto: .alto, ancho: true, habilitado: !pagando) {
                    pagando = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(900))
                        estado.pagar(servicioId: s.id, medio: medio)
                        cerrar()
                    }
                }
                HStack(spacing: 6) {
                    IconoVista(.candado, tamano: 16)
                    Text("Pago protegido por Mercado Pago. De a Poco no guarda tu tarjeta.").tipo(.texto(12, 400))
                }
                .foregroundStyle(Color.texto2).frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.bottom, 12)
        .background(Color.fondo.ignoresSafeArea())
        .presentationDetents([.large])
    }
}
