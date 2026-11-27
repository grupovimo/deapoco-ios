import SwiftUI

// MARK: - Tu plan de De a Poco

/// Tu plan: prueba de 14 días, pacientes activos sobre el tope, lo que incluye, facturas y acciones.
struct TuPlanDAP: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var cancelar = false

    var body: some View {
        PantallaBandaN(abajoBanda: 22) {
            NavAtras(atras: "Ajustes")
            VStack(alignment: .leading, spacing: 4) {
                Etiqueta("Tu plan de De a Poco", color: .sobreBanda2)
                Titulo(estado.enPrueba ? "Profesional · prueba" : estado.suscripcion.plan.nombre, tamano: 32, color: .crema)
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 4)
            HStack(spacing: 20) {
                AroPacientes()
                ResumenSuscripcion()
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 18)
            Boton(titulo: estado.enPrueba && estado.suscripcion.planElegido == nil ? "Elegir mi plan" : "Cambiar de plan",
                  variante: .man, alto: .alto, ancho: true) { nav.hoja = .elegirPlanDAP }
                .padding(.horizontal, Espacio.margen).padding(.top, 18)
        } cuerpo: {
            IncluyePlanDAP(plan: estado.planActual)
            HStack(alignment: .top, spacing: 10) {
                IconoVista(.candado, tamano: 16).foregroundStyle(Color.logroTexto)
                Text("Precio de lanzamiento fijo hasta \(Fecha.meses[Fecha.mes(estado.suscripcion.precioFijoHasta) - 1]) de \(String(estado.suscripcion.precioFijoHasta.prefix(4))). Tus pacientes nunca pagan la app.")
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto3).fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            TituloSeccion(texto: "Pagos y facturas")
            FacturasDAP()
            AccionesDAP(cancelar: $cancelar)
        }
        .confirmationDialog("¿Cancelar la suscripción?", isPresented: $cancelar, titleVisibility: .visible) {
            Button("Cancelar suscripción", role: .destructive) { estado.cancelarSuscripcion() }
            Button("Seguir con mi plan", role: .cancel) {}
        } message: {
            Text("Seguís hasta el fin del período. Después pasás a Gratis y los pacientes que superen 10 quedan en pausa, sin borrarse.")
        }
    }
}

/// Pacientes activos sobre el tope del plan, como un aro.
private struct AroPacientes: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let f = min(1, Double(estado.activos) / Double(max(estado.tope, 1)))
        let lleno = estado.activos >= estado.tope
        ZStack {
            Circle().stroke(Color.vidrio12, lineWidth: 12)
            Circle().trim(from: 0, to: f).stroke(lleno ? Color.naranja300 : Color.mandarina, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(estado.activos)").tipo(.numero(30)).foregroundStyle(Color.crema)
                    Text("/\(estado.tope)").tipo(.numero(16)).foregroundStyle(Color.sobreBanda2)
                }
                Text("pacientes").tipo(.texto(12, 600)).foregroundStyle(Color.sobreBanda2)
            }
        }
        .frame(width: 112, height: 112)
        .accessibilityElement()
        .accessibilityLabel("\(estado.activos) de \(estado.tope) pacientes activos")
    }
}

