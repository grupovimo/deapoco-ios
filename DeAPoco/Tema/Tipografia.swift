import SwiftUI
import UIKit

/// Fraunces (variable: opsz 9–144, wght, SOFT, WONK) para títulos y Hanken Grotesk (variable: wght) para todo
/// lo que se lee y para todas las cifras. Fraunces nunca va en cifras que se comparan.
enum Tipo {
    private static let wght = NSNumber(value: 0x7767_6874) // 'wght'
    private static let opsz = NSNumber(value: 0x6F70_737A) // 'opsz'
    private static let soft = NSNumber(value: 0x534F_4654) // 'SOFT'
    private static let wonk = NSNumber(value: 0x574F_4E4B) // 'WONK'
    nonisolated(unsafe) private static var cache: [String: UIFont] = [:]
    private static let candado = NSLock()

    enum Familia: String {
        case fraunces, hanken
        var nombrePostScript: String { self == .fraunces ? "Fraunces-9ptBlack" : "HankenGrotesk-Regular" }
    }

    static func uiFont(_ familia: Familia, tamano: CGFloat, peso: CGFloat) -> UIFont {
        let clave = "\(familia.rawValue)-\(tamano)-\(peso)"
        candado.lock(); defer { candado.unlock() }
        if let f = cache[clave] { return f }
        var ejes: [NSNumber: NSNumber] = [wght: NSNumber(value: Double(peso))]
        if familia == .fraunces {
            // Óptico automático (a 32 pt, opsz 32), Soft 100 (terminaciones redondas) y Wonk 0.
            ejes[opsz] = NSNumber(value: Double(min(max(tamano, 9), 144)))
            ejes[soft] = 100
            ejes[wonk] = 0
        }
        // CoreText reusa la instancia por nombre y tamaño: se copia la base con la variación pedida.
        let base = CTFontCreateWithName(familia.nombrePostScript as CFString, tamano, nil)
        let desc = CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: ejes] as CFDictionary)
        let f = CTFontCreateCopyWithAttributes(base, tamano, nil, desc) as UIFont
        cache[clave] = f
        return f
    }
}

/// Estilos de la escala de las pantallas: 11/12/13/14/15/17/20/24/30/36.
enum Estilo {
    /// Fraunces 600, Soft 100, interlineado 1,04, tracking −0,015 em. En minúsculas, como frase.
    case titulo(CGFloat)
    /// Hanken 600 con cifras tabulares y tracking −0,02 em (`.num`).
    case numero(CGFloat)
    /// Hanken con peso explícito (400 texto, 600 secundario fuerte y botones, 700 énfasis).
    case texto(CGFloat, CGFloat)
    /// Etiqueta: 12, 700, mayúsculas, 0,06 em.
    case etiqueta

    var tamano: CGFloat {
        switch self {
        case .titulo(let t), .numero(let t), .texto(let t, _): return t
        case .etiqueta: return 12
        }
    }

    /// Cuánto crece con Dynamic Type: el texto sí, los títulos y números grandes poco (no rompen la grilla).
    func factor(_ dts: DynamicTypeSize) -> CGFloat {
        let f: CGFloat
        switch dts {
        case .xSmall: f = 0.85
        case .small: f = 0.9
        case .medium: f = 0.95
        case .large: f = 1
        case .xLarge: f = 1.1
        case .xxLarge: f = 1.2
        case .xxxLarge: f = 1.3
        default: f = 1.4
        }
        let tope: CGFloat = tamano >= 24 ? 1.1 : 1.3
        return min(f, tope)
    }

    func uiFont(_ dts: DynamicTypeSize = .large) -> UIFont {
        let t = tamano * factor(dts)
        switch self {
        case .titulo: return Tipo.uiFont(.fraunces, tamano: t, peso: 600)
        case .numero: return Tipo.uiFont(.hanken, tamano: t, peso: 600)
        case .texto(_, let peso): return Tipo.uiFont(.hanken, tamano: t, peso: peso)
        case .etiqueta: return Tipo.uiFont(.hanken, tamano: t, peso: 700)
        }
    }

    func font(_ dts: DynamicTypeSize = .large) -> Font {
        if case .numero = self { return Font(uiFont(dts)).monospacedDigit() }
        return Font(uiFont(dts))
    }

    var tracking: CGFloat {
        switch self {
        case .titulo(let t): return t * -0.015
        case .numero(let t): return t * -0.02
        case .etiqueta: return 12 * 0.06
        case .texto: return 0
        }
    }
}

private struct ModificadorTipo: ViewModifier {
    let estilo: Estilo
    /// Alto de línea en pt (el line-height del CSS) para las líneas únicas.
    let alto: CGFloat?
    @Environment(\.dynamicTypeSize) private var dts

    func body(content: Content) -> some View {
        let base = content
            .font(estilo.font(dts))
            .tracking(estilo.tracking)
        if let alto {
            base.lineLimit(1).minimumScaleFactor(0.6).fixedSize(horizontal: false, vertical: true)
                .frame(height: alto * estilo.factor(dts))
        } else if case .texto(let t, _) = estilo {
            // Hanken trae 1,30 de interlineado natural; el diseño usa 1,35 (body) en párrafos.
            base.lineSpacing(t * 0.05)
        } else {
            base
        }
    }
}

