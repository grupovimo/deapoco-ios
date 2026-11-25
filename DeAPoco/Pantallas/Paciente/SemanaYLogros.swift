import SwiftUI

/// Tu semana (p16): la racha con los últimos 14 días, el comodín, los platitos de la semana, la meta y el «bien ahí».
struct TuSemana: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav

    var body: some View {
        PantallaPaciente {
            NavAtras(atras: "Volver")
            Cabecera(fecha: estado.textoSemanaPaciente, titulo: "Tu semana").padding(.top, -6)
        } cuerpo: {
            TarjetaRacha()
            if let usado = estado.paciente.comodinUsado { Comodin(usado: usado, quedan: estado.paciente.comodines) }
            Platitos()
            TarjetaMeta(etiqueta: "Meta con \(estado.paciente.nutri.nombre) · esta semana")
            if let b = estado.paciente.bienAhi.first {
                Tarjeta {
                    HStack(spacing: 12) {
                        Avatar(foto: estado.paciente.nutri.foto)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("«¡Bien ahí!», de \(estado.paciente.nutri.nombre)").tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                            Text("Por \(b.por)").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ChipEstado(texto: "+1 al nivel", tipo: .dur)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                }
            }
            if estado.semanaPaciente.allSatisfy({ $0.futuro || $0.llenas == 4 }) {
                Boton(titulo: "Festejar la semana", icono: .bocado, variante: .prim, alto: .alto, ancho: true) { nav.cubierta = .fiesta(semana: true) }
            }
        }
    }
}

/// La racha (.racha): el número grande, la mejor marca y los 14 días.
private struct TarjetaRacha: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let p = estado.paciente
        Tarjeta(relleno: 16) {
            HStack(spacing: 16) {
                Text("\(p.racha)").font(Estilo.numero(56).font()).tracking(-1.7).foregroundStyle(Color.titulo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("días seguidos anotando").tipo(.texto(17, 700)).foregroundStyle(Color.texto)
                    Text("Tu mejor marca: \(p.mejorRacha) días.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                }
            }
            HStack(spacing: 0) {
                ForEach(Array(p.dias14.enumerated()), id: \.offset) { i, d in
                    if i > 0 { Spacer(minLength: 0) }
                    Circulo(dia: d)
                }
            }
            .padding(.top, 14)
            .accessibilityElement()
            .accessibilityLabel("Los últimos 14 días: \(p.dias14.filter { $0 == .anotado }.count) anotados, \(p.dias14.filter { $0 == .comodin }.count) con comodín")
            HStack {
                Text(Fecha.diaMes(Fecha.sumar(-13, a: p.hoy)).replacingOccurrences(of: " de ", with: " ").prefix(6))
                Spacer()
                Text("hoy")
            }
            .tipo(.texto(11.5, 600)).foregroundStyle(Color.texto2).padding(.top, 4)
        }
    }
}

private struct Circulo: View {
    let dia: DiaRacha
    var body: some View {
        switch dia {
        case .anotado: Circle().fill(Color.rabanito500).frame(width: 18, height: 18)
        case .no: Circle().fill(Color.loza).frame(width: 18, height: 18)
        case .comodin: Circle().fill(Color.durazno).overlay(Circle().strokeBorder(Color.durazno700, lineWidth: 2)).frame(width: 18, height: 18)
        case .hoy: Circle().fill(Color.superficie).overlay(Circle().strokeBorder(Color.rabanito500, lineWidth: 2)).frame(width: 18, height: 18)
        }
    }
}

