import SwiftUI
import UIKit

/// Paleta de De a Poco v2, la naranja en gajos (marca/sistema/tokens.css). Las escalas son fijas; los roles cambian con el modo oscuro,
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

    // Verde: el texto, los títulos y el botón principal.
    static let verde950 = Color(hex: 0x0A2A1D)
    static let verde900 = Color(hex: 0x0F3D2A)
    static let verde850 = Color(hex: 0x123B2B)
    static let verde800 = Color(hex: 0x1A4A37)
    static let verde100 = Color(hex: 0xE2F0DC)

    // Hoja: sólo la hoja del logo, ilustración y la verdura del plato armado.
    static let hoja = Color(hex: 0x3E8E41)
    static let hojaClara = Color(hex: 0x7CC47F)

    // Naranja: el gajo. Relleno, nunca texto chico (como texto, el 700).
    static let naranja800 = Color(hex: 0x9A3D08)
    static let naranja700 = Color(hex: 0xB84A0B)
    static let naranja600 = Color(hex: 0xE55E12)
    static let naranja500 = Color(hex: 0xF26B1D)
    static let naranja300 = Color(hex: 0xFF8A4C)
    static let naranja100 = Color(hex: 0xFFE9D6)

    // Mandarina (el gajo de ahora y los logros) y pulpa (lo que falta).
    static let mandarina = Color(hex: 0xFBA92C)
    static let mandarina200 = Color(hex: 0xFDCB7E)
    static let pulpa = Color(hex: 0xFDDC9E)

    // Crema: los fondos (fija: igual en los dos modos).
    static let crema50 = Color(hex: 0xFFF8EC)
    static let crema = Color(hex: 0xFBEFD9)
    static let crema300 = Color(hex: 0xF4E3C3)
    static let crema400 = Color(hex: 0xE9D3AC)

    // Salvia: el texto secundario, un verde gris.
    static let salvia700 = Color(hex: 0x35503F)
    static let salvia = Color(hex: 0x466253)
    static let salvia400 = Color(hex: 0x7C8F83)
    static let salvia300 = Color(hex: 0xB5C6BA)
    static let salvia200 = Color(hex: 0xDCD6C2)

    // Marcas de terceros.
    static let whatsapp = Color(hex: 0x1A8D47)
    static let whatsappClaro = Color(hex: 0x1FA855)
    static let salud = Color(hex: 0xE0364F)
    static let otraMas = Color(hex: 0x2B1638)

    // MARK: Roles (cambian con el modo)

    static let fondo = Color(claro: 0xFBEFD9, oscuro: 0x0A2A1D)
    static let superficie = Color(claro: 0xFFFFFF, oscuro: 0x123B2B)
    /// Superficie hundida (crema 300): botones «crema», fondos hundidos, lo que todavía no está.
    static let superficie2 = Color(claro: 0xF4E3C3, oscuro: 0x1A4A37)
    static let texto = Color(claro: 0x0F3D2A, oscuro: 0xFBEFD9)
    static let texto2 = Color(claro: 0x466253, oscuro: 0xB5C6BA)
    /// Secundario fuerte: etiquetas de porción, «a medias».
    static let texto3 = Color(claro: 0x35503F, oscuro: 0xD4DED6)
    static let titulo = Color(claro: 0x0F3D2A, oscuro: 0xFBEFD9)
    static let borde = Color(claro: 0xDCD6C2, oscuro: 0x24503D)
    static let bordeCampo = Color(claro: 0x7C8F83, oscuro: 0x6F8C7C)
    /// Verde en claro, crema en oscuro: botones principales, enlaces fuertes.
    static let marca = Color(claro: 0x0F3D2A, oscuro: 0xFBEFD9)
    static let sobreMarca = Color(claro: 0xFBEFD9, oscuro: 0x0F3D2A)
    /// El gajo hecho: naranja 600 en claro (3,11 sobre crema), naranja 500 en oscuro.
    static let acento = Color(claro: 0xE55E12, oscuro: 0xF26B1D)
    static let acentoTexto = Color(claro: 0xB84A0B, oscuro: 0xFF8A4C)
    static let enlace = Color(claro: 0x0F3D2A, oscuro: 0xFBEFD9)
    /// La banda de arriba del lado de la nutri.
    static let banda = Color(claro: 0x0F3D2A, oscuro: 0x123B2B)
    static let suave = Color(claro: 0xE2F0DC, oscuro: 0x1A4A37)
    static let sobreSuave = Color(claro: 0x0F3D2A, oscuro: 0xE2F0DC)
    static let logro = Color(claro: 0xFBA92C, oscuro: 0xFBA92C)
    static let logroSuave = Color(claro: 0xFFE9D6, oscuro: 0x4A3A12)
    static let sobreLogro = Color(claro: 0x0F3D2A, oscuro: 0xFBEFD9)
    static let logroTexto = Color(claro: 0x9A3D08, oscuro: 0xFDCB7E)
    static let badge = Color(claro: 0xB84A0B, oscuro: 0xFF8A4C)
    static let sobreBadge = Color(claro: 0xFFFFFF, oscuro: 0x0A2A1D)
    static let infoSuave = Color(claro: 0xFFF8EC, oscuro: 0x123B2B)
    /// La barra «la mesa».
    static let barra = Color(claro: 0xFFFFFF, oscuro: 0x123B2B)

    // Los gajos como gráfico (gajos.js): lo hecho, lo de ahora y lo que falta.
    static let gajoLleno = Color(claro: 0xE55E12, oscuro: 0xF26B1D)
    static let gajoAhora = Color(hex: 0xFBA92C)
    static let gajoFalta = Color(claro: 0xFDDC9E, oscuro: 0x2A5A44)

    // Estados: siempre con ícono y palabra.
    static let ok = Color(claro: 0x2A6E35, oscuro: 0x8FD49A)
    static let okFondo = Color(claro: 0xE2F0DC, oscuro: 0x163A27)
    static let error = Color(claro: 0xA62B1F, oscuro: 0xFF9A8A)
    static let errorFondo = Color(claro: 0xFBE5E0, oscuro: 0x3A1A1C)
    static let aviso = Color(claro: 0x8A5300, oscuro: 0xF5C46B)
    static let avisoFondo = Color(claro: 0xFFEFD2, oscuro: 0x33280F)

    // Sobre la banda verde (iguales en los dos modos).
    static let sobreBanda2 = Color(hex: 0xB5C6BA)
    static let vidrio = Color(hex: 0xFBEFD9, alpha: 0.14)
    static let vidrio12 = Color(hex: 0xFBEFD9, alpha: 0.12)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}
