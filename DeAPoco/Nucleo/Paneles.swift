import Foundation

/// Todo lo que ve la nutri. Lo trae `Datos.panelNutri()`.
struct PanelNutri: Codable, Hashable {
    /// «Laura»: el nombre con el que la saludan.
    var nombre: String
    var nombreCompleto: String
    var foto: String?
    /// Hoy y la hora de ahora (en la maqueta, fijos: martes 25/11, 11:12).
    var hoy: String
    var ahora: String
    var pacientes: [Paciente]
    var turnos: [Turno]
    var espera: [Espera]
    var registros: [Registro]
    var planes: [PlanAlimentario]
    var mediciones: [Medicion]
    var cobros: [Cobro]
    var servicios: [Servicio]
    /// Las conversaciones, por paciente.
    var chats: [String: [Mensaje]]
    var avisos: [AvisoApp]
    var integraciones: [Integracion]
    /// Cuántos pagos entraron este mes por cada medio (para la dona).
    var mediosDelMes: [MedioPago: Int]
    /// Cobrado en meses anteriores, para «Tu mes» (miles de pesos, de junio a noviembre).
    var historico: [Int]
}

/// La nutri, vista desde el paciente.
struct NutriDelPaciente: Codable, Hashable {
    var nombre: String
    var nombreCompleto: String
    var titulo: String
    var matricula: String
    var foto: String?
    var responde: String
    var telefono: String
    var lugar: String
}

/// Un «¡Bien ahí!» de la nutri.
struct BienAhi: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var fecha: String
    var por: String
}

/// Una tarjeta de logro de «Tu avance» (durazno, con su platito).
struct Destacado: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var titulo: String
    var bajada: String
    var partes: Int
    var llenas: Int
    /// Durazno lleno (el más importante) o durazno-100.
    var fuerte = false
}

/// Todo lo que ve el paciente. Lo trae `Datos.panelPaciente()`.
struct PanelPaciente: Codable, Hashable {
    var id: String
    var nombre: String
    var foto: String?
    var nutri: NutriDelPaciente
    var hoy: String
    var ahora: String
    /// Desde cuándo se atiende (ISO).
    var desde: String
    /// Todas las comidas anotadas (las de hoy incluidas).
    var registros: [Registro]
    var plan: PlanAlimentario
    var agua: Int
    var aguaMeta: Int
    var meta: String
    var metaHechas: Int
    var metaTotal: Int
    var racha: Int
    var mejorRacha: Int
    /// Comodines que le quedan este mes (un día sin anotar no corta la racha).
    var comodines: Int
    var comodinUsado: String?
    /// Los últimos 14 días, del más viejo a hoy.
    var dias14: [DiaRacha]
    /// Días anotados por semana, desde que empezó (cada plato, una semana).
    var semanas: [Int]
    var nivel: Int
    /// Semanas que faltan para el próximo nivel.
    var faltanNivel: Int
    var logros: [Logro]
    var destacados: [Destacado]
    var mediciones: [Medicion]
    var mostrarPeso: Bool
    var saludConectada: Bool
    var pasos: Int
    /// Minutos de sueño por noche (promedio).
    var sueno: Int
    var turno: Turno?
    var servicios: [Servicio]
    /// El servicio contratado (un `Servicio.id`), si tiene un plan.
    var contratado: String?
    var pagos: [Cobro]
    var mensajes: [Mensaje]
    var avisos: [AvisoApp]
    var bienAhi: [BienAhi]
    var avisosPrendidos: Bool
}
