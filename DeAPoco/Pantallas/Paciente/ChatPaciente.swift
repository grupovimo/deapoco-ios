import SwiftUI
import PhotosUI

/// Mensajes con la nutri (p13): burbujas, fotos de comidas, audios, respuestas rápidas y la caja para escribir.
struct ChatPaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @State private var texto = ""
    @State private var foto: PhotosPickerItem?
    @FocusState private var escribiendo: Bool

    private let rapidas = ["¡Gracias!", "Dale, lo pruebo", "Tengo una duda"]

    var body: some View {
        VStack(spacing: 0) {
            CabeceraChat()
            ScrollViewReader { lector in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        if estado.paciente.mensajes.isEmpty {
                            Vacio(titulo: "Escribile a \(estado.paciente.nutri.nombre)", texto: "Una duda, una foto o cómo te fue. Te contesta \(estado.paciente.nutri.responde.lowercased().replacingOccurrences(of: "responde ", with: "")).")
                        }
                        ForEach(grupos, id: \.0) { dia, ms in
                            Text(dia).font(Estilo.texto(12, 700).font()).tracking(0.72).foregroundStyle(Color.texto2).padding(.vertical, 6)
                            ForEach(ms) { m in Burbuja(mensaje: m).id(m.id) }
                        }
                        Color.clear.frame(height: 8).id("fin")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onAppear { lector.scrollTo("fin", anchor: .bottom) }
                .onChange(of: estado.paciente.mensajes.count) { withAnimation { lector.scrollTo("fin", anchor: .bottom) } }
            }
            if texto.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(rapidas, id: \.self) { r in
                            Button { Haptico.seleccion(); estado.enviarMensajePaciente(texto: r) } label: {
                                Text(r).tipo(.texto(14, 600)).foregroundStyle(Color.enlace)
                                    .padding(.horizontal, 14).frame(height: 36)
                                    .background(Color.superficie, in: Capsule())
                                    .overlay(Capsule().strokeBorder(Color(claro: 0xC6D4F2, oscuro: 0x2C3C60), lineWidth: 1.5))
                                    .frame(minHeight: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(Apretable())
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.bottom, 8)
            }
            caja
        }
        .background(Color.fondo.ignoresSafeArea())
        .barraClara(false)
        .onAppear { estado.leerMensajesPaciente() }
        .onChange(of: foto) { _, item in
            guard let item else { return }
            Task {
                if let d = try? await item.loadTransferable(type: Data.self) {
                    estado.enviarMensajePaciente(foto: UIImage(data: d)?.jpegData(compressionQuality: 0.8) ?? d)
                }
                foto = nil
            }
        }
    }

    private var grupos: [(String, [Mensaje])] {
        var orden: [String] = [], porDia: [String: [Mensaje]] = [:]
        for m in estado.paciente.mensajes {
            if porDia[m.fecha] == nil { orden.append(m.fecha) }
            porDia[m.fecha, default: []].append(m)
        }
        return orden.sorted().map { f in
            let d = Fecha.dias(entre: f, y: estado.paciente.hoy)
            let titulo = d == 0 ? "HOY" : d == 1 ? "AYER" : Fecha.larga(f).uppercased()
            return (titulo, porDia[f] ?? [])
        }
    }

    private var caja: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $foto, matching: .images) {
                IconoVista(.foto, tamano: 20).foregroundStyle(Color.marca)
                    .frame(width: 44, height: 44).background(Color.superficie, in: Circle()).sombraChica()
            }
            .buttonStyle(Apretable())
            .accessibilityLabel("Mandar una foto")
            TextField("", text: $texto, prompt: Text("Escribile a \(estado.paciente.nutri.nombre)").foregroundColor(.texto2), axis: .vertical)
                .font(Estilo.texto(15, 400).font())
                .foregroundStyle(Color.texto)
                .lineLimit(1...4)
                .focused($escribiendo)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .frame(minHeight: 44)
                .background(Color.superficie, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.borde, lineWidth: 1))
            Button {
                if texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Haptico.suave()
                    estado.avisar("Mantené apretado para grabar un audio.")
                } else {
                    estado.enviarMensajePaciente(texto: texto.trimmingCharacters(in: .whitespacesAndNewlines))
                    texto = ""
                }
            } label: {
                IconoVista(texto.isEmpty ? .mic : .enviar, tamano: 20).foregroundStyle(Color.sobreMarca)
                    .frame(width: 44, height: 44).background(Color.marca, in: Circle())
                    .contentTransition(.opacity)
            }
            .buttonStyle(Apretable())
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                guard texto.isEmpty else { return }
                estado.enviarMensajePaciente(audio: 12)
            })
            .accessibilityLabel(texto.isEmpty ? "Grabar un audio" : "Enviar")
        }
        .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 8)
        .background(Color.fondo.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Divisor() }
    }
}

