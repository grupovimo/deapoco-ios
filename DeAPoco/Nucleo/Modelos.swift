import Foundation

// Los modelos de De a Poco. Todo es Codable para que una API real los pueda mandar tal cual.

/// Los dos lados de la app.
enum Lado: String, Codable, CaseIterable, Hashable {
    case nutri, paciente
}

/// Las comidas del día.
enum Momento: String, Codable, CaseIterable, Hashable, Identifiable {
    case desayuno, almuerzo, merienda, cena, colacion
    var id: String { rawValue }
    var titulo: String {
        switch self {
        case .desayuno: return "Desayuno"
        case .almuerzo: return "Almuerzo"
        case .merienda: return "Merienda"
        case .cena: return "Cena"
        case .colacion: return "Colación"
        }
    }
    var horaSugerida: String {
        switch self {
        case .desayuno: return "08:00"
        case .almuerzo: return "13:00"
        case .merienda: return "17:00"
        case .cena: return "21:00"
        case .colacion: return "11:00"
        }
    }
    /// Las cuatro del plato del día.
    static let principales: [Momento] = [.desayuno, .almuerzo, .merienda, .cena]
}

/// «¿Cómo llegaste a la comida?»: el plato vacío, a medias o lleno. Nunca un juicio.
enum Sensacion: String, Codable, CaseIterable, Hashable {
    case hambre, bien, lleno
    var titulo: String {
        switch self { case .hambre: return "Con hambre"; case .bien: return "Bien"; case .lleno: return "Lleno" }
    }
    var llenas: Int {
        switch self { case .hambre: return 0; case .bien: return 2; case .lleno: return 4 }
    }
}

enum Modalidad: String, Codable, CaseIterable, Hashable {
    case consultorio, enLinea
    var titulo: String { self == .consultorio ? "Consultorio" : "En línea" }
    var icono: Icono { self == .consultorio ? .lugar : .video }
}

enum MedioPago: String, Codable, CaseIterable, Hashable {
    case mercadoPago = "Mercado Pago", transferencia = "Transferencia", efectivo = "Efectivo"
}

/// Cómo viene un paciente esta semana. Se calcula de lo que anota, nunca del peso.
enum Ritmo: String, Codable, CaseIterable, Hashable {
    case bien, medias, aflojo
    var titulo: String {
        switch self { case .bien: return "vienen bien"; case .medias: return "a medias"; case .aflojo: return "aflojaron" }
    }
}

enum EstadoPaciente: String, Codable, CaseIterable, Hashable {
    case activo, pausado, alta
    var titulo: String {
        switch self { case .activo: return "Activo"; case .pausado: return "En pausa"; case .alta: return "De alta" }
    }
}

enum Sexo: String, Codable, CaseIterable, Hashable {
    case mujer, hombre, sinDecir
    var titulo: String {
        switch self { case .mujer: return "Mujer"; case .hombre: return "Hombre"; case .sinDecir: return "Prefiero no decir" }
    }
}

struct Nota: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var fecha: String
    var texto: String
}

struct Paciente: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var foto: String?
    var tono: TonoAvatar = .durazno
    var edad: Int
    var sexo: Sexo = .mujer
    var telefono: String
    var email: String = ""
    /// Desde cuándo se atiende (ISO).
    var desde: String
    /// El servicio que tiene contratado (un `Servicio.id`).
    var servicioId: String
    var objetivo: String
    var comoCome: String = ""
    var restricciones: [String] = []
    var notas: [Nota] = []
    /// Días que anotó esta semana (0 a 7).
    var diasSemana: Int
    /// Días seguidos anotando.
    var racha: Int
    /// Días desde la última comida anotada.
    var sinAnotar: Int
    var meta: String = ""
    var metaHechas: Int = 0
    var metaTotal: Int = 5
    /// La nutri decide si el paciente ve su peso (por defecto, no: ve la curva de medidas).
    var mostrarPeso = false
    var saludConectada = false
    var pasos: Int?
    var estado: EstadoPaciente = .activo
    /// Logro reciente que la nutri puede festejar («Cumplió su meta»).
    var novedad: String?

    var primerNombre: String { String(nombre.split(separator: " ").first ?? "") }
    var iniciales: String {
        nombre.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
    var ritmo: Ritmo {
        if sinAnotar >= 5 || diasSemana <= 2 { return .aflojo }
        if diasSemana <= 4 { return .medias }
        return .bien
    }
    /// «12 días seguidos», «Hace 10 días», «Anotó 2 días de 7».
    var resumenRitmo: String {
        if let novedad { return novedad }
        if sinAnotar >= 5 { return "Hace \(sinAnotar) días" }
        if racha >= 3 { return "\(racha) días seguidos" }
        return "Anotó \(diasSemana) \(diasSemana == 1 ? "día" : "días") de 7"
    }
}

/// Una medida tomada en consulta. Nunca se muestra la balanza: la curva y la diferencia.
struct Medicion: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var pacienteId: String
    var fecha: String
    var modalidad: Modalidad
    var cintura: Double?
    var cadera: Double?
    var brazo: Double?
    var peso: Double?
}

