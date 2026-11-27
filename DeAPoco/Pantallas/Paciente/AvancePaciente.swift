import SwiftUI

/// Tu avance (p12 y p26): los platos de cada semana, la curva de medidas (nunca balanza), los logros,
/// el día a día de Apple Salud y la promo de Otra Más.
struct AvancePaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav

    var body: some View {
        ScrollViewReader { lector in
            PantallaPaciente {
                Cabecera(fecha: "Desde el \(Fecha.diaMes(estado.paciente.desde))", titulo: "Tu avance")
            } cuerpo: {
                SemanasEnPlatos()
                CurvaMedidas()
                TituloSeccion(texto: "Logros", dato: "\(estado.logrosConseguidos.count) de \(estado.paciente.logros.count)\u{00A0}›") { nav.empujar(.logros) }
                TarjetasLogro()
                DiaADia()
                BannerGrupo(.movimiento, titulo: "¿Querés sumar movimiento?", texto: "Entrená con un profe.")
                FilaSemana().id("abajo")
            }
            .onAppear {
                guard nav.avanceAbajo else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    lector.scrollTo("abajo", anchor: .bottom)
                    nav.avanceAbajo = false
                }
            }
        }
    }
}

/// «De a poco · nivel 3»: un plato por semana, lleno según los días anotados.
private struct SemanasEnPlatos: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let p = estado.paciente
        Tarjeta(relleno: 16) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Etiqueta("De a poco · nivel \(p.nivel)")
                    Text("Cada gajo, una semana anotando.").tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ChipEstado(texto: "Faltan \(p.faltanNivel) para el \(p.nivel + 1)", tipo: .dur)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                ForEach(Array(p.semanas.enumerated()), id: \.offset) { i, n in
                    Gajos(partes: 7, llenas: n, chico: true)
                        .accessibilityLabel("Semana \(i + 1): \(n) de 7 días")
                }
            }
            .padding(.top, 12)
        }
    }
}

/// La curva de cintura, cadera (y peso sólo si la nutri lo habilitó).
struct CurvaMedidas: View {
    @Environment(Estado.self) private var estado
    @State private var tipo: TipoMedida = .cintura

    var body: some View {
        let opciones: [TipoMedida] = estado.paciente.mostrarPeso ? [.cintura, .cadera, .peso] : [.cintura, .cadera]
        let ms = estado.paciente.mediciones.filter { tipo.valor($0) != nil }
        let valores = ms.compactMap { tipo.valor($0) }
        Tarjeta(relleno: 16) {
            if valores.count < 2 {
                Vacio(titulo: "Tu curva arranca en el próximo turno", texto: "\(estado.paciente.nutri.nombre) anota tus medidas en la consulta.", icono: .cinta)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiqueta(tipo.titulo)
                        Numero(valor: Formato.diferencia((valores.last ?? 0) - (valores.first ?? 0)), tamano: 26, unidad: " \(tipo.unidad)", tamanoUnidad: 15)
                    }
                    Spacer(minLength: 0)
                    MiniSeg(opciones: opciones.map { ($0, $0.titulo) }, elegida: $tipo)
                }
                Curva(valores: valores, etiquetas: etiquetas(ms), alto: 96)
                    .padding(.top, 6)
                    .animation(.snappy, value: tipo)
            }
        }
    }

    /// El mes, sólo en la primera medida de cada mes («AGO», «SEP»…).
    private func etiquetas(_ ms: [Medicion]) -> [String] {
        var ultimo = 0
        return ms.map { m in
            let mes = Fecha.mes(m.fecha)
            defer { ultimo = mes }
            return mes == ultimo ? "" : String(Fecha.meses[mes - 1].prefix(3)).uppercased()
        }
    }
}

/// Las tarjetas de logro (.logro): 150 de ancho, mandarina la más importante.
private struct TarjetasLogro: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(estado.paciente.destacados) { d in
                    Button { Haptico.seleccion(); nav.empujar(.logros) } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Gajos(partes: d.partes, llenas: d.llenas, ahora: d.fuerte ? .siguiente : .no,
                                  lleno: d.fuerte ? .naranja700 : nil, falta: d.fuerte ? .pulpa : nil)
                                .frame(width: 36, height: 36)
                            Text(d.titulo).tipo(.texto(15, 700)).foregroundStyle(Color.sobreLogro)
                                .fixedSize(horizontal: false, vertical: true).padding(.top, 10)
                            Text(d.bajada).tipo(.texto(12.5, 400)).foregroundStyle((d.fuerte ? Color.verde900 : Color.texto2))
                                .fixedSize(horizontal: false, vertical: true).padding(.top, 3)
                        }
                        .padding(14)
                        .frame(width: 150, alignment: .topLeading)
                        .frame(minHeight: 154, alignment: .topLeading)
                        .background(d.fuerte ? Color.logro : Color.logroSuave, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(Apretable())
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}

/// «Tu día a día · De Apple Salud»: pasos y sueño. Si no está conectada, una invitación.
private struct DiaADia: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        let p = estado.paciente
        HStack(alignment: .firstTextBaseline) {
            Text("Tu día a día").font(Estilo.titulo(20).font()).tracking(-0.3).foregroundStyle(Color.titulo)
            Spacer()
            HStack(spacing: 4) {
                IconoVista(.salud, tamano: 12).foregroundStyle(Color.salud)
                Text("De Apple Salud").tipo(.texto(12, 600)).foregroundStyle(Color.texto2)
            }
        }
        .padding(.top, 8).padding(.bottom, -2)
        if p.saludConectada {
            Tarjeta {
                HStack(spacing: 0) {
                    dato("Pasos", Formato.entero(p.pasos), " por día")
                    Rectangle().fill(Color.borde).frame(width: 1)
                    dato("Sueño", "\(p.sueno / 60) h \(p.sueno % 60)", " min")
                }
            }
        } else {
            Tarjeta {
                Fila {
                    IconoCirculo(icono: .salud, tono: .salud)
                    NomSub(nombre: "Sumá tus pasos y tu sueño", sub: "Sólo los ve \(p.nutri.nombre)", lineas: 2)
                    Boton(titulo: "Conectar", variante: .suave, alto: .chico) { estado.conectarSalud(true) }
                }
            }
        }
    }

    private func dato(_ e: String, _ v: String, _ u: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Etiqueta(e)
            Numero(valor: v, tamano: 22, color: .texto, unidad: u, tamanoUnidad: 13)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Atajo a «Tu semana» (la racha y los platitos).
private struct FilaSemana: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        Tarjeta {
            Button { Haptico.seleccion(); nav.empujar(.semana) } label: {
                Fila {
                    ChipRachaFija(dias: estado.paciente.racha)
                    NomSub(nombre: "Tu semana", sub: "La racha, el comodín y los platitos")
                    IconoVista(.chev, tamano: 16).foregroundStyle(Color.salvia400)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
        }
        .padding(.top, 4)
    }
}

private struct ChipRachaFija: View {
    let dias: Int
    var body: some View {
        Gajos(partes: 7, llenas: 7, chico: true).frame(width: 40, height: 40)
            .overlay(alignment: .bottomTrailing) {
                Text("\(dias)").font(Estilo.texto(11, 700).font()).foregroundStyle(Color.sobreLogro)
                    .padding(.horizontal, 5).frame(height: 18).background(Color.logro, in: Capsule()).offset(x: 6, y: 4)
            }
    }
}
