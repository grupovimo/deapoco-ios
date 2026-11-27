import SwiftUI

/// Los gajos como gráfico de progreso (marca/sistema/gajos.js, porteado tal cual): la misma geometría del logo.
/// Cada parte del día o de la semana es un gajo: los hechos en naranja, el de ahora en mandarina y los que faltan
/// en pulpa. Nunca en rojo ni en gris: lo que falta es naranja por comer, no una falla.
/// - `forma`: la rodaja (como el logo, sin cáscara) o el anillo de gajos.
/// - `partes`: cuántos gajos (6 = comidas del día, 7 = la semana). De 2 a 12.
/// - `llenas`: cuántos están hechos, desde las 12 en sentido horario.
/// - `ahora`: el gajo de ahora (por defecto, el siguiente al último lleno) o `.no`.
/// - `chico`: canal más ancho, para 40 pt o menos.
/// - `servir`: el último gajo lleno aparece una sola vez al mostrarse (respeta «reducir movimiento»).
struct Gajos: View {
    enum Forma { case rodaja, anillo }
    enum Ahora: Equatable { case siguiente, no, en(Int) }

    var forma: Forma = .rodaja
    var partes: Int = 6
    var llenas: Int = 0
    var ahora: Ahora = .siguiente
    var chico = false
    var servir = false
    /// Para pisar los colores (en la tarjeta mandarina de logros, lo lleno va en naranja 700).
    var lleno: Color? = nil
    var falta: Color? = nil
    @State private var servido = false
    @Environment(\.accessibilityReduceMotion) private var sinMovimiento

    private var n: Int { min(max(partes, 2), 12) }
    private var hechas: Int { min(max(llenas, 0), n) }
    private var indiceAhora: Int {
        switch ahora {
        case .no: return -1
        case .en(let i): return i
        case .siguiente: return hechas < n ? hechas : -1
        }
    }

    var body: some View {
        ZStack {
            Canvas { ctx, size in dibujar(ctx, s: size.width / 100, ultimo: false) }
            Canvas { ctx, size in dibujar(ctx, s: size.width / 100, ultimo: true) }
                .scaleEffect(servir && !servido ? 0.8 : 1)
                .opacity(servir && !servido ? 0 : 1)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard servir, !servido else { return }
            if sinMovimiento { servido = true; return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.52).delay(0.1)) { servido = true }
        }
        .accessibilityElement()
        .accessibilityLabel("\(hechas) de \(n)")
    }

    /// Dibuja todos los gajos menos el último lleno (`ultimo` = false) o sólo ese (para servirlo).
    private func dibujar(_ ctx: GraphicsContext, s: CGFloat, ultimo: Bool) {
        let tr = CGAffineTransform(scaleX: s, y: s)
        let paso = 360 / CGFloat(n)
        let servible = servir && hechas > 0 ? hechas - 1 : -1
        for i in 0..<n where (i == servible) == ultimo {
            let color: Color
            if i < hechas { color = lleno ?? .gajoLleno } else if i == indiceAhora { color = .gajoAhora } else { color = falta ?? .gajoFalta }
            let a0 = CGFloat(i) * paso, a1 = CGFloat(i + 1) * paso
            let camino: Path
            if forma == .anillo {
                camino = PlatoGeo.corona(50, 50, chico ? 24 : 29, 48, a0, a1, chico ? 7 : 5, 3.2)
            } else {
                let R: CGFloat = 48
                camino = PlatoGeo.porcion(50, 50, R, a0, a1, R * (chico ? 0.1 : 0.075), R * (chico ? 0.12 : 0.075))
            }
            ctx.fill(camino.applying(tr), with: .color(color))
        }
    }
}

/// La geometría de los gajos (igual que sector(), gajo() y corona() en gajos.js y fuente/generar_logo.py).
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

    /// Gajo de corona, entre `ri` y `ro`, de `a0` a `a1`, con canal parejo `g` y esquinas redondeadas `rc`.
    static func corona(_ cx: CGFloat, _ cy: CGFloat, _ ri: CGFloat, _ ro: CGFloat, _ a0: CGFloat, _ a1: CGFloat,
                       _ g: CGFloat, _ rc: CGFloat) -> Path {
        func asn(_ r: CGFloat) -> CGFloat { asin(g / 2 / r) * 180 / .pi }
        func dg(_ r: CGFloat) -> CGFloat { rc / r * 180 / .pi }
        func hacia(_ a: CGPoint, _ b: CGPoint, _ d: CGFloat) -> CGPoint {
            let dx = b.x - a.x, dy = b.y - a.y
            let l = max(hypot(dx, dy), 0.0001)
            return CGPoint(x: a.x + dx / l * d, y: a.y + dy / l * d)
        }
        let o0 = p(cx, cy, a0 + asn(ro), ro), o1 = p(cx, cy, a1 - asn(ro), ro)
        let i0 = p(cx, cy, a0 + asn(ri), ri), i1 = p(cx, cy, a1 - asn(ri), ri)
        // Ángulos en el sistema de SwiftUI (0 = las 3, en sentido horario con y hacia abajo): a − 90.
        func ang(_ a: CGFloat) -> Angle { .degrees(Double(a - 90)) }
        var c = Path()
        c.move(to: hacia(i0, o0, rc))
        c.addLine(to: hacia(o0, i0, rc))
        c.addQuadCurve(to: p(cx, cy, a0 + asn(ro) + dg(ro), ro), control: o0)
        c.addArc(center: CGPoint(x: cx, y: cy), radius: ro, startAngle: ang(a0 + asn(ro) + dg(ro)),
                 endAngle: ang(a1 - asn(ro) - dg(ro)), clockwise: false)
        c.addQuadCurve(to: hacia(o1, i1, rc), control: o1)
        c.addLine(to: hacia(i1, o1, rc))
        c.addQuadCurve(to: p(cx, cy, a1 - asn(ri) - dg(ri), ri), control: i1)
        c.addArc(center: CGPoint(x: cx, y: cy), radius: ri, startAngle: ang(a1 - asn(ri) - dg(ri)),
                 endAngle: ang(a0 + asn(ri) + dg(ri)), clockwise: true)
        c.addQuadCurve(to: hacia(i0, o0, rc), control: i0)
        c.closeSubpath()
        return c
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

/// El plato armado (`svg.armado`): medio de verdura, un cuarto de proteína, un cuarto de almidón, con borde verde.
struct PlatoArmado: View {
    /// Cada porción: color y la fracción del plato que ocupa (en orden, desde las 12 en sentido horario).
    var porciones: [(Color, Double)] = [(.naranja600, 0.25), (.mandarina, 0.25), (.hojaClara, 0.5)]

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 100
            let tr = CGAffineTransform(scaleX: s, y: s)
            let ext = Path(ellipseIn: CGRect(x: 4, y: 4, width: 92, height: 92)).applying(tr)
            ctx.fill(ext, with: .color(.crema))
            ctx.stroke(ext, with: .color(.verde900), lineWidth: 7 * s)
            ctx.stroke(Path(ellipseIn: CGRect(x: 17, y: 17, width: 66, height: 66)).applying(tr), with: .color(Color.crema300), lineWidth: 1.6 * s)
            var a: CGFloat = 0
            for (color, f) in porciones where f > 0 {
                let b = a + CGFloat(f) * 360
                let p = PlatoGeo.cuna(a, b, 30).applying(tr)
                ctx.fill(p, with: .color(color))
                ctx.stroke(p, with: .color(.crema), style: StrokeStyle(lineWidth: 3 * s, lineJoin: .round))
                a = b
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
