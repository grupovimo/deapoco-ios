import SwiftUI

/// La celebración (p18): el plato lleno con migas, una vibración suave y compartir.
/// `semana`: semana completa (7 de 7); si no, el día completo (4 de 4).
struct Celebracion: View {
    var semana = true
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(claro: 0xFFE6D6, oscuro: 0x3A2A2E), Color.fondo], center: UnitPoint(x: 0.5, y: 0.38),
                           startRadius: 0, endRadius: 520)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                NavAtras(atras: nil, icono: .x, accionAtras: { cerrar() }) {
                    HStack(spacing: 6) {
                        IconoVista(.campana, tamano: 16)
                        Text("Vibra suave").tipo(.texto(13, 600))
                    }
                    .foregroundStyle(Color.texto2)
                }
                Spacer(minLength: 0)
                VStack(spacing: 18) {
                    ZStack {
                        Migas(lado: 236)
                        Plato(partes: semana ? 7 : 4, llenas: semana ? 7 : 4, servir: true).frame(width: 236, height: 236)
                    }
                    .frame(width: 236, height: 236)
                    Titulo(semana ? "Semana completa." : "Día completo.", tamano: 40, centrado: true)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 22)
                    Text(semana ? "Siete días anotando. De a poco, se nota." : "Las cuatro comidas, anotadas. De a poco, se nota.")
                        .tipo(.texto(17, 400)).foregroundStyle(Color(claro: 0x54402F, oscuro: 0xE3D3BF))
                        .multilineTextAlignment(.center).frame(maxWidth: 260)
                    ChipEstado(texto: semana ? "Nivel \(estado.paciente.nivel) · +1 semana" : "Racha de \(estado.paciente.racha) días", tipo: .dur, alto: 30, tamano: 14)
                }
                .padding(.horizontal, 32)
                Spacer(minLength: 0)
                VStack(spacing: 10) {
                    Boton(titulo: semana ? "Compartir mi semana" : "Ver mi semana", icono: semana ? .compartir : .turno, variante: .prim, alto: .alto, ancho: true) {
                        cerrar()
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            nav.pestana = .avance
                            nav.avance = semana ? [.resumen] : [.semana]
                        }
                    }
                    Boton(titulo: "Seguir", variante: .texto, alto: .alto, ancho: true) { cerrar() }
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.bottom, 8)
            }
        }
        .barraClara(false)
        .onAppear { Haptico.exito() }
    }
}

/// Resumen para compartir (p19): la tarjeta para historias, sin peso ni medidas.
struct ResumenCompartir: View {
    @Environment(Estado.self) private var estado
    @Environment(\.displayScale) private var escala
    @State private var paquete: [Any]?

    var body: some View {
        let racha = estado.paciente.racha
        let fotos = estado.paciente.registros.filter { $0.foto != nil && Fecha.dias(entre: $0.fecha, y: estado.paciente.hoy) < 7 }.count
        VStack(spacing: 0) {
            NavAtras(atras: "Volver") {
                Text("Para tus historias").tipo(.texto(15, 600)).foregroundStyle(Color.texto2)
            }
            ScrollView {
                VStack(spacing: 0) {
                    TarjetaSemana(racha: racha, fotos: fotos)
                        .padding(.top, 8)
                        .accessibilityElement()
                        .accessibilityLabel("Resumen de la semana para compartir: \(racha) días seguidos y \(fotos) comidas con foto")
                    Text("Sin peso ni medidas: eso queda entre vos y \(estado.paciente.nutri.nombre).")
                        .tipo(.texto(12, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center).padding(.top, 12)
                    HStack(spacing: 8) {
                        destino(.ig, "Historias", Color(hex: 0xC13584), racha, fotos)
                        destino(.wa, "WhatsApp", .whatsappClaro, racha, fotos)
                        destino(.bajar, "Guardar", .marca, racha, fotos)
                        destino(.compartir, "Más", .marca, racha, fotos)
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 18)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.fondo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .barraClara(false)
        .sheet(isPresented: Binding(get: { paquete != nil }, set: { if !$0 { paquete = nil } })) {
            ActividadCompartir(items: paquete ?? []).presentationDetents([.medium, .large]).ignoresSafeArea()
        }
    }

    private func destino(_ i: Icono, _ t: String, _ c: Color, _ racha: Int, _ fotos: Int) -> some View {
        Button {
            Haptico.seleccion()
            let r = ImageRenderer(content: TarjetaSemana(racha: racha, fotos: fotos, paraImagen: true).environment(\.colorScheme, .light))
            r.scale = 4
            if let img = r.uiImage { paquete = [img] }
        } label: {
            VStack(spacing: 6) {
                IconoVista(i, tamano: 26).foregroundStyle(c)
                    .frame(width: 56, height: 56)
                    .background(Color.superficie, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .sombraChica()
                Text(t).tipo(.texto(12.5, 600)).foregroundStyle(Color.texto3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("Compartir en \(t)")
    }
}

/// La tarjeta de la semana (.prev): 262 × 466, enlozado, el plato lleno, los datos y la foto abajo.
/// Con `paraImagen` usa sólo vistas de SwiftUI (el título de UIKit no se dibuja en ImageRenderer).
struct TarjetaSemana: View {
    let racha: Int
    let fotos: Int
    var paraImagen = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.enlozado800
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .top) {
                    FotoRecortada(nombre: "plato-milanesa")
                    LinearGradient(colors: [Color.enlozado800, Color.enlozado800.opacity(0)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4))
                }
                .frame(height: 200)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("MI SEMANA").font(Estilo.texto(10, 700).font()).tracking(0.6).foregroundStyle(Color.durazno)
                Group {
                    if paraImagen {
                        Text("Siete de siete, de\u{00A0}a\u{00A0}poco.").font(Estilo.titulo(28).font()).tracking(-0.56)
                            .foregroundStyle(Color.mantecaFija).lineSpacing(-6).fixedSize(horizontal: false, vertical: true)
                    } else {
                        Titulo("Siete de siete, de\u{00A0}a\u{00A0}poco.", tamano: 28, color: .mantecaFija)
                    }
                }
                .padding(.top, 6)
                HStack(spacing: 14) {
                    Plato(partes: 7, llenas: 7, fondo: .mantecaFija, borde: .enlozado800).frame(width: 84, height: 84)
                    VStack(alignment: .leading, spacing: 10) {
                        dato("\(racha)", "días seguidos")
                        dato("\(fotos)", "comidas con foto")
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20).padding(.top, 22)
        }
        .overlay(alignment: .bottomLeading) {
            Image("logotipo-enlozado").resizable().scaledToFit().frame(height: 15)
                .padding(.horizontal, 10).frame(height: 26)
                .background(Color.mantecaFija.opacity(0.94), in: Capsule())
                .padding(.leading, 16).padding(.bottom, 14)
        }
        .frame(width: 262, height: 466)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.enlozado950.opacity(paraImagen ? 0 : 0.3), radius: 25, y: 24)
    }

    private func dato(_ v: String, _ t: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(v).font(Estilo.numero(26).font()).foregroundStyle(Color.mantecaFija)
            Text(t).tipo(.texto(11.5, 400)).foregroundStyle(Color.sobreBanda2)
        }
    }
}
