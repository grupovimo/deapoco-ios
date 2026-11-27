import SwiftUI

/// Inicio de la nutri (p2): «Hoy atendés a seis.», el plato del día, lo que hay para hacer y el mes.
struct InicioNutri: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        PantallaBandaN {
            MarcaApp()
            Cabecera(fecha: Fecha.larga(estado.hoy), titulo: estado.tituloHoy) {
                Redondo(icono: .mensaje, badge: estado.noLeidosNutri, etiqueta: "Mensajes") { nav.abrir(.mensajes) }
                    .padding(.top, -2).padding(.trailing, -2)
            }
            ProximoTurno()
        } cuerpo: {
            ParaHacerHoy()
            ResumenMes()
            TuConsultorio()
            if let t = estado.tip(.nutri) { TipVista(tip: t).padding(.top, 8) }
        }
    }
}

/// El plato del día (un turno por porción) y el próximo paciente.
private struct ProximoTurno: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let total = estado.atiendeHoy.count
        HStack(spacing: 16) {
            Gajos(partes: max(total, 2), llenas: estado.atendidosHoy, ahora: estado.proximoTurno == nil ? .no : .siguiente,
                  servir: true)
                .frame(width: 112, height: 112)
                .accessibilityLabel("\(estado.atendidosHoy) de \(total) turnos atendidos")
            if let t = estado.proximoTurno, let p = estado.paciente(t.pacienteId) {
                VStack(alignment: .leading, spacing: 0) {
                    Etiqueta(cuando(t), color: .mandarina)
                    Text(p.nombre).tipo(.texto(19, 600)).foregroundStyle(Color.crema).padding(.top, 4).lineLimit(1)
                    Text("\(t.hora) · \(t.tipo.lowercased()) \(t.modalidad == .enLinea ? "en línea" : "en consultorio")")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.sobreBanda2).padding(.top, 2).lineLimit(1)
                    Boton(titulo: t.modalidad == .enLinea ? "Abrir la consulta" : "Ver su ficha", icono: t.modalidad == .enLinea ? .video : .persona,
                          variante: .man, alto: .chico) {
                        if t.modalidad == .enLinea { estado.avisar("Abrimos la videollamada con \(p.primerNombre).") }
                        nav.abrirFicha(p.id)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Etiqueta("Por hoy, listo", color: .mandarina)
                    Text(total == 0 ? "Día libre. Aprovechá para armar planes." : "Atendiste a todos. Bien ahí.")
                        .tipo(.texto(17, 600)).foregroundStyle(Color.crema).fixedSize(horizontal: false, vertical: true)
                    Boton(titulo: "Ver la agenda", icono: .turno, variante: .man, alto: .chico) { nav.ir(.agenda) }.padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 18)
    }

    private func cuando(_ t: Turno) -> String {
        let m = estado.minutosHasta(t)
        if m <= 0 { return "Ahora · en curso" }
        if m < 60 { return "Ahora · en \(m) min" }
        return "Próximo · a las \(t.hora)"
    }
}

/// «Para hacer hoy»: quién aflojó, comidas para mirar y turnos sin confirmar.
private struct ParaHacerHoy: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @Environment(\.openURL) private var abrir

    var body: some View {
        let aflojo = estado.pacientesActivos.filter { $0.sinAnotar >= 5 }.max { $0.sinAnotar < $1.sinAnotar }
        let revisar = estado.porRevisar
        let sin = estado.sinConfirmar.filter { $0.fecha == estado.hoy }
        let cantidad = (aflojo == nil ? 0 : 1) + (revisar.isEmpty ? 0 : 1) + (sin.isEmpty ? 0 : 1)
        TituloSeccion(texto: "Para hacer hoy", dato: "\(cantidad)")
        Tarjeta {
            if cantidad == 0 {
                Vacio(titulo: "Nada pendiente", texto: "Todo al día. Bien ahí.", accion: "Ver pacientes") { nav.ir(.pacientes) }
            }
            if let p = aflojo {
                Fila(alto: 72) {
                    Avatar(foto: p.foto, iniciales: p.iniciales, tono: p.tono)
                    NomSub(nombre: "\(p.primerNombre) no anota hace\u{00A0}\(Formato.enLetras(p.sinAnotar)) días.", sub: "¿Le escribís hoy?", lineas: 2)
                    BotonWA(titulo: "Escribir") {
                        if let u = estado.whatsapp(p.telefono, "Hola \(p.primerNombre), ¿cómo venís? Contame cómo van las comidas, sin culpa.") { abrir(u) }
                    }
                }
                if !revisar.isEmpty || !sin.isEmpty { Divisor() }
            }
            if !revisar.isEmpty {
                Fila(alto: 72) {
                    FotosApiladasN(fotos: revisar.prefix(3).compactMap(\.foto))
                    NomSub(nombre: "\(revisar.count) \(revisar.count == 1 ? "comida" : "comidas") para mirar",
                           sub: "De \(Formato.lista(estado.quienesPorRevisar))")
                    Boton(titulo: "Mirar", variante: .prim, alto: .chico) { nav.cubierta = .revisar }
                }
                if !sin.isEmpty { Divisor() }
            }
            if !sin.isEmpty {
                let nombres = sin.compactMap { estado.paciente($0.pacienteId)?.primerNombre }
                                Fila(alto: 72) {
                    IconoCirculo(icono: .reloj, tono: .aviso)
                    NomSub(nombre: "\(sin.count) sin confirmar", sub: "\(Formato.lista(nombres)), para hoy")
                    Boton(titulo: "Recordar", variante: .suave, alto: .chico) { estado.recordarTurnos(sin.map(\.id)) }
                }
            }
        }
    }
}

