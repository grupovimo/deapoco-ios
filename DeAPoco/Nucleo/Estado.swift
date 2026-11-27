import SwiftUI
import UIKit

/// Lo que la interfaz lee y las acciones que hace. Todo pasa en memoria al instante (con animación) y
/// después se avisa a `datos`; cuando haya API, `datos` es la que persiste.
@MainActor
@Observable
final class Estado {
    @ObservationIgnored let datos: Datos
    var nutri: PanelNutri
    var paciente: PanelPaciente
    /// Aviso corto que se muestra arriba (toast).
    var aviso: String?
    /// Lo que se respondió en el onboarding (nil: todavía no se hizo).
    var perfil: Perfil?
    var perfilNutri: PerfilNutri = DatosDeMuestra.perfilLaura
    var suscripcion: Suscripcion = DatosDeMuestra.suscripcion
    var tipsNutri: [Tip] = DatosDeMuestra.tipsNutri
    var tipsPaciente: [Tip] = DatosDeMuestra.tipsPaciente
    /// Pacientes que quedaron en pausa por el tope del plan (vuelven al subir de plan).
    var pausadosPorTope: Set<String> = []

    init(datos: Datos = DatosDeMuestra()) {
        self.datos = datos
        nutri = DatosDeMuestra.nutri
        paciente = DatosDeMuestra.paciente
        perfil = Perfil.guardado()
    }

    /// Trae lo último de `datos`. Secuencial a propósito: nunca `async let` (cerraba la app en Release).
    func cargar() async {
        // La maqueta ya arranca con todo en memoria: recargarla pisaría lo que se hizo al abrir.
        if datos is DatosDeMuestra { return }
        if let n = try? await datos.panelNutri() { nutri = n }
        if let p = try? await datos.panelPaciente() { paciente = p }
        if let p = try? await datos.perfilNutri() { perfilNutri = p }
        if let s = try? await datos.suscripcion() { suscripcion = s }
        if let t = try? await datos.tips(para: .nutri) { tipsNutri = t }
        if let t = try? await datos.tips(para: .paciente) { tipsPaciente = t }
    }

    // MARK: - Perfil, tips y avisos

    func guardarPerfil(_ p: Perfil) {
        perfil = p
        p.guardar()
        if p.lado == .paciente && !p.nombre.isEmpty {
            let apellido = paciente.nombre.split(separator: " ").dropFirst().joined(separator: " ")
            paciente.nombre = p.nombre.contains(" ") ? p.nombre : "\(p.nombre) \(apellido)"
            paciente.saludConectada = p.saludConectada
            paciente.avisosPrendidos = p.avisos
        }
        if p.lado == .nutri && !p.nombre.isEmpty {
            nutri.nombre = p.primerNombre
            nutri.nombreCompleto = p.nombre
            perfilNutri.nombre = p.nombre
            if !p.matricula.isEmpty { perfilNutri.matricula = p.matricula }
            if !p.especialidades.isEmpty { perfilNutri.especialidades = p.especialidades }
            perfilNutri.enLinea = p.modalidades.contains(.enLinea)
        }
        let datos = self.datos
        Task { try? await datos.guardarPerfil(p) }
    }

    func guardar(perfilNutri p: PerfilNutri, aviso: String? = "Perfil guardado.") {
        perfilNutri = p
        let datos = self.datos
        Task { try? await datos.guardarPerfilNutri(p) }
        if let aviso { Haptico.exito(); avisar(aviso) }
    }

    func borrarPerfil() {
        perfil = nil
        Perfil.borrar()
    }

    /// Un tip para mostrar: cambia con el día (y con `salto`, para que no se repita en la misma pantalla).
    func tip(_ lado: Lado, salto: Int = 0) -> Tip? {
        let lista = lado == .nutri ? tipsNutri : tipsPaciente
        guard !lista.isEmpty else { return nil }
        let dia = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return lista[(dia + salto) % lista.count]
    }

