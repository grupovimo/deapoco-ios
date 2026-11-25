import SwiftUI

/// El plato como gráfico (marca/sistema/plato.js, porteado tal cual): la misma porción del isotipo crece de a una
/// parte (un día de la semana, una comida del día, un turno). Lo que falta queda como plato limpio, nunca en rojo.
/// - `partes`: cuántas porciones tiene el plato (7 = la semana, 4 = el día).
/// - `llenas`: cuántas están servidas, como una sola porción rabanito que crece desde las 12.
/// - `hoy`: la parte que toca ahora, con borde punteado.
/// - `chico`: sin ala, para 48 pt o menos.
/// - `servir`: la porción aparece una sola vez al mostrarse (respeta «reducir movimiento»).
struct Plato: View {
    var partes: Int = 7
    var llenas: Int = 0
    var hoy: Int? = nil
    var chico = false
    var servir = false
    /// Para pisar el fondo del plato (sobre la banda en modo oscuro va #101A30).
    var fondo: Color? = nil
    var borde: Color? = nil
    @State private var servido = false
    @Environment(\.accessibilityReduceMotion) private var sinMovimiento

    var body: some View {
        ZStack {
            Canvas { ctx, size in dibujarBase(ctx, s: size.width / 100) }
            Canvas { ctx, size in dibujarPorcion(ctx, s: size.width / 100) }
                .scaleEffect(servir && !servido ? 0.86 : 1)
                .opacity(servir && !servido ? 0 : 1)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard servir, !servido else { return }
            if sinMovimiento { servido = true; return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.6).delay(0.1)) { servido = true }
        }
        .accessibilityElement()
        .accessibilityLabel("\(min(llenas, partes)) de \(partes)")
    }

    private var R: CGFloat { 46 }

    private func dibujarBase(_ ctx: GraphicsContext, s: CGFloat) {
        let g = R * (chico ? 0.2 : 0.16)
        let tr = CGAffineTransform(scaleX: s, y: s)
        let rr = R - g / 2
        let disco = Path(ellipseIn: CGRect(x: 50 - rr, y: 50 - rr, width: rr * 2, height: rr * 2)).applying(tr)
        ctx.fill(disco, with: .color(fondo ?? .platoFondo))
        ctx.stroke(disco, with: .color(borde ?? .platoBorde), lineWidth: g * s)
        if !chico {
            let ra = R * 0.70
            ctx.stroke(Path(ellipseIn: CGRect(x: 50 - ra, y: 50 - ra, width: ra * 2, height: ra * 2)).applying(tr),
                       with: .color(.platoAla), lineWidth: R * 0.04 * s)
            if partes > 1 {
                // Marcas de cada parte sobre el ala, para contar sin números.
                var marcas = Path()
                let paso = 360 / CGFloat(partes)
                for i in 0..<partes {
                    marcas.move(to: PlatoGeo.p(50, 50, CGFloat(i) * paso, R * 0.66))
                    marcas.addLine(to: PlatoGeo.p(50, 50, CGFloat(i) * paso, R * 0.74))
                }
                ctx.stroke(marcas.applying(tr), with: .color((borde ?? .platoBorde).opacity(0.28)),
                           style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round))
            }
        }
    }

    private func dibujarPorcion(_ ctx: GraphicsContext, s: CGFloat) {
        let tr = CGAffineTransform(scaleX: s, y: s)
        let n = max(partes, 1)
        let paso = 360 / CGFloat(n)
        let r = R * (chico ? 0.62 : 0.60), rc = R * 0.07, canal = R * 0.06
        let llenas = min(max(self.llenas, 0), n)
        if llenas >= n {
            ctx.fill(Path(ellipseIn: CGRect(x: 50 - r, y: 50 - r, width: r * 2, height: r * 2)).applying(tr), with: .color(.rabanito500))
        } else if llenas > 0 {
            ctx.fill(PlatoGeo.sector(50, 50, r, 0, CGFloat(llenas) * paso, rc).applying(tr), with: .color(.rabanito500))
        }
        if let hoy, hoy >= 0, llenas < n {
            let a0 = CGFloat(hoy) * paso, a1 = CGFloat(hoy + 1) * paso
            let p = llenas > 0 && hoy == llenas
                ? PlatoGeo.porcion(50, 50, r, a0, a1, rc, canal)
                : PlatoGeo.sector(50, 50, r, a0, a1, rc)
            ctx.stroke(p.applying(tr), with: .color(.rabanito500),
                       style: StrokeStyle(lineWidth: 1.6 * s, lineJoin: .round, dash: [3 * s, 2.6 * s]))
        }
    }
}

