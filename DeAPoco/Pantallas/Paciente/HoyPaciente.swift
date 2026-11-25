import SwiftUI

/// Hoy (p10): el plato del día, las cuatro comidas, el agua y la meta con la nutri.
struct HoyPaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav

    var body: some View {
        PantallaPaciente {
            Cabecera(fecha: estado.fechaCabeceraHoy, titulo: "Tu plan de hoy") {
                ChipRacha(dias: estado.paciente.racha) { nav.empujar(.semana) }
            }
        } cuerpo: {
            PlatoDelDia()
            ComidasDelDia()
            TarjetaAgua()
            TarjetaMeta(etiqueta: "Meta con \(estado.paciente.nutri.nombre)")
            LoTuyo()
            if let tip = estado.tip(.paciente, salto: 3) {
                TipVista(tip: tip, foto: estado.paciente.nutri.foto, etiqueta: "Tip de \(estado.paciente.nutri.nombre)")
                    .padding(.top, 4)
            }
        }
    }
}

/// La racha (.racha-chip): platito lleno y los días, en durazno-100.
struct ChipRacha: View {
    let dias: Int
    var accion: () -> Void
    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            HStack(spacing: 6) {
                Plato(partes: 7, llenas: dias > 0 ? 7 : 0, chico: true).frame(width: 30, height: 30)
                Text("\(dias)").font(Estilo.texto(17, 700).font()).monospacedDigit().foregroundStyle(Color.sobreLogro)
            }
            .padding(.leading, 6).padding(.trailing, 14)
            .frame(height: 40)
            .background(Color.logroSuave, in: Capsule())
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .padding(.top, 4)
        .accessibilityLabel("\(dias) días seguidos anotando. Ver tu semana")
    }
}

/// El plato del día (.plato-hoy): 4 partes, la que toca punteada, «2 de 4» y la frase.
private struct PlatoDelDia: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let hechas = estado.comidasHechasHoy
        Tarjeta(relleno: 16) {
            HStack(spacing: 16) {
                Plato(partes: 4, llenas: hechas, hoy: hechas < 4 ? hechas : nil, servir: true)
                    .frame(width: 128, height: 128)
                    .accessibilityLabel("\(hechas) de 4 comidas anotadas")
                VStack(alignment: .leading, spacing: 8) {
                    Numero(valor: "\(hechas)", tamano: 40, unidad: " de 4", tamanoUnidad: 17)
                        .contentTransition(.numericText(value: Double(hechas)))
                    Text(estado.fraseDelDia).tipo(.texto(15, 400)).foregroundStyle(Color.texto)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Las cuatro comidas (.com): foto o ícono, nombre y plan, y a la derecha el tilde, «Foto» o la hora.
private struct ComidasDelDia: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        Tarjeta {
            ForEach(Array(Momento.principales.enumerated()), id: \.element) { i, m in
                if i > 0 { Divisor() }
                FilaComida(momento: m, registro: estado.registroHoy(m), toca: estado.proximaComida == m,
                           plan: estado.resumenPlan(m), hora: estado.planDe(m)?.hora ?? m.horaSugerida) {
                    if let r = estado.registroHoy(m) { nav.hoja = .registro(r.id) } else { nav.cubierta = .foto(m, muestra: false) }
                }
            }
        }
    }
}

private struct FilaComida: View {
    let momento: Momento
    let registro: Registro?
    let toca: Bool
    let plan: String
    let hora: String
    var accion: () -> Void

    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            HStack(spacing: 12) {
                FotoComida(foto: registro?.foto, lado: 44, radio: 13, icono: registro == nil && !toca ? .plan : .foto)
                VStack(alignment: .leading, spacing: 0) {
                    Text(momento.titulo).tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                    Text(registro?.descripcion ?? plan).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                derecha
            }
            .padding(.vertical, 10).padding(.horizontal, 16)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(registro != nil ? "\(momento.titulo), anotado: \(registro?.descripcion ?? "")" : "\(momento.titulo): \(plan)")
        .accessibilityHint(registro != nil ? "Ver la comida" : "Sacar la foto")
    }

    @ViewBuilder private var derecha: some View {
        if registro != nil {
            IconoVista(.check, tamano: 16, grosor: 2.6).foregroundStyle(.white)
                .frame(width: 28, height: 28).background(Color.rabanito500, in: Circle())
        } else if toca {
            HStack(spacing: 8) {
                IconoVista(.foto, tamano: 16)
                Text("Foto").tipo(.texto(14, 600))
            }
            .foregroundStyle(Color.sobreMarca)
            .padding(.horizontal, 12).frame(height: 34)
            .background(Color.marca, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Text(hora.count == 4 ? "0" + hora : hora).tipo(.texto(13, 600)).monospacedDigit().foregroundStyle(Color.texto2)
        }
    }
}

/// El agua (.agua): ocho vasos; tocar uno los llena hasta ahí.
struct TarjetaAgua: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let a = estado.paciente.agua, meta = estado.paciente.aguaMeta
        Tarjeta {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Agua").tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                    Text("\(a) de \(meta) vasos").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        .contentTransition(.numericText(value: Double(a)))
                }
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    ForEach(0..<meta, id: \.self) { i in
                        Button {
                            estado.tomarAgua(i + 1 == a ? -1 : i + 1 - a)
                        } label: {
                            IconoVista(.agua, tamano: 20)
                                .foregroundStyle(i < a ? Color(claro: 0x2E5293, oscuro: 0x9DB4E8) : Color(claro: 0x9C8573, oscuro: 0x4A5C82))
                                .frame(width: 22, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(Apretable())
                        .accessibilityHidden(true)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 2)
            .frame(minHeight: 64)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Agua, \(a) de \(meta) vasos")
        .accessibilityAdjustableAction { d in estado.tomarAgua(d == .increment ? 1 : -1) }
    }
}

/// La meta de la semana (.meta-hoy).
struct TarjetaMeta: View {
    @Environment(Estado.self) private var estado
    var etiqueta: String
    var body: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 4) {
                Etiqueta(etiqueta)
                HStack(spacing: 10) {
                    Text(estado.paciente.meta).tipo(.texto(15, 600)).foregroundStyle(Color.texto).lineLimit(1)
                    Spacer(minLength: 0)
                    Porciones(hechas: estado.paciente.metaHechas, total: estado.paciente.metaTotal)
                }
            }
            .padding(.vertical, 12).padding(.horizontal, 16)
        }
    }
}