private struct ResumenSuscripcion: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if estado.enPrueba {
                linea("Prueba", estado.diasDePrueba == 1 ? "Queda 1 día" : "Quedan \(estado.diasDePrueba) días", fuerte: true)
                linea("Termina", Fecha.larga(estado.suscripcion.pruebaHasta ?? estado.hoy))
                linea("Después", estado.suscripcion.planElegido.map { "\($0.nombre) · \(Formato.plata($0.precio(estado.suscripcion.periodo)))" } ?? "Gratis, si no elegís")
            } else {
                let s = estado.suscripcion
                linea("Precio", s.plan == .gratis ? "$0" : "\(Formato.plata(s.plan.precio(s.periodo)))\(s.periodo.unidad)", fuerte: true)
                linea("Próximo cobro", s.proximoCobro.map { s.renueva ? Fecha.larga($0) : "No se renueva" } ?? "—")
                linea("Medio", s.plan == .gratis ? "—" : "App Store")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func linea(_ e: String, _ v: String, fuerte: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(e).tipo(.texto(12, 600)).foregroundStyle(Color.sobreBanda2)
            Text(v).tipo(.texto(fuerte ? 17 : 15, 700)).foregroundStyle(fuerte ? Color.mandarina : Color.crema)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct IncluyePlanDAP: View {
    let plan: PlanDAP
    var body: some View {
        Tarjeta(relleno: 16) {
            Etiqueta("Lo que tenés en \(plan.nombre)")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.incluye, id: \.self) { t in
                    HStack(spacing: 10) {
                        IconoVista(.check, tamano: 16, grosor: 2.6).foregroundStyle(Color.ok)
                        Text(t).tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct FacturasDAP: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let f = estado.suscripcion.facturas
        Tarjeta(relleno: f.isEmpty ? 18 : 0) {
            if f.isEmpty {
                Text(estado.enPrueba ? "Todavía no pagaste nada" : "Sin pagos").tipo(.texto(16, 700)).foregroundStyle(Color.texto)
                Text(estado.enPrueba ? "Estás en la prueba gratis, sin tarjeta. Las facturas van a aparecer acá." : "Cuando pagues un plan, las facturas van a aparecer acá.")
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(f.enumerated()), id: \.element.id) { i, x in
                if i > 0 { Divisor() }
                HStack(spacing: 12) {
                    NomSub(nombre: x.concepto, sub: "Factura \(x.numero) · \(Fecha.corta(x.fecha))")
                    Text(Formato.plata(x.monto)).tipo(.numero(17)).foregroundStyle(Color.texto)
                    CompartirBoton(generar: { FacturaDAPPDF.generar(x, titular: estado.perfilNutri.nombre) }) {
                        IconoVista(.bajar, tamano: 18).foregroundStyle(Color.sobreSuave)
                            .frame(width: 44, height: 44).background(Color.suave, in: Circle())
                    }
                    .accessibilityLabel("Descargar factura")
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }
}

private struct AccionesDAP: View {
    @Environment(Estado.self) private var estado
    @Binding var cancelar: Bool
    var body: some View {
        VStack(spacing: 0) {
            Boton(titulo: "Restaurar compras", variante: .texto, ancho: true) { estado.restaurarCompras() }
            if estado.suscripcion.plan != .gratis && estado.suscripcion.renueva && !estado.enPrueba {
                Button { cancelar = true } label: {
                    Text("Cancelar suscripción").tipo(.texto(15, 700)).foregroundStyle(Color.error).frame(maxWidth: .infinity).frame(height: 48)
                }
            }
            Text("La suscripción se cobra en tu cuenta de App Store y se renueva sola. La cancelás cuando quieras desde acá o desde Ajustes del iPhone. Términos · Privacidad")
                .tipo(.texto(12, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
        }
        .padding(.top, 8)
    }
}

// MARK: - Elegir plan (carrito)

struct ElegirPlanDAP: View {
    nonisolated(unsafe) static var abrirCompra = false
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    var inicial: PlanDAP?
    @State private var plan: PlanDAP = .profesional
    @State private var periodo: PeriodoPlan = .mensual
    @State private var comprando = false

    var body: some View {
        HojaBaseN(titulo: "Elegí tu plan", bajada: "Tus pacientes nunca pagan la app.") {
            SelectorPeriodo(periodo: $periodo)
            ForEach(PlanDAP.allCases, id: \.self) { p in
                TarjetaPlanDAP(plan: p, periodo: periodo, elegido: plan == p) {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.2)) { plan = p }
                }
            }
            TicketPlanDAP(plan: plan, periodo: periodo).padding(.top, 8)
        } pie: {
            PieHojaN {
                let hoy = (estado.enPrueba || plan == .gratis) ? 0 : plan.precio(periodo)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Hoy pagás").tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                        Text(Formato.plata(hoy)).tipo(.numero(28)).foregroundStyle(Color.titulo).contentTransition(.numericText())
                    }
                    Spacer()
                    Text(despues).tipo(.texto(13, 600)).foregroundStyle(Color.texto3).multilineTextAlignment(.trailing)
                }
                Boton(titulo: plan == .gratis ? "Quedarme en Gratis" : "Suscribirme · \(Formato.plata(hoy)) hoy", variante: .prim, alto: .alto, ancho: true) {
                    if plan == .gratis { estado.comprar(.gratis, periodo); cerrar() } else { comprando = true }
                }
                Text("Se renueva solo. Cancelás cuando quieras.").tipo(.texto(12, 400)).foregroundStyle(Color.texto2)
            }
        }
        .onAppear {
            plan = inicial ?? (estado.suscripcion.planElegido ?? max(estado.planQueAlcanza, .profesional))
            if ElegirPlanDAP.abrirCompra { ElegirPlanDAP.abrirCompra = false; comprando = true }
        }
        .sheet(isPresented: $comprando) { CompraAppStore(plan: plan, periodo: periodo) { cerrar() } }
    }

    private var despues: String {
        if plan == .gratis { return "Sin cobros" }
        let desde = estado.enPrueba ? "desde el \(Fecha.corta(estado.primerCobro))" : "desde hoy"
        return "Después \(Formato.plata(plan.precio(periodo)))\(periodo.unidad)\n\(desde)"
    }
}

extension PlanDAP: Comparable, Identifiable {
    var id: String { rawValue }
    static func < (a: PlanDAP, b: PlanDAP) -> Bool { a.tope < b.tope }
}

private struct SelectorPeriodo: View {
    @Binding var periodo: PeriodoPlan
    var body: some View {
        HStack(spacing: 4) {
            ForEach(PeriodoPlan.allCases, id: \.self) { p in
                let on = periodo == p
                Button { Haptico.seleccion(); withAnimation(.snappy(duration: 0.2)) { periodo = p } } label: {
                    HStack(spacing: 6) {
                        Text(p.titulo).tipo(.texto(15, 700))
                        if p == .anual {
                            Text("2 meses gratis").tipo(.texto(11, 700))
                                .padding(.horizontal, 6).frame(height: 20)
                                .background(on ? Color.mandarina : Color.logroSuave, in: Capsule())
                                .foregroundStyle(Color.verde900)
                        }
                    }
                    .foregroundStyle(on ? Color.sobreMarca : Color.titulo)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(on ? Color.marca : Color.clear, in: Capsule())
                }
                .buttonStyle(Apretable())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.superficie2, in: Capsule())
    }
}

private struct TarjetaPlanDAP: View {
    @Environment(Estado.self) private var estado
    let plan: PlanDAP
    let periodo: PeriodoPlan
    let elegido: Bool
    var tocar: () -> Void

    var body: some View {
        let sobran = estado.activos - plan.tope
        Button(action: tocar) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.nombre).font(Estilo.titulo(24).font()).foregroundStyle(Color.titulo)
                        Text(plan.bajada).tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(Formato.plata(plan.precio(periodo))).tipo(.numero(24)).foregroundStyle(Color.titulo)
                            Text(periodo.unidad).tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                        }
                        if periodo == .anual && plan.precioMes > 0 {
                            Text("ahorrás \(Formato.plata(plan.precioMes * 2))").tipo(.texto(12, 700)).foregroundStyle(Color.ok)
                        }
                    }
                }
                Text(plan.incluye.joined(separator: " · ")).tipo(.texto(13, 600)).foregroundStyle(Color.texto3).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    IconoVista(sobran > 0 ? .reloj : .check, tamano: 14, grosor: 2.4)
                    Text(sobran > 0 ? "Tenés \(estado.activos): \(sobran) quedarían en pausa" : "Te alcanza para tus \(estado.activos) pacientes").tipo(.texto(13, 700))
                }
                .foregroundStyle(sobran > 0 ? Color.error : Color.ok)
            }
            .padding(16)
            .background(elegido ? Color.infoSuave : Color.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(elegido ? Color.marca : Color.borde, lineWidth: elegido ? 2.5 : 1))
            .overlay(alignment: .topTrailing) {
                if plan == max(estado.planQueAlcanza, .profesional) {
                    Text("Para vos").tipo(.texto(11, 700)).foregroundStyle(Color.verde900)
                        .padding(.horizontal, 8).frame(height: 22).background(Color.mandarina, in: Capsule())
                        .offset(x: -14, y: -11)
                }
            }
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}

/// El ticket (.ticket): qué comprás, primer cobro, después, y «Hoy pagás».
private struct TicketPlanDAP: View {
    @Environment(Estado.self) private var estado
    let plan: PlanDAP
    let periodo: PeriodoPlan

    var body: some View {
        let monto = plan.precio(periodo)
        let hoyPaga = (estado.enPrueba || plan == .gratis) ? 0 : monto
        Tarjeta {
            VStack(alignment: .leading, spacing: 0) {
                renglon("Plan", "\(plan.nombre) · \(periodo.titulo.lowercased())")
                if plan != .gratis {
                    renglon("Primer cobro", estado.enPrueba ? "\(Fecha.diaMes(estado.primerCobro)), al terminar la prueba" : "Hoy")
                    renglon("Después", "\(Formato.plata(monto)) \(periodo == .mensual ? "cada mes" : "cada año")")
                    renglon("Con", "App Store")
                } else {
                    renglon("Pacientes", "Hasta 10 activos; el resto queda en pausa")
                }
                HStack(alignment: .bottom) {
                    Etiqueta("Hoy pagás").padding(.bottom, 4)
                    Spacer()
                    Text(Formato.plata(hoyPaga)).tipo(.numero(32)).foregroundStyle(Color.titulo).contentTransition(.numericText())
                }
                .padding(.top, 12)
                .overlay(alignment: .top) { Rectangle().fill(Color.texto).frame(height: 1.5) }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 16)
        }
    }

    private func renglon(_ e: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(e).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            Spacer(minLength: 8)
            Text(v).tipo(.texto(14, 600)).foregroundStyle(Color.texto).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.borde).frame(height: 1).mask(HStack(spacing: 3) { ForEach(0..<80, id: \.self) { _ in Rectangle().frame(width: 3) } }) }
    }
}

