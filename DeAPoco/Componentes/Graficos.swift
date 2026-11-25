import SwiftUI

/// La curva de medidas (`svg.curva`): nunca balanza, sólo la tendencia. Catmull-Rom a Bézier, relleno enlozado-200
/// que se desvanece, punto final con aro rabanito y los meses abajo.
struct Curva: View {
    let valores: [Double]
    var etiquetas: [String] = []
    var alto: CGFloat = 92
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Canvas { ctx, size in
            guard valores.count > 1 else { return }
            let W = size.width, H = size.height
            let top: CGFloat = 12, bot = H - 24
            let mn = (valores.min() ?? 0) - 1, mx = (valores.max() ?? 1) + 1
            func X(_ i: Int) -> CGFloat { 6 + CGFloat(i) * (W - 22) / CGFloat(valores.count - 1) }
            func Y(_ v: Double) -> CGFloat { top + CGFloat((mx - v) / (mx - mn)) * (bot - top) }
            let pts = valores.enumerated().map { CGPoint(x: X($0.offset), y: Y($0.element)) }
            var linea = Path()
            linea.move(to: pts[0])
            for i in 0..<(pts.count - 1) {
                let p0 = i > 0 ? pts[i - 1] : pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = i + 2 < pts.count ? pts[i + 2] : p2
                linea.addCurve(to: p2,
                               control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                               control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
            }
            let oscuro = esquema == .dark
            let guia = oscuro ? Color(hex: 0x2C3C60) : Color(hex: 0xE3D3BF)
            for f in [0, 0.5, 1.0] {
                let y = top + CGFloat(f) * (bot - top)
                var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: W, y: y))
                ctx.stroke(l, with: .color(guia), style: StrokeStyle(lineWidth: 1, dash: f == 1 ? [] : [2, 4]))
            }
            var area = linea
            let ultimo = pts[pts.count - 1]
            area.addLine(to: CGPoint(x: ultimo.x, y: bot)); area.addLine(to: CGPoint(x: pts[0].x, y: bot)); area.closeSubpath()
            let tinte = oscuro ? Color(hex: 0x9DB4E8) : Color(hex: 0xC6D4F2)
            ctx.fill(area, with: .linearGradient(Gradient(colors: [tinte.opacity(oscuro ? 0.35 : 0.9), tinte.opacity(0)]),
                                                 startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: bot)))
            ctx.stroke(linea, with: .color(oscuro ? Color(hex: 0x9DB4E8) : .enlozado800), style: StrokeStyle(lineWidth: 2.75, lineCap: .round))
            let punto = Path(ellipseIn: CGRect(x: ultimo.x - 7, y: ultimo.y - 7, width: 14, height: 14))
            ctx.fill(punto, with: .color(oscuro ? Color(hex: 0x1A2742) : .white))
            ctx.stroke(punto, with: .color(.rabanito500), lineWidth: 3)
            for (i, t) in etiquetas.enumerated() where !t.isEmpty && i < valores.count {
                let texto = Text(t).font(Estilo.texto(11, 700).font()).tracking(0.66).foregroundColor(.texto2)
                ctx.draw(texto, at: CGPoint(x: X(i), y: H - 4), anchor: i == 0 ? .bottomLeading : .bottom)
            }
        }
        .frame(height: alto)
        .accessibilityElement()
        .accessibilityLabel(valores.count > 1 ? "De \(Formato.decimal(valores[0])) a \(Formato.decimal(valores[valores.count - 1]))" : "Sin medidas")
    }
}

/// La dona de cobros (`svg.dona`): un aro por medio de pago con su color, separados por 4, y el % en el centro.
struct Dona: View {
    /// Cantidad y color de cada segmento.
    let segmentos: [(Int, Color)]
    var porcentaje: Int
    var leyenda = "cobrado"
    var lado: CGFloat = 124

