import SwiftUI

/// Medidas del paciente (p22): la curva (nunca balanza), la tabla por consulta y si le muestra el peso.
struct MedidasPaciente: View {
    let pacienteId: String
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var tipo: TipoMedida = .cintura
    @State private var todas = false

    var body: some View {
        let p = estado.paciente(pacienteId)
        let nombre = p?.primerNombre ?? "tu paciente"
        let m = estado.mediciones(de: pacienteId)
        PantallaClaraN(abajo: 24) {
            NavAtras(atras: nombre) {
                Boton(titulo: "Anotar hoy", icono: .mas, variante: .prim, alto: .chico) { nav.hoja = .anotarMedidas(pacienteId) }
            }
            Titulo("Medidas de\u{00A0}\(nombre)", tamano: 30).padding(.horizontal, Espacio.margen)
            MiniSeg(opciones: TipoMedida.allCases.map { ($0, $0.titulo) }, elegida: $tipo)
                .padding(.horizontal, Espacio.margen).padding(.top, 2)
            VStack(spacing: 12) {
                CurvaGrande(tipo: tipo, mediciones: m)
                if !m.isEmpty { TablaMedidas(mediciones: m, tipo: tipo, todas: $todas) }
                if let p {
                    Tarjeta {
                        Fila(alto: 60) {
                            NomSub(nombre: "Mostrarle el peso a \(p.primerNombre)",
                                   sub: p.mostrarPeso ? "Ve la curva y su peso" : "\(p.sexo == .hombre ? "Él" : "Ella") ve la curva de medidas")
                            Interruptor(prendido: Binding(get: { p.mostrarPeso }, set: { estado.cambiarMostrarPeso(pacienteId, $0) }),
                                        etiqueta: "Mostrarle el peso a \(p.primerNombre)")
                        }
                    }
                    BannerGrupo(.profe, titulo: "¿\(p.primerNombre) entrena con alguien?", texto: "Conectá con su profe.", cerrable: false, compacta: true)
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 2)
        }
    }
}

private struct CurvaGrande: View {
    let tipo: TipoMedida
    let mediciones: [Medicion]
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let con = mediciones.filter { tipo.valor($0) != nil }
        let v = con.compactMap { tipo.valor($0) }
        Tarjeta(relleno: 16) {
            if v.count < 2 {
                Vacio(titulo: v.isEmpty ? "Sin medidas de \(tipo.titulo.lowercased())" : "Falta una más para la curva",
                      texto: "Anotalas en la consulta y la curva aparece sola.", accion: "Anotar hoy") {
                    nav.hoja = .anotarMedidas(con.first?.pacienteId ?? mediciones.first?.pacienteId ?? "")
                }
            } else {
                Etiqueta("Desde el \(Fecha.diaMes(con[0].fecha))")
                Numero(valor: Formato.diferencia((v.last ?? 0) - (v.first ?? 0)), tamano: 26, color: .titulo,
                       unidad: tipo == .peso ? " kg" : " \(tipo.unidad) de \(tipo.titulo.lowercased())", tamanoUnidad: 15)
                    .padding(.top, 4)
                Curva(valores: v, etiquetas: estado.etiquetasMeses(con), alto: 150).padding(.top, 8)
                    .id(tipo)
                    .transition(.opacity)
            }
        }
    }
}

private struct TablaMedidas: View {
    let mediciones: [Medicion]
    let tipo: TipoMedida
    @Binding var todas: Bool
    @Environment(Estado.self) private var estado

    /// La columna elegida y la que la acompaña.
    private var columnas: [TipoMedida] { tipo == .cintura || tipo == .cadera ? [.cintura, .cadera] : [tipo, .cintura] }

