import Foundation

/// Plata y números como se leen en Argentina: «$1.284.000», «89,2».
enum Formato {
    private static let enteros: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "es_AR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.groupingSeparator = "."
        return f
    }()
    private static let decimales: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "es_AR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        f.decimalSeparator = ","
        f.groupingSeparator = "."
        return f
    }()

    static func plata(_ n: Int) -> String { "$" + (enteros.string(from: NSNumber(value: n)) ?? "\(n)") }
    static func entero(_ n: Int) -> String { enteros.string(from: NSNumber(value: n)) ?? "\(n)" }
    static func decimal(_ d: Double) -> String { decimales.string(from: NSNumber(value: d)) ?? "\(d)" }

    /// «−6», «+1,5»: la diferencia con signo (el menos tipográfico).
    static func diferencia(_ d: Double) -> String {
        let s = decimal(abs(d))
        if d < -0.05 { return "−" + s }
        if d > 0.05 { return "+" + s }
        return "0"
    }

    /// «diez» para los números chicos de las frases («Martín no anota hace diez días»).
    static func enLetras(_ n: Int) -> String {
        let l = ["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
                 "once", "doce", "trece", "catorce", "quince"]
        return n >= 0 && n < l.count ? l[n] : "\(n)"
    }

    /// Lista con «y»: «Sofía, Ana y Carla».
    static func lista(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default: return items.dropLast().joined(separator: ", ") + " y " + items[items.count - 1]
        }
    }
}

/// Fechas en ISO (AAAA-MM-DD) y su lectura en castellano.
enum Fecha {
    static let calendario: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "es_AR")
        c.timeZone = TimeZone(identifier: "America/Argentina/Buenos_Aires") ?? .current
        c.firstWeekday = 2
        return c
    }()

    private static let isoF: DateFormatter = {
        let f = DateFormatter()
        f.calendar = calendario
        f.timeZone = calendario.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func iso(_ d: Date) -> String { isoF.string(from: d) }
    static func fecha(_ iso: String) -> Date { isoF.date(from: iso) ?? Date() }

    static let meses = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
    static let diasLargos = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
    static let diasCortos = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]

    /// 1 = lunes … 7 = domingo.
    static func diaSemana(_ iso: String) -> Int {
        let w = calendario.component(.weekday, from: fecha(iso)) // 1 = domingo
        return w == 1 ? 7 : w - 1
    }
    static func dia(_ iso: String) -> Int { calendario.component(.day, from: fecha(iso)) }
    static func mes(_ iso: String) -> Int { calendario.component(.month, from: fecha(iso)) }

    static func sumar(_ dias: Int, a iso: String) -> String {
        Fecha.iso(calendario.date(byAdding: .day, value: dias, to: fecha(iso)) ?? fecha(iso))
    }
    static func sumarMeses(_ m: Int, a iso: String) -> String {
        Fecha.iso(calendario.date(byAdding: .month, value: m, to: fecha(iso)) ?? fecha(iso))
    }
    static func dias(entre a: String, y b: String) -> Int {
        calendario.dateComponents([.day], from: fecha(a), to: fecha(b)).day ?? 0
    }

    /// «Martes 25 de noviembre»
    static func larga(_ iso: String) -> String {
        let d = diasLargos[diaSemana(iso) - 1]
        return d.prefix(1).uppercased() + d.dropFirst() + " \(dia(iso)) de \(meses[mes(iso) - 1])"
    }
    /// «25 de noviembre»
    static func diaMes(_ iso: String) -> String { "\(dia(iso)) de \(meses[mes(iso) - 1])" }
    /// «25/11»
    static func corta(_ iso: String) -> String { "\(dia(iso))/\(mes(iso))" }
    /// «mar»
    static func diaCorto(_ iso: String) -> String { diasCortos[diaSemana(iso) - 1] }
    /// «martes»
    static func diaLargo(_ iso: String) -> String { diasLargos[diaSemana(iso) - 1] }
    /// «Noviembre»
    static func nombreMes(_ iso: String) -> String { let m = meses[mes(iso) - 1]; return m.prefix(1).uppercased() + m.dropFirst() }

    /// «hoy», «mañana», «ayer», «el jueves» o «el 3/12».
    static func relativa(_ iso: String, hoy: String) -> String {
        let d = dias(entre: hoy, y: iso)
        switch d {
        case 0: return "hoy"
        case 1: return "mañana"
        case -1: return "ayer"
        case 2...6: return "el \(diaLargo(iso))"
        default: return "el \(corta(iso))"
        }
    }

    /// Lunes de la semana de esa fecha.
    static func lunes(de iso: String) -> String { sumar(-(diaSemana(iso) - 1), a: iso) }

    /// Minutos desde las 00:00 de un «11:30».
    static func minutos(_ hora: String) -> Int {
        let p = hora.split(separator: ":").compactMap { Int($0) }
        return p.count == 2 ? p[0] * 60 + p[1] : 0
    }
    static func hora(_ minutos: Int) -> String { String(format: "%02d:%02d", minutos / 60, minutos % 60) }
}

/// Fotos que se sacan o eligen en el teléfono: se guardan en Documentos y se nombran «foto-<id>.jpg».
enum Archivos {
    static var carpeta: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static func guardar(_ datos: Data) -> String {
        let nombre = "foto-\(UUID().uuidString.prefix(8)).jpg"
        try? datos.write(to: carpeta.appendingPathComponent(nombre))
        return nombre
    }
    static func leer(_ nombre: String) -> Data? {
        guard nombre.hasPrefix("foto-") && nombre.hasSuffix(".jpg") else { return nil }
        return try? Data(contentsOf: carpeta.appendingPathComponent(nombre))
    }
}
