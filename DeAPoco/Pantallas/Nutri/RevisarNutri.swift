import SwiftUI

/// Revisar comidas (p6): una pila de fotos, de a una, con comentarios rápidos. Fondo enlozado-950 siempre.
struct RevisarComidas: View {
    nonisolated(unsafe) static var empezarEn = 0
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var ids: [String] = []
    @State private var indice = 0
    @State private var rapido: String? = "¡Bien ahí!"
    @State private var texto = ""
    @State private var arrastre: CGSize = .zero
    @FocusState private var escribiendo: Bool

    static let rapidos = ["¡Bien ahí!", "Qué buena pinta", "Sumale una fruta", "Contame más"]

    var body: some View {
        ZStack {
            Color.enlozado950.ignoresSafeArea()
            VStack(spacing: 0) {
                cabecera
                if indice < ids.count, let r = estado.nutri.registros.first(where: { $0.id == ids[indice] }) {
                    pila(r)
                    Rapidos(elegido: $rapido)
                    Spacer(minLength: 0)
                    Escribir(texto: $texto, escribiendo: $escribiendo) { enviar(r) }
                } else {
                    Terminado { cerrar() }
                }
            }
        }
        .barraClara()
        .onAppear {
            guard ids.isEmpty else { return }
            // Agrupadas por paciente: así se miran juntas las comidas de cada uno.
            let lista = estado.porRevisar
            var orden: [String] = []
            for r in lista where !orden.contains(r.pacienteId) { orden.append(r.pacienteId) }
            ids = orden.flatMap { id in lista.filter { $0.pacienteId == id }.map(\.id) }
            indice = min(RevisarComidas.empezarEn, max(ids.count - 1, 0))
            RevisarComidas.empezarEn = 0
        }
    }

    private var cabecera: some View {
        VStack(spacing: 4) {
            HStack {
                Redondo(icono: .x, tamanoIcono: 20, etiqueta: "Cerrar") { cerrar() }
                Spacer()
                Text(ids.isEmpty ? "" : "\(min(indice + 1, ids.count)) de \(ids.count)").tipo(.texto(16, 700)).foregroundStyle(Color.mantecaFija)
                    .monospacedDigit()
                Spacer()
                Redondo(icono: .chev, tamanoIcono: 20, etiqueta: "Saltear") { siguiente() }
                    .opacity(indice < ids.count ? 1 : 0)
            }
            .padding(.horizontal, 18)
            .frame(height: 48)
            HStack(spacing: 4) {
                ForEach(0..<ids.count, id: \.self) { i in
                    Capsule().fill(i <= indice ? Color.mantecaFija : Color.mantecaFija.opacity(0.2)).frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
            .accessibilityHidden(true)
        }
    }

    private func pila(_ r: Registro) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x1F2D4C))
                .padding(.horizontal, 28).offset(y: -20)
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x2A3A5E))
                .padding(.horizontal, 14).offset(y: -10)
            TarjetaFoto(registro: r)
                .offset(x: arrastre.width, y: arrastre.height * 0.2)
                .rotationEffect(.degrees(Double(arrastre.width) / 25))
                .gesture(DragGesture()
                    .onChanged { arrastre = $0.translation }
                    .onEnded { g in
                        if abs(g.translation.width) > 110 { enviar(r) } else { withAnimation(.spring(duration: 0.3)) { arrastre = .zero } }
                    })
                .id(r.id)
                .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
        }
        .frame(height: 470)
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 18)
    }

    private func enviar(_ r: Registro) {
        let t = texto.trimmingCharacters(in: .whitespaces)
        let respuesta = t.isEmpty ? rapido : t
        estado.revisar(r.id, respuesta: respuesta, bienAhi: rapido == RevisarComidas.rapidos[0])
        texto = ""
        escribiendo = false
        siguiente()
    }

    private func siguiente() {
        withAnimation(.spring(duration: 0.4)) {
            arrastre = .zero
            indice += 1
            rapido = RevisarComidas.rapidos[0]
        }
    }
}

/// La foto con quién, cuándo y lo que decía el plan (.cfoto).
private struct TarjetaFoto: View {
    let registro: Registro
    @Environment(Estado.self) private var estado

