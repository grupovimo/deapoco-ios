import Foundation

// Lo que se responde en el onboarding. Se guarda en el teléfono (UserDefaults) y se manda a `Datos`.

/// Qué quiere lograr el paciente. Nunca «dieta» ni «bajar X kilos».
enum ObjetivoNutri: String, Codable, CaseIterable, Hashable {
    case ordenarme, energia, panza, peso, deporte, salud
    var titulo: String {
        switch self {
        case .ordenarme: return "Comer más ordenado"
        case .energia: return "Tener más energía"
        case .panza: return "Sentirme mejor de la panza"
        case .peso: return "Cuidar mi peso, sin dietas"
        case .deporte: return "Rendir en mi deporte"
        case .salud: return "Acompañar un tema de salud"
        }
    }
    var bajada: String {
        switch self {
        case .ordenarme: return "Horarios, compras y menos improvisar"
        case .energia: return "Llegar bien a la tarde"
        case .panza: return "Menos hinchazón, mejor digestión"
        case .peso: return "Cambios que se sostienen"
        case .deporte: return "Comer para entrenar y recuperar"
        case .salud: return "Colesterol, glucemia, presión"
        }
    }
}

/// Cómo come hoy (se pueden elegir varias).
enum ComoCome: String, Codable, CaseIterable, Hashable {
    case salteo, apurado, picoteo, afuera, tarde, ordenado
    var titulo: String {
        switch self {
        case .salteo: return "Salteo comidas"
        case .apurado: return "Como apurado"
        case .picoteo: return "Picoteo entre horas"
        case .afuera: return "Como mucho afuera"
        case .tarde: return "Ceno muy tarde"
        case .ordenado: return "Bastante ordenado"
        }
    }
}

/// Restricciones y alergias que se ofrecen como chips.
let restriccionesComunes = ["Vegetariana", "Vegana", "Celiaquía (sin TACC)", "Sin lactosa", "Diabetes", "Hipertensión",
                            "Alergia al maní", "Alergia al huevo", "Alergia a mariscos", "Embarazo o lactancia"]

/// Especialidades que se ofrecen a la nutri.
let especialidadesComunes = ["Adultos", "Deportiva", "Vegetariana y vegana", "Infancias", "Diabetes", "Celiaquía",
                             "Embarazo y lactancia", "Trastornos digestivos", "Conducta alimentaria", "Adultos mayores"]

struct Perfil: Codable, Hashable {
    var lado: Lado
    var nombre: String = ""

    // Paciente
    var sexo: Sexo = .sinDecir
    var edad: Int = 35
    var objetivo: ObjetivoNutri?
    var comoCome: [ComoCome] = []
    var restricciones: [String] = []
    var otraRestriccion: String = ""
    /// Las comidas que hace y a qué hora («13:00»). Las que no hace, no están.
    var horarios: [Momento: String] = [.desayuno: "08:00", .almuerzo: "13:00", .merienda: "17:00", .cena: "21:00"]
    var saludConectada = false
    var avisos = true

    // Nutri
    var matricula: String = ""
    var especialidades: [String] = []
    var modalidades: [Modalidad] = []
    var cantidadPacientes: Int = 20
    var conectadas: [String] = []

    var primerNombre: String { String(nombre.split(separator: " ").first ?? "") }

    private static let clave = "perfil"

    static func guardado(_ defaults: UserDefaults = .standard) -> Perfil? {
        guard let d = defaults.data(forKey: clave) else { return nil }
        return try? JSONDecoder().decode(Perfil.self, from: d)
    }

    func guardar(_ defaults: UserDefaults = .standard) {
        if let d = try? JSONEncoder().encode(self) { defaults.set(d, forKey: Perfil.clave) }
    }

    static func borrar(_ defaults: UserDefaults = .standard) { defaults.removeObject(forKey: clave) }
}

// MARK: - Perfil profesional de la nutri (su página pública)

struct LugarAtencion: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var nombre: String
    var direccion: String
    var dias: String
}

struct Integracion: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var detalle: String
    var conectada: Bool
    var cuenta: String?
}

struct PerfilNutri: Codable, Hashable {
    var nombre: String
    var titulo: String
    var matricula: String
    var foto: String?
    var frase: String
    var sobreMi: String
    var especialidades: [String]
    var lugares: [LugarAtencion]
    var enLinea: Bool
    var aceptaNuevos: Bool
    var slug: String
    var whatsapp: String
    var instagram: String
    var email: String
    var desde: Int

    var link: URL { URL(string: "https://deapoco.com.ar/\(slug)")! }
    var linkCorto: String { "deapoco.com.ar/\(slug)" }

    /// Qué le falta al perfil para estar completo, en orden de importancia.
    var pendientes: [(String, String)] {
        var p: [(String, String)] = []
        if foto == nil { p.append(("Tu foto", "Una foto tuya, de frente y con luz de ventana.")) }
        if matricula.isEmpty { p.append(("Tu matrícula", "Les da confianza a los pacientes nuevos.")) }
        if frase.isEmpty { p.append(("Tu frase", "Una línea que diga cómo trabajás.")) }
        if sobreMi.count < 40 { p.append(("Sobre vos", "Dos o tres frases, en tus palabras.")) }
        if especialidades.isEmpty { p.append(("Especialidades", "Así te encuentran los que buscan algo puntual.")) }
        if lugares.isEmpty && !enLinea { p.append(("Dónde atendés", "Un consultorio o en línea.")) }
        if instagram.isEmpty { p.append(("Instagram", "Para que vean tu día a día.")) }
        return p
    }
    var completitud: Int { max(0, 100 - pendientes.count * 12) }
}
