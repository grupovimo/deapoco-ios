import SwiftUI

/// Los íconos de De a Poco, copiados tal cual de los `<symbol>` de pantallas/app.html y sistema/iconos.svg
/// (grilla de 24, trazo 1,75, puntas y uniones redondas). Los que suma la app siguen el mismo trazo.
enum Icono: String, CaseIterable {
    case turno, plan, foto, pesaje, mensaje, pago, logro, agua, check, x, flecha, mas, persona, inicio, campana,
         reloj, luna, aviso, buscar, gente, atras, chev, video, lugar, mic, enviar, rayo, copiar, cinta, candado,
         asa, play, girar, galeria, bocado, brote, vuelta, compartir, bajar
    // Marcas (rellenas): WhatsApp, Google Calendar, Apple Salud, Instagram.
    case wa, gcal, salud, ig
    // Sumados por la app, con el mismo trazo.
    case lapiz, puntos, menos, abajo, basura, salir, qr, link, ajustes, estrella, sol, ojo, ayuda, escudo, filtro, pausa

    fileprivate enum Elemento {
        case trazo(String)
        case relleno(String)
        case circulo(CGFloat, CGFloat, CGFloat)
        case circuloLleno(CGFloat, CGFloat, CGFloat)
        case rect(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    }

    /// Las marcas se dibujan rellenas, con su forma de simple-icons.
    var esMarca: Bool { [.wa, .gcal, .salud].contains(self) }

    fileprivate var elementos: [Elemento] {
        switch self {
        case .turno: return [.rect(3.5, 5, 17, 15.5, 4.5), .trazo("M8 3v4M16 3v4M3.5 10.25h17"), .circulo(12, 15.4, 2.1)]
        case .plan: return [.rect(5, 4, 14, 16.5, 3.5), .trazo("M9.25 4V3.25h5.5V4M8.75 10h6.5M8.75 13.75h6.5M8.75 17.5h3.5")]
        case .foto: return [.trazo("M3.5 9a3 3 0 0 1 3-3h1.8l1.5-2.25h4.4L15.7 6h1.8a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3h-11a3 3 0 0 1-3-3z"), .circulo(12, 13, 3.75)]
        case .pesaje: return [.rect(3.5, 3.5, 17, 17, 6), .trazo("M7.5 13.5l3-2.75 2.75 2.25 3.25-3.5"), .circulo(7.5, 13.5, 0.6)]
        case .mensaje: return [.trazo("M20.5 11.5c0 4.14-3.8 7.5-8.5 7.5a9.6 9.6 0 0 1-3.36-.6L4 20l1.2-3.6a7 7 0 0 1-1.7-4.9C3.5 7.36 7.3 4 12 4s8.5 3.36 8.5 7.5z")]
        case .pago: return [.rect(2.75, 5.75, 18.5, 12.5, 3.5), .trazo("M2.75 10h18.5M6.5 14.5H10")]
        case .logro: return [.circulo(12, 12, 9), .trazo("M12 12V6.5a5.5 5.5 0 0 1 4.76 8.25z")]
        case .agua: return [.trazo("M6.25 3.75h11.5l-1.45 15a2.2 2.2 0 0 1-2.2 2h-4.2a2.2 2.2 0 0 1-2.2-2z"), .trazo("M7.1 9.25c1.65-.9 3.25-.9 4.9 0s3.25.9 4.9 0")]
        case .check: return [.trazo("M5 12.5l4.5 4.5L19 7.5")]
        case .x: return [.trazo("M6 6l12 12M18 6L6 18")]
        case .flecha: return [.trazo("M5 12h14M13 6l6 6-6 6")]
        case .mas: return [.trazo("M12 5v14M5 12h14")]
        case .persona: return [.circulo(12, 8.5, 3.75), .trazo("M4.75 20c.8-3.7 3.7-5.75 7.25-5.75s6.45 2.05 7.25 5.75")]
        case .inicio: return [.trazo("M4 11.2L12 4.5l8 6.7V19a1.75 1.75 0 0 1-1.75 1.75H15V15.5H9v5.25H5.75A1.75 1.75 0 0 1 4 19z")]
        case .campana: return [.trazo("M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15zM10 20.5a2 2 0 0 0 4 0")]
        case .reloj: return [.circulo(12, 12, 8.75), .trazo("M12 7.5V12l3 2")]
        case .luna: return [.trazo("M19.5 14.6A7.8 7.8 0 0 1 9.4 4.5a7.8 7.8 0 1 0 10.1 10.1z")]
        case .aviso: return [.circulo(12, 12, 8.75), .trazo("M12 7.75v5M12 16.25v.01")]
        case .buscar: return [.circulo(11, 11, 6.5), .trazo("M16 16l4 4")]
        case .gente: return [.circulo(9, 9, 3.25), .trazo("M3 19.5c.6-3.1 3-4.9 6-4.9s5.4 1.8 6 4.9"), .trazo("M15.5 5.9a3.2 3.2 0 0 1 0 6.2M17.6 14.9c1.8.6 3 2.2 3.4 4.6")]
        case .atras: return [.trazo("M15 5l-7 7 7 7")]
        case .chev: return [.trazo("M9.5 6l6 6-6 6")]
        case .video: return [.rect(3, 6.5, 12.5, 11, 3.5), .trazo("M15.5 10.5l5-3v9l-5-3")]
        case .lugar: return [.trazo("M12 20.5s-6.5-5.6-6.5-10.5a6.5 6.5 0 0 1 13 0c0 4.9-6.5 10.5-6.5 10.5z"), .circulo(12, 10, 2.3)]
        case .mic: return [.rect(9, 3.5, 6, 11, 3), .trazo("M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v2.5")]
        case .enviar: return [.trazo("M12 19V5.5M6 11l6-6 6 6")]
        case .rayo: return [.trazo("M13 3.5L6 13.25h5.25L10.5 20.5l7.5-10h-5.5z")]
        case .copiar: return [.rect(8.5, 8.5, 11, 11, 3), .trazo("M15.5 8.5V7a2.5 2.5 0 0 0-2.5-2.5H7A2.5 2.5 0 0 0 4.5 7v6A2.5 2.5 0 0 0 7 15.5h1.5")]
        case .cinta: return [.rect(3.5, 7.5, 17, 9, 3), .trazo("M7.5 7.5v3M11 7.5v2M14.5 7.5v3M18 7.5v2")]
        case .candado: return [.rect(5, 10.5, 14, 10, 3.5), .trazo("M8.25 10.5V8a3.75 3.75 0 0 1 7.5 0v2.5")]
        case .asa: return [.circuloLleno(9, 7, 0.9), .circuloLleno(15, 7, 0.9), .circuloLleno(9, 12, 0.9),
                           .circuloLleno(15, 12, 0.9), .circuloLleno(9, 17, 0.9), .circuloLleno(15, 17, 0.9)]
        case .play: return [.relleno("M8 5.5v13l10.5-6.5z")]
        case .girar: return [.trazo("M4.5 12a7.5 7.5 0 0 1 13-5.1M19.5 12a7.5 7.5 0 0 1-13 5.1"), .trazo("M17.5 3.5v3.4h-3.4M6.5 20.5v-3.4h3.4")]
        case .galeria: return [.rect(3.5, 4.5, 17, 15, 4), .circulo(9, 9.75, 1.6), .trazo("M4 17l4.75-4.5 3.5 3 3-2.5L20 17")]
        case .bocado: return [.relleno("M12 12V2.5a9.5 9.5 0 0 1 8.2 14.25z")]
        case .brote: return [.trazo("M12 20.5v-8"), .trazo("M12 12.5c0-4 2.6-6.5 7-6.5 0 4.2-2.7 6.5-7 6.5zM12 14.5c0-3.2-2.1-5.2-6.5-5.2 0 3.4 2.3 5.2 6.5 5.2z")]
        case .vuelta: return [.trazo("M19.5 12a7.5 7.5 0 1 1-2.2-5.3"), .trazo("M19.5 4v4h-4")]
        case .compartir: return [.trazo("M12 3.5v11M7.5 8 12 3.5 16.5 8"), .trazo("M8 11.5H6.5a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-5a2 2 0 0 0-2-2H16")]
        case .bajar: return [.trazo("M12 4v11M7.5 10.5 12 15l4.5-4.5M5 19.5h14")]
        case .wa: return [.relleno("M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413z")]
        case .gcal: return [.relleno("M18.316 5.684H24v12.632h-5.684V5.684zM5.684 24h12.632v-5.684H5.684V24zM18.316 5.684V0H1.895A1.894 1.894 0 0 0 0 1.895v16.421h5.684V5.684h12.632zm-7.207 6.25v-.065c.272-.144.5-.349.687-.617s.279-.595.279-.982c0-.379-.099-.72-.3-1.025a2.05 2.05 0 0 0-.832-.714 2.703 2.703 0 0 0-1.197-.257c-.6 0-1.094.156-1.485.471-.387.311-.65.671-.792 1.071l1.207.5c.086-.249.226-.461.418-.633.194-.17.43-.255.711-.255.29 0 .532.085.722.255.19.17.284.385.284.647 0 .29-.104.519-.315.686-.209.17-.475.254-.791.254h-.6v1.204h.66c.355 0 .652.086.889.256.237.17.355.4.355.693 0 .289-.106.518-.32.693-.214.17-.48.256-.793.256-.311 0-.58-.098-.808-.295-.227-.198-.385-.468-.474-.81l-1.215.495c.143.506.428.928.855 1.264.43.338.968.508 1.613.508.432 0 .82-.088 1.165-.258.345-.172.613-.41.807-.719.192-.31.29-.664.29-1.065 0-.4-.105-.75-.316-1.05a1.997 1.997 0 0 0-.793-.692zm2.786 2.73h1.315V9.087h-.042l-1.906 1.379.633.973.97-.727v3.952h-.97zM0 18.316v3.789A1.894 1.894 0 0 0 1.895 24h3.789v-5.684H0z")]
        case .salud: return [.relleno("M12 21s-7.6-4.6-9.4-9.6C1.4 8 3.4 4.2 7.2 4.2c2 0 3.6 1.1 4.8 2.8 1.2-1.7 2.8-2.8 4.8-2.8 3.8 0 5.8 3.8 4.6 7.2C19.6 16.4 12 21 12 21z")]
        case .ig: return [.rect(3, 3, 18, 18, 5.5), .circulo(12, 12, 4.2), .circuloLleno(17.3, 6.7, 1.3)]
        case .lapiz: return [.trazo("M4.5 19.5l1-4.25L15.75 5a2.12 2.12 0 0 1 3 3L8.5 18.25z"), .trazo("M13.75 7l3 3")]
        case .puntos: return [.circuloLleno(5.5, 12, 1.5), .circuloLleno(12, 12, 1.5), .circuloLleno(18.5, 12, 1.5)]
        case .menos: return [.trazo("M5 12h14")]
        case .abajo: return [.trazo("M6 9.5l6 6 6-6")]
        case .basura: return [.trazo("M4.5 7h15M9.5 7V4.75h5V7M6.5 7l.9 12a2 2 0 0 0 2 1.75h5.2a2 2 0 0 0 2-1.75l.9-12")]
        case .salir: return [.trazo("M14.5 4.5H17a2.5 2.5 0 0 1 2.5 2.5v10a2.5 2.5 0 0 1-2.5 2.5h-2.5"), .trazo("M10 16.5 5.5 12 10 7.5M5.5 12h10")]
        case .qr: return [.rect(4, 4, 6.5, 6.5, 2), .rect(13.5, 4, 6.5, 6.5, 2), .rect(4, 13.5, 6.5, 6.5, 2), .trazo("M13.5 13.5h2.5v2.5M20 13.5v.01M13.5 20h.01M17 17v3h3")]
        case .link: return [.trazo("M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 0 0-5.66-5.66l-1 1"), .trazo("M14 10a4 4 0 0 0-5.66 0l-3 3a4 4 0 0 0 5.66 5.66l1-1")]
        case .ajustes: return [.trazo("M4 7.5h9M17 7.5h3M4 16.5h3M11 16.5h9"), .circulo(15, 7.5, 2), .circulo(9, 16.5, 2)]
        case .estrella: return [.trazo("M12 3.75l2.5 5.1 5.6.8-4.05 3.95.95 5.6L12 16.55 6.95 19.2l.95-5.6L3.85 9.65l5.6-.8z")]
        case .sol: return [.circulo(12, 12, 4), .trazo("M12 2.75v2M12 19.25v2M2.75 12h2M19.25 12h2M5.45 5.45l1.4 1.4M17.15 17.15l1.4 1.4M5.45 18.55l1.4-1.4M17.15 6.85l1.4-1.4")]
        case .ojo: return [.trazo("M2.75 12S6.25 5.5 12 5.5 21.25 12 21.25 12 17.75 18.5 12 18.5 2.75 12 2.75 12z"), .circulo(12, 12, 3)]
        case .ayuda: return [.circulo(12, 12, 8.75), .trazo("M9.6 9.6a2.45 2.45 0 1 1 3.5 2.2c-.65.32-1.1.95-1.1 1.7v.4M12 16.75v.01")]
        case .escudo: return [.trazo("M12 3.5l7 2.75v5.5c0 4.4-3 7.6-7 8.75-4-1.15-7-4.35-7-8.75v-5.5z"), .trazo("M8.75 12.25l2.25 2.25 4.25-4.5")]
        case .filtro: return [.trazo("M4.5 6.5h15M7.5 12h9M10.5 17.5h3")]
        case .pausa: return [.rect(6.5, 5, 3.75, 14, 1.5), .rect(13.75, 5, 3.75, 14, 1.5)]
        }
    }

    /// Partes trazadas y rellenas, en coordenadas del viewBox (24×24). Se calculan una sola vez.
    fileprivate var partes: (trazo: Path, relleno: Path) {
        Icono.cerrojo.lock(); defer { Icono.cerrojo.unlock() }
        if let p = Icono.cachePartes[self] { return p }
        var t = Path(), r = Path()
        for e in elementos {
            switch e {
            case .trazo(let d): t.addPath(SVGPath.path(d))
            case .relleno(let d): r.addPath(SVGPath.path(d))
            case .circulo(let x, let y, let rr): t.addEllipse(in: CGRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2))
            case .circuloLleno(let x, let y, let rr): r.addEllipse(in: CGRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2))
            case .rect(let x, let y, let w, let h, let rx):
                t.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: rx, height: rx))
            }
        }
        Icono.cachePartes[self] = (t, r)
        return (t, r)
    }
    nonisolated(unsafe) private static var cachePartes: [Icono: (trazo: Path, relleno: Path)] = [:]
    private static let cerrojo = NSLock()
}

