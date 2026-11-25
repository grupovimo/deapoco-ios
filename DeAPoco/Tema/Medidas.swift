import SwiftUI

/// Radios de las pantallas: tarjetas 20, controles 14, banda 28, fotos 32, el plato redondo.
enum Radio {
    static let tarjeta: CGFloat = 20
    static let control: CGFloat = 14
    static let banda: CGFloat = 28
    static let foto: CGFloat = 32
    static let hoja: CGFloat = 30
}

/// Grilla de 4. Margen lateral del teléfono: 20.
enum Espacio {
    static let e1: CGFloat = 4
    static let e2: CGFloat = 8
    static let e3: CGFloat = 12
    static let e4: CGFloat = 16
    static let margen: CGFloat = 20
    static let e6: CGFloat = 24
    static let e8: CGFloat = 32
    /// Alto mínimo de lo que se toca.
    static let tactil: CGFloat = 44
    /// Lo que ocupa la barra «la mesa» (90 con el indicador) más aire, para que nada quede debajo.
    static let bajoBarra: CGFloat = 112
}

/// Sombras cálidas, teñidas de corteza (nunca gris puro). El blur del CSS ≈ el doble del radio de SwiftUI.
/// En oscuro, las tarjetas no llevan sombra sino un borde de 1 (#2C3C60), como en el diseño.
private struct SombraTarjeta: ViewModifier {
    var radio: CGFloat
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        if esquema == .dark {
            content.overlay(RoundedRectangle(cornerRadius: radio, style: .continuous).strokeBorder(Color(hex: 0x2C3C60), lineWidth: 1))
        } else {
            // .card: 0 1px 2px rgb(110 86 70 / .08), 0 10px 26px rgb(110 86 70 / .08)
            content
                .shadow(color: Color.corteza.opacity(0.08), radius: 1, x: 0, y: 1)
                .shadow(color: Color.corteza.opacity(0.08), radius: 13, x: 0, y: 10)
        }
    }
}

extension View {
    func sombraTarjeta(radio: CGFloat = Radio.tarjeta) -> some View { modifier(SombraTarjeta(radio: radio)) }

    /// --dap-sombra-1: 0 1px 2px rgb(110 86 70 / .10)
    func sombraChica() -> some View {
        shadow(color: Color.corteza.opacity(0.10), radius: 1, x: 0, y: 1)
    }

    /// --dap-sombra-2: 0 6px 16px rgb(110 86 70 / .12)
    func sombraMedia() -> some View {
        shadow(color: Color.corteza.opacity(0.12), radius: 8, x: 0, y: 6)
            .shadow(color: Color.corteza.opacity(0.08), radius: 1.5, x: 0, y: 1)
    }

    /// --dap-sombra-flotante: 0 24px 60px rgb(16 26 48 / .30) (tarjeta de la app sobre una foto).
    func sombraFlotante() -> some View {
        shadow(color: Color.enlozado950.opacity(0.30), radius: 30, x: 0, y: 24)
    }
}