/// Debajo de lo del día: la próxima consulta, los avisos y el perfil (con los ajustes).
private struct LoTuyo: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        TituloSeccion(texto: "Lo tuyo")
        Tarjeta {
            fila(.turno, "Tu próxima consulta", estado.paciente.turno.map { "\(Fecha.diaLargo($0.fecha).capitalized) \(Fecha.dia($0.fecha)) · \($0.hora) · \($0.modalidad.titulo)" } ?? "Sacá un turno con \(estado.paciente.nutri.nombre)") { nav.empujar(.turno) }
            Divisor()
            fila(.campana, "Avisos", estado.avisosSinLeerPaciente > 0 ? "\(estado.avisosSinLeerPaciente) sin leer" : "Estás al día", badge: estado.avisosSinLeerPaciente) { nav.empujar(.avisos) }
            Divisor()
            Button { Haptico.seleccion(); nav.empujar(.perfil) } label: {
                Fila(alto: 60) {
                    Avatar(foto: estado.paciente.foto, iniciales: "SB")
                    NomSub(nombre: "Tu perfil y ajustes", sub: "Tus datos, pagos, Apple Salud y la cuenta")
                    IconoVista(.chev, tamano: 16).foregroundStyle(Color.corteza400)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
        }
    }

    private func fila(_ i: Icono, _ t: String, _ s: String, badge: Int = 0, accion: @escaping () -> Void) -> some View {
        Button { Haptico.seleccion(); accion() } label: {
            Fila(alto: 60) {
                IconoCirculo(icono: i, tono: .az)
                    .overlay(alignment: .topTrailing) { if badge > 0 { Badge(n: badge, aro: .superficie).offset(x: 4, y: -4) } }
                NomSub(nombre: t, sub: s)
                IconoVista(.chev, tamano: 16).foregroundStyle(Color.corteza400)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
    }
}

/// Una comida anotada, en grande: la foto, cómo llegó, la nota y lo que contestó la nutri.
struct DetalleRegistro: View {
    let registroId: String
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        let r = estado.paciente.registros.first { $0.id == registroId }
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                NavAtras(atras: nil, icono: .x) { cerrar() }.padding(.horizontal, -Espacio.margen)
                if let r {
                    if let f = r.foto {
                        FotoRecortada(nombre: f).frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    Etiqueta("\(r.momento.titulo) · \(Fecha.relativa(r.fecha, hoy: estado.paciente.hoy)) \(r.hora)")
                    Titulo(r.descripcion, tamano: 26)
                    HStack(spacing: 8) {
                        if let s = r.sensacion { ChipEstado(texto: s.titulo, tipo: .info) }
                        if r.bienAhi { ChipEstado(texto: "¡Bien ahí!", icono: .bocado, tipo: .dur) }
                    }
                    if !r.nota.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            IconoVista(.mensaje, tamano: 20).foregroundStyle(Color.texto2)
                            Text(r.nota).tipo(.texto(15, 400)).foregroundStyle(Color.texto)
                        }
                    }
                    if let resp = r.respuesta {
                        HStack(alignment: .top, spacing: 10) {
                            Avatar(foto: estado.paciente.nutri.foto, tamano: 32)
                            Text(resp).tipo(.texto(15, 400)).foregroundStyle(Color.texto)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(Color.superficie, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 6, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous))
                                .sombraChica()
                        }
                    } else {
                        Text("\(estado.paciente.nutri.nombre) la ve y te contesta acá.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    }
                } else {
                    Vacio(titulo: "No encontramos esa comida", texto: "Puede que la hayas borrado.")
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.bottom, 32)
        }
        .background(Color.fondo.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
