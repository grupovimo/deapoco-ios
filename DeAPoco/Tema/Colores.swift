import SwiftUI
import UIKit

/// Paleta de De a Poco (marca/sistema/tokens.css). Las escalas son fijas; los roles cambian con el modo oscuro,
/// igual que en el CSS (`.oscuro` sólo cambia los roles).
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }

    /// Un color que cambia con el modo: claro y oscuro.
    init(claro: UInt32, oscuro: UInt32) {
        self.init(uiColor: UIColor { t in
            UIColor(hex: t.userInterfaceStyle == .dark ? oscuro : claro)
        })
    }

    // Enlozado: la base.
    static let enlozado950 = Color(hex: 0x101A30)
    static let enlozado900 = Color(hex: 0x1A2742)
    static let enlozado800 = Color(hex: 0x1F3F78)
    static let enlozado600 = Color(hex: 0x2E5293)
    static let enlozado500 = Color(hex: 0x4A6BB0)
    static let enlozado300 = Color(hex: 0x9DB4E8)
    static let enlozado200 = Color(hex: 0xC6D4F2)
    static let enlozado100 = Color(hex: 0xE3EAF8)
    static let enlozado50 = Color(hex: 0xF1F5FC)

    // Rabanito: el único acento (relleno). Como texto, el 700.
    static let rabanito800 = Color(hex: 0x8E1A33)
    static let rabanito700 = Color(hex: 0xB42340)
    static let rabanito600 = Color(hex: 0xCF3350)
    static let rabanito500 = Color(hex: 0xE8455E)
    static let rabanito300 = Color(hex: 0xFF8A9A)
    static let rabanito100 = Color(hex: 0xFFE0E5)

    // Manteca, loza y durazno.
    static let manteca50 = Color(hex: 0xFFFBF2)
    static let manteca = Color(hex: 0xFFF5E1)
    static let mantecaFija = Color(hex: 0xFFF5E1)
    static let manteca300 = Color(hex: 0xE8D6B4)
    static let durazno100 = Color(hex: 0xFFE6D6)
    static let durazno = Color(hex: 0xFFC2A1)
    static let durazno500 = Color(hex: 0xF5A27A)
    static let durazno700 = Color(hex: 0x9A4A24)

    // Tinta y corteza.
    static let tinta = Color(hex: 0x1B2233)
    static let corteza700 = Color(hex: 0x54402F)
    static let corteza = Color(hex: 0x6E5646)
    static let corteza500 = Color(hex: 0x8C7464)
    static let corteza400 = Color(hex: 0x9C8573)
    static let corteza300 = Color(hex: 0xC9B8AA)

    // Marcas de terceros.
    static let whatsapp = Color(hex: 0x1A8D47)
    static let whatsappClaro = Color(hex: 0x1FA855)
    static let salud = Color(hex: 0xE0364F)
    static let otraMas = Color(hex: 0x2B1638)

    // MARK: Roles (cambian con el modo)

    static let fondo = Color(claro: 0xFFF5E1, oscuro: 0x101A30)
    static let superficie = Color(claro: 0xFFFFFF, oscuro: 0x1A2742)
    static let superficie2 = Color(claro: 0xF3E6CC, oscuro: 0x24345A)
    /// La loza (porciones vacías, botones «loza», fondos hundidos).
    static let loza = Color(claro: 0xF3E6CC, oscuro: 0x24345A)
    static let texto = Color(claro: 0x1B2233, oscuro: 0xFFF5E1)
    static let texto2 = Color(claro: 0x6E5646, oscuro: 0xC9B8AA)
    /// Secundario fuerte (corteza 700): etiquetas de porción, «a medias».
    static let texto3 = Color(claro: 0x54402F, oscuro: 0xE3D3BF)
    static let titulo = Color(claro: 0x1F3F78, oscuro: 0xFFF5E1)
    static let borde = Color(claro: 0xE3D3BF, oscuro: 0x2C3C60)
    static let bordeCampo = Color(claro: 0x9C8573, oscuro: 0x6A7FA8)
    /// Enlozado en claro, manteca en oscuro: botones principales, enlaces fuertes.
    static let marca = Color(claro: 0x1F3F78, oscuro: 0xFFF5E1)
    static let sobreMarca = Color(claro: 0xFFF5E1, oscuro: 0x1F3F78)
    static let acentoTexto = Color(claro: 0xB42340, oscuro: 0xFF8A9A)
    static let enlace = Color(claro: 0x1F3F78, oscuro: 0x9DB4E8)
    /// La banda de arriba del lado de la nutri.
    static let banda = Color(claro: 0x1F3F78, oscuro: 0x1A2742)
    static let suave = Color(claro: 0xE3EAF8, oscuro: 0x24345A)
    static let sobreSuave = Color(claro: 0x1F3F78, oscuro: 0xC6D4F2)
    static let logro = Color(claro: 0xFFC2A1, oscuro: 0x3A2A2E)
    static let logroSuave = Color(claro: 0xFFE6D6, oscuro: 0x3A2A2E)
    static let sobreLogro = Color(claro: 0x1B2233, oscuro: 0xFFF5E1)
    static let logroTexto = Color(claro: 0x9A4A24, oscuro: 0xFFC2A1)
    static let badge = Color(claro: 0xB42340, oscuro: 0xFF8A9A)
    static let sobreBadge = Color(claro: 0xFFFFFF, oscuro: 0x101A30)
    static let infoSuave = Color(claro: 0xF1F5FC, oscuro: 0x1F2E4E)

    // El plato como gráfico.
    static let platoBorde = Color(claro: 0x1F3F78, oscuro: 0xFFF5E1)
    static let platoFondo = Color(claro: 0xFFF5E1, oscuro: 0x1A2742)
    static let platoAla = Color(claro: 0xF3E6CC, oscuro: 0x2C3C60)

    // Estados: siempre con ícono y palabra.
    static let ok = Color(claro: 0x2B6B3F, oscuro: 0x7FD39A)
    static let okFondo = Color(claro: 0xE3F0E1, oscuro: 0x163223)
    static let error = Color(claro: 0xA62B1F, oscuro: 0xFF9A8A)
    static let errorFondo = Color(claro: 0xFBE5E0, oscuro: 0x3A1A1C)
    static let aviso = Color(claro: 0x8A5300, oscuro: 0xF5C46B)
    static let avisoFondo = Color(claro: 0xFFEFD2, oscuro: 0x33280F)

    // Sobre la banda enlozada (iguales en los dos modos).
    static let sobreBanda2 = Color(hex: 0xC6D4F2)
    static let vidrio = Color(hex: 0xFFF5E1, alpha: 0.14)
    static let vidrio12 = Color(hex: 0xFFF5E1, alpha: 0.12)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}
