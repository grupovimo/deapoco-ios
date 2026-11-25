import SwiftUI

/// Se achica un poco al apretar (todo lo tocable).
struct Apretable: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// Botones (.btn): prim (enlozado), suave (enlozado-100), loza, man (manteca, sobre la banda), vidrio (sobre la banda)
/// y texto. Chico (36, con 44 de área táctil), normal (44) y alto (54).
struct Boton: View {
    enum Variante { case prim, suave, loza, man, vidrio, texto, peligro }
    enum Alto { case chico, normal, medio, alto }

    let titulo: String
    var icono: Icono? = nil
    var iconoDerecha: Icono? = nil
    var variante: Variante = .prim
    var alto: Alto = .normal
    var ancho = false
    var colorIcono: Color? = nil
    var habilitado = true
    var accion: () -> Void

    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            HStack(spacing: 8) {
                if let icono {
                    IconoVista(icono, tamano: alto == .chico ? 16 : 20).foregroundStyle(colorIcono ?? frente)
                }
                if !titulo.isEmpty {
                    Text(titulo).tipo(.texto(tamanoTexto, 600)).lineLimit(1).minimumScaleFactor(0.8)
                }
                if let iconoDerecha {
                    IconoVista(iconoDerecha, tamano: 20)
                }
            }
            .foregroundStyle(frente)
            .padding(.horizontal, titulo.isEmpty ? 0 : (alto == .chico ? 12 : alto == .alto ? 26 : 16))
            .frame(minWidth: titulo.isEmpty ? altura : nil)
            .frame(maxWidth: ancho ? .infinity : nil)
            .frame(height: altura)
            .background(fondo, in: RoundedRectangle(cornerRadius: radio, style: .continuous))
            .opacity(habilitado ? 1 : 0.45)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .disabled(!habilitado)
    }

    private var altura: CGFloat {
        switch alto { case .chico: return 36; case .normal: return 44; case .medio: return 48; case .alto: return 54 }
    }
    private var radio: CGFloat {
        switch alto { case .chico: return 12; case .normal, .medio: return 14; case .alto: return 16 }
    }
    private var tamanoTexto: CGFloat {
        switch alto { case .chico: return 14; case .normal, .medio: return 15; case .alto: return 16 }
    }

    private var fondo: Color {
        switch variante {
        case .prim: return .marca
        case .suave: return .suave
        case .loza: return .loza
        case .man: return .mantecaFija
        case .vidrio: return .vidrio
        case .texto: return .clear
        case .peligro: return .errorFondo
        }
    }

    private var frente: Color {
        switch variante {
        case .prim: return .sobreMarca
        case .suave: return .sobreSuave
        case .loza: return .texto
        case .man: return .enlozado800
        case .vidrio: return .mantecaFija
        case .texto: return .marca
        case .peligro: return .error
        }
    }
}

/// Botón de WhatsApp (suave, con el logo verde): «Escribir», «Escribile» o sólo el logo.
struct BotonWA: View {
    var titulo: String = "Escribir"
    var alto: Boton.Alto = .chico
    var etiqueta: String? = nil
    var accion: () -> Void

    var body: some View {
        Boton(titulo: titulo, icono: .wa, variante: .suave, alto: alto, colorIcono: .whatsapp, accion: accion)
            .accessibilityLabel(etiqueta ?? (titulo.isEmpty ? "WhatsApp" : titulo))
    }
}

/// Chip de selección grande (opciones del onboarding, filtros, comentarios rápidos).
struct ChipOpcion: View {
    let titulo: String
    var icono: Icono? = nil
    var elegido: Bool
    var alto: CGFloat = 40
    var accion: () -> Void

    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            HStack(spacing: 6) {
                if let icono { IconoVista(icono, tamano: 16) }
                Text(titulo).tipo(.texto(14.5, 600)).lineLimit(1)
            }
            .foregroundStyle(elegido ? Color.sobreMarca : Color.texto3)
            .padding(.horizontal, 14)
            .frame(height: alto)
            .background(elegido ? Color.marca : Color.superficie, in: Capsule())
            .overlay(Capsule().strokeBorder(elegido ? Color.clear : Color.borde, lineWidth: 1))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}
