import SwiftUI
import PhotosUI

/// Bandeja de mensajes: una conversación por paciente, la más nueva arriba.
struct BandejaMensajes: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        PantallaClaraN {
            NavAtras(atras: "Hoy") {
                Boton(titulo: "A varios", icono: .gente, variante: .suave, alto: .chico) { nav.hoja = .mensajeVarios }
            }
            Titulo("Mensajes", tamano: 30).padding(.horizontal, Espacio.margen)
            Text("Respondés de lunes a viernes. Ellos lo saben.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                .padding(.horizontal, Espacio.margen)
            let convs = estado.conversaciones
            Tarjeta {
                if convs.isEmpty {
                    Vacio(titulo: "Sin mensajes", texto: "Cuando un paciente te escriba, aparece acá.", accion: "Escribirle a alguien") { nav.hoja = .mensajeVarios }
                }
                ForEach(Array(convs.enumerated()), id: \.element.paciente.id) { i, c in
                    if i > 0 { Divisor() }
                    Button { Haptico.seleccion(); nav.abrir(.chat(c.paciente.id)) } label: {
                        FilaConversacion(paciente: c.paciente, ultimo: c.ultimo, sinLeer: estado.noLeidos(c.paciente.id))
                    }
                    .buttonStyle(Apretable())
                }
            }
            .padding(.horizontal, Espacio.margen)
        }
    }
}

private struct FilaConversacion: View {
    let paciente: Paciente
    let ultimo: Mensaje
    let sinLeer: Int
    @Environment(Estado.self) private var estado