/// Dibuja un ícono a 24 (barra), 20 (botones) o 16 (junto a texto), con el grosor del CSS
/// (1,75 · 1,9 · 2,1 en unidades del viewBox).
struct IconoVista: View {
    let icono: Icono
    var tamano: CGFloat = 24
    var grosor: CGFloat? = nil

    init(_ icono: Icono, tamano: CGFloat = 24, grosor: CGFloat? = nil) {
        self.icono = icono; self.tamano = tamano; self.grosor = grosor
    }

    var body: some View {
        let g = grosor ?? (tamano <= 16 ? 2.1 : tamano <= 20 ? 1.9 : 1.75)
        let partes = icono.partes
        Canvas { ctx, size in
            let s = size.width / 24
            let tr = CGAffineTransform(scaleX: s, y: s)
            ctx.stroke(partes.trazo.applying(tr), with: .foreground,
                       style: StrokeStyle(lineWidth: g * s, lineCap: .round, lineJoin: .round))
            ctx.fill(partes.relleno.applying(tr), with: .foreground)
        }
        .frame(width: tamano, height: tamano)
        .accessibilityHidden(true)
    }
}

/// El logo de Mercado Pago (la plantilla #mp-logo del diseño), 40×28.
struct LogoMP: View {
    var ancho: CGFloat = 26
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 40
            let tr = CGAffineTransform(scaleX: s, y: s)
            ctx.fill(Path(ellipseIn: CGRect(x: 1, y: 1, width: 38, height: 26)).applying(tr), with: .color(Color(hex: 0x00B1EA)))
            ctx.fill(Path(ellipseIn: CGRect(x: 4.5, y: 4.2, width: 31, height: 19.6)).applying(tr), with: .color(.white))
            let azul = Color(hex: 0x0A2E8A)
            ctx.stroke(SVGPath.path("M8.5 13.2c3-2.6 6.3-3.6 8.9-1.9l2.3 1.5c1 .6 2.1.6 3 0l2.5-1.6c2.6-1.6 6-.5 8.4 2.1").applying(tr),
                       with: .color(azul), style: StrokeStyle(lineWidth: 1.9 * s, lineCap: .round))
            ctx.stroke(SVGPath.path("M12 16.6l2.4 1.7M15.4 15.8l2.6 2M18.8 15.4l2.4 2").applying(tr),
                       with: .color(azul), style: StrokeStyle(lineWidth: 1.7 * s, lineCap: .round))
        }
        .frame(width: ancho, height: ancho * 28 / 40)
        .accessibilityHidden(true)
    }
}