/// Fotos chicas apiladas (.apila).
struct FotosApiladasN: View {
    let fotos: [String]
    var body: some View {
        HStack(spacing: -12) {
            ForEach(Array(fotos.enumerated()), id: \.offset) { _, f in
                FotoRecortada(nombre: f)
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.superficie, lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

/// «Noviembre · Cobrado $1.284.000 de $1.620.000».
private struct ResumenMes: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        TituloSeccion(texto: Fecha.nombreMes(estado.hoy), dato: "Cobros\u{00A0}›") { nav.ir(.cobros) }
        Button { Haptico.seleccion(); nav.ir(.cobros) } label: {
            Tarjeta(relleno: 16) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiqueta("Cobrado")
                        Text(Formato.plata(estado.cobradoMes)).tipo(.numero(30)).foregroundStyle(Color.titulo)
                            .contentTransition(.numericText(value: Double(estado.cobradoMes)))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("de \(Formato.plata(estado.esperadoMes))").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        Text("\(estado.pagadosDelMes.count) consultas").tipo(.texto(14, 700)).foregroundStyle(Color.texto)
                    }
                }
                BarraMes(fraccion: Double(estado.porcentajeCobrado) / 100).padding(.top, 14)
            }
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("Cobrado \(Formato.plata(estado.cobradoMes)) de \(Formato.plata(estado.esperadoMes)). Ver cobros")
    }
}

/// Accesos a lo demás: perfil, mensajes, avisos, ajustes y el plan de De a Poco.
private struct TuConsultorio: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        TituloSeccion(texto: "Tu consultorio")
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            AccesoN(icono: .persona, titulo: "Tu perfil", sub: "\(estado.perfilNutri.completitud)% completo", tono: .dur) { nav.abrir(.perfil) }
            AccesoN(icono: .mensaje, titulo: "Mensajes", sub: estado.noLeidosNutri > 0 ? "\(estado.noLeidosNutri) sin leer" : "Al día", tono: .az) { nav.abrir(.mensajes) }
            AccesoN(icono: .campana, titulo: "Avisos", sub: estado.avisosSinLeerNutri > 0 ? "\(estado.avisosSinLeerNutri) nuevos" : "Nada nuevo", tono: .az) { nav.abrir(.avisos) }
            AccesoN(icono: .ajustes, titulo: "Ajustes", sub: estado.enPrueba ? "Prueba: \(estado.diasDePrueba) días" : "Plan \(estado.planActual.nombre)", tono: .dur) { nav.abrir(.ajustes) }
        }
    }
}

/// Un acceso en tarjeta (.tile).
struct AccesoN: View {
    let icono: Icono
    let titulo: String
    let sub: String
    var tono: IconoCirculo.Tono = .az
    var accion: () -> Void

    var body: some View {
        Button { Haptico.seleccion(); accion() } label: {
            VStack(alignment: .leading, spacing: 10) {
                IconoCirculo(icono: icono, tono: tono)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo).tipo(.texto(16, 700)).foregroundStyle(Color.texto).lineLimit(1)
                    Text(sub).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.superficie, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .sombraTarjeta()
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
    }
}
