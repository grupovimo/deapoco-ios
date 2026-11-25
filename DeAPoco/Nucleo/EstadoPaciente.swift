import SwiftUI

/// Un día de la semana del paciente, como platito: cuántas de las cuatro comidas anotó.
struct DiaPlatito: Identifiable, Hashable {
    var id: String { fecha }
    let fecha: String
    let llenas: Int
    let esHoy: Bool
    let futuro: Bool
}

/// Derivados y acciones extra del lado del paciente.
extension Estado {
    /// La semana en curso, de lunes a domingo.
    var semanaPaciente: [DiaPlatito] {
        let lunes = Fecha.lunes(de: paciente.hoy)
        return (0..<7).map { i in
            let f = Fecha.sumar(i, a: lunes)
            return DiaPlatito(fecha: f, llenas: f > paciente.hoy ? 0 : comidasAnotadas(f), esHoy: f == paciente.hoy, futuro: f > paciente.hoy)
        }
    }

    /// «Del 24 al 30 de noviembre»
    var textoSemanaPaciente: String {
        let lunes = Fecha.lunes(de: paciente.hoy), domingo = Fecha.sumar(6, a: lunes)
        return Fecha.mes(lunes) == Fecha.mes(domingo)
            ? "Del \(Fecha.dia(lunes)) al \(Fecha.diaMes(domingo))"
            : "Del \(Fecha.diaMes(lunes)) al \(Fecha.diaMes(domingo))"
    }

    /// «Martes 24 · turno el jueves 11:30»
    var fechaCabeceraHoy: String {
        let d = Fecha.diaLargo(paciente.hoy)
        let base = d.prefix(1).uppercased() + d.dropFirst() + " \(Fecha.dia(paciente.hoy))"
        guard let t = paciente.turno else { return base }
        return base + " · turno \(Fecha.relativa(t.fecha, hoy: paciente.hoy)) \(t.hora)"
    }

    var comidasConFoto: Int { paciente.registros.filter { $0.foto != nil }.count }

    /// La frase debajo del plato del día.
    var fraseDelDia: String {
        guard let m = proximaComida else { return "Las cuatro, anotadas. Bien ahí, de a poco." }
        return "Sacale una foto \(articulo(m)) \(m.titulo.lowercased()). Con eso alcanza."
    }

    func articulo(_ m: Momento) -> String { m == .merienda || m == .cena || m == .colacion ? "a la" : "al" }

    /// Lo que hay que comprar para la semana, sacado del plan.
    var listaCompras: [String] {
        var vistos = Set<String>(), l: [String] = []
        func sumar(_ s: String) { let k = s.lowercased(); if !vistos.contains(k) { vistos.insert(k); l.append(s) } }
        for c in paciente.plan.comidas {
            for i in c.items { sumar(i.nombre) }
            for o in c.opciones { for p in o.partes { sumar(p.nombre) } }
        }
        return l
    }

    /// Días hábiles desde mañana (los próximos diez) para sacar o cambiar un turno.
    var diasParaTurno: [String] {
        var l: [String] = [], f = paciente.hoy
        while l.count < 10 {
            f = Fecha.sumar(1, a: f)
            if Fecha.diaSemana(f) <= 5 { l.append(f) }
        }
        return l
    }

    /// Horarios libres de la nutri ese día (en la maqueta, armados del número del día).
    func horariosLibres(_ fecha: String) -> [String] {
        let todos = ["09:00", "09:30", "10:00", "11:30", "12:00", "15:00", "16:30", "17:00", "18:00", "18:30"]
        let d = Fecha.dia(fecha)
        return todos.enumerated().filter { (i, _) in (i + d) % 3 != 0 }.map(\.element)
    }

    /// El pago de hoy, si ya pagó.
    var pagoDeHoy: Cobro? { paciente.pagos.first { $0.pagadoEl == paciente.hoy } }

    func marcarAvisoLeido(_ id: String) {
        guard let i = paciente.avisos.firstIndex(where: { $0.id == id }) else { return }
        paciente.avisos[i].leido = true
    }

    func leerTodosLosAvisos() {
        withAnimation(.snappy) { for i in paciente.avisos.indices { paciente.avisos[i].leido = true } }
    }

    func prenderAvisosPaciente(_ si: Bool) {
        Haptico.seleccion()
        paciente.avisosPrendidos = si
        if var p = perfil, p.lado == .paciente { p.avisos = si; perfil = p; p.guardar() }
    }

    /// Los datos del paciente en un JSON para descargar (lo pide la ley de datos personales).
    func exportarDatosPaciente() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("de-a-poco-mis-datos.json")
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? enc.encode(paciente) { try? d.write(to: url) }
        return url
    }
}
