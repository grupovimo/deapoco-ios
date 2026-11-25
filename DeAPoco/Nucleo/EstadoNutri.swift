import SwiftUI

/// Lo que calcula y hace el lado de la nutri, además de lo de `Estado`.
extension Estado {
    /// «Hoy atendés a seis.»
    var tituloHoy: String {
        let n = atiendeHoy.count
        if n == 0 { return "Hoy no tenés turnos." }
        if n == 1 { return "Hoy atendés a\u{00A0}una persona." }
        return "Hoy atendés a\u{00A0}\(Formato.enLetras(n))."
    }

    /// Los horarios en que atiende (los huecos posibles para dar un turno).
    static let horarios = ["09:00", "10:00", "11:30", "13:00", "15:00", "16:30", "18:00", "19:00"]

    /// Horarios libres de un día (sin turno o con un hueco marcado).
    func libres(en fecha: String) -> [String] {
        guard Fecha.diaSemana(fecha) <= 5 else { return [] }
        let ocupados = Set(turnos(en: fecha).filter { $0.pacienteId != nil }.map(\.hora))
        return Estado.horarios.filter { h in
            !ocupados.contains(h) && !(fecha == hoy && Fecha.minutos(h) <= Fecha.minutos(ahora))
        }
    }

    func turno(_ id: String) -> Turno? { nutri.turnos.first { $0.id == id } }

    /// El próximo turno de un paciente (de hoy en adelante).
    func proximoTurno(de pacienteId: String) -> Turno? {
        nutri.turnos.filter { $0.pacienteId == pacienteId && $0.estado != .cancelado && !yaPaso($0) }
            .min { ($0.fecha, $0.hora) < ($1.fecha, $1.hora) }
    }

    func cobro(_ id: String) -> Cobro? { nutri.cobros.first { $0.id == id } }
    func deuda(de pacienteId: String) -> [Cobro] { porCobrar.filter { $0.pacienteId == pacienteId } }

    /// «Vence mañana», «Desde el 18/11», «Primera consulta · hoy».
    func estadoCobro(_ c: Cobro) -> (texto: String, aviso: Bool) {
        if let v = c.vence {
            let d = Fecha.dias(entre: hoy, y: v)
            if d < 0 { return ("Venció el \(Fecha.corta(v))", true) }
            if d == 0 { return ("Vence hoy", true) }
            if d == 1 { return ("Vence mañana", true) }
        }
        if c.fecha == hoy { return ("\(c.concepto) · hoy", false) }
        return ("Desde el \(Fecha.corta(c.fecha))", false)
    }

    /// Las conversaciones, la más reciente primero.
    var conversaciones: [(paciente: Paciente, ultimo: Mensaje)] {
        nutri.chats.compactMap { id, msjs -> (Paciente, Mensaje)? in
            guard let p = paciente(id), let u = msjs.last else { return nil }
            return (p, u)
        }
        .sorted { ($0.1.fecha, $0.1.hora) > ($1.1.fecha, $1.1.hora) }
    }

    /// Los nombres de quienes tienen comidas para mirar («De Sofía, Ana y Carla»).
    var quienesPorRevisar: [String] {
        var vistos: [String] = []
        for r in porRevisar { if let n = paciente(r.pacienteId)?.primerNombre, !vistos.contains(n) { vistos.append(n) } }
        return vistos
    }

    /// «36 años · desde agosto · plan 3 meses».
    func resumenFicha(_ p: Paciente) -> String {
        let desde = p.desde == hoy ? "desde hoy" : "desde \(Fecha.meses[Fecha.mes(p.desde) - 1])"
        let plan = servicio(p.servicioId)?.nombre.lowercased() ?? "consulta"
        return "\(p.edad) años · \(desde) · \(plan)"
    }

    /// Diferencia de una medida desde la primera.
    func diferencia(_ tipo: TipoMedida, de pacienteId: String) -> Double? {
        let v = mediciones(de: pacienteId).compactMap { tipo.valor($0) }
        guard let a = v.first, let b = v.last, v.count > 1 else { return nil }
        return b - a
    }

    func etiquetasMeses(_ m: [Medicion]) -> [String] {
        var ultimo = 0
        return m.map { x in
            let mes = Fecha.mes(x.fecha)
            defer { ultimo = mes }
            return mes != ultimo ? Fecha.meses[mes - 1].prefix(3).uppercased() : ""
        }
    }

    func cambiarMostrarPeso(_ pacienteId: String, _ si: Bool) {
        guard var p = paciente(pacienteId) else { return }
        p.mostrarPeso = si
        guardarPaciente(p, aviso: si ? "\(p.primerNombre) va a ver su peso." : "\(p.primerNombre) ve sólo la curva de medidas.")
    }

    func agregarNota(_ pacienteId: String, _ texto: String) {
        guard var p = paciente(pacienteId), !texto.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        p.notas.insert(Nota(fecha: hoy, texto: texto), at: 0)
        guardarPaciente(p, aviso: "Nota guardada.")
    }

    func marcarAvisosLeidosNutri() {
        for i in nutri.avisos.indices { nutri.avisos[i].leido = true }
    }

    /// Mensaje a varios (por ritmo o a todos).
    func mensajeAVarios(_ ids: [String], _ texto: String) {
        for id in ids { nutri.chats[id, default: []].append(Mensaje(deNutri: true, fecha: hoy, hora: ahora, texto: texto)) }
        Haptico.exito()
        avisar(ids.count == 1 ? "Listo, le llegó a \(paciente(ids[0])?.primerNombre ?? "tu paciente")." : "Listo, les llegó a los \(ids.count).")
    }

    /// Un plan nuevo para un paciente: desde un modelo o copiando el último.
    func planNuevo(para pacienteId: String, modelo: String?) -> PlanAlimentario {
        let anterior = plan(de: pacienteId)
        let base = modelo.flatMap { m in nutri.planes.first { $0.id == m } } ?? anterior
        var p = base ?? PlanAlimentario(id: "", pacienteId: pacienteId, nombre: "", semana: 1, desde: hoy,
                                        comidas: Momento.principales.map { ComidaPlan(momento: $0, hora: String($0.horaSugerida.drop(while: { $0 == "0" }))) })
        let semana = (anterior?.semana ?? 0) + (modelo == nil && anterior != nil ? 0 : 1)
        if modelo != nil || anterior == nil {
            p.id = "plan-\(pacienteId)-\(UUID().uuidString.prefix(4))"
            p.semana = max(semana, 1)
            p.nombre = "Plan de la semana\u{00A0}\(p.semana)"
            p.enviado = false
            p.desde = Fecha.sumar(8 - Fecha.diaSemana(hoy), a: hoy)
        }
        p.pacienteId = pacienteId
        return p
    }
}
