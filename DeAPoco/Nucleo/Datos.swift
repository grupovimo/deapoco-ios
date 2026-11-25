import Foundation

/// De dónde salen los datos. Hoy, `DatosDeMuestra` (la maqueta, en memoria). Para conectar la API real se
/// escribe otra implementación (p. ej. `DatosApi`) y se la pasa a `Estado(datos:)`: las pantallas no cambian.
protocol Datos: Sendable {
    // MARK: Lectura
    func panelNutri() async throws -> PanelNutri
    func panelPaciente() async throws -> PanelPaciente
    func perfilNutri() async throws -> PerfilNutri
    func suscripcion() async throws -> Suscripcion
    func tips(para lado: Lado) async throws -> [Tip]

    // MARK: Perfil (lo del onboarding)
    func guardarPerfil(_ perfil: Perfil) async throws
    func guardarPerfilNutri(_ perfil: PerfilNutri) async throws

    // MARK: Nutri · agenda
    func darTurno(_ turno: Turno) async throws
    func cambiarTurno(id: String, fecha: String, hora: String) async throws
    func cancelarTurno(id: String, avisar: Bool) async throws
    func recordarTurnos(ids: [String]) async throws
    func ofrecerHueco(turnoId: String, a pacienteIds: [String]) async throws

    // MARK: Nutri · pacientes
    func crearPaciente(_ paciente: Paciente) async throws
    func guardarPaciente(_ paciente: Paciente) async throws
    func anotarMedicion(_ medicion: Medicion) async throws
    func revisarRegistro(id: String, respuesta: String?, bienAhi: Bool) async throws
    func mandarBienAhi(pacienteId: String) async throws
    func guardarPlan(_ plan: PlanAlimentario) async throws
    func enviarPlan(id: String) async throws

    // MARK: Nutri · plata
    func registrarPago(cobroId: String, medio: MedioPago) async throws
    func crearCobro(_ cobro: Cobro) async throws
    func recordarCobros(ids: [String]) async throws
    func guardarServicios(_ servicios: [Servicio]) async throws
    func conectar(integracion id: String, _ conectada: Bool) async throws

    // MARK: Nutri · suscripción a De a Poco (por App Store)
    func comprarPlan(_ plan: PlanDAP, periodo: PeriodoPlan) async throws
    func cancelarSuscripcion() async throws
    func restaurarCompras() async throws

    // MARK: Mensajes (los dos lados)
    func enviarMensaje(pacienteId: String, _ mensaje: Mensaje) async throws
    func marcarLeidos(pacienteId: String) async throws

    // MARK: Paciente
    func registrarComida(_ registro: Registro, foto: Data?) async throws
    func anotarAgua(vasos: Int) async throws
    func usarComodin() async throws
    func confirmarTurno(id: String) async throws
    func pagar(servicioId: String, medio: MedioPago) async throws
    func conectarSalud(_ conectada: Bool) async throws
}

/// La maqueta: todo lo del diseño (pantallas/app.html), exacto, y las escrituras no hacen nada.
struct DatosDeMuestra: Datos {
    func panelNutri() async throws -> PanelNutri { Self.nutri }
    func panelPaciente() async throws -> PanelPaciente { Self.paciente }
    func perfilNutri() async throws -> PerfilNutri { Self.perfilLaura }
    func suscripcion() async throws -> Suscripcion { Self.suscripcion }
    func tips(para lado: Lado) async throws -> [Tip] { lado == .nutri ? Self.tipsNutri : Self.tipsPaciente }
    func guardarPerfil(_ perfil: Perfil) async throws {}
    func guardarPerfilNutri(_ perfil: PerfilNutri) async throws {}
    func darTurno(_ turno: Turno) async throws {}
    func cambiarTurno(id: String, fecha: String, hora: String) async throws {}
    func cancelarTurno(id: String, avisar: Bool) async throws {}
    func recordarTurnos(ids: [String]) async throws {}
    func ofrecerHueco(turnoId: String, a pacienteIds: [String]) async throws {}
    func crearPaciente(_ paciente: Paciente) async throws {}
    func guardarPaciente(_ paciente: Paciente) async throws {}
    func anotarMedicion(_ medicion: Medicion) async throws {}
    func revisarRegistro(id: String, respuesta: String?, bienAhi: Bool) async throws {}
    func mandarBienAhi(pacienteId: String) async throws {}
    func guardarPlan(_ plan: PlanAlimentario) async throws {}
    func enviarPlan(id: String) async throws {}
    func registrarPago(cobroId: String, medio: MedioPago) async throws {}
    func crearCobro(_ cobro: Cobro) async throws {}
    func recordarCobros(ids: [String]) async throws {}
    func guardarServicios(_ servicios: [Servicio]) async throws {}
    func conectar(integracion id: String, _ conectada: Bool) async throws {}
    func comprarPlan(_ plan: PlanDAP, periodo: PeriodoPlan) async throws {}
    func cancelarSuscripcion() async throws {}
    func restaurarCompras() async throws {}
    func enviarMensaje(pacienteId: String, _ mensaje: Mensaje) async throws {}
    func marcarLeidos(pacienteId: String) async throws {}
    func registrarComida(_ registro: Registro, foto: Data?) async throws {}
    func anotarAgua(vasos: Int) async throws {}
    func usarComodin() async throws {}
    func confirmarTurno(id: String) async throws {}
    func pagar(servicioId: String, medio: MedioPago) async throws {}
    func conectarSalud(_ conectada: Bool) async throws {}
}