    var body: some View {
        let r = registro
        let p = estado.paciente(r.pacienteId)
        ZStack {
            if let f = r.foto { FotoRecortada(nombre: f) } else { Color.enlozado900 }
            LinearGradient(stops: [.init(color: Color.enlozado950.opacity(0.55), location: 0), .init(color: .clear, location: 0.26),
                                   .init(color: .clear, location: 0.58), .init(color: Color.enlozado950.opacity(0.86), location: 1)],
                           startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Avatar(foto: p?.foto, iniciales: p?.iniciales ?? "", tono: p?.tono ?? .durazno, anillo: .white)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(p?.nombre ?? "").tipo(.texto(15, 700))
                        Text("\(r.momento.titulo) · \(Fecha.relativa(r.fecha, hoy: estado.hoy)) \(r.hora)").tipo(.texto(13, 400)).opacity(0.9)
                    }
                    .foregroundStyle(.white)
                }
                Spacer()
                Etiqueta(r.enPlan == nil ? "Lo que comió" : "En el plan", color: .enlozado100)
                Text(r.enPlan ?? r.descripcion).tipo(.texto(17, 600)).foregroundStyle(.white).padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                Fluir(espacio: 6) {
                    if r.comoElPlan == true { ChipEstado(texto: "Como el plan", icono: .check, tipo: .ok) }
                    if r.comoElPlan == false { ChipEstado(texto: "Cambió: \(r.descripcion.lowercased())", tipo: .vidrio) }
                    if let s = r.sensacion { ChipEstado(texto: sensacion(s), tipo: .vidrio) }
                    if !r.nota.isEmpty { ChipEstado(texto: "«\(r.nota)»", tipo: .vidrio) }
                }
                .padding(.top, 10)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 25, y: 24)
        .accessibilityElement(children: .combine)
    }

    private func sensacion(_ s: Sensacion) -> String {
        switch s { case .hambre: return "Llegó con hambre"; case .bien: return "Llegó bien, sin hambre"; case .lleno: return "Quedó lleno" }
    }
}

/// Los comentarios rápidos (.rapidos): el elegido en manteca con el bocado rabanito.
private struct Rapidos: View {
    @Binding var elegido: String?
    var body: some View {
        Fluir(espacio: 8) {
            ForEach(RevisarComidas.rapidos, id: \.self) { t in
                let on = elegido == t
                Button {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.2)) { elegido = on ? nil : t }
                } label: {
                    HStack(spacing: 6) {
                        if t == RevisarComidas.rapidos[0] {
                            IconoVista(.bocado, tamano: 14).foregroundStyle(on ? Color.rabanito500 : Color.mantecaFija)
                        }
                        Text(t).tipo(.texto(14.5, 600))
                    }
                    .foregroundStyle(on ? Color.enlozado800 : Color.mantecaFija)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(on ? Color.mantecaFija : Color.mantecaFija.opacity(0.1), in: Capsule())
                    .overlay(Capsule().strokeBorder(on ? Color.mantecaFija : Color.mantecaFija.opacity(0.16), lineWidth: 1))
                    .frame(minHeight: 44)
                }
                .buttonStyle(Apretable())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }
}

/// La caja para escribirle (.escribir) y el botón de mandar en manteca.
private struct Escribir: View {
    @Binding var texto: String
    var escribiendo: FocusState<Bool>.Binding
    var enviar: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack {
                TextField("", text: $texto, prompt: Text("Escribile algo…").foregroundColor(.corteza300))
                    .font(Estilo.texto(15, 400).font())
                    .foregroundStyle(Color.mantecaFija)
                    .tint(Color.durazno)
                    .focused(escribiendo)
                    .submitLabel(.send)
                    .onSubmit(enviar)
                IconoVista(.mic, tamano: 24).foregroundStyle(Color.mantecaFija).accessibilityHidden(true)
            }
            .padding(.leading, 18).padding(.trailing, 10)
            .frame(height: 52)
            .background(Color.mantecaFija.opacity(0.1), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.mantecaFija.opacity(0.18), lineWidth: 1))
            Button { Haptico.suave(); enviar() } label: {
                IconoVista(.enviar, tamano: 24).foregroundStyle(Color.enlozado800)
                    .frame(width: 52, height: 52).background(Color.mantecaFija, in: Circle())
            }
            .buttonStyle(Apretable())
            .accessibilityLabel("Mandar y pasar a la siguiente")
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.bottom, 8)
    }
}

/// Cuando ya no quedan: el plato lleno.
private struct Terminado: View {
    var cerrar: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Plato(partes: 4, llenas: 4, servir: true, fondo: .enlozado900, borde: .mantecaFija).frame(width: 140, height: 140)
            Titulo("Miraste todo.", tamano: 32, color: .mantecaFija, centrado: true).fixedSize(horizontal: false, vertical: true)
            Text("Les llegó tu respuesta. Mañana hay más.").tipo(.texto(16, 400)).foregroundStyle(Color.sobreBanda2)
            Spacer()
            Boton(titulo: "Volver", variante: .man, alto: .alto, ancho: true, accion: cerrar)
                .padding(.horizontal, Espacio.margen).padding(.bottom, 8)
        }
        .padding(.horizontal, 32)
    }
}
