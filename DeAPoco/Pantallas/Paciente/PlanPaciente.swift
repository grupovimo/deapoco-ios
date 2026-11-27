import SwiftUI

/// Tu plan (p21): los días de la semana y, por comida, lo que va (o el plato armado con sus opciones).
struct PlanPaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @State private var dia: String = ""

    var body: some View {
        let semana = estado.semanaPaciente.map(\.fecha)
        let elegido = dia.isEmpty ? estado.paciente.hoy : dia
        PantallaPaciente {
            Cabecera(fecha: "Semana \(estado.paciente.plan.semana) · lo armó \(estado.paciente.nutri.nombre)", titulo: "Tu plan") {
                Redondo(icono: .plan, variante: .claro, tamanoIcono: 20, etiqueta: "Lista de compras") { nav.empujar(.compras) }
            }
            DiasPlan(dias: semana, elegido: elegido) { dia = $0 }
        } cuerpo: {
            if Fecha.diaSemana(elegido) >= 6 {
                FinDeSemana(nutri: estado.paciente.nutri.nombre)
            }
            ForEach(estado.paciente.plan.comidas) { c in TarjetaComidaPlan(comida: c) }
            if !estado.paciente.plan.nota.isEmpty {
                NotaDeLaNutri(nombre: estado.paciente.nutri.nombre, texto: estado.paciente.plan.nota)
            }
        }
    }
}

/// Los siete días (.dias-sem): 52 de alto, el elegido en verde.
private struct DiasPlan: View {
    let dias: [String]
    let elegido: String
    var elegir: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(dias, id: \.self) { d in
                let on = d == elegido
                Button { Haptico.seleccion(); withAnimation(.snappy(duration: 0.2)) { elegir(d) } } label: {
                    VStack(spacing: 2) {
                        Text(Fecha.diaCorto(d)).tipo(.texto(12, 600)).foregroundStyle(on ? Color.sobreBanda2 : Color.texto2)
                        Text("\(Fecha.dia(d))").font(Estilo.texto(16, 600).font()).monospacedDigit()
                            .foregroundStyle(on ? Color.crema : Color.texto)
                    }
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(on ? Color.banda : Color.superficie2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(Apretable())
                .accessibilityLabel(Fecha.larga(d))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 14)
    }
}

private struct FinDeSemana: View {
    let nutri: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            IconoVista(.sol, tamano: 20).foregroundStyle(Color.logroTexto)
            Text("El finde es más libre: tomá el plan como guía y comé tranqui. \(nutri) no espera la foto perfecta.")
                .tipo(.texto(14, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Una comida del plan (.comida): nombre en Nunito, la hora, y sus ítems o el plato armado.
struct TarjetaComidaPlan: View {
    let comida: ComidaPlan
    @State private var opcion = 0

    var body: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Text(comida.momento.titulo).font(Estilo.titulo(19).font()).tracking(-0.28).foregroundStyle(Color.titulo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(comida.hora).tipo(.texto(13, 600)).monospacedDigit().foregroundStyle(Color.texto2)
                }
                if comida.opciones.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(Array(comida.opciones.enumerated()), id: \.offset) { i, o in
                            ChipPlan(titulo: o.nombre, on: i == opcion) { withAnimation(.snappy(duration: 0.2)) { opcion = i } }
                        }
                    }
                    .padding(.top, 10)
                }
                if let o = comida.opciones[safe: opcion] {
                    PlatoArmadoLista(opcion: o).padding(.top, 10)
                }
                ForEach(Array(comida.items.enumerated()), id: \.element.id) { i, it in
                    Divisor().padding(.top, i == 0 ? 10 : 0)
                    HStack(spacing: 10) {
                        Text(it.nombre).tipo(.texto(15, 600)).foregroundStyle(Color.texto).frame(maxWidth: .infinity, alignment: .leading)
                        Text(it.porcion).tipo(.texto(13, 600)).foregroundStyle(Color.texto3)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.superficie2, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .padding(.vertical, 9)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, comida.items.isEmpty ? 14 : 5)
        }
    }
}

/// Opción de plato (.opcion span): crema 300, la elegida en verde-100 con borde.
private struct ChipPlan: View {
    let titulo: String
    let on: Bool
    var accion: () -> Void
    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            Text(titulo).tipo(.texto(13, 600))
                .foregroundStyle(on ? Color.sobreSuave : Color.texto3)
                .padding(.horizontal, 12).frame(height: 32)
                .background(on ? Color.suave : Color.superficie2, in: Capsule())
                .overlay(Capsule().strokeBorder(on ? Color.marca : .clear, lineWidth: 1.5))
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -6)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// El plato armado (.plato-armado): el dibujo de 96 y la lista con el color de cada parte.
struct PlatoArmadoLista: View {
    let opcion: OpcionPlato