private struct CabeceraChat: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    var body: some View {
        HStack(spacing: 10) {
            Button { Haptico.seleccion(); withAnimation { nav.volverDelChat() } } label: {
                IconoVista(.atras, tamano: 24).foregroundStyle(Color.marca).frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
            .accessibilityLabel("Volver")
            Avatar(foto: estado.paciente.nutri.foto)
            VStack(alignment: .leading, spacing: 0) {
                Text(estado.paciente.nutri.nombreCompleto).tipo(.texto(16, 700)).foregroundStyle(Color.texto)
                Text(estado.paciente.nutri.responde).tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Redondo(icono: .turno, variante: .claro, tamanoIcono: 20, etiqueta: "Tu próxima consulta") {
                nav.pestana = .hoy
                nav.hoy = [.turno]
            }
        }
        .padding(.leading, 4).padding(.trailing, 14).padding(.bottom, 8)
        .overlay(alignment: .bottom) { Divisor() }
    }
}

/// Una burbuja (.bur): la nutri en blanco a la izquierda, uno en enlozado a la derecha.
private struct Burbuja: View {
    let mensaje: Mensaje
    var body: some View {
        let mio = !mensaje.deNutri
        HStack {
            if mio { Spacer(minLength: 60) }
            contenido
                .background(mio ? Color.marca : Color.superficie,
                            in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: mio ? 20 : 6,
                                                       bottomTrailingRadius: mio ? 6 : 20, topTrailingRadius: 20, style: .continuous))
                .modifier(SombraSi(activa: !mio))
            if !mio { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder private var contenido: some View {
        let mio = !mensaje.deNutri
        if let f = mensaje.foto {
            VStack(alignment: .leading, spacing: 0) {
                FotoRecortada(nombre: f).frame(width: 192, height: 128).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                HStack {
                    Text(mensaje.pieFoto ?? "Foto").tipo(.texto(15, 400))
                    Spacer()
                    hora(mio)
                }
                .foregroundStyle(mio ? Color.sobreMarca : Color.texto)
                .padding(.horizontal, 10).padding(.top, 6).padding(.bottom, 4)
            }
            .padding(4)
            .frame(width: 200)
        } else if let s = mensaje.audio {
            Audio(segundos: s, mio: mio).padding(.horizontal, 14).padding(.vertical, 10).frame(width: 250, alignment: .leading)
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                Text(mensaje.texto ?? "").tipo(.texto(15, 400)).foregroundStyle(mio ? Color.sobreMarca : Color.texto)
                    .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                hora(mio)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 290, alignment: .leading)
        }
    }

    private func hora(_ mio: Bool) -> some View {
        Text(mensaje.hora).font(Estilo.texto(11, 400).font()).monospacedDigit()
            .foregroundStyle(mio ? Color(claro: 0xC6D4F2, oscuro: 0x2E5293) : Color.texto2)
    }
}

private struct SombraSi: ViewModifier {
    let activa: Bool
    func body(content: Content) -> some View { if activa { content.sombraChica() } else { content } }
}

/// Un audio: play, la onda que se va pintando y la duración.
private struct Audio: View {
    let segundos: Int
    let mio: Bool
    @State private var sonando = false
    @State private var avance = 8

    var body: some View {
        HStack(spacing: 10) {
            Button {
                Haptico.seleccion()
                sonando.toggle()
            } label: {
                IconoVista(sonando ? .pausa : .play, tamano: 16)
                    .foregroundStyle(mio ? Color.marca : Color.sobreMarca)
                    .frame(width: 34, height: 34).background(mio ? Color.sobreMarca : Color.marca, in: Circle())
                    .contentShape(Rectangle().inset(by: -6))
            }
            .buttonStyle(Apretable())
            .accessibilityLabel(sonando ? "Pausar el audio" : "Escuchar el audio de \(segundos) segundos")
            Onda(escuchado: avance)
            Text(String(format: "%d:%02d", segundos / 60, segundos % 60)).font(Estilo.texto(11, 400).font()).monospacedDigit()
                .foregroundStyle(mio ? Color.sobreBanda2 : Color.texto2)
        }
        .task(id: sonando) {
            guard sonando else { return }
            while sonando && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(max(80, segundos * 1000 / Onda.alturas.count)))
                withAnimation(.linear(duration: 0.1)) { avance = avance >= Onda.alturas.count ? 0 : avance + 1 }
                if avance == 0 { sonando = false }
            }
        }
    }
}