// MARK: - Compra (estilo App Store)

/// Hoja de compra simulada, como la del sistema (StoreKit).
struct CompraAppStore: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    let plan: PlanDAP
    let periodo: PeriodoPlan
    var listo: () -> Void = {}
    @State private var paso = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("App Store").font(.system(size: 17, weight: .semibold))
                Spacer()
                Button { cerrar() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                        .frame(width: 30, height: 30).background(Color(.tertiarySystemFill), in: Circle())
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Cerrar")
            }
            .padding(.top, 8)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image("isotipo-negativo").resizable().scaledToFit().padding(8)
                        .frame(width: 60, height: 60).background(Color.verde900, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("De a Poco \(plan.nombre)").font(.system(size: 17, weight: .semibold))
                        Text("Suscripción \(periodo == .mensual ? "mensual" : "anual")").font(.system(size: 14)).foregroundStyle(.secondary)
                        Text(estado.enPrueba ? "Prueba gratis hasta el \(Fecha.corta(estado.primerCobro))" : "Empieza hoy").font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                }
                Divider()
                fila("Precio", "\(Formato.plata(plan.precio(periodo)))\(periodo.unidad)")
                fila("Primer cobro", estado.enPrueba ? Fecha.corta(estado.primerCobro) : "Hoy")
                fila("Cuenta", estado.suscripcion.cuenta)
                Divider()
            }
            .padding(.top, 12)
            Spacer(minLength: 16)
            if paso == 2 {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(.blue).transition(.scale.combined(with: .opacity))
                Text("Listo").font(.system(size: 17, weight: .semibold)).padding(.top, 8)
            } else {
                Button { pagar() } label: {
                    Group {
                        if paso == 1 { ProgressView().tint(.white) } else { Text("Suscribirse").font(.system(size: 17, weight: .semibold)) }
                    }
                    .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(paso != 0)
            }
            Text("Simulado: en la maqueta no se cobra nada.").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .presentationDetents([.height(440)])
        .presentationBackground(Color(.systemBackground))
    }

    private func fila(_ e: String, _ v: String) -> some View {
        HStack { Text(e).foregroundStyle(.secondary); Spacer(); Text(v).fontWeight(.medium) }.font(.system(size: 15))
    }

    private func pagar() {
        withAnimation { paso = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(duration: 0.4)) { paso = 2 }
            estado.comprar(plan, periodo)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { cerrar(); listo() }
        }
    }
}