enum TipoMedida: String, Codable, CaseIterable, Hashable {
    case cintura, cadera, brazo, peso
    var titulo: String {
        switch self { case .cintura: return "Cintura"; case .cadera: return "Cadera"; case .brazo: return "Brazo"; case .peso: return "Peso" }
    }
    var unidad: String { self == .peso ? "kg" : "cm" }
    func valor(_ m: Medicion) -> Double? {
        switch self { case .cintura: return m.cintura; case .cadera: return m.cadera; case .brazo: return m.brazo; case .peso: return m.peso }
    }
}

/// Una comida que anotó el paciente (con foto o sin foto).
struct Registro: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var pacienteId: String
    var momento: Momento
    var fecha: String
    var hora: String
    /// Asset de la maqueta o un archivo guardado en el teléfono (`Archivos`).
    var foto: String?
    var descripcion: String
    var nota: String = ""
    var sensacion: Sensacion?
    /// Lo que decía el plan para esa comida.
    var enPlan: String?
    var comoElPlan: Bool?
    var revisada = false
    var respuesta: String?
    var bienAhi = false
}

// MARK: - Plan de comidas

enum TipoPorcion: String, Codable, CaseIterable, Hashable {
    case verdura, proteina, almidon
    var titulo: String {
        switch self { case .verdura: return "Verdura"; case .proteina: return "Proteína"; case .almidon: return "Almidón" }
    }
}

/// Una parte del plato armado («Medio plato de verdura · tomate y zanahoria»).
struct ParteArmado: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var tipo: TipoPorcion
    var fraccion: Double
    var nombre: String
    var detalle: String
}

/// Una opción de plato armado para una comida («Milanesa al horno» o «Tarta de verdura»).
struct OpcionPlato: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var nombre: String
    var partes: [ParteArmado]
}

struct ItemPlan: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var nombre: String
    var porcion: String
}

struct ComidaPlan: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var momento: Momento
    var hora: String
    var items: [ItemPlan] = []
    var opciones: [OpcionPlato] = []
}

struct PlanAlimentario: Codable, Hashable, Identifiable {
    var id: String
    /// nil: un modelo de la nutri para reusar.
    var pacienteId: String?
    var nombre: String
    var semana: Int
    var desde: String
    var dias: String = "Lunes a viernes"
    var comidas: [ComidaPlan]
    var nota: String = ""
    var enviado = false
    var guardado: String?
}

// MARK: - Agenda

enum EstadoTurno: String, Codable, Hashable {
    case confirmado, sinConfirmar, cancelado
}

struct Turno: Codable, Hashable, Identifiable {
    var id: String
    /// nil: un hueco libre.
    var pacienteId: String?
    var fecha: String
    var hora: String
    var duracion: Int = 60
    var modalidad: Modalidad = .consultorio
    /// «Control», «Primera vez».
    var tipo: String = "Control"
    var estado: EstadoTurno = .confirmado
    /// Para los turnos ya dados: si se cobró.
    var pagado: Bool?
    var monto: Int = 48_000
    var lugar: String = "Consultorio Güemes"
}

/// Alguien que quiere un turno antes.
struct Espera: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var pacienteId: String
    var preferencia: String
}

// MARK: - Plata

struct Servicio: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var detalle: String
    var monto: Int
    /// 0: consulta suelta. Si no, un plan que se paga por mes.
    var meses: Int = 0
    var controles: Int = 1
    var precioMes: Int { meses > 0 ? monto / meses : monto }
}

struct Cobro: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var pacienteId: String
    var concepto: String
    var monto: Int
    var fecha: String
    var vence: String?
    var pagado = false
    var medio: MedioPago?
    var pagadoEl: String?
}

// MARK: - Mensajes y avisos

struct Mensaje: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var deNutri: Bool
    var fecha: String
    var hora: String
    var texto: String?
    var foto: String?
    /// Pie de una foto («Almuerzo»).
    var pieFoto: String?
    /// Duración de un audio, en segundos.
    var audio: Int?
    /// Un archivo («Plan de la semana 3 · PDF»).
    var adjunto: String?
    var adjuntoDetalle: String?
    var leido = true
}

enum TipoAviso: String, Codable, Hashable {
    case turno, comida, pago, mensaje, logro, plan, sistema
    var icono: Icono {
        switch self {
        case .turno: return .turno
        case .comida: return .foto
        case .pago: return .pago
        case .mensaje: return .mensaje
        case .logro: return .logro
        case .plan: return .plan
        case .sistema: return .campana
        }
    }
}

struct AvisoApp: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var tipo: TipoAviso
    var titulo: String
    var texto: String
    var fecha: String
    var hora: String
    var leido = false
}

// MARK: - Juego del paciente

enum DiaRacha: String, Codable, Hashable {
    case anotado, no, comodin, hoy
}

struct Logro: Codable, Hashable, Identifiable {
    var id: String
    var titulo: String
    /// Fecha o pista («4 de agosto», «Vas 41»).
    var detalle: String
    var icono: Icono
    var conseguido: Bool
    var nuevo = false
}

extension Icono: Codable {}

struct Tip: Codable, Hashable, Identifiable {
    var id: String { texto }
    let texto: String
    let tema: String
}