    var body: some View {
        let filas = Array(mediciones.reversed())
        Tarjeta {
            HStack(spacing: 12) {
                Text("CONSULTA").frame(maxWidth: .infinity, alignment: .leading)
                ForEach(columnas, id: \.self) { c in Text(c.titulo.uppercased()).frame(width: 64, alignment: .trailing) }
            }
            .font(Estilo.texto(11, 700).font()).tracking(0.66).foregroundStyle(Color.texto2)
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 6)
            ForEach(Array((todas ? filas : Array(filas.prefix(3))).enumerated()), id: \.element.id) { i, m in
                if i > 0 { Divisor() }
                HStack(spacing: 12) {
                    NomSub(nombre: m.fecha == estado.hoy ? "Hoy" : Fecha.diaMes(m.fecha), sub: m.modalidad.titulo)
                    ForEach(columnas, id: \.self) { c in
                        Text(c.valor(m).map(Formato.decimal) ?? "—").tipo(.numero(16)).foregroundStyle(Color.texto).frame(width: 64, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 50)
                .accessibilityElement(children: .combine)
            }
            if filas.count > 3 {
                Divisor()
                Button { Haptico.seleccion(); withAnimation(.snappy) { todas.toggle() } } label: {
                    Text(todas ? "Ver menos" : "Ver las \(filas.count) consultas").tipo(.texto(14, 700)).foregroundStyle(Color.enlace)
                        .frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
            }
        }
    }
}

/// Anotar las medidas de hoy con la regla: cintura, cadera, brazo y (si querés) peso.
struct HojaAnotarMedidas: View {
    let pacienteId: String
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var tipo: TipoMedida = .cintura
    @State private var valores: [TipoMedida: Double] = [:]
    @State private var anotados: Set<TipoMedida> = []
    @State private var modalidad: Modalidad = .consultorio

    var body: some View {
        let nombre = estado.paciente(pacienteId)?.primerNombre ?? ""
        HojaBaseN(titulo: "Medidas de\u{00A0}\(nombre)", bajada: "Hoy, \(Fecha.diaMes(estado.hoy)). Deslizá la regla.") {
            MiniSeg(opciones: TipoMedida.allCases.map { ($0, anotados.contains($0) ? "\($0.titulo) ✓" : $0.titulo) }, elegida: $tipo)
            Regla(valor: Binding(get: { valores[tipo] ?? base(tipo) }, set: { valores[tipo] = $0; anotados.insert(tipo) }),
                  rango: tipo == .peso ? 35...180 : (tipo == .brazo ? 15...60 : 50...160), paso: 0.5, unidad: tipo.unidad, cadaLarga: 10)
                .id(tipo)
                .padding(.horizontal, -Espacio.margen)
                .padding(.top, 8)
            if let d = diferencia {
                Text(d).tipo(.texto(14, 600)).foregroundStyle(Color.texto2).frame(maxWidth: .infinity)
            }
            Etiqueta("Dónde").padding(.top, 8)
            Pastillas(opciones: Modalidad.allCases.map { ($0, $0.titulo) }, elegida: $modalidad)
        } pie: {
            PieHojaN {
                Boton(titulo: anotados.isEmpty ? "Mové la regla para anotar" : "Guardar \(anotados.count) \(anotados.count == 1 ? "medida" : "medidas")",
                      variante: .prim, alto: .alto, ancho: true, habilitado: !anotados.isEmpty) {
                    estado.anotarMedicion(Medicion(pacienteId: pacienteId, fecha: estado.hoy, modalidad: modalidad,
                                                   cintura: anotados.contains(.cintura) ? valores[.cintura] : nil,
                                                   cadera: anotados.contains(.cadera) ? valores[.cadera] : nil,
                                                   brazo: anotados.contains(.brazo) ? valores[.brazo] : nil,
                                                   peso: anotados.contains(.peso) ? valores[.peso] : nil))
                    cerrar()
                }
            }
        }
    }

    /// Arranca en la última medida (o un valor típico).
    private func base(_ t: TipoMedida) -> Double {
        estado.mediciones(de: pacienteId).compactMap { t.valor($0) }.last ?? (t == .peso ? 70 : t == .brazo ? 30 : t == .cadera ? 100 : 90)
    }

    private var diferencia: String? {
        guard anotados.contains(tipo), let v = valores[tipo],
              let ant = estado.mediciones(de: pacienteId).compactMap({ tipo.valor($0) }).last else { return nil }
        return "\(Formato.diferencia(v - ant)) \(tipo.unidad) desde la última consulta"
    }
}
