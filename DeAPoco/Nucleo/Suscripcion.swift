import SwiftUI

/// Los planes de De a Poco para la nutri. El paciente nunca paga la app.
enum PlanDAP: String, Codable, CaseIterable, Hashable {
    case gratis, profesional, consultorio

    var nombre: String {
        switch self { case .gratis: return "Gratis"; case .profesional: return "Profesional"; case .consultorio: return "Consultorio" }
    }
    /// Por mes, con IVA.
    var precioMes: Int {
        switch self { case .gratis: return 0; case .profesional: return 14_900; case .consultorio: return 29_900 }
    }
    /// Anual = 10 meses.
    var precioAnual: Int { precioMes * 10 }
    /// Pacientes activos que entran.
    var tope: Int {
        switch self { case .gratis: return 10; case .profesional: return 80; case .consultorio: return 300 }
    }
    var bajada: String {
        switch self {
        case .gratis: return "Para empezar"
        case .profesional: return "Para la nutri que vive de esto"
        case .consultorio: return "Para un equipo que comparte pacientes"
        }
    }
    var incluye: [String] {
        switch self {
        case .gratis: return ["Hasta 10 pacientes activos", "Agenda, planes, fotos y mensajes", "Tu página con «hecha con De a Poco»"]
        case .profesional: return ["Hasta 80 pacientes activos", "Cobros con Mercado Pago y recordatorios", "Tu página sin la marca"]
        case .consultorio: return ["Hasta 300 pacientes y 4 profesionales", "Agenda compartida y derivaciones", "Lo nuevo, apenas sale"]
        }
    }
    func precio(_ p: PeriodoPlan) -> Int { p == .mensual ? precioMes : precioAnual }
}

enum PeriodoPlan: String, Codable, CaseIterable, Hashable {
    case mensual, anual
    var titulo: String { self == .mensual ? "Mensual" : "Anual" }
    var unidad: String { self == .mensual ? "/mes" : "/año" }
}

struct FacturaDAP: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var numero: String
    var fecha: String
    var concepto: String
    var monto: Int
}

struct Suscripcion: Codable, Hashable {
    var plan: PlanDAP
    var periodo: PeriodoPlan = .mensual
    /// Prueba de Profesional: 14 días, sin tarjeta, arranca con el 3.er paciente.
    var pruebaHasta: String?
    var pruebaUsada = false
    var proximoCobro: String?
    /// Plan elegido para cuando termine la prueba.
    var planElegido: PlanDAP?
    var renueva = true
    /// Precio de lanzamiento fijo por 6 meses.
    var precioFijoHasta: String
    var facturas: [FacturaDAP] = []
    var cuenta = "laura.ferreyra@gmail.com"
}

extension Estado {
    var activos: Int { nutri.pacientes.filter { $0.estado == .activo }.count }

    var enPrueba: Bool { (suscripcion.pruebaHasta ?? "") >= hoy && suscripcion.pruebaHasta != nil }
    var diasDePrueba: Int { suscripcion.pruebaHasta.map { max(0, Fecha.dias(entre: hoy, y: $0)) } ?? 0 }
    /// El plan que rige hoy: Profesional mientras dura la prueba.
    var planActual: PlanDAP { enPrueba ? .profesional : suscripcion.plan }
    var tope: Int { planActual.tope }
    var puedeSumarPaciente: Bool { activos < tope }
    /// El plan que alcanza para los pacientes activos.
    var planQueAlcanza: PlanDAP { PlanDAP.allCases.first { $0.tope >= activos } ?? .consultorio }
    /// Cuándo sería el primer cobro si elige hoy: al terminar la prueba o ahora.
    var primerCobro: String { enPrueba ? (suscripcion.pruebaHasta ?? hoy) : hoy }

