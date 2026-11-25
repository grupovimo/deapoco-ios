import SwiftUI

/// Las otras marcas de Grupo Vimo que se promocionan donde tiene sentido (por ahora, Otra Más: entrenadores).
enum PromoGrupo: String, CaseIterable {
    /// Para el paciente, en «Tu avance»: sumar movimiento.
    case movimiento
    /// Para la nutri, en las medidas de un paciente: conectar con su profe.
    case profe

    var marca: String { "Otra Más" }
    var isotipo: String { "otramas-isotipo" }
    var link: URL? { URL(string: "https://otramas.com.ar") }
}

/// Promo de otra marca del grupo (.casa): «De Grupo Vimo · Otra Más», enlozado-50 con borde enlozado-200, «Ver ›».
/// Se cierra con la cruz y no vuelve por 30 días. Sin popups.
struct BannerGrupo: View {
    let promo: PromoGrupo
    var titulo: String
    var texto: String
    var cerrable = true
    @AppStorage private var cerrado: Double
    @Environment(\.openURL) private var abrir

    init(_ promo: PromoGrupo, titulo: String, texto: String, cerrable: Bool = true) {
        self.promo = promo; self.titulo = titulo; self.texto = texto; self.cerrable = cerrable
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
                HStack(spacing: 12) {
                    Image(promo.isotipo).resizable().scaledToFit().frame(width: 28, height: 28)
                        .frame(width: 44, height: 44)
                        .background(Color.otraMas, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DE GRUPO VIMO · \(promo.marca.uppercased(with: Locale(identifier: "es_AR")))")
                            .font(Estilo.texto(10.5, 700).font()).tracking(0.74)
                            .foregroundStyle(Color(claro: 0x2E5293, oscuro: 0x9DB4E8))
                            .lineLimit(1)
                        Text(titulo).tipo(.texto(15, 700)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                        Text(texto).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 2) {
                        Text("Ver").tipo(.texto(14, 700))
                        IconoVista(.chev, tamano: 16)
                    }
                    .foregroundStyle(Color.enlace)
                    .padding(.trailing, cerrable ? 18 : 0)
                }
                .padding(.vertical, 12)
                .padding(.leading, 14)
                .padding(.trailing, 12)
                .background(Color.infoSuave, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                    .strokeBorder(Color(claro: 0xC6D4F2, oscuro: 0x2C3C60), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: Radio.tarjeta))
            }
            .buttonStyle(Apretable())
            .accessibilityLabel("De Grupo Vimo, \(promo.marca): \(titulo) \(texto)")
            .overlay(alignment: .topTrailing) {
                if cerrable {
                    Button {
                        Haptico.seleccion()
                        withAnimation(.snappy) { cerrado = Date().timeIntervalSince1970 }
                    } label: {
                        IconoVista(.x, tamano: 14, grosor: 2.2).foregroundStyle(Color.corteza400)
                            .frame(width: 22, height: 22)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .offset(x: 3, y: -3)
                    .accessibilityLabel("Cerrar la promo de \(promo.marca)")
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }
}