    var body: some View {
        Fila(alto: 72) {
            Avatar(foto: paciente.foto, iniciales: paciente.iniciales, tono: paciente.tono, tamano: 48)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(paciente.nombre).tipo(.texto(15, sinLeer > 0 ? 700 : 600)).foregroundStyle(Color.texto).lineLimit(1)
                    Spacer()
                    Text(ultimo.fecha == estado.hoy ? ultimo.hora : Fecha.corta(ultimo.fecha)).tipo(.texto(12, 600)).monospacedDigit()
                        .foregroundStyle(sinLeer > 0 ? Color.acentoTexto : Color.texto2)
                }
                HStack {
                    Text((ultimo.deNutri ? "Vos: " : "") + resumen(ultimo)).tipo(.texto(13, sinLeer > 0 ? 600 : 400))
                        .foregroundStyle(sinLeer > 0 ? Color.texto : Color.texto2).lineLimit(1)
                    Spacer()
                    if sinLeer > 0 { Badge(n: sinLeer, aro: .superficie) }
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func resumen(_ m: Mensaje) -> String {
        if let t = m.texto { return t }
        if m.foto != nil { return "Foto · \(m.pieFoto ?? "comida")" }
        if let a = m.audio { return "Audio · \(a / 60):\(String(format: "%02d", a % 60))" }
        return m.adjunto ?? ""
    }
}

/// El chat con un paciente (como p13, del lado de la nutri): burbujas, respuestas rápidas, foto y audio.
struct ChatNutri: View {
    let pacienteId: String
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var texto = ""
    @State private var foto: PhotosPickerItem?
    @FocusState private var escribiendo: Bool

    var body: some View {
        let p = estado.paciente(pacienteId)
        VStack(spacing: 0) {
            CabeceraChat(paciente: p) { nav.hoja = .darTurno(paciente: pacienteId, fecha: nil, hora: nil) }
            ScrollViewReader { lector in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        let msjs = estado.chat(pacienteId)
                        if msjs.isEmpty {
                            Vacio(titulo: "Todavía no hablaron", texto: "Un «¿cómo venís?» alcanza para arrancar.", icono: .mensaje)
                        }
                        ForEach(Array(msjs.enumerated()), id: \.element.id) { i, m in
                            if i == 0 || msjs[i - 1].fecha != m.fecha {
                                Etiqueta(m.fecha == estado.hoy ? "Hoy" : Fecha.larga(m.fecha)).padding(.vertical, 6)
                            }
                            Burbuja(mensaje: m, mia: m.deNutri).id(m.id)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { lector.scrollTo(estado.chat(pacienteId).last?.id, anchor: .bottom) }
                .onChange(of: estado.chat(pacienteId).count) { withAnimation { lector.scrollTo(estado.chat(pacienteId).last?.id, anchor: .bottom) } }
            }
            RespuestasRapidas(opciones: ["¡Bien ahí!", "Dale, lo vemos el jueves", "Mandame una foto"]) { estado.enviarMensajeNutri(pacienteId, texto: $0) }
            CajaMensaje(texto: $texto, foto: $foto, escribiendo: $escribiendo, para: p?.primerNombre ?? "") {
                let t = texto.trimmingCharacters(in: .whitespaces)
                guard !t.isEmpty else { estado.avisar("Mantené apretado para grabar un audio."); return }
                estado.enviarMensajeNutri(pacienteId, texto: t); texto = ""
            }
        }
        .background(Color.fondo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .barraClara(false)
        .onAppear { estado.marcarLeidos(pacienteId) }
        .onChange(of: foto) {
            guard let foto else { return }
            Task {
                if let d = try? await foto.loadTransferable(type: Data.self) {
                    estado.enviarMensajeNutri(pacienteId, foto: Archivos.guardar(d))
                }
                self.foto = nil
            }
        }
    }
}

/// La cabecera del chat (.chat-cab).
private struct CabeceraChat: View {
    let paciente: Paciente?
    var turno: () -> Void
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        HStack(spacing: 10) {
            Button { Haptico.seleccion(); cerrar() } label: {
                IconoVista(.atras, tamano: 24).foregroundStyle(Color.marca).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Volver")
            Avatar(foto: paciente?.foto, iniciales: paciente?.iniciales ?? "", tono: paciente?.tono ?? .mandarina)
            VStack(alignment: .leading, spacing: 0) {
                Text(paciente?.nombre ?? "").tipo(.texto(16, 700)).foregroundStyle(Color.texto)
                Text(paciente.map { $0.resumenRitmo } ?? "").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Redondo(icono: .turno, variante: .claro, tamanoIcono: 20, etiqueta: "Darle un turno", accion: turno)
        }
        .padding(.leading, 8).padding(.trailing, 16).padding(.bottom, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.borde).frame(height: 1) }
    }
}

/// Una burbuja (.bur): la mía en verde a la derecha, la otra en blanco a la izquierda.
private struct Burbuja: View {
    let mensaje: Mensaje
    let mia: Bool

    var body: some View {
        let m = mensaje
        HStack {
            if mia { Spacer(minLength: 60) }
            VStack(alignment: .leading, spacing: 4) {
                if let f = m.foto {
                    FotoRecortada(nombre: f).frame(width: 192, height: 128).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                if let a = m.audio {
                    HStack(spacing: 10) {
                        IconoVista(.play, tamano: 16).foregroundStyle(mia ? Color.verde900 : Color.crema)
                            .frame(width: 34, height: 34).background(mia ? Color.crema : Color.verde900, in: Circle())
                        Onda()
                        Text("\(a / 60):\(String(format: "%02d", a % 60))").tipo(.texto(11, 400)).monospacedDigit()
                    }
                }
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    if let t = m.texto ?? m.pieFoto { Text(t).tipo(.texto(15, 400)).fixedSize(horizontal: false, vertical: true) }
                    Spacer(minLength: 0)
                    Text(m.hora).tipo(.texto(11, 400)).monospacedDigit().opacity(0.75)
                }
                .padding(.horizontal, m.foto != nil ? 10 : 0)
            }
            .foregroundStyle(mia ? Color.sobreMarca : Color.texto)
            .padding(m.foto != nil ? 4 : 0)
            .padding(.horizontal, m.foto != nil ? 0 : 14)
            .padding(.vertical, m.foto != nil ? 4 : 10)
            .background(mia ? Color.marca : Color.superficie,
                        in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: mia ? 20 : 6, bottomTrailingRadius: mia ? 6 : 20,
                                                   topTrailingRadius: 20, style: .continuous))
            .modifier(SombraBurbuja(activa: !mia))
            .frame(maxWidth: 290, alignment: mia ? .trailing : .leading)
            if !mia { Spacer(minLength: 60) }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SombraBurbuja: ViewModifier {
    let activa: Bool
    func body(content: Content) -> some View { if activa { content.sombraChica() } else { content } }
}

/// Respuestas rápidas (.respuestas).
private struct RespuestasRapidas: View {
    let opciones: [String]
    var elegir: (String) -> Void
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(opciones, id: \.self) { o in
                    Button { Haptico.seleccion(); elegir(o) } label: {
                        Text(o).tipo(.texto(14, 600)).foregroundStyle(Color.titulo)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(Color.superficie, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color(claro: 0xDCD6C2, oscuro: 0x24503D), lineWidth: 1.5))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(Apretable())
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}

/// La caja de abajo (.caja-msj): foto, campo y mandar (o micrófono).
private struct CajaMensaje: View {
    @Binding var texto: String
    @Binding var foto: PhotosPickerItem?
    var escribiendo: FocusState<Bool>.Binding
    let para: String
    var enviar: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $foto, matching: .images) {
                IconoVista(.foto, tamano: 20).foregroundStyle(Color.marca)
                    .frame(width: 44, height: 44).background(Color.superficie, in: Circle()).sombraChica()
            }
            .accessibilityLabel("Mandar una foto")
            TextField("", text: $texto, prompt: Text("Escribile a \(para)").foregroundColor(.salvia), axis: .vertical)
                .font(Estilo.texto(15, 400).font())
                .foregroundStyle(Color.texto)
                .lineLimit(1...4)
                .focused(escribiendo)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .frame(minHeight: 44)
                .background(Color.superficie, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.borde, lineWidth: 1))
            Button { Haptico.suave(); enviar() } label: {
                IconoVista(texto.isEmpty ? .mic : .enviar, tamano: 20).foregroundStyle(Color.sobreMarca)
                    .frame(width: 44, height: 44).background(Color.marca, in: Circle())
            }
            .buttonStyle(Apretable())
            .accessibilityLabel(texto.isEmpty ? "Grabar un audio" : "Mandar")
        }
        .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)
        .background(Color.fondo.overlay(alignment: .top) { Rectangle().fill(Color.borde).frame(height: 1) }.ignoresSafeArea(edges: .bottom))
    }
}

/// Avisos de la nutri.
struct AvisosNutri: View {
    @Environment(Estado.self) private var estado

    var body: some View {
        PantallaClaraN {
            NavAtras(atras: "Hoy") {
                if estado.avisosSinLeerNutri > 0 {
                    Button("Marcar leídos") { Haptico.seleccion(); withAnimation { estado.marcarAvisosLeidosNutri() } }
                        .font(Estilo.texto(15, 600).font()).foregroundStyle(Color.enlace).frame(minHeight: 44)
                }
            }
            Titulo("Avisos", tamano: 30).padding(.horizontal, Espacio.margen)
            Tarjeta {
                if estado.nutri.avisos.isEmpty {
                    Vacio(titulo: "Nada nuevo", texto: "Acá te avisamos de turnos, pagos y comidas.", icono: .campana)
                }
                ForEach(Array(estado.nutri.avisos.enumerated()), id: \.element.id) { i, a in
                    if i > 0 { Divisor() }
                    FilaAviso(aviso: a, hoy: estado.hoy)
                }
            }
            .padding(.horizontal, Espacio.margen)
        }
    }
}

private struct FilaAviso: View {
    let aviso: AvisoApp
    let hoy: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconoCirculo(icono: aviso.tipo.icono, tono: tono)
            VStack(alignment: .leading, spacing: 2) {
                Text(aviso.titulo).tipo(.texto(15, aviso.leido ? 600 : 700)).foregroundStyle(Color.texto)
                Text(aviso.texto).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 6) {
                Text(aviso.fecha == hoy ? aviso.hora : Fecha.corta(aviso.fecha)).tipo(.texto(12, 600)).monospacedDigit().foregroundStyle(Color.texto2)
                if !aviso.leido { Circle().fill(Color.acento).frame(width: 8, height: 8).accessibilityLabel("Nuevo") }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var tono: IconoCirculo.Tono {
        switch aviso.tipo {
        case .pago: return .ok
        case .turno: return .aviso
        case .logro: return .dur
        default: return .az
        }
    }
}
