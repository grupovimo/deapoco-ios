import SwiftUI

/// Agenda (p3): la semana en la banda y el día como una línea de tiempo con la línea de «ahora».
struct AgendaNutri: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var dia: String = ""

    private var elegido: String { dia.isEmpty ? estado.hoy : dia }

    var body: some View {
        PantallaBandaN(abajoBanda: 14, arribaCuerpo: 14) {
            CabeceraBanda(titulo: "Agenda", dato: Fecha.nombreMes(elegido))
            SemanaBanda(dia: Binding(get: { elegido }, set: { dia = $0 }))
        } cuerpo: {
            LineaDelDia(fecha: elegido)
            HStack(spacing: 10) {
                Boton(titulo: "Dar un turno", icono: .mas, variante: .prim, alto: .medio, ancho: true) {
                    nav.hoja = .darTurno(paciente: nil, fecha: elegido < estado.hoy ? estado.hoy : elegido, hora: nil)
                }
                if elegido != estado.hoy {
                    Boton(titulo: "Hoy", variante: .loza, alto: .medio) { withAnimation(.snappy) { dia = estado.hoy } }
                }
            }
            .padding(.top, 8)
        }
    }
}

/// La semana (.semana): lun a dom, el elegido en manteca, un punto si hay turnos. Se desliza de semana en semana.
private struct SemanaBanda: View {
    @Binding var dia: String
    @Environment(Estado.self) private var estado

    var body: some View {
        let lunes = Fecha.lunes(de: dia)
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { i in
                let f = Fecha.sumar(i, a: lunes)
                DiaSemana(fecha: f, elegido: f == dia, hayTurnos: !estado.turnos(en: f).filter { $0.pacienteId != nil }.isEmpty) {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.25)) { dia = f }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .gesture(DragGesture(minimumDistance: 30).onEnded { g in
            guard abs(g.translation.width) > abs(g.translation.height) else { return }
            Haptico.seleccion()
            withAnimation(.snappy) { dia = Fecha.sumar(g.translation.width < 0 ? 7 : -7, a: dia) }
        })
        .accessibilityAction(named: "Semana siguiente") { dia = Fecha.sumar(7, a: dia) }
        .accessibilityAction(named: "Semana anterior") { dia = Fecha.sumar(-7, a: dia) }
    }
}

private struct DiaSemana: View {
    let fecha: String
    let elegido: Bool
    let hayTurnos: Bool
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(spacing: 4) {
                Text(Fecha.diaCorto(fecha)).tipo(.texto(12, 600)).foregroundStyle(elegido ? Color.corteza : Color.sobreBanda2)
                Text("\(Fecha.dia(fecha))").tipo(.numero(18)).foregroundStyle(elegido ? Color.enlozado800 : Color.mantecaFija)
                Circle().fill(hayTurnos ? (elegido ? Color.rabanito500 : Color.mantecaFija.opacity(0.5)) : .clear).frame(width: 5, height: 5)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(elegido ? Color.mantecaFija : .clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("\(Fecha.diaLargo(fecha)) \(Fecha.dia(fecha))\(hayTurnos ? ", con turnos" : "")")
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}

/// La línea de tiempo de un día (.linea).
private struct LineaDelDia: View {
    let fecha: String
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let lista = estado.turnos(en: fecha)
        if lista.isEmpty {
            Tarjeta {
                Vacio(titulo: Fecha.diaSemana(fecha) > 5 ? "Fin de semana libre" : "Día sin turnos",
                      texto: Fecha.diaSemana(fecha) > 5 ? "Descansá. El lunes seguimos." : "Tenés todo el día para dar turnos.",
                      accion: Fecha.diaSemana(fecha) > 5 ? nil : "Dar un turno") {
                    nav.hoja = .darTurno(paciente: nil, fecha: fecha, hora: nil)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lista.enumerated()), id: \.element.id) { i, t in
                    if fecha == estado.hoy && esLineaAhora(antes: i == 0 ? nil : lista[i - 1], t) {
                        LineaAhora(hora: estado.ahora)
                    }
                    FilaTurno(turno: t)
                }
                if fecha == estado.hoy, let u = lista.last, estado.yaPaso(u) { LineaAhora(hora: estado.ahora) }
            }
        }
    }

    private func esLineaAhora(antes: Turno?, _ t: Turno) -> Bool {
        !estado.yaPaso(t) && (antes.map { estado.yaPaso($0) } ?? true)
    }
}