/// El comodín (.comodin): un día sin anotar no corta la racha.
private struct Comodin: View {
    let usado: String
    let quedan: Int
    var body: some View {
        HStack(spacing: 12) {
            IconoVista(.vuelta, tamano: 20).foregroundStyle(Color.tinta)
                .frame(width: 40, height: 40).background(Color.durazno, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text("Usaste el comodín el \(Fecha.diaLargo(usado))").tipo(.texto(15, 700)).foregroundStyle(Color.sobreLogro)
                Text("Un día sin anotar no corta la racha. Te queda\(quedan == 1 ? "" : "n") \(quedan) este mes.")
                    .tipo(.texto(13, 400)).foregroundStyle(Color(claro: 0x54402F, oscuro: 0xE3D3BF))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Los platos de la semana (.platitos): cuatro partes por día; hoy en rabanito, lo que viene apagado.
private struct Platitos: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        Tarjeta(relleno: 16) {
            Etiqueta("Platos de la semana")
            HStack(spacing: 6) {
                ForEach(estado.semanaPaciente) { d in
                    VStack(spacing: 4) {
                        Plato(partes: 4, llenas: d.llenas, hoy: d.esHoy && d.llenas < 4 ? d.llenas : nil, chico: true)
                            .opacity(d.futuro ? 0.45 : 1)
                        Text(Fecha.diaCorto(d.fecha)).tipo(.texto(12, d.esHoy ? 700 : 600))
                            .foregroundStyle(d.esHoy ? Color.acentoTexto : Color.texto2)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement()
                    .accessibilityLabel("\(Fecha.diaLargo(d.fecha)), \(d.llenas) de 4")
                }
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - Logros

/// Tus logros (p17): el nivel, lo nuevo y las medallas (cuencos vistos desde arriba).
struct TusLogros: View {
    @Environment(Estado.self) private var estado
    @State private var elegido: Logro?

    var body: some View {
        let p = estado.paciente
        PantallaPaciente {
            NavAtras(atras: "Avance")
            Cabecera(titulo: "Tus logros").padding(.top, -6)
        } cuerpo: {
            VStack(alignment: .leading, spacing: 16) {
                Nivel(nivel: p.nivel, faltan: p.faltanNivel)
                if let n = p.logros.first(where: \.nuevo) {
                    LogroNuevo(logro: n)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 14) {
                    ForEach(p.logros) { l in
                        Button { Haptico.seleccion(); elegido = l } label: { Medalla(logro: l) }
                            .buttonStyle(Apretable())
                    }
                }
            }
        }
        .sheet(item: $elegido) { l in DetalleLogro(logro: l).presentationDetents([.height(360)]) }
    }
}

private struct Nivel: View {
    let nivel: Int
    let faltan: Int
    var body: some View {
        HStack(spacing: 14) {
            Plato(partes: 4, llenas: 3, hoy: 3, fondo: .mantecaFija, borde: .enlozado800).frame(width: 76, height: 76)
            VStack(alignment: .leading, spacing: 0) {
                Etiqueta("De a poco", color: .durazno)
                Text("Nivel \(nivel)").font(Estilo.titulo(24).font()).foregroundStyle(Color.mantecaFija).padding(.top, 2)
                Text(faltan == 1 ? "Una semana más anotando y llegás al \(nivel + 1)." : "\(Formato.enLetras(faltan).capitalized) semanas más anotando y llegás al \(nivel + 1).")
                    .tipo(.texto(13, 400)).foregroundStyle(Color.sobreBanda2).padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.banda, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct LogroNuevo: View {
    let logro: Logro
    var body: some View {
        HStack(spacing: 14) {
            Cuenco(icono: logro.icono, conseguido: true)
            VStack(alignment: .leading, spacing: 2) {
                Etiqueta("Nuevo · \(logro.detalle.lowercased())", color: .logroTexto)
                Text(logro.titulo).tipo(.texto(17, 700)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                Text("Lo difícil es volver. Bien ahí.").tipo(.texto(13.5, 400)).foregroundStyle(Color(claro: 0x54402F, oscuro: 0xE3D3BF))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct Medalla: View {
    let logro: Logro
    var body: some View {
        VStack(spacing: 6) {
            Cuenco(icono: logro.icono, conseguido: logro.conseguido)
            Text(logro.titulo).tipo(.texto(13, logro.conseguido ? 700 : 600))
                .foregroundStyle(logro.conseguido ? Color.texto : Color.texto2)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(logro.detalle).tipo(.texto(11.5, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(logro.titulo), \(logro.conseguido ? "conseguido" : "por conseguir"): \(logro.detalle)")
    }
}

/// El cuenco (.cuenco): durazno con aro enlozado y el centro manteca; bloqueado, loza con borde punteado.
struct Cuenco: View {
    let icono: Icono
    let conseguido: Bool
    var lado: CGFloat = 76

    var body: some View {
        let k = lado / 76
        ZStack {
            Circle().fill(conseguido ? Color.durazno : Color.loza)
            Circle().strokeBorder(conseguido ? Color.enlozado800 : Color.manteca300, lineWidth: (conseguido ? 5 : 2) * k)
            Circle().fill(Color.mantecaFija).padding(12 * k)
                .overlay {
                    if !conseguido {
                        Circle().strokeBorder(Color.manteca300, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])).padding(12 * k)
                    }
                }
            IconoVista(icono, tamano: 26 * k, grosor: 2).foregroundStyle(conseguido ? Color.enlozado800 : Color.corteza400)
            if conseguido {
                IconoVista(.bocado, tamano: 20 * k).foregroundStyle(Color.rabanito500)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(13 * k)
            }
        }
        .frame(width: lado, height: lado)
        .accessibilityHidden(true)
    }
}

private struct DetalleLogro: View {
    let logro: Logro
    @Environment(\.dismiss) private var cerrar
    var body: some View {
        VStack(spacing: 14) {
            Cuenco(icono: logro.icono, conseguido: logro.conseguido, lado: 110).padding(.top, 28)
            Titulo(logro.titulo, tamano: 26, centrado: true).fixedSize(horizontal: false, vertical: true)
            Text(logro.conseguido ? "Lo conseguiste: \(logro.detalle.lowercased())." : "Todavía no: \(logro.detalle.lowercased()). De a poco.")
                .tipo(.texto(15, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
            Boton(titulo: "Listo", variante: .loza, alto: .medio, ancho: true) { cerrar() }.padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.fondo.ignoresSafeArea())
    }
}
