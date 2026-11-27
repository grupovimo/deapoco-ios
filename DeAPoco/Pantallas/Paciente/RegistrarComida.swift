import SwiftUI
import PhotosUI
import UIKit

/// Registrar una comida (p11): la foto arriba, la comida elegida, cómo llegó, una nota y «Mandársela a Laura».
/// La foto sale de la cámara (si el teléfono tiene) o de la galería.
struct RegistrarComida: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @Environment(\.dismiss) private var cerrar
    @State private var momento: Momento
    @State private var foto: Data?
    @State private var sensacion: Sensacion? = .bien
    @State private var nota = ""
    @State private var camara = false
    @State private var galeria: PhotosPickerItem?
    @FocusState private var escribiendo: Bool

    init(momento: Momento, conMuestra: Bool = false) {
        _momento = State(initialValue: momento)
        if conMuestra {
            _foto = State(initialValue: UIImage(named: "plato-milanesa")?.jpegData(compressionQuality: 0.85))
            _nota = State(initialValue: "Comí en la oficina")
        }
    }

    private var hayCamara: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x06180F).ignoresSafeArea()
            Visor(foto: foto, hayCamara: hayCamara, sacar: { camara = true }, galeria: $galeria)
                .frame(height: 560)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
            VStack(spacing: 0) {
                arriba
                Spacer(minLength: 0)
                hoja
            }
        }
        .barraClara()
        .fullScreenCover(isPresented: $camara) {
            Camara { datos in foto = datos }.ignoresSafeArea()
        }
        .onChange(of: galeria) { _, item in
            guard let item else { return }
            Task {
                if let d = try? await item.loadTransferable(type: Data.self) {
                    foto = UIImage(data: d)?.jpegData(compressionQuality: 0.8) ?? d
                    Haptico.suave()
                }
                galeria = nil
            }
        }
        .onAppear { if foto == nil && hayCamara { camara = true } }
    }

    // MARK: Arriba: cerrar, la comida y volver a sacar

    private var arriba: some View {
        HStack(spacing: 8) {
            Redondo(icono: .x, variante: .oscuro, tamanoIcono: 20, etiqueta: "Cerrar") { cerrar() }
            SelectorComida(momento: $momento)
            Redondo(icono: .girar, variante: .oscuro, tamanoIcono: 20, etiqueta: hayCamara ? "Sacar otra" : "Elegir otra") {
                if hayCamara { camara = true } else { foto = nil }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    // MARK: La hoja crema

    private var hoja: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color.crema400).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.bottom, 14)
            Titulo("¿Cómo llegaste \(estado.articulo(momento)) \(momento.titulo.lowercased())?", tamano: 24)
            HStack(spacing: 8) {
                ForEach(Sensacion.allCases, id: \.self) { s in
                    TileSensacion(sensacion: s, elegida: sensacion == s) {
                        withAnimation(.snappy(duration: 0.2)) { sensacion = sensacion == s ? nil : s }
                    }
                }
            }
            .padding(.top, 10)
            HStack(spacing: 8) {
                IconoVista(.mensaje, tamano: 20).foregroundStyle(Color.texto2)
                TextField("", text: $nota, prompt: Text("Una nota, si querés").foregroundColor(.texto2))
                    .font(Estilo.texto(15, 400).font())
                    .foregroundStyle(Color.texto)
                    .focused($escribiendo)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.superficie, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(escribiendo ? Color.marca : Color.borde, lineWidth: escribiendo ? 1.5 : 1))
            .padding(.top, 12)
            HStack(spacing: 10) {
                PhotosPicker(selection: $galeria, matching: .images) {
                    IconoVista(.galeria, tamano: 24).foregroundStyle(Color.texto)
                        .frame(width: 56, height: 54)
                        .background(Color.superficie2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("Elegir de la galería")
                Boton(titulo: "Mandársela a \(estado.paciente.nutri.nombre)", variante: .prim, alto: .alto, ancho: true,
                      habilitado: foto != nil || !nota.isEmpty) { mandar() }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radio.hoja, topTrailingRadius: Radio.hoja, style: .continuous)
                .fill(Color.fondo).ignoresSafeArea(edges: .bottom)
        }
    }

    private func mandar() {
        escribiendo = false
        let antes = estado.comidasHechasHoy
        estado.registrarComida(momento: momento, foto: foto, sensacion: sensacion, nota: nota)
        let completo = antes < 4 && estado.comidasHechasHoy == 4
        cerrar()
        if completo {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                nav.cubierta = .fiesta(semana: false)
            }
        }
    }
}

