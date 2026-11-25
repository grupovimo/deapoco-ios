import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins

/// Tu perfil profesional: lo que ven los pacientes nuevos en tu página (deapoco.com.ar/laura).
struct PerfilProfesional: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        let p = estado.perfilNutri
        PantallaBandaN(abajoBanda: 20) {
            NavAtras(atras: "Hoy") {
                Boton(titulo: "Editar", icono: .lapiz, variante: .vidrio, alto: .chico) { nav.hoja = .editarPerfil }
            }
            HStack(spacing: 14) {
                Avatar(foto: p.foto, iniciales: inicialesDe(p.nombre), tamano: 72, anillo: .mantecaFija, anilloAncho: 3)
                VStack(alignment: .leading, spacing: 4) {
                    Titulo(p.nombre, tamano: 28, color: .mantecaFija)
                    Text("\(p.titulo) · \(p.matricula.isEmpty ? "sin matrícula" : p.matricula)").tipo(.texto(14, 400)).foregroundStyle(Color.sobreBanda2)
                }
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 2)
            Completitud(porcentaje: p.completitud).padding(.horizontal, Espacio.margen).padding(.top, 16)
        } cuerpo: {
            if !p.pendientes.isEmpty {
                TituloSeccion(texto: "Para completar", dato: "\(p.pendientes.count)")
                Tarjeta {
                    ForEach(Array(p.pendientes.enumerated()), id: \.offset) { i, x in
                        if i > 0 { Divisor() }
                        Button { Haptico.seleccion(); nav.hoja = .editarPerfil } label: {
                            Fila { IconoCirculo(icono: .lapiz, tono: .dur); NomSub(nombre: x.0, sub: x.1, lineas: 2); IconoVista(.chev, tamano: 16).foregroundStyle(Color.corteza400) }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(Apretable())
                    }
                }
            }
            TituloSeccion(texto: "Tu página")
            TarjetaLink()
            HStack(spacing: 10) {
                AccesoN(icono: .ojo, titulo: "Así te ven", sub: "Tu página pública", tono: .az) { nav.abrir(.asiTeVen) }
                AccesoN(icono: .qr, titulo: "Tu QR", sub: "Para el consultorio", tono: .dur) { nav.hoja = .qr }
            }
            TituloSeccion(texto: "Sobre vos")
            Tarjeta(relleno: 16) {
                Text("«\(p.frase)»").font(Estilo.titulo(20).font()).foregroundStyle(Color.titulo).fixedSize(horizontal: false, vertical: true)
                Text(p.sobreMi).tipo(.texto(15, 400)).foregroundStyle(Color.texto).padding(.top, 8).fixedSize(horizontal: false, vertical: true)
                Fluir(espacio: 6) { ForEach(p.especialidades, id: \.self) { ChipEstado(texto: $0, tipo: .info) } }.padding(.top, 12)
            }
            TituloSeccion(texto: "Dónde atendés")
            Tarjeta {
                ForEach(Array(p.lugares.enumerated()), id: \.element.id) { i, l in
                    if i > 0 { Divisor() }
                    Fila { IconoCirculo(icono: .lugar, tono: .az); NomSub(nombre: l.nombre, sub: "\(l.direccion) · \(l.dias)", lineas: 2) }
                }
                if p.enLinea {
                    if !p.lugares.isEmpty { Divisor() }
                    Fila { IconoCirculo(icono: .video, tono: .az); NomSub(nombre: "En línea", sub: "Videollamada desde la app") }
                }
            }
            TituloSeccion(texto: "Tus precios", dato: "Editar\u{00A0}›") { nav.ir(.cobros); nav.cobros = [.precios] }
            Tarjeta {
                ForEach(Array(estado.nutri.servicios.enumerated()), id: \.element.id) { i, s in
                    if i > 0 { Divisor() }
                    Fila(alto: 52, vertical: 10) {
                        NomSub(nombre: s.nombre, sub: s.detalle)
                        Text(Formato.plata(s.monto)).tipo(.texto(15, 700)).monospacedDigit().foregroundStyle(Color.texto)
                    }
                }
            }
            TituloSeccion(texto: "Contacto")
            Tarjeta {
                Fila(alto: 52) { IconoVista(.wa, tamano: 20).foregroundStyle(Color.whatsapp); NomSub(nombre: p.whatsapp, sub: "WhatsApp") }
                Divisor()
                Fila(alto: 52) { IconoVista(.ig, tamano: 20).foregroundStyle(Color(hex: 0xC13584)); NomSub(nombre: p.instagram.isEmpty ? "Sin cargar" : p.instagram, sub: "Instagram") }
                Divisor()
                Fila(alto: 60) {
                    NomSub(nombre: "Tomo pacientes nuevos", sub: p.aceptaNuevos ? "Tu página muestra «Pedir turno»" : "Tu página muestra «Agenda completa»")
                    Interruptor(prendido: Binding(get: { p.aceptaNuevos }, set: { v in var q = p; q.aceptaNuevos = v; estado.guardar(perfilNutri: q, aviso: nil) }),
                                etiqueta: "Tomo pacientes nuevos")
                }
            }
        }
    }
}