    static func color(_ t: TipoPorcion) -> Color {
        switch t { case .verdura: return .hojaClara; case .proteina: return .acento; case .almidon: return .mandarina }
    }

    var body: some View {
        let orden = opcion.partes.sorted { a, b in
            let o: [TipoPorcion] = [.proteina, .almidon, .verdura]
            return (o.firstIndex(of: a.tipo) ?? 0) < (o.firstIndex(of: b.tipo) ?? 0)
        }
        HStack(spacing: 14) {
            PlatoArmado(porciones: orden.map { (Self.color($0.tipo), $0.fraccion) }).frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(opcion.partes.sorted { $0.fraccion > $1.fraccion }) { p in
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Self.color(p.tipo)).frame(width: 12, height: 12).padding(.top, 3)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(p.nombre).tipo(.texto(14, 600)).foregroundStyle(Color.texto)
                            Text(p.detalle).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// La nota de la nutri (.nota-pac): naranja-100, el globito y «Para Sofía:».
struct NotaDeLaNutri: View {
    let nombre: String
    let texto: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            IconoVista(.mensaje, tamano: 20).foregroundStyle(Color.logroTexto).padding(.top, 1)
            (Text("De \(nombre): ").bold() + Text(texto))
                .font(Estilo.texto(14, 400).font()).foregroundStyle(Color.sobreLogro)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// La lista de compras de la semana, sacada del plan. Se tilda y se comparte.
struct ListaCompras: View {
    @Environment(Estado.self) private var estado
    @AppStorage("compras-tildadas") private var tildadasTexto = ""

    private var tildadas: Set<String> { Set(tildadasTexto.split(separator: "|").map(String.init)) }

    var body: some View {
        let lista = estado.listaCompras
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Plan") {
                ShareLink(item: texto(lista)) {
                    HStack(spacing: 6) { IconoVista(.compartir, tamano: 20); Text("Compartir").tipo(.texto(15, 600)) }
                        .foregroundStyle(Color.marca).frame(minHeight: 44)
                }
            }
            Cabecera(fecha: "Para la semana \(estado.paciente.plan.semana)", titulo: "Lista de compras", tamano: 30)
        } cuerpo: {
            if lista.isEmpty {
                Vacio(titulo: "Todavía no hay plan", texto: "Cuando \(estado.paciente.nutri.nombre) te lo arme, acá aparece lo que hay que comprar.")
            } else {
                Tarjeta {
                    ForEach(Array(lista.enumerated()), id: \.element) { i, item in
                        if i > 0 { Divisor() }
                        let on = tildadas.contains(item)
                        Button { alternar(item) } label: {
                            Fila(alto: 52, vertical: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(on ? Color.clear : Color.bordeCampo, lineWidth: 2)
                                        .background(on ? Color.marca : .clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                                    if on { IconoVista(.check, tamano: 16, grosor: 2.8).foregroundStyle(Color.sobreMarca) }
                                }
                                .frame(width: 24, height: 24)
                                Text(item).tipo(.texto(15, 600)).foregroundStyle(on ? Color.texto2 : Color.texto)
                                    .strikethrough(on, color: Color.texto2)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                Text("Comprá lo de la semana y cociná algo el domingo: te salva el miércoles.")
                    .tipo(.texto(13, 400)).foregroundStyle(Color.texto2).padding(.horizontal, 4)
                if !tildadas.isEmpty {
                    Boton(titulo: "Empezar de nuevo", icono: .vuelta, variante: .crema, ancho: true) { tildadasTexto = "" }
                }
            }
        }
    }

    private func alternar(_ item: String) {
        Haptico.seleccion()
        var t = tildadas
        if t.contains(item) { t.remove(item) } else { t.insert(item) }
        tildadasTexto = t.sorted().joined(separator: "|")
    }

    private func texto(_ l: [String]) -> String {
        "Lista de compras · De a Poco\n" + l.map { "• \($0)" }.joined(separator: "\n")
    }
}

fileprivate extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