/// La foto (o, si todavía no hay, los dos caminos para sumarla).
private struct Visor: View {
    let foto: Data?
    let hayCamara: Bool
    var sacar: () -> Void
    @Binding var galeria: PhotosPickerItem?

    var body: some View {
        ZStack {
            if let foto, let ui = UIImage(data: foto) {
                GeometryReader { g in
                    Image(uiImage: ui).resizable().scaledToFill().frame(width: g.size.width, height: g.size.height).clipped()
                }
                .accessibilityLabel("La foto de tu comida")
            } else {
                VStack(spacing: 16) {
                    IconoVista(.foto, tamano: 44).foregroundStyle(Color.crema.opacity(0.85))
                    Text(hayCamara ? "Sacale una foto. No hace falta que sea linda." : "Elegí la foto de tu comida.")
                        .tipo(.texto(16, 600)).foregroundStyle(Color.crema).multilineTextAlignment(.center)
                    HStack(spacing: 10) {
                        if hayCamara { Boton(titulo: "Sacar foto", icono: .foto, variante: .man, alto: .medio, accion: sacar) }
                        PhotosPicker(selection: $galeria, matching: .images) {
                            HStack(spacing: 8) { IconoVista(.galeria, tamano: 20); Text("Galería").tipo(.texto(15, 600)) }
                                .foregroundStyle(Color.crema)
                                .padding(.horizontal, 16).frame(height: 48)
                                .background(Color.vidrio, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(Apretable())
                    }
                }
                .padding(.horizontal, 40)
            }
            LinearGradient(stops: [.init(color: Color(hex: 0x06180F, alpha: 0.55), location: 0), .init(color: .clear, location: 0.22),
                                   .init(color: .clear, location: 0.8), .init(color: Color(hex: 0x06180F, alpha: 0.5), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
        }
    }
}

/// El selector de comida sobre la foto (.comidas-sel): vidrio oscuro, la elegida en crema.
private struct SelectorComida: View {
    @Binding var momento: Momento
    var body: some View {
        ScrollViewReader { lector in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Momento.principales, id: \.self) { m in
                        let on = m == momento
                        Button {
                            Haptico.seleccion()
                            withAnimation(.snappy(duration: 0.22)) { momento = m; lector.scrollTo(m, anchor: .center) }
                        } label: {
                            Text(m.titulo).tipo(.texto(14, 600))
                                .foregroundStyle(on ? Color.verde900 : Color.verde100)
                                .padding(.horizontal, 12).frame(height: 32)
                                .background(on ? Color.crema : .clear, in: Capsule())
                                .frame(minHeight: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(m)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 3)
            }
            .scrollIndicators(.hidden)
            .frame(height: 38)
            .background(Color.verde950.opacity(0.55), in: Capsule())
            .background(.ultraThinMaterial.opacity(0.4), in: Capsule())
            .clipShape(Capsule())
            .onAppear { lector.scrollTo(momento, anchor: .center) }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Con hambre / Bien / Lleno (.sensacion): un platito vacío, a medias o lleno.
private struct TileSensacion: View {
    let sensacion: Sensacion
    let elegida: Bool
    var accion: () -> Void
    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            VStack(spacing: 4) {
                Gajos(partes: 4, llenas: sensacion.llenas, ahora: .no, chico: true).frame(width: 24, height: 24)
                Text(sensacion.titulo).tipo(.texto(13, 600))
            }
            .foregroundStyle(elegida ? Color.sobreSuave : Color.texto3)
            .frame(maxWidth: .infinity).frame(height: 64)
            .background(elegida ? Color.suave : Color.superficie, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(elegida ? Color.marca : Color.borde, lineWidth: elegida ? 2 : 1))
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegida ? .isSelected : [])
    }
}

/// La cámara del sistema.
struct Camara: UIViewControllerRepresentable {
    var listo: (Data) -> Void
    @Environment(\.dismiss) private var cerrar

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let c = UIImagePickerController()
        c.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        c.delegate = context.coordinator
        return c
    }
    func updateUIViewController(_ c: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinador { Coordinador(self) }

    final class Coordinador: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let padre: Camara
        init(_ p: Camara) { padre = p }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage, let d = img.jpegData(compressionQuality: 0.8) { padre.listo(d) }
            padre.cerrar()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { padre.cerrar() }
    }
}