extension View {
    /// Aplica un estilo de la escala. `alto` fija el line-height (sólo para una línea).
    func tipo(_ estilo: Estilo, alto: CGFloat? = nil) -> some View {
        modifier(ModificadorTipo(estilo: estilo, alto: alto))
    }
}

/// Título en Fraunces con el interlineado exacto del diseño (1,04) y `text-wrap: balance`: si ocupa dos o más
/// renglones, se busca el ancho más angosto que mantiene la misma cantidad de renglones, así no quedan viudas.
struct Titulo: View {
    let texto: String
    var tamano: CGFloat = 32
    var color: Color = .titulo
    var centrado = false
    @Environment(\.dynamicTypeSize) private var dts

    init(_ texto: String, tamano: CGFloat = 32, color: Color = .titulo, centrado: Bool = false) {
        self.texto = texto; self.tamano = tamano; self.color = color; self.centrado = centrado
    }

    var body: some View {
        EtiquetaTitulo(texto: texto, fuente: Estilo.titulo(tamano).uiFont(dts), color: UIColor(color),
                       interlineado: 1.04, tracking: Estilo.titulo(tamano).tracking * Estilo.titulo(tamano).factor(dts),
                       centrado: centrado)
            .accessibilityElement()
            .accessibilityLabel(texto.replacingOccurrences(of: "\u{00A0}", with: " "))
            .accessibilityAddTraits(.isHeader)
    }
}

/// UILabel con interlineado fijo y renglones balanceados.
struct EtiquetaTitulo: UIViewRepresentable {
    let texto: String
    let fuente: UIFont
    let color: UIColor
    var interlineado: CGFloat = 1.04
    var tracking: CGFloat = 0
    var centrado = false

    func makeUIView(context: Context) -> UILabel {
        let l = UILabel()
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.lineBreakStrategy = .pushOut
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        l.isAccessibilityElement = false
        return l
    }

    func updateUIView(_ l: UILabel, context: Context) {
        l.attributedText = atribuido
    }

    var atribuido: NSAttributedString {
        let alto = fuente.pointSize * interlineado
        let p = NSMutableParagraphStyle()
        p.minimumLineHeight = alto
        p.maximumLineHeight = alto
        p.alignment = centrado ? .center : .natural
        p.lineBreakStrategy = .pushOut
        // Con la línea más baja que la natural, el texto se corre hacia arriba: se lo baja la mitad de la diferencia.
        let natural = fuente.ascender - fuente.descender
        let desplazar = (alto - natural) / 2
        return NSAttributedString(string: texto, attributes: [
            .font: fuente, .foregroundColor: color, .paragraphStyle: p, .kern: tracking,
            .baselineOffset: desplazar / 2,
        ])
    }

    func sizeThatFits(_ propuesta: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let ancho = propuesta.width ?? 10_000
        let a = atribuido
        func medir(_ w: CGFloat) -> CGSize {
            a.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                           options: [.usesLineFragmentOrigin], context: nil).integral.size
        }
        let completo = medir(ancho)
        let alto = fuente.pointSize * interlineado
        let renglones = Int((completo.height / alto).rounded())
        guard renglones >= 2, propuesta.width != nil else {
            return CGSize(width: propuesta.width ?? completo.width, height: completo.height)
        }
        // text-wrap: balance
        var bajo: CGFloat = ancho / CGFloat(renglones), alto2 = ancho
        for _ in 0..<12 {
            let medio = (bajo + alto2) / 2
            if Int((medir(medio).height / alto).rounded()) > renglones { bajo = medio } else { alto2 = medio }
        }
        uiView.preferredMaxLayoutWidth = alto2
        let final = medir(alto2)
        return CGSize(width: ancho, height: final.height)
    }
}

/// Etiqueta en mayúsculas (12, 700, 0,06 em).
struct Etiqueta: View {
    let texto: String
    var color: Color = .texto2
    var tamano: CGFloat = 12
    init(_ texto: String, color: Color = .texto2, tamano: CGFloat = 12) { self.texto = texto; self.color = color; self.tamano = tamano }
    var body: some View {
        Text(texto.uppercased(with: Locale(identifier: "es_AR")))
            .font(Estilo.texto(tamano, 700).font())
            .tracking(tamano * 0.06)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

/// Número en Hanken 600 tabular con una unidad más chica al lado (el `<small>` del diseño).
struct Numero: View {
    let valor: String
    var tamano: CGFloat
    var color: Color = .titulo
    var unidad: String? = nil
    var tamanoUnidad: CGFloat? = nil
    var colorUnidad: Color = .texto2

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(valor).tipo(.numero(tamano)).foregroundStyle(color)
            if let unidad {
                Text(unidad).tipo(.texto(tamanoUnidad ?? max(13, tamano * 0.42), 500)).foregroundStyle(colorUnidad)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}