/// La línea rabanito de «ahora» (.ahora-l).
private struct LineaAhora: View {
    let hora: String
    var body: some View {
        HStack(spacing: 10) {
            Text(hora).tipo(.texto(12, 700)).monospacedDigit().foregroundStyle(Color.acentoTexto).frame(width: 50, alignment: .leading)
            Rectangle().fill(Color.rabanito500).frame(height: 2)
                .overlay(alignment: .leading) { Circle().fill(Color.rabanito500).frame(width: 10, height: 10).offset(x: -5) }
        }
        .padding(.vertical, -2)
        .accessibilityLabel("Ahora, \(hora)")
    }
}

/// Un turno en la línea (.tl): hora a la izquierda, tarjeta a la derecha.
private struct FilaTurno: View {
    let turno: Turno
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let hecho = estado.yaPaso(turno)
        let ahora = estado.proximoTurno?.id == turno.id
        HStack(alignment: .top, spacing: 10) {
            Text(turno.hora).tipo(.texto(14, 600)).monospacedDigit().foregroundStyle(hecho ? Color.corteza : Color.texto2)
                .frame(width: 50, alignment: .leading).padding(.top, 14)
            Button {
                Haptico.seleccion()
                nav.hoja = turno.pacienteId == nil ? .darTurno(paciente: nil, fecha: turno.fecha, hora: turno.hora) : .turno(turno.id)
            } label: {
                TarjetaTurno(turno: turno, hecho: hecho, ahora: ahora)
            }
            .buttonStyle(Apretable())
        }
    }
}

private struct TarjetaTurno: View {
    let turno: Turno
    let hecho: Bool
    let ahora: Bool
    @Environment(Estado.self) private var estado
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        let p = estado.paciente(turno.pacienteId)
        HStack(spacing: 10) {
            if let p, !hecho { Avatar(foto: p.foto, iniciales: p.iniciales, tono: p.tono, tamano: 32) }
            VStack(alignment: .leading, spacing: 2) {
                Text(p?.nombre ?? "Libre, 1 hora").tipo(.texto(15, 600))
                    .foregroundStyle(hecho || p == nil ? Color.texto3 : Color.texto).lineLimit(1)
                if p == nil {
                    Text("\(estado.nutri.espera.count) en lista de espera").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                } else {
                    HStack(spacing: 4) {
                        IconoVista(turno.modalidad.icono, tamano: 14)
                        Text(turno.tipo == "Primera vez" ? "Primera vez" : turno.modalidad.titulo).tipo(.texto(13, 400))
                    }
                    .foregroundStyle(Color.texto2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            chip(p == nil)
        }
        .padding(.vertical, 12)
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .background(fondo(libre: p == nil), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { borde(libre: p == nil) }
        .modifier(SombraTurno(activa: !hecho && p != nil && esquema != .dark, ahora: ahora))
        .contentShape(Rectangle())
    }

    @ViewBuilder private func chip(_ libre: Bool) -> some View {
        if libre {
            Text("Ofrecer").tipo(.texto(14, 600)).foregroundStyle(Color.sobreSuave)
                .padding(.horizontal, 12).frame(height: 36).background(Color.suave, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onTapGesture { estado.ofrecerHueco(turno.id) }
        } else if hecho {
            if turno.pagado == true { ChipEstado(texto: "Pagó", icono: .check, tipo: .ok) }
            else { ChipEstado(texto: "A cobrar", icono: .pago, tipo: .aviso) }
        } else if turno.estado == .confirmado {
            ChipEstado(texto: "Confirmó", icono: .check, tipo: .ok)
        } else {
            ChipEstado(texto: "Sin confirmar", icono: .reloj, tipo: .aviso)
        }
    }

    private func fondo(libre: Bool) -> Color { hecho || libre ? .clear : .superficie }

    @ViewBuilder private func borde(libre: Bool) -> some View {
        let forma = RoundedRectangle(cornerRadius: 18, style: .continuous)
        if libre {
            forma.strokeBorder(esquema == .dark ? Color(hex: 0x2C3C60) : Color.manteca300, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        } else if ahora {
            forma.strokeBorder(Color.marca, lineWidth: 2)
        } else if hecho || esquema == .dark {
            forma.strokeBorder(Color.borde, lineWidth: 1)
        }
    }
}

private struct SombraTurno: ViewModifier {
    let activa: Bool
    let ahora: Bool
    func body(content: Content) -> some View {
        if activa {
            content
                .shadow(color: (ahora ? Color.enlozado800.opacity(0.14) : Color.corteza.opacity(0.06)), radius: ahora ? 12 : 9, y: ahora ? 10 : 8)
                .shadow(color: Color.corteza.opacity(0.08), radius: 1, y: 1)
        } else {
            content
        }
    }
}
