import SwiftUI

/// Las otras marcas de Grupo Vimo que se promocionan donde tiene sentido (por ahora, Otra Más: entrenadores).
/// Imágenes y textos de propuestas/promos (promos.json): la foto con la app, sin texto; la frase y el CTA van acá.
enum PromoGrupo: String, CaseIterable {
    /// Para el paciente, en «Tu avance»: sumar movimiento.
    case movimiento
    /// Para la nutri, en las medidas de un paciente: conectar con su profe.
    case profe

    var marca: String { "Otra Más" }
    var imagen: String { "promo-otramas-banner" }
    var mini: String { "promo-otramas-mini" }
    var cta: String { "Encontrá tu entrenador" }
    var link: URL? { URL(string: "https://otramas.com.ar") }
}

/// Promo de otra marca del grupo, como publicidad de verdad: la foto con la app arriba, «De Grupo Vimo · Otra Más»,
/// el título, una línea y el CTA. Se cierra con la cruz y no vuelve por 30 días. Sin popups.
/// `compacta`: la versión en fila (foto cuadrada a la izquierda), para listas.
struct BannerGrupo: View {
    let promo: PromoGrupo
    var titulo: String
    var texto: String
    var cerrable = true
    var compacta = false
    @AppStorage private var cerrado: Double
    @Environment(\.openURL) private var abrir

    init(_ promo: PromoGrupo, titulo: String, texto: String, cerrable: Bool = true, compacta: Bool = false) {
        self.promo = promo; self.titulo = titulo; self.texto = texto; self.cerrable = cerrable; self.compacta = compacta
        _cerrado = AppStorage(wrappedValue: 0, "banner-\(promo.rawValue)")
    }

    static let dias: TimeInterval = 30 * 24 * 3600
    private var visible: Bool { cerrado == 0 || Date().timeIntervalSince1970 - cerrado > Self.dias }

    var body: some View {
        if visible {
            Button {
                Haptico.seleccion()
                if let url = promo.link { abrir(url) }
            } label: {
                Group { if compacta { fila } else { tarjeta } }
                    .background(Color.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                    .sombraTarjeta()
                    .contentShape(RoundedRectangle(cornerRadius: Radio.tarjeta))
            }
            .buttonStyle(Apretable())
            .accessibilityLabel("Publicidad de Grupo Vimo, \(promo.marca): \(titulo). \(texto). \(promo.cta)")
            .overlay(alignment: .topTrailing) { if cerrable { cruz } }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }

    private var tarjeta: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(promo.imagen).resizable().scaledToFill()
                .frame(maxWidth: .infinity).frame(height: 150).clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                etiqueta
                Text(titulo).tipo(.texto(16, 700)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                Text(texto).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(promo.cta).tipo(.texto(14, 700))
                    IconoVista(.flecha, tamano: 16)
                }
                .foregroundStyle(Color.yemaTexto)
                .padding(.horizontal, 14).frame(height: 40)
                .background(Color.otraMas, in: Capsule())
                .padding(.top, 8)
            }
            .padding(14)
        }
    }

    private var fila: some View {
        HStack(spacing: 12) {
            Image(promo.mini).resizable().scaledToFill().frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                etiqueta
                Text(titulo).tipo(.texto(15, 700)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 2) {
                    Text(promo.cta).tipo(.texto(14, 700))
                    IconoVista(.chev, tamano: 16)
                }
                .foregroundStyle(Color.enlace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, cerrable ? 26 : 0)
        }
        .padding(10)
    }

    private var etiqueta: some View {
        Text("DE GRUPO VIMO · \(promo.marca.uppercased(with: Locale(identifier: "es_AR")))")
            .font(Estilo.texto(10.5, 700).font()).tracking(0.74)
            .foregroundStyle(Color(claro: 0x2E5293, oscuro: 0x9DB4E8))
            .lineLimit(1)
    }

    private var cruz: some View {
        Button {
            Haptico.seleccion()
            withAnimation(.snappy) { cerrado = Date().timeIntervalSince1970 }
        } label: {
            IconoVista(.x, tamano: 14, grosor: 2.4).foregroundStyle(Color.white)
                .frame(width: 26, height: 26)
                .background(Color.enlozado950.opacity(0.55), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .offset(x: -2, y: 2)
        .accessibilityLabel("Cerrar la publicidad de \(promo.marca) por 30 días")
    }
}

extension Color {
    /// La yema de Otra Más, para el texto del CTA sobre su berenjena.
    static let yemaTexto = Color(hex: 0xFFC83D)
}