/// La geometría del plato (igual que sector() en fuente/generar_logo.py y plato.js).
enum PlatoGeo {
    static func p(_ cx: CGFloat, _ cy: CGFloat, _ a: CGFloat, _ r: CGFloat) -> CGPoint {
        let t = a * .pi / 180
        return CGPoint(x: cx + r * sin(t), y: cy - r * cos(t))
    }

    /// Sector desde el centro con las tres puntas redondeadas.
    static func sector(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ a0: CGFloat, _ a1: CGFloat, _ rc: CGFloat) -> Path {
        let da = (rc / r) * 180 / .pi
        let ap = rc / sin(((a1 - a0) / 2) * .pi / 180)
        let v0 = p(cx, cy, a0, ap), v1 = p(cx, cy, a1, ap)
        let e0 = p(cx, cy, a0, r - rc), e1 = p(cx, cy, a1, r - rc)
        let q0 = p(cx, cy, a0 + da, r), q1 = p(cx, cy, a1 - da, r)
        let big = a1 - a0 > 180 ? 1 : 0
        func f(_ q: CGPoint) -> String { String(format: "%.3f,%.3f", q.x, q.y) }
        let d = "M\(f(v0)) L\(f(e0)) Q\(f(p(cx, cy, a0, r))) \(f(q0)) A\(String(format: "%.3f,%.3f", r, r)) 0 \(big) 1 \(f(q1)) " +
            "Q\(f(p(cx, cy, a1, r))) \(f(e1)) L\(f(v1)) Q\(f(CGPoint(x: cx, y: cy))) \(f(v0)) Z"
        return SVGPath.path(d)
    }

    /// El centro de cada porción se corre hacia afuera para dejar un canal parejo entre porciones.
    static func porcion(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ a0: CGFloat, _ a1: CGFloat, _ rc: CGFloat, _ canal: CGFloat) -> Path {
        let mid = (a0 + a1) / 2, d = canal / 2 / sin(((a1 - a0) / 2) * .pi / 180)
        let c = p(cx, cy, mid, d)
        return sector(c.x, c.y, r - d, a0, a1, rc)
    }

    /// Sector simple (para el plato armado y la dona).
    static func cuna(_ a0: CGFloat, _ a1: CGFloat, _ r: CGFloat, centro: CGPoint = CGPoint(x: 50, y: 50)) -> Path {
        var path = Path()
        path.move(to: centro)
        path.addArc(center: centro, radius: r, startAngle: .degrees(Double(a0) - 90), endAngle: .degrees(Double(a1) - 90), clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// El plato armado (`svg.armado`): medio de verdura, un cuarto de proteína, un cuarto de almidón, con el enlozado de borde.
struct PlatoArmado: View {
    /// Cada porción: color y la fracción del plato que ocupa (en orden, desde las 12 en sentido horario).
    var porciones: [(Color, Double)] = [(.rabanito500, 0.25), (.durazno, 0.25), (.enlozado200, 0.5)]

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 100
            let tr = CGAffineTransform(scaleX: s, y: s)
            let ext = Path(ellipseIn: CGRect(x: 4, y: 4, width: 92, height: 92)).applying(tr)
            ctx.fill(ext, with: .color(.mantecaFija))
            ctx.stroke(ext, with: .color(.enlozado800), lineWidth: 7 * s)
            ctx.stroke(Path(ellipseIn: CGRect(x: 17, y: 17, width: 66, height: 66)).applying(tr), with: .color(Color(hex: 0xF3E6CC)), lineWidth: 1.6 * s)
            var a: CGFloat = 0
            for (color, f) in porciones where f > 0 {
                let b = a + CGFloat(f) * 360
                let p = PlatoGeo.cuna(a, b, 30).applying(tr)
                ctx.fill(p, with: .color(color))
                ctx.stroke(p, with: .color(.mantecaFija), style: StrokeStyle(lineWidth: 3 * s, lineJoin: .round))
                a = b
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