/// Lector mínimo de `d` de SVG (M L H V C S Q T A Z, absolutos y relativos, con repetición implícita).
enum SVGPath {
    static func path(_ d: String) -> Path {
        var p = Path()
        var s = Escaner(Array(d.utf8))
        var actual = CGPoint.zero, inicio = CGPoint.zero
        var ultimoControl: CGPoint? = nil
        var comando: UInt8 = 0
        while true {
            s.saltarSeparadores()
            guard let c = s.mirar() else { break }
            if Escaner.esLetra(c) { comando = c; s.i += 1 } else if comando == 0 { break }
            let rel = comando >= 97
            let base = rel ? actual : .zero
            switch comando | 0x20 { // en minúscula
            case UInt8(ascii: "m"):
                guard let x = s.numero(), let y = s.numero() else { return p }
                actual = CGPoint(x: base.x + x, y: base.y + y); inicio = actual
                p.move(to: actual)
                comando = rel ? UInt8(ascii: "l") : UInt8(ascii: "L") // pares siguientes: lineto
                ultimoControl = nil
            case UInt8(ascii: "l"):
                guard let x = s.numero(), let y = s.numero() else { return p }
                actual = CGPoint(x: base.x + x, y: base.y + y); p.addLine(to: actual); ultimoControl = nil
            case UInt8(ascii: "h"):
                guard let x = s.numero() else { return p }
                actual = CGPoint(x: (rel ? actual.x : 0) + x, y: actual.y); p.addLine(to: actual); ultimoControl = nil
            case UInt8(ascii: "v"):
                guard let y = s.numero() else { return p }
                actual = CGPoint(x: actual.x, y: (rel ? actual.y : 0) + y); p.addLine(to: actual); ultimoControl = nil
            case UInt8(ascii: "c"):
                guard let x1 = s.numero(), let y1 = s.numero(), let x2 = s.numero(), let y2 = s.numero(),
                      let x = s.numero(), let y = s.numero() else { return p }
                let c1 = CGPoint(x: base.x + x1, y: base.y + y1), c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addCurve(to: actual, control1: c1, control2: c2); ultimoControl = c2
            case UInt8(ascii: "s"):
                guard let x2 = s.numero(), let y2 = s.numero(), let x = s.numero(), let y = s.numero() else { return p }
                let c1 = ultimoControl.map { CGPoint(x: 2 * actual.x - $0.x, y: 2 * actual.y - $0.y) } ?? actual
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addCurve(to: actual, control1: c1, control2: c2); ultimoControl = c2
            case UInt8(ascii: "q"):
                guard let x1 = s.numero(), let y1 = s.numero(), let x = s.numero(), let y = s.numero() else { return p }
                let c = CGPoint(x: base.x + x1, y: base.y + y1)
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addQuadCurve(to: actual, control: c); ultimoControl = c
            case UInt8(ascii: "t"):
                guard let x = s.numero(), let y = s.numero() else { return p }
                let c = ultimoControl.map { CGPoint(x: 2 * actual.x - $0.x, y: 2 * actual.y - $0.y) } ?? actual
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addQuadCurve(to: actual, control: c); ultimoControl = c
            case UInt8(ascii: "a"):
                guard let rx = s.numero(), let ry = s.numero(), let rot = s.numero(),
                      let grande = s.bandera(), let barrido = s.bandera(),
                      let x = s.numero(), let y = s.numero() else { return p }
                let fin = CGPoint(x: base.x + x, y: base.y + y)
                arco(&p, desde: actual, hasta: fin, rx: rx, ry: ry, rotacion: rot, grande: grande, barrido: barrido)
                actual = fin; ultimoControl = nil
            case UInt8(ascii: "z"):
                p.closeSubpath(); actual = inicio; ultimoControl = nil
                comando = 0
                continue
            default:
                return p
            }
        }
        return p
    }