    func comprar(_ p: PlanDAP, _ periodo: PeriodoPlan) {
        let monto = p.precio(periodo)
        let cobraHoy = !enPrueba && monto > 0
        let fin = enPrueba ? (suscripcion.pruebaHasta ?? hoy) : hoy
        let siguiente = periodo == .mensual ? Fecha.sumarMeses(1, a: fin) : Fecha.sumarMeses(12, a: fin)
        let estabaEnPrueba = enPrueba
        withAnimation(.snappy) {
            suscripcion.periodo = periodo
            suscripcion.renueva = true
            if estabaEnPrueba {
                suscripcion.planElegido = p
                suscripcion.proximoCobro = p == .gratis ? nil : fin
            } else {
                suscripcion.plan = p
                suscripcion.planElegido = nil
                suscripcion.proximoCobro = p == .gratis ? nil : siguiente
            }
            if cobraHoy {
                let n = String(format: "0001-%08d", 214 + suscripcion.facturas.count)
                suscripcion.facturas.insert(FacturaDAP(numero: n, fecha: hoy, concepto: "De a Poco \(p.nombre) · \(periodo.titulo.lowercased())", monto: monto), at: 0)
            }
        }
        reactivarHasta(p.tope)
        let datos = self.datos
        Task { try? await datos.comprarPlan(p, periodo: periodo) }
        Haptico.exito()
        avisar(estabaEnPrueba ? "Listo: \(p.nombre) arranca el \(Fecha.corta(fin)), cuando termina la prueba." : "¡Bienvenida a \(p.nombre)!")
    }

    func cancelarSuscripcion() {
        withAnimation(.snappy) { suscripcion.renueva = false }
        let datos = self.datos
        Task { try? await datos.cancelarSuscripcion() }
        Haptico.exito()
        let hasta = suscripcion.proximoCobro.map { " hasta el \(Fecha.corta($0))" } ?? ""
        avisar("Cancelada. Seguís con \(suscripcion.plan.nombre)\(hasta) y después pasás a Gratis.")
    }

    func restaurarCompras() {
        let datos = self.datos
        Task { try? await datos.restaurarCompras() }
        Haptico.exito()
        avisar(suscripcion.facturas.isEmpty && suscripcion.planElegido == nil ? "No encontramos compras en esta cuenta." : "Compras restauradas: \(suscripcion.plan.nombre).")
    }

    /// Fin de la prueba sin plan elegido: pasa a Gratis y los pacientes que sobran quedan en pausa (no se borran).
    func vencerPrueba() {
        withAnimation(.snappy) {
            suscripcion.pruebaHasta = Fecha.sumar(-1, a: hoy)
            if let p = suscripcion.planElegido { suscripcion.plan = p; suscripcion.planElegido = nil } else { suscripcion.plan = .gratis }
        }
        pausarExcedente()
    }

    /// Deja activos sólo hasta el tope: pausa a los más nuevos.
    func pausarExcedente() {
        let ids = nutri.pacientes.filter { $0.estado == .activo }.sorted { $0.desde < $1.desde }.map(\.id)
        guard ids.count > tope else { return }
        for id in ids.suffix(ids.count - tope) {
            if let i = nutri.pacientes.firstIndex(where: { $0.id == id }) {
                nutri.pacientes[i].estado = .pausado
                pausadosPorTope.insert(id)
            }
        }
    }

    /// Al subir de plan, vuelven los que habían quedado en pausa por el tope.
    private func reactivarHasta(_ nuevoTope: Int) {
        var libres = nuevoTope - activos
        for id in pausadosPorTope.sorted() where libres > 0 {
            if let i = nutri.pacientes.firstIndex(where: { $0.id == id }) {
                nutri.pacientes[i].estado = .activo
                pausadosPorTope.remove(id)
                libres -= 1
            }
        }
    }

    /// La prueba arranca sola cuando se suma el tercer paciente.
    func empezarPruebaSiCorresponde() {
        guard !suscripcion.pruebaUsada, activos >= 3 else { return }
        suscripcion.pruebaUsada = true
        suscripcion.pruebaHasta = Fecha.sumar(14, a: hoy)
        avisar("¡Tenés 14 días de Profesional gratis! Sin tarjeta.")
    }
}
