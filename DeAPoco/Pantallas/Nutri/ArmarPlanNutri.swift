import SwiftUI

/// Qué se está editando dentro del plan.
private struct Edicion: Identifiable {
    var id: String { "\(comida)-\(item ?? "nuevo")" }
    let comida: String
    let item: String?
}

/// Armar plan (p5): comida por comida, con platos armados (medio de verdura, un cuarto, un cuarto), porciones
/// caseras («1 taza», «del tamaño de tu mano») y una nota para el paciente. Se guarda solo.
struct ArmarPlan: View {
    let pacienteId: String
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var plan: PlanAlimentario
    @State private var edicion: Edicion?
    @State private var editandoNota = false
    @State private var vistaPrevia = false

    init(pacienteId: String, modeloId: String?) {
        self.pacienteId = pacienteId
        _plan = State(initialValue: PlanAlimentario(id: "", pacienteId: pacienteId, nombre: "", semana: 1, desde: DatosDeMuestra.hoy, comidas: []))
        self.modeloInicial = modeloId
    }
    private let modeloInicial: String?
    @State private var cargado = false

    private var nombre: String { estado.paciente(pacienteId)?.primerNombre ?? "tu paciente" }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    NavAtras(atras: nombre, accionAtras: { guardar(); cerrar() }) {
                        Menu {
                            ForEach(estado.modelosDePlan) { m in
                                Button(m.nombre) { usarModelo(m.id) }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(plan.guardado == nil ? "Sin guardar" : "Guardado").tipo(.texto(15, 600))
                                IconoVista(.puntos, tamano: 20)
                            }
                            .foregroundStyle(Color.texto2)
                            .frame(minHeight: 44)
                        }
                        .accessibilityLabel("Usar un modelo de plan")
                    }
                    .padding(.horizontal, -Espacio.margen)
                    VStack(alignment: .leading, spacing: 6) {
                        Titulo(plan.nombre, tamano: 30)
                        Text("\(plan.dias) · desde el \(Fecha.diaMes(plan.desde))").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    }
                    ForEach(plan.comidas) { c in
                        TarjetaComidaN(comida: c, editable: true,
                                      editar: { item in edicion = Edicion(comida: c.id, item: item) },
                                      mover: { item, d in mover(c.id, item, d) },
                                      borrar: { item in borrar(c.id, item) },
                                      cambiarHora: { h in cambiarHora(c.id, h) })
                    }
                    if plan.comidas.count < Momento.allCases.count {
                        Menu {
                            ForEach(Momento.allCases.filter { m in !plan.comidas.contains { $0.momento == m } }) { m in
                                Button(m.titulo) { sumarComida(m) }
                            }
                        } label: {
                            HStack(spacing: 6) { IconoVista(.mas, tamano: 20); Text("Sumar una comida").tipo(.texto(14, 700)) }
                                .foregroundStyle(Color.enlace).frame(minHeight: 44)
                        }
                    }
                    NotaParaPaciente(nombre: nombre, nota: plan.nota) { editandoNota = true }
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            Pie {
                HStack(spacing: 10) {
                    Boton(titulo: "Ver como \(nombre)", variante: .crema, alto: .alto) { vistaPrevia = true }
                    Boton(titulo: plan.enviado ? "Mandar los cambios" : "Mandárselo a \(nombre)", variante: .prim, alto: .alto, ancho: true) {
                        guardar()
                        estado.enviarPlan(plan.id)
                        cerrar()
                    }
                }
            }
        }
        .background(Color.fondo.ignoresSafeArea())
        .barraClara(false)
        .onAppear {
            guard !cargado else { return }
            cargado = true
            plan = estado.planNuevo(para: pacienteId, modelo: modeloInicial)
        }
        .sheet(item: $edicion) { e in
            HojaItemPlan(item: item(e)) { nuevo in guardarItem(e, nuevo) }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $editandoNota) {
            HojaNotaPlan(nota: plan.nota, nombre: nombre) { plan.nota = $0; guardar() }
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $vistaPrevia) { VistaPreviaPlan(plan: plan, nombre: nombre) }
    }

    // MARK: Edición

    private func item(_ e: Edicion) -> ItemPlan? {
        plan.comidas.first { $0.id == e.comida }?.items.first { $0.id == e.item }
    }

    private func guardarItem(_ e: Edicion, _ nuevo: ItemPlan) {
        guard let c = plan.comidas.firstIndex(where: { $0.id == e.comida }) else { return }
        withAnimation(.snappy) {
            if let i = plan.comidas[c].items.firstIndex(where: { $0.id == nuevo.id }) { plan.comidas[c].items[i] = nuevo }
            else { plan.comidas[c].items.append(nuevo) }
        }
        guardar()
    }

    private func mover(_ comida: String, _ item: String, _ d: Int) {
        guard let c = plan.comidas.firstIndex(where: { $0.id == comida }),
              let i = plan.comidas[c].items.firstIndex(where: { $0.id == item }) else { return }
        let j = i + d
        guard j >= 0 && j < plan.comidas[c].items.count else { return }
        Haptico.seleccion()
        withAnimation(.snappy) { plan.comidas[c].items.swapAt(i, j) }
        guardar()
    }

    private func borrar(_ comida: String, _ item: String) {
        guard let c = plan.comidas.firstIndex(where: { $0.id == comida }) else { return }
        Haptico.seleccion()
        withAnimation(.snappy) { plan.comidas[c].items.removeAll { $0.id == item } }
        guardar()
    }

    private func cambiarHora(_ comida: String, _ h: String) {
        guard let c = plan.comidas.firstIndex(where: { $0.id == comida }) else { return }
        plan.comidas[c].hora = h
        guardar()
    }

    private func sumarComida(_ m: Momento) {
        Haptico.seleccion()
        withAnimation(.snappy) {
            plan.comidas.append(ComidaPlan(momento: m, hora: String(m.horaSugerida.drop(while: { $0 == "0" }))))
            plan.comidas.sort { (Momento.allCases.firstIndex(of: $0.momento) ?? 0) < (Momento.allCases.firstIndex(of: $1.momento) ?? 0) }
        }
        guardar()
    }

    private func usarModelo(_ id: String) {
        Haptico.seleccion()
        guard let m = estado.nutri.planes.first(where: { $0.id == id }) else { return }
        withAnimation(.snappy) { plan.comidas = m.comidas.map { var c = $0; c.id = UUID().uuidString; return c } }
        guardar()
        estado.avisar("Usamos «\(m.nombre)». Ajustalo a \(nombre).")
    }

    private func guardar() {
        estado.guardarPlan(plan)
        plan.guardado = estado.ahora
    }
}