    var body: some View {
        Canvas { ctx, size in
            let s = size.width, w: CGFloat = 16, r = (s - w) / 2, c = 2 * .pi * r, m = s / 2, gap: CGFloat = 4
            let total = max(1, segmentos.reduce(0) { $0 + $1.0 })
            var acc: CGFloat = 0
            for (v, col) in segmentos where v > 0 {
                let largo = CGFloat(v) / CGFloat(total) * c
                let a0 = acc / c * 360, a1 = (acc + max(largo - gap, 0.5)) / c * 360
                var arco = Path()
                arco.addArc(center: CGPoint(x: m, y: m), radius: r, startAngle: .degrees(Double(a0) - 90), endAngle: .degrees(Double(a1) - 90), clockwise: false)
                ctx.stroke(arco, with: .color(col), style: StrokeStyle(lineWidth: w))
                acc += largo
            }
            ctx.draw(Text("\(porcentaje)%").font(Estilo.numero(30).font()).tracking(-0.6).foregroundColor(.mantecaFija),
                     at: CGPoint(x: m, y: m + 2), anchor: .bottom)
            ctx.draw(Text(leyenda).font(Estilo.texto(11.5, 600).font()).foregroundColor(.sobreBanda2),
                     at: CGPoint(x: m, y: m + 20), anchor: .bottom)
        }
        .frame(width: lado, height: lado)
        .accessibilityElement()
        .accessibilityLabel("\(porcentaje) por ciento \(leyenda)")
    }
}

/// Porciones de una meta (`data-porc="3/5"`): pastillas rabanito y loza, y «3 de 5».
struct Porciones: View {
    let hechas: Int
    let total: Int
    var conTexto = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 0), id: \.self) { i in
                Capsule().fill(i < hechas ? Color.rabanito500 : Color.loza).frame(width: 16, height: 10)
            }
            if conTexto {
                Text("\(hechas) de \(total)").tipo(.texto(13, 700)).monospacedDigit().foregroundStyle(Color.texto2)
                    .padding(.leading, 6).fixedSize()
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(hechas) de \(total)")
    }
}

/// Los vasos de agua (`data-vasos`): ocho, los tomados en enlozado.
struct Vasos: View {
    let tomados: Int
    var total = 8
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                IconoVista(.agua, tamano: 20)
                    .foregroundStyle(i < tomados ? (esquema == .dark ? Color(hex: 0x9DB4E8) : Color.enlozado600)
                                                  : (esquema == .dark ? Color(hex: 0x4A5C82) : Color.corteza400))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(tomados) de \(total) vasos")
    }
}

/// La onda de un audio: barras de 3, las ya escuchadas en enlozado.
struct Onda: View {
    var escuchado: Int = 8
    static let alturas: [CGFloat] = [8, 14, 20, 12, 18, 24, 16, 10, 22, 14, 8, 18, 12, 20, 16, 10, 14, 8, 12, 6, 10, 8]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(Self.alturas.enumerated()), id: \.offset) { i, h in
                Capsule().fill(i < escuchado ? Color.enlozado800 : Color.enlozado500).frame(width: 3, height: h)
            }
        }
        .frame(height: 26)
        .accessibilityHidden(true)
    }
}

/// Las migas de la celebración: 22 puntos de colores alrededor del plato.
struct Migas: View {
    var lado: CGFloat = 236
    @State private var salen = false
    private static let colores: [Color] = [.rabanito500, .durazno, .enlozado300, .durazno500, .enlozado800]

    var body: some View {
        ZStack {
            ForEach(0..<22, id: \.self) { i in miga(i) }
        }
        .frame(width: lado, height: lado)
        .onAppear { withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.15)) { salen = true } }
        .accessibilityHidden(true)
    }

    private func miga(_ i: Int) -> some View {
        let a: Double = Double(i) / 22.0 * .pi * 2 + Double(i % 3) * 0.2
        let r: Double = (138.0 + Double(i % 4) * 10.0) * Double(lado) / 236.0
        let k: Double = salen ? 1 : 0.6
        let tam = CGFloat(6 + (i % 3) * 4)
        let x = CGFloat(r * cos(a) * k), y = CGFloat(r * sin(a) * k)
        let opacidad: Double = 0.55 + Double(i % 3) * 0.15
        return Circle()
            .fill(Self.colores[i % 5])
            .opacity(opacidad)
            .frame(width: tam, height: tam)
            .offset(x: x, y: y)
            .opacity(salen ? 1 : 0)
    }
}

/// Barra de progreso del mes (`.barra-mes`): 10 de alto, loza y rabanito.
struct BarraMes: View {
    let fraccion: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.loza)
                Capsule().fill(Color.rabanito500).frame(width: g.size.width * min(max(fraccion, 0), 1))
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}