func inicialesDe(_ nombre: String) -> String {
    nombre.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
}

private struct Completitud: View {
    let porcentaje: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Perfil \(porcentaje)% completo").tipo(.texto(14, 600)).foregroundStyle(Color.mantecaFija)
                Spacer()
                Text(porcentaje >= 90 ? "Listo para mostrar" : "Te falta poco").tipo(.texto(13, 600)).foregroundStyle(Color.durazno)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.vidrio12)
                    Capsule().fill(Color.durazno).frame(width: g.size.width * Double(porcentaje) / 100)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TarjetaLink: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let p = estado.perfilNutri
        Tarjeta(relleno: 16) {
            HStack(spacing: 10) {
                IconoCirculo(icono: .link, tono: .az)
                VStack(alignment: .leading, spacing: 0) {
                    Text(p.linkCorto).tipo(.texto(16, 700)).foregroundStyle(Color.texto)
                    Text("Pasalo en tu bio, en WhatsApp o en el consultorio").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Boton(titulo: "Copiar", icono: .copiar, variante: .loza, alto: .medio, ancho: true) {
                    UIPasteboard.general.string = p.link.absoluteString
                    estado.avisar("Link copiado.")
                }
                ShareLink(item: p.link, message: Text("Pedí turno conmigo en De a Poco")) {
                    HStack(spacing: 8) { IconoVista(.compartir, tamano: 20); Text("Compartir").tipo(.texto(15, 600)) }
                        .foregroundStyle(Color.sobreMarca).frame(maxWidth: .infinity).frame(height: 48)
                        .background(Color.marca, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Así te ven

/// La página pública como la ve un paciente nuevo.
struct AsiTeVen: View {
    @Environment(Estado.self) private var estado

    var body: some View {
        let p = estado.perfilNutri
        PantallaClaraN(abajo: 40) {
            NavAtras(atras: "Tu perfil") {
                Text(p.linkCorto).tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
            }
            VStack(alignment: .leading, spacing: 0) {
                FotoRecortada(nombre: "foto-consultorio", foco: UnitPoint(x: 0.4, y: 0.3))
                    .frame(height: 220)
                    .overlay(alignment: .bottomLeading) {
                        Avatar(foto: p.foto, iniciales: inicialesDe(p.nombre), tamano: 84, anillo: .white, anilloAncho: 4)
                            .offset(x: 20, y: 42)
                    }
                VStack(alignment: .leading, spacing: 8) {
                    Titulo(p.nombre, tamano: 30)
                    HStack(spacing: 6) {
                        ChipEstado(texto: "\(p.titulo) · \(p.matricula)", icono: .escudo, tipo: .ok)
                        if p.enLinea { ChipEstado(texto: "También en línea", icono: .video, tipo: .info) }
                    }
                    Text("«\(p.frase)»").font(Estilo.titulo(19).font()).foregroundStyle(Color.titulo).padding(.top, 6)
                    Text(p.sobreMi).tipo(.texto(15, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                    Fluir(espacio: 6) { ForEach(p.especialidades, id: \.self) { ChipEstado(texto: $0, tipo: .loza) } }.padding(.top, 4)
                    ForEach(p.lugares) { l in
                        HStack(spacing: 8) {
                            IconoVista(.lugar, tamano: 16).foregroundStyle(Color.texto2)
                            Text("\(l.nombre) · \(l.direccion)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                        .padding(.top, 6)
                    }
                    Divisor().padding(.vertical, 8)
                    ForEach(estado.nutri.servicios) { s in
                        HStack {
                            NomSub(nombre: s.nombre, sub: s.detalle)
                            Text(Formato.plata(s.monto)).tipo(.numero(16)).foregroundStyle(Color.titulo)
                        }
                        .padding(.vertical, 4)
                    }
                    Boton(titulo: p.aceptaNuevos ? "Pedir turno" : "Agenda completa", icono: .turno, variante: .prim, alto: .alto, ancho: true,
                          habilitado: p.aceptaNuevos) { estado.avisar("Así lo ve un paciente: le abre tu agenda.") }
                        .padding(.top, 10)
                    if estado.planActual == .gratis {
                        HStack(spacing: 6) {
                            Image("isotipo-color").resizable().scaledToFit().frame(width: 16)
                            Text("Hecha con De a Poco").tipo(.texto(12, 600)).foregroundStyle(Color.texto2)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 54).padding(.bottom, 20)
            }
            .background(Color.superficie)
            .clipShape(RoundedRectangle(cornerRadius: Radio.foto, style: .continuous))
            .background { RoundedRectangle(cornerRadius: Radio.foto, style: .continuous).fill(Color.superficie).sombraFlotante() }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 8)
        }
    }
}

// MARK: - QR

enum QRCodigo {
    static func imagen(_ texto: String) -> UIImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(texto.utf8)
        f.correctionLevel = "M"
        guard let salida = f.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cg = CIContext().createCGImage(salida, from: salida.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// El QR de tu página, para imprimir y dejar en el consultorio.
struct HojaQR: View {
    @Environment(Estado.self) private var estado

    var body: some View {
        let p = estado.perfilNutri
        HojaBaseN(titulo: "Tu QR", bajada: "Escaneándolo, un paciente nuevo llega a tu página y pide turno.") {
            VStack(spacing: 14) {
                if let qr = QRCodigo.imagen(p.link.absoluteString) {
                    Image(uiImage: qr).interpolation(.none).resizable().scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(18)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay {
                            Image("isotipo-color").resizable().scaledToFit().frame(width: 44)
                                .padding(6).background(Color.white, in: Circle())
                        }
                        .accessibilityLabel("Código QR de \(p.linkCorto)")
                }
                Text(p.linkCorto).tipo(.texto(17, 700)).foregroundStyle(Color.texto)
                Text(p.nombre).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.loza, in: RoundedRectangle(cornerRadius: Radio.foto, style: .continuous))
        } pie: {
            PieHojaN {
                if let qr = QRCodigo.imagen(p.link.absoluteString) {
                    ShareLink(item: Image(uiImage: qr), preview: SharePreview("QR de \(p.nombre)", image: Image(uiImage: qr))) {
                        HStack(spacing: 8) { IconoVista(.compartir, tamano: 20); Text("Guardar o imprimir").tipo(.texto(16, 600)) }
                            .foregroundStyle(Color.sobreMarca).frame(maxWidth: .infinity).frame(height: 54)
                            .background(Color.marca, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }
}

// MARK: - Editar perfil

struct EditarPerfilNutri: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var p: PerfilNutri = DatosDeMuestra.perfilLaura
    @State private var foto: PhotosPickerItem?
    @State private var cargado = false
    @State private var lugar = ""

    var body: some View {
        HojaBaseN(titulo: "Editar tu perfil", bajada: "Lo ven los pacientes nuevos en tu página.") {
            HStack(spacing: 14) {
                Avatar(foto: p.foto, iniciales: inicialesDe(p.nombre), tamano: 72)
                PhotosPicker(selection: $foto, matching: .images) {
                    HStack(spacing: 6) { IconoVista(.foto, tamano: 20); Text(p.foto == nil ? "Subir foto" : "Cambiar foto").tipo(.texto(15, 600)) }
                        .foregroundStyle(Color.sobreSuave).padding(.horizontal, 14).frame(height: 44)
                        .background(Color.suave, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
            }
            CampoN(etiqueta: "Nombre", texto: $p.nombre, prompt: "Laura Ferreyra")
            HStack(spacing: 10) {
                CampoN(etiqueta: "Título", texto: $p.titulo, prompt: "Lic. en Nutrición")
                CampoN(etiqueta: "Matrícula", texto: $p.matricula, prompt: "MP 2174").frame(width: 120)
            }
            CampoN(etiqueta: "Tu frase", texto: $p.frase, prompt: "Comer mejor se hace de a poco.")
            CampoN(etiqueta: "Sobre vos", texto: $p.sobreMi, prompt: "Cómo trabajás, en tus palabras", multilinea: true)
            Etiqueta("Especialidades").padding(.top, 4)
            Fluir(espacio: 8) {
                ForEach(especialidadesComunes, id: \.self) { e in
                    ChipOpcion(titulo: e, elegido: p.especialidades.contains(e), alto: 36) {
                        if let i = p.especialidades.firstIndex(of: e) { p.especialidades.remove(at: i) } else { p.especialidades.append(e) }
                    }
                }
            }
            Etiqueta("Dónde atendés").padding(.top, 4)
            ForEach(p.lugares) { l in
                HStack {
                    NomSub(nombre: l.nombre, sub: l.direccion)
                    Button { p.lugares.removeAll { $0.id == l.id } } label: {
                        IconoVista(.basura, tamano: 20).foregroundStyle(Color.error).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Sacar \(l.nombre)")
                }
            }
            HStack(spacing: 8) {
                CampoN(etiqueta: "", texto: $lugar, prompt: "Otro consultorio: dirección", icono: .lugar)
                Boton(titulo: "", icono: .mas, variante: .suave, habilitado: !lugar.isEmpty) {
                    p.lugares.append(LugarAtencion(nombre: "Consultorio", direccion: lugar, dias: "A coordinar")); lugar = ""
                }
                .accessibilityLabel("Sumar consultorio")
            }
            Tarjeta {
                Fila(alto: 56) { NomSub(nombre: "También en línea", sub: "Videollamada desde la app"); Interruptor(prendido: $p.enLinea, etiqueta: "También en línea") }
            }
            CampoN(etiqueta: "WhatsApp", texto: $p.whatsapp, prompt: "+54 223 …", icono: .wa, teclado: .phonePad)
            CampoN(etiqueta: "Instagram", texto: $p.instagram, prompt: "@tu.cuenta", icono: .ig)
            CampoN(etiqueta: "Tu link", texto: $p.slug, prompt: "laura", icono: .link)
        } pie: {
            PieHojaN {
                Boton(titulo: "Guardar", variante: .prim, alto: .alto, ancho: true, habilitado: !p.nombre.trimmingCharacters(in: .whitespaces).isEmpty) {
                    p.slug = p.slug.lowercased().folding(options: .diacriticInsensitive, locale: nil).filter { $0.isLetter || $0.isNumber || $0 == "." }
                    estado.guardar(perfilNutri: p); cerrar()
                }
            }
        }
        .onAppear { if !cargado { p = estado.perfilNutri; cargado = true } }
        .onChange(of: foto) {
            guard let foto else { return }
            Task {
                if let d = try? await foto.loadTransferable(type: Data.self) { p.foto = Archivos.guardar(d) }
            }
        }
    }
}