/// Una comida del plan (.comida): título Nunito, hora, ítems con porción y asa, o el plato armado.
struct TarjetaComidaN: View {
    let comida: ComidaPlan
    var editable = false
    var editar: (String?) -> Void = { _ in }
    var mover: (String, Int) -> Void = { _, _ in }
    var borrar: (String) -> Void = { _ in }
    var cambiarHora: (String) -> Void = { _ in }
    @State private var opcion = 0

    var body: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Text(comida.momento.titulo).font(Estilo.titulo(19).font()).tracking(-0.3).foregroundStyle(Color.titulo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if comida.opciones.count > 1 {
                        Button {
                            Haptico.seleccion()
                            withAnimation(.snappy) { opcion = (opcion + 1) % comida.opciones.count }
                        } label: {
                            ChipEstado(texto: "\(comida.opciones.count) opciones", tipo: .crema)
                        }
                        .accessibilityHint("Cambia la opción que se ve")
                    }
                    hora
                }
                if let o = comida.opciones[safe: opcion] {
                    PlatoArmadoLeyendaN(opcion: o).padding(.top, 10)
                }
                ForEach(comida.items) { i in
                    Divisor().padding(.top, comida.opciones.isEmpty && i.id == comida.items.first?.id ? 10 : 0)
                    FilaItem(item: i, editable: editable, editar: { editar(i.id) }, subir: { mover(i.id, -1) },
                             bajar: { mover(i.id, 1) }, borrar: { borrar(i.id) })
                }
                if editable && comida.opciones.isEmpty {
                    Button { Haptico.seleccion(); editar(nil) } label: {
                        HStack(spacing: 6) { IconoVista(.mas, tamano: 20); Text("Sumar algo").tipo(.texto(14, 700)) }
                            .foregroundStyle(Color.enlace)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(Apretable())
                    .padding(.top, -2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, editable && comida.opciones.isEmpty ? 4 : 14)
        }
    }

    @ViewBuilder private var hora: some View {
        let t = Text(comida.hora).tipo(.texto(13, 600)).monospacedDigit().foregroundStyle(Color.texto2)
        if editable {
            Menu {
                ForEach(horas, id: \.self) { h in Button(h) { cambiarHora(h) } }
            } label: { t.frame(minWidth: 44, minHeight: 44, alignment: .trailing) }
            .padding(.vertical, -10)
            .accessibilityLabel("Hora del \(comida.momento.titulo.lowercased()): \(comida.hora)")
        } else {
            t
        }
    }

    private var horas: [String] {
        stride(from: 6 * 60, through: 23 * 60, by: 30).map { m in "\(m / 60):\(String(format: "%02d", m % 60))" }
    }
}

fileprivate extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

/// Un ítem (.item): nombre, porción en crema 300 y el asa para moverlo.
private struct FilaItem: View {
    let item: ItemPlan
    let editable: Bool
    var editar: () -> Void
    var subir: () -> Void
    var bajar: () -> Void
    var borrar: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(item.nombre).tipo(.texto(15, 600)).foregroundStyle(Color.texto).frame(maxWidth: .infinity, alignment: .leading)
            Text(item.porcion).tipo(.texto(13, 600)).foregroundStyle(Color.texto3)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.superficie2, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            if editable {
                Menu {
                    Button("Editar", action: editar)
                    Button("Subir", action: subir)
                    Button("Bajar", action: bajar)
                    Button("Sacar", role: .destructive, action: borrar)
                } label: {
                    IconoVista(.asa, tamano: 20).foregroundStyle(Color.salvia400).frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Opciones de \(item.nombre)")
            }
        }
        .padding(.vertical, -1)
        .contentShape(Rectangle())
        .onTapGesture { if editable { Haptico.seleccion(); editar() } }
    }
}