// MARK: - Tope

/// «Llegaste a 10 pacientes»: cuando en Gratis se quiere sumar uno más.
struct HojaTope: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    var nombre: String
    @State private var elegir: PlanDAP?

    var body: some View {
        let quien = nombre.split(separator: " ").first.map(String.init) ?? "a tu paciente nuevo"
        HojaBaseN(titulo: "Llegaste a \(estado.tope) pacientes",
                  bajada: "Pasá a \(siguiente.nombre) para sumar a \(quien.isEmpty ? "alguien más" : quien). Tus pacientes no pagan nada.") {
            ForEach(PlanDAP.allCases.filter { $0.tope > estado.tope }, id: \.self) { p in
                Button { Haptico.seleccion(); elegir = p } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.nombre).font(Estilo.titulo(22).font()).foregroundStyle(Color.titulo)
                            Text("Hasta \(p.tope) pacientes").tipo(.texto(14, 600)).foregroundStyle(Color.texto2)
                        }
                        Spacer()
                        Text("\(Formato.plata(p.precioMes))/mes").tipo(.numero(18)).foregroundStyle(Color.titulo)
                        IconoVista(.chev, tamano: 16).foregroundStyle(Color.salvia400)
                    }
                    .padding(16)
                    .background(Color.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                    .sombraTarjeta()
                }
                .buttonStyle(Apretable())
            }
            HStack(spacing: 8) {
                IconoVista(.escudo, tamano: 16).foregroundStyle(Color.ok)
                Text("Nadie se borra: los que no entran quedan en pausa.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
            }
        } pie: {
            PieHojaN { Boton(titulo: "Ahora no", variante: .texto, ancho: true) { cerrar() } }
        }
        .presentationDetents([.medium, .large])
        .sheet(item: $elegir) { p in ElegirPlanDAP(inicial: p) }
    }

    private var siguiente: PlanDAP { PlanDAP.allCases.first { $0.tope > estado.tope } ?? .consultorio }
}