    /// Arco elíptico de SVG pasado a curvas de Bézier (parametrización por centro, W3C F.6).
    private static func arco(_ p: inout Path, desde p0: CGPoint, hasta p1: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat,
                             rotacion: CGFloat, grande: Bool, barrido: Bool) {
        var rx = abs(rx0), ry = abs(ry0)
        if rx == 0 || ry == 0 || p0 == p1 { p.addLine(to: p1); return }
        let phi = rotacion * .pi / 180, cp = cos(phi), sp = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var coef = sqrt(max(0, num / den))
        if grande == barrido { coef = -coef }
        let cxp = coef * rx * y1 / ry, cyp = -coef * ry * x1 / rx
        let cx = cp * cxp - sp * cyp + (p0.x + p1.x) / 2
        let cy = sp * cxp + cp * cyp + (p0.y + p1.y) / 2
        func angulo(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let t1 = angulo(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry)
        var dt = angulo((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry)
        if !barrido && dt > 0 { dt -= 2 * .pi } else if barrido && dt < 0 { dt += 2 * .pi }
        let n = max(1, Int(ceil(abs(dt) / (.pi / 2))))
        let paso = dt / CGFloat(n)
        let k = 4.0 / 3.0 * tan(paso / 4)
        func punto(_ t: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cos(t) * cp - ry * sin(t) * sp, y: cy + rx * cos(t) * sp + ry * sin(t) * cp)
        }
        func derivada(_ t: CGFloat) -> CGPoint {
            CGPoint(x: -rx * sin(t) * cp - ry * cos(t) * sp, y: -rx * sin(t) * sp + ry * cos(t) * cp)
        }
        var t = t1
        for _ in 0..<n {
            let a = punto(t), b = punto(t + paso), da = derivada(t), db = derivada(t + paso)
            p.addCurve(to: b, control1: CGPoint(x: a.x + k * da.x, y: a.y + k * da.y),
                       control2: CGPoint(x: b.x - k * db.x, y: b.y - k * db.y))
            t += paso
        }
    }

    private struct Escaner {
        let b: [UInt8]
        var i = 0
        init(_ b: [UInt8]) { self.b = b }
        func mirar() -> UInt8? { i < b.count ? b[i] : nil }
        static func esLetra(_ c: UInt8) -> Bool { (c >= 65 && c <= 90) || (c >= 97 && c <= 122) && c != 101 }
        mutating func saltarSeparadores() {
            while i < b.count, b[i] == 32 || b[i] == 44 || b[i] == 10 || b[i] == 9 || b[i] == 13 { i += 1 }
        }
        mutating func bandera() -> Bool? {
            saltarSeparadores()
            guard i < b.count else { return nil }
            let c = b[i]
            if c == 48 || c == 49 { i += 1; return c == 49 }
            return nil
        }
        mutating func numero() -> CGFloat? {
            saltarSeparadores()
            let ini = i
            if i < b.count, b[i] == 43 || b[i] == 45 { i += 1 }
            var punto = false, digitos = false
            while i < b.count {
                let c = b[i]
                if c >= 48 && c <= 57 { digitos = true; i += 1 }
                else if c == 46 && !punto { punto = true; i += 1 }
                else if (c == 101 || c == 69) && digitos {
                    i += 1
                    if i < b.count, b[i] == 43 || b[i] == 45 { i += 1 }
                } else { break }
            }
            guard digitos, let s = String(bytes: b[ini..<i], encoding: .ascii), let v = Double(s) else { i = ini; return nil }
            return CGFloat(v)
        }
    }
}