/// El plato armado con su leyenda (.plato-armado).
struct PlatoArmadoLeyendaN: View {
    let opcion: OpcionPlato
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            PlatoArmado(porciones: porciones).frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(opcion.partes.sorted { orden($0.tipo) < orden($1.tipo) }) { p in
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(color(p.tipo)).frame(width: 12, height: 12).padding(.top, 3)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(p.nombre).tipo(.texto(14, 600)).foregroundStyle(Color.texto)
                            Text(p.detalle).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// En el plato: proteína (cuarto de arriba a la derecha), almidón y la verdura en la mitad izquierda.
    private var porciones: [(Color, Double)] {
        [TipoPorcion.proteina, .almidon, .verdura].compactMap { t in
            opcion.partes.first { $0.tipo == t }.map { (color(t), $0.fraccion) }
        }
    }
    private func orden(_ t: TipoPorcion) -> Int { t == .verdura ? 0 : t == .proteina ? 1 : 2 }
    private func color(_ t: TipoPorcion) -> Color {
        switch t { case .verdura: return .hojaClara; case .proteina: return .acento; case .almidon: return .mandarina }
    }
}

/// «Para Sofía: si un día no sale, seguís en la próxima comida.» (.nota-pac)
private struct NotaParaPaciente: View {
    let nombre: String
    let nota: String
    var editar: () -> Void
    var body: some View {
        Button { Haptico.seleccion(); editar() } label: {
            HStack(alignment: .top, spacing: 10) {
                IconoVista(.mensaje, tamano: 20).foregroundStyle(Color.logroTexto).padding(.top, 1)
                (Text("Para \(nombre): ").font(Estilo.texto(14, 700).font()) +
                 Text(nota.isEmpty ? "sumale una frase para acompañar el plan." : nota).font(Estilo.texto(14, 400).font()))
                    .foregroundStyle(Color.sobreLogro)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(Apretable())
        .accessibilityHint("Editar la nota")
    }
}

/// Editar o sumar un ítem: nombre y una porción casera.
private struct HojaItemPlan: View {
    let item: ItemPlan?
    var guardar: (ItemPlan) -> Void
    @Environment(\.dismiss) private var cerrar
    @State private var nombre = ""
    @State private var porcion = ""
    private let porciones = ["1 taza", "2 rodajas", "1 plato hondo", "1 pote", "un puñado", "del tamaño de tu mano", "1 unidad", "a gusto"]

    var body: some View {
        HojaBaseN(titulo: item == nil ? "Sumar algo" : "Editar") {
            CampoN(etiqueta: "Qué", texto: $nombre, prompt: "Yogur con durazno")
            CampoN(etiqueta: "Cuánto", texto: $porcion, prompt: "1 pote")
            Fluir(espacio: 8) {
                ForEach(porciones, id: \.self) { p in ChipOpcion(titulo: p, elegido: porcion == p, alto: 36) { porcion = p } }
            }
        } pie: {
            PieHojaN {
                Boton(titulo: "Listo", variante: .prim, alto: .alto, ancho: true, habilitado: !nombre.trimmingCharacters(in: .whitespaces).isEmpty) {
                    guardar(ItemPlan(id: item?.id ?? UUID().uuidString, nombre: nombre, porcion: porcion.isEmpty ? "a gusto" : porcion))
                    cerrar()
                }
            }
        }
        .onAppear { nombre = item?.nombre ?? ""; porcion = item?.porcion ?? "" }
    }
}

private struct HojaNotaPlan: View {
    @State var nota: String
    let nombre: String
    var guardar: (String) -> Void
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        HojaBaseN(titulo: "Para \(nombre)", bajada: "La ve arriba de su plan. Corta y sin culpa.") {
            CampoN(etiqueta: "", texto: $nota, prompt: "si un día no sale, seguís en la próxima comida.", multilinea: true)
        } pie: {
            PieHojaN { Boton(titulo: "Guardar", variante: .prim, alto: .alto, ancho: true) { guardar(nota); cerrar() } }
        }
    }
}

/// «Ver como Sofía»: el plan como lo ve el paciente, sin edición.
private struct VistaPreviaPlan: View {
    let plan: PlanAlimentario
    let nombre: String
    var body: some View {
        HojaBaseN(titulo: "Tu plan", bajada: "Así lo ve \(nombre) · \(plan.nombre.replacingOccurrences(of: "\u{00A0}", with: " "))") {
            if !plan.nota.isEmpty {
                Text(plan.nota.prefix(1).uppercased() + plan.nota.dropFirst()).tipo(.texto(15, 600)).foregroundStyle(Color.texto)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.logroSuave, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            ForEach(plan.comidas) { TarjetaComidaN(comida: $0) }
        }
    }
}