// MARK: - Factura

enum FacturaDAPPDF {
    @MainActor
    static func generar(_ f: FacturaDAP, titular: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Factura \(f.numero).pdf")
        let vista = VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image("horizontal-color").resizable().scaledToFit().frame(height: 28)
                Spacer()
                Text("FACTURA \(f.numero)").font(Estilo.etiqueta.font()).foregroundStyle(Color.salvia)
            }
            Rectangle().fill(Color.salvia200).frame(height: 1)
            Text("Para: \(titular)").font(Estilo.texto(13, 700).font())
            Text("Fecha: \(Fecha.larga(f.fecha))").font(Estilo.texto(13, 400).font())
            Text(f.concepto).font(Estilo.texto(15, 600).font()).padding(.top, 12)
            Text(Formato.plata(f.monto)).font(Estilo.numero(40).font()).foregroundStyle(Color.verde900)
            Text("IVA incluido · cobrado por App Store · Grupo Vimo").font(Estilo.texto(11, 400).font()).foregroundStyle(Color.salvia)
            Spacer()
        }
        .padding(40).frame(width: 595, height: 842).background(Color.white).environment(\.colorScheme, .light)
        var caja = CGRect(x: 0, y: 0, width: 595, height: 842)
        if let ctx = CGContext(url as CFURL, mediaBox: &caja, nil) {
            ImageRenderer(content: vista).render { _, dibujar in ctx.beginPDFPage(nil); dibujar(ctx); ctx.endPDFPage() }
            ctx.closePDF()
        }
        return url
    }
}