    func avisar(_ texto: String) {
        withAnimation(.spring(duration: 0.35)) { aviso = texto }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard let self, self.aviso == texto else { return }
            withAnimation(.easeOut(duration: 0.25)) { self.aviso = nil }
        }
    }

    /// Abre WhatsApp con un mensaje armado (si no está instalado, el link web).
    func whatsapp(_ telefono: String, _ texto: String) -> URL? {
        let numero = telefono.filter(\.isNumber)
        let t = texto.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(numero)?text=\(t)")
    }

    // MARK: - Nutri · derivados

    var hoy: String { nutri.hoy }
    var ahora: String { nutri.ahora }

    func paciente(_ id: String?) -> Paciente? { id.flatMap { i in nutri.pacientes.first { $0.id == i } } }
    var pacientesActivos: [Paciente] { nutri.pacientes.filter { $0.estado == .activo } }
    func pacientes(_ r: Ritmo) -> [Paciente] { pacientesActivos.filter { $0.ritmo == r } }
    func servicio(_ id: String) -> Servicio? { nutri.servicios.first { $0.id == id } }

    func turnos(en fecha: String) -> [Turno] {
        nutri.turnos.filter { $0.fecha == fecha && $0.estado != .cancelado }.sorted { $0.hora < $1.hora }
    }
    var turnosHoy: [Turno] { turnos(en: hoy) }
    /// Turnos con paciente (lo que se «atiende»).
    var atiendeHoy: [Turno] { turnosHoy.filter { $0.pacienteId != nil } }
    func yaPaso(_ t: Turno) -> Bool {
        t.fecha < hoy || (t.fecha == hoy && Fecha.minutos(t.hora) + t.duracion <= Fecha.minutos(ahora))
    }
    var atendidosHoy: Int { atiendeHoy.filter(yaPaso).count }
    /// El próximo turno de hoy (o el que está en curso).
    var proximoTurno: Turno? {
        atiendeHoy.first { Fecha.minutos($0.hora) + $0.duracion > Fecha.minutos(ahora) }
    }
    func minutosHasta(_ t: Turno) -> Int { Fecha.minutos(t.hora) - Fecha.minutos(ahora) }
    /// Los que todavía no confirmaron, de hoy en adelante.
    var sinConfirmar: [Turno] {
        nutri.turnos.filter { $0.estado == .sinConfirmar && !yaPaso($0) && $0.pacienteId != nil && Fecha.dias(entre: hoy, y: $0.fecha) <= 1 }
            .sorted { ($0.fecha, $0.hora) < ($1.fecha, $1.hora) }
    }

    var porRevisar: [Registro] {
        nutri.registros.filter { !$0.revisada }.sorted { ($0.fecha, $0.hora) > ($1.fecha, $1.hora) }
    }
    func registros(de pacienteId: String) -> [Registro] {
        nutri.registros.filter { $0.pacienteId == pacienteId }.sorted { ($0.fecha, $0.hora) > ($1.fecha, $1.hora) }
    }
    func mediciones(de pacienteId: String) -> [Medicion] {
        nutri.mediciones.filter { $0.pacienteId == pacienteId }.sorted { $0.fecha < $1.fecha }
    }
    func plan(de pacienteId: String) -> PlanAlimentario? {
        nutri.planes.filter { $0.pacienteId == pacienteId }.max { $0.semana < $1.semana }
    }
    var modelosDePlan: [PlanAlimentario] { nutri.planes.filter { $0.pacienteId == nil } }

    // Plata
    var porCobrar: [Cobro] { nutri.cobros.filter { !$0.pagado }.sorted { ($0.vence ?? "9", $0.fecha) < ($1.vence ?? "9", $1.fecha) } }
    var pagadosDelMes: [Cobro] {
        let mes = String(hoy.prefix(7))
        return nutri.cobros.filter { $0.pagado && ($0.pagadoEl ?? $0.fecha).hasPrefix(mes) }
    }
    var cobradoMes: Int { pagadosDelMes.reduce(0) { $0 + $1.monto } }
    var faltaCobrar: Int { porCobrar.reduce(0) { $0 + $1.monto } }
    var esperadoMes: Int { cobradoMes + faltaCobrar }
    var porcentajeCobrado: Int { esperadoMes == 0 ? 0 : Int((Double(cobradoMes) / Double(esperadoMes) * 100).rounded()) }
    func cobros(de pacienteId: String) -> [Cobro] {
        nutri.cobros.filter { $0.pacienteId == pacienteId }.sorted { $0.fecha > $1.fecha }
    }
    func pagosPorMedio(_ m: MedioPago) -> Int { pagadosDelMes.filter { $0.medio == m }.count }
    func alDia(_ pacienteId: String) -> Bool { !porCobrar.contains { $0.pacienteId == pacienteId } }

    // Mensajes
    func chat(_ pacienteId: String) -> [Mensaje] { nutri.chats[pacienteId] ?? [] }
    func noLeidos(_ pacienteId: String) -> Int { chat(pacienteId).filter { !$0.deNutri && !$0.leido }.count }
    var noLeidosNutri: Int { nutri.chats.keys.reduce(0) { $0 + noLeidos($1) } }
    var avisosSinLeerNutri: Int { nutri.avisos.filter { !$0.leido }.count }

    // MARK: - Nutri · acciones

    func confirmarTurno(_ id: String) {
        guard let i = nutri.turnos.firstIndex(where: { $0.id == id }) else { return }
        Haptico.exito()
        withAnimation(.snappy) { nutri.turnos[i].estado = .confirmado }
        avisar("Turno confirmado.")
    }

    func recordarTurnos(_ ids: [String]) {
        guard !ids.isEmpty else { avisar("Todos confirmaron. Bien ahí."); return }
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.recordarTurnos(ids: ids) }
        let nombres = ids.compactMap { id in nutri.turnos.first { $0.id == id }.flatMap { paciente($0.pacienteId)?.primerNombre } }
        avisar(nombres.count == 1 ? "Listo, le llegó el recordatorio a \(nombres[0])." : "Listo, les llegó el recordatorio a \(Formato.lista(nombres)).")
    }

    @discardableResult
    func darTurno(pacienteId: String, fecha: String, hora: String, modalidad: Modalidad, tipo: String = "Control") -> Turno {
        let t = Turno(id: "t-\(UUID().uuidString.prefix(6))", pacienteId: pacienteId, fecha: fecha, hora: hora, modalidad: modalidad,
                      tipo: tipo, estado: .sinConfirmar, monto: servicio("control")?.monto ?? 48_000)
        Haptico.exito()
        withAnimation(.snappy) {
            // Si había un hueco libre a esa hora, se ocupa.
            if let h = nutri.turnos.firstIndex(where: { $0.pacienteId == nil && $0.fecha == fecha && $0.hora == hora }) {
                nutri.turnos.remove(at: h)
            }
            nutri.turnos.append(t)
        }
        let datos = self.datos
        Task { try? await datos.darTurno(t) }
        let nombre = paciente(pacienteId)?.primerNombre ?? "tu paciente"
        avisar("Listo. A \(nombre) le llega por WhatsApp para confirmar.")
        return t
    }

    func cambiarTurno(_ id: String, fecha: String, hora: String) {
        guard let i = nutri.turnos.firstIndex(where: { $0.id == id }) else { return }
        Haptico.exito()
        withAnimation(.snappy) {
            nutri.turnos[i].fecha = fecha
            nutri.turnos[i].hora = hora
            nutri.turnos[i].estado = .sinConfirmar
        }
        let datos = self.datos
        Task { try? await datos.cambiarTurno(id: id, fecha: fecha, hora: hora) }
        avisar("Turno movido al \(Fecha.diaLargo(fecha)) \(Fecha.dia(fecha)) a las \(hora).")
    }

    func cancelarTurno(_ id: String, avisarPaciente: Bool = true) {
        guard let i = nutri.turnos.firstIndex(where: { $0.id == id }) else { return }
        Haptico.exito()
        let nombre = paciente(nutri.turnos[i].pacienteId)?.primerNombre
        withAnimation(.snappy) { nutri.turnos[i].estado = .cancelado }
        let datos = self.datos
        Task { try? await datos.cancelarTurno(id: id, avisar: avisarPaciente) }
        avisar(nombre.map { avisarPaciente ? "Cancelado. Le avisamos a \($0)." : "Turno cancelado." } ?? "Turno cancelado.")
    }

    /// Ofrece un hueco libre a la lista de espera: el primero que confirma, se lo queda.
    func ofrecerHueco(_ turnoId: String) {
        let ids = nutri.espera.map(\.pacienteId)
        guard !ids.isEmpty else { avisar("No hay nadie en lista de espera."); return }
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.ofrecerHueco(turnoId: turnoId, a: ids) }
        avisar("Se lo ofrecimos a los \(ids.count) de la lista. El primero que confirma, se lo queda.")
    }

    func revisar(_ registroId: String, respuesta: String?, bienAhi: Bool) {
        guard let i = nutri.registros.firstIndex(where: { $0.id == registroId }) else { return }
        if bienAhi { Haptico.exito() } else { Haptico.seleccion() }
        withAnimation(.snappy) {
            nutri.registros[i].revisada = true
            nutri.registros[i].bienAhi = bienAhi
            nutri.registros[i].respuesta = respuesta
        }
        let r = nutri.registros[i]
        if let respuesta, !respuesta.isEmpty {
            nutri.chats[r.pacienteId, default: []].append(Mensaje(deNutri: true, fecha: hoy, hora: ahora, texto: respuesta))
        }
        let datos = self.datos
        Task { try? await datos.revisarRegistro(id: registroId, respuesta: respuesta, bienAhi: bienAhi) }
    }

    func mandarBienAhi(_ pacienteId: String) {
        Haptico.exito()
        nutri.chats[pacienteId, default: []].append(Mensaje(deNutri: true, fecha: hoy, hora: ahora, texto: "¡Bien ahí! Seguí así, de a poco."))
        let datos = self.datos
        Task { try? await datos.mandarBienAhi(pacienteId: pacienteId) }
        avisar("Le mandaste un «bien ahí» a \(paciente(pacienteId)?.primerNombre ?? "tu paciente").")
    }

    func registrarPago(_ cobroId: String, medio: MedioPago) {
        guard let i = nutri.cobros.firstIndex(where: { $0.id == cobroId }) else { return }
        Haptico.exito()
        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            nutri.cobros[i].pagado = true
            nutri.cobros[i].medio = medio
            nutri.cobros[i].pagadoEl = hoy
            nutri.mediosDelMes[medio, default: 0] += 1
            if let t = nutri.turnos.firstIndex(where: { $0.pacienteId == nutri.cobros[i].pacienteId && $0.fecha == hoy }) {
                nutri.turnos[t].pagado = true
            }
        }
        let datos = self.datos
        Task { try? await datos.registrarPago(cobroId: cobroId, medio: medio) }
        let c = nutri.cobros[i]
        avisar("Listo, \(Formato.plata(c.monto)) de \(paciente(c.pacienteId)?.primerNombre ?? "tu paciente").")
    }

    @discardableResult
    func crearCobro(pacienteId: String, concepto: String, monto: Int) -> Cobro {
        let c = Cobro(id: "co-\(UUID().uuidString.prefix(6))", pacienteId: pacienteId, concepto: concepto, monto: monto, fecha: hoy,
                      vence: Fecha.sumar(7, a: hoy))
        withAnimation(.snappy) { nutri.cobros.append(c) }
        let datos = self.datos
        Task { try? await datos.crearCobro(c) }
        return c
    }

    func recordarCobros(_ ids: [String]) {
        guard !ids.isEmpty else { avisar("Nadie te debe este mes."); return }
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.recordarCobros(ids: ids) }
        if ids.count == 1, let c = nutri.cobros.first(where: { $0.id == ids[0] }), let p = paciente(c.pacienteId) {
            avisar("Listo, le llegó el link de pago a \(p.primerNombre).")
        } else {
            avisar("Listo, les llegó el recordatorio a los \(ids.count).")
        }
    }

    func guardarPlan(_ plan: PlanAlimentario) {
        var p = plan
        p.guardado = ahora
        if let i = nutri.planes.firstIndex(where: { $0.id == p.id }) { nutri.planes[i] = p } else { nutri.planes.append(p) }
        let datos = self.datos
        Task { try? await datos.guardarPlan(p) }
    }

    func enviarPlan(_ id: String) {
        guard let i = nutri.planes.firstIndex(where: { $0.id == id }) else { return }
        Haptico.exito()
        withAnimation(.snappy) { nutri.planes[i].enviado = true }
        let datos = self.datos
        Task { try? await datos.enviarPlan(id: id) }
        let nombre = paciente(nutri.planes[i].pacienteId)?.primerNombre ?? "tu paciente"
        avisar("Listo, a \(nombre) le llegó el plan.")
    }

    func anotarMedicion(_ m: Medicion) {
        Haptico.exito()
        withAnimation(.snappy) {
            nutri.mediciones.removeAll { $0.pacienteId == m.pacienteId && $0.fecha == m.fecha }
            nutri.mediciones.append(m)
        }
        let datos = self.datos
        Task { try? await datos.anotarMedicion(m) }
        avisar("Medidas anotadas.")
    }

    func guardarPaciente(_ p: Paciente, aviso: String? = "Guardado.") {
        if let i = nutri.pacientes.firstIndex(where: { $0.id == p.id }) {
            withAnimation(.snappy) { nutri.pacientes[i] = p }
        }
        let datos = self.datos
        Task { try? await datos.guardarPaciente(p) }
        if let aviso { Haptico.exito(); avisar(aviso) }
    }

    /// Alta de un paciente. Devuelve nil si el plan no alcanza (hay que mostrar el tope).
    @discardableResult
    func crearPaciente(nombre: String, telefono: String, servicioId: String, objetivo: String) -> String? {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty, puedeSumarPaciente else { return nil }
        let id = "nuevo-\(UUID().uuidString.prefix(6))"
        let p = Paciente(id: id, nombre: limpio, tono: [.mandarina, .az, .lo][nutri.pacientes.count % 3], edad: 30,
                         telefono: telefono, desde: hoy, servicioId: servicioId, objetivo: objetivo,
                         diasSemana: 0, racha: 0, sinAnotar: 0)
        Haptico.exito()
        withAnimation(.snappy) { nutri.pacientes.insert(p, at: 0) }
        let datos = self.datos
        Task { try? await datos.crearPaciente(p) }
        UIPasteboard.general.string = "https://deapoco.com.ar/\(perfilNutri.slug)/\(p.primerNombre.lowercased().folding(options: .diacriticInsensitive, locale: nil))"
        empezarPruebaSiCorresponde()
        avisar("\(p.primerNombre) ya está. Copiamos su invitación para mandársela.")
        return id
    }

    func enviarMensajeNutri(_ pacienteId: String, texto: String? = nil, foto: String? = nil) {
        let m = Mensaje(deNutri: true, fecha: hoy, hora: ahora, texto: texto, foto: foto)
        Haptico.suave()
        withAnimation(.snappy) { nutri.chats[pacienteId, default: []].append(m) }
        let datos = self.datos
        Task { try? await datos.enviarMensaje(pacienteId: pacienteId, m) }
    }

    func marcarLeidos(_ pacienteId: String) {
        guard var c = nutri.chats[pacienteId], c.contains(where: { !$0.leido }) else { return }
        for i in c.indices { c[i].leido = true }
        nutri.chats[pacienteId] = c
        let datos = self.datos
        Task { try? await datos.marcarLeidos(pacienteId: pacienteId) }
    }

    func conectar(_ integracionId: String, _ conectada: Bool) {
        guard let i = nutri.integraciones.firstIndex(where: { $0.id == integracionId }) else { return }
        Haptico.exito()
        withAnimation(.snappy) { nutri.integraciones[i].conectada = conectada }
        let datos = self.datos
        Task { try? await datos.conectar(integracion: integracionId, conectada) }
        avisar(conectada ? "\(nutri.integraciones[i].nombre) conectado." : "\(nutri.integraciones[i].nombre) desconectado.")
    }

    func guardarServicios(_ s: [Servicio]) {
        nutri.servicios = s
        let datos = self.datos
        Task { try? await datos.guardarServicios(s) }
        Haptico.exito()
        avisar("Precios guardados.")
    }

    // MARK: - Paciente · derivados

    /// Lo que toca hoy: por cada comida principal, lo anotado o lo del plan.
    var registrosHoy: [Registro] { paciente.registros.filter { $0.fecha == paciente.hoy } }
    func registroHoy(_ m: Momento) -> Registro? { registrosHoy.first { $0.momento == m } }
    var comidasHechasHoy: Int { Momento.principales.filter { registroHoy($0) != nil }.count }
    /// La primera comida que falta anotar.
    var proximaComida: Momento? { Momento.principales.first { registroHoy($0) == nil } }
    func planDe(_ m: Momento) -> ComidaPlan? { paciente.plan.comidas.first { $0.momento == m } }
    func resumenPlan(_ m: Momento) -> String {
        guard let c = planDe(m) else { return "Lo que tengas a mano" }
        if let o = c.opciones.first { return o.nombre }
        let nombres = c.items.enumerated().map { i, it in i == 0 ? it.nombre : it.nombre.prefix(1).lowercased() + it.nombre.dropFirst() }
        return nombres.joined(separator: " y ")
    }
    /// Comidas anotadas en un día (0 a 4).
    func comidasAnotadas(_ fecha: String) -> Int {
        Set(paciente.registros.filter { $0.fecha == fecha && Momento.principales.contains($0.momento) }.map(\.momento)).count
    }
    var logrosConseguidos: [Logro] { paciente.logros.filter(\.conseguido) }
    var noLeidosPaciente: Int { paciente.mensajes.filter { $0.deNutri && !$0.leido }.count }
    var avisosSinLeerPaciente: Int { paciente.avisos.filter { !$0.leido }.count }
    func medidas(_ tipo: TipoMedida) -> [Double] { paciente.mediciones.compactMap { tipo.valor($0) } }

    // MARK: - Paciente · acciones

    /// Anota una comida (con la foto que sacó o eligió). Suma al plato del día y, si completa el día, a la racha.
    func registrarComida(momento: Momento, foto: Data?, sensacion: Sensacion?, nota: String, descripcion: String? = nil) {
        let archivo = foto.map(Archivos.guardar)
        let r = Registro(pacienteId: paciente.id, momento: momento, fecha: paciente.hoy, hora: paciente.ahora, foto: archivo,
                         descripcion: descripcion ?? resumenPlan(momento), nota: nota, sensacion: sensacion)
        Haptico.exito()
        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            let hoy = paciente.hoy
            paciente.registros.removeAll { $0.fecha == hoy && $0.momento == momento }
            paciente.registros.append(r)
        }
        if archivo != nil {
            paciente.mensajes.append(Mensaje(deNutri: false, fecha: paciente.hoy, hora: paciente.ahora, foto: archivo, pieFoto: momento.titulo))
        }
        let datos = self.datos
        Task { try? await datos.registrarComida(r, foto: foto) }
        avisar("Listo. Le llegó a \(paciente.nutri.nombre).")
    }

    func tomarAgua(_ delta: Int = 1) {
        let nuevo = min(max(paciente.agua + delta, 0), paciente.aguaMeta + 4)
        guard nuevo != paciente.agua else { return }
        if nuevo == paciente.aguaMeta { Haptico.exito() } else { Haptico.seleccion() }
        withAnimation(.snappy(duration: 0.25)) { paciente.agua = nuevo }
        let datos = self.datos
        Task { try? await datos.anotarAgua(vasos: nuevo) }
        if nuevo == paciente.aguaMeta && delta > 0 { avisar("¡Ocho vasos! Bien ahí.") }
    }

    func enviarMensajePaciente(texto: String? = nil, foto: Data? = nil, audio: Int? = nil) {
        let m = Mensaje(deNutri: false, fecha: paciente.hoy, hora: paciente.ahora, texto: texto, foto: foto.map(Archivos.guardar), audio: audio)
        Haptico.suave()
        withAnimation(.snappy) { paciente.mensajes.append(m) }
        let datos = self.datos
        Task { try? await datos.enviarMensaje(pacienteId: paciente.id, m) }
    }

    func leerMensajesPaciente() {
        guard paciente.mensajes.contains(where: { $0.deNutri && !$0.leido }) else { return }
        for i in paciente.mensajes.indices { paciente.mensajes[i].leido = true }
        let datos = self.datos
        let id = paciente.id
        Task { try? await datos.marcarLeidos(pacienteId: id) }
    }

    func confirmarTurnoPaciente() {
        guard paciente.turno != nil else { return }
        Haptico.exito()
        withAnimation(.snappy) { paciente.turno?.estado = .confirmado }
        let datos = self.datos
        let id = paciente.turno?.id ?? ""
        Task { try? await datos.confirmarTurno(id: id) }
        avisar("Confirmado. \(paciente.nutri.nombre) te espera.")
    }

    func cambiarTurnoPaciente(fecha: String, hora: String) {
        guard paciente.turno != nil else { return }
        Haptico.exito()
        withAnimation(.snappy) {
            paciente.turno?.fecha = fecha
            paciente.turno?.hora = hora
            paciente.turno?.estado = .confirmado
        }
        let datos = self.datos
        let id = paciente.turno?.id ?? ""
        Task { try? await datos.cambiarTurno(id: id, fecha: fecha, hora: hora) }
        avisar("Listo, quedó el \(Fecha.diaLargo(fecha)) \(Fecha.dia(fecha)) a las \(hora).")
    }

    func cancelarTurnoPaciente() {
        guard let t = paciente.turno else { return }
        Haptico.exito()
        withAnimation(.snappy) { paciente.turno = nil }
        let datos = self.datos
        Task { try? await datos.cancelarTurno(id: t.id, avisar: true) }
        avisar("Cancelado. Le avisamos a \(paciente.nutri.nombre).")
    }

    /// Sacar un turno nuevo (el paciente elige día y hora de los libres).
    func sacarTurnoPaciente(fecha: String, hora: String, modalidad: Modalidad) {
        Haptico.exito()
        withAnimation(.snappy) {
            paciente.turno = Turno(id: "tp-\(UUID().uuidString.prefix(6))", pacienteId: paciente.id, fecha: fecha, hora: hora,
                                   duracion: 30, modalidad: modalidad, estado: .confirmado)
        }
        avisar("Listo, turno el \(Fecha.diaLargo(fecha)) \(Fecha.dia(fecha)) a las \(hora).")
    }

    /// Paga una consulta o el plan: «Hoy pagás» la primera cuota; el resto se cobra solo cada mes.
    func pagar(servicioId: String, medio: MedioPago = .mercadoPago) {
        guard let s = paciente.servicios.first(where: { $0.id == servicioId }) else { return }
        Haptico.exito()
        withAnimation(.snappy) {
            paciente.pagos.insert(Cobro(pacienteId: paciente.id, concepto: s.meses > 0 ? "\(s.nombre) · cuota 1" : s.nombre,
                                        monto: s.precioMes, fecha: paciente.hoy, pagado: true, medio: medio, pagadoEl: paciente.hoy), at: 0)
            if s.meses > 0 { paciente.contratado = s.id }
        }
        let datos = self.datos
        Task { try? await datos.pagar(servicioId: servicioId, medio: medio) }
        let cuando = paciente.turno.map { " Nos vemos el \(Fecha.diaLargo($0.fecha))." } ?? ""
        avisar("Listo, pagaste la consulta.\(cuando)")
    }

    func conectarSalud(_ si: Bool) {
        Haptico.exito()
        withAnimation(.snappy) { paciente.saludConectada = si }
        let datos = self.datos
        Task { try? await datos.conectarSalud(si) }
        avisar(si ? "Apple Salud conectada. Sólo la ve \(paciente.nutri.nombre)." : "Apple Salud desconectada.")
    }
}
