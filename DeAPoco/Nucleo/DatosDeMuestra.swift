import Foundation

/// Los datos de la maqueta: los de pantallas/app.html (Laura Ferreyra, nutri en Mar del Plata, y su paciente Sofía),
/// con el resto completado con gente y comida de verdad. Hoy es el martes 24 de noviembre de 2026.
extension DatosDeMuestra {
    static let hoy = "2026-11-24"

    // MARK: - Pacientes

    private static func p(_ id: String, _ nombre: String, foto: String? = nil, tono: TonoAvatar = .durazno, edad: Int,
                          sexo: Sexo = .mujer, desde: String, servicio: String = "plan3", objetivo: String,
                          dias: Int, racha: Int, sin: Int, meta: String = "", hechas: Int = 0,
                          novedad: String? = nil, tel: String) -> Paciente {
        Paciente(id: id, nombre: nombre, foto: foto, tono: tono, edad: edad, sexo: sexo, telefono: tel,
                 email: nombre.lowercased().folding(options: .diacriticInsensitive, locale: nil).replacingOccurrences(of: " ", with: ".") + "@gmail.com",
                 desde: desde, servicioId: servicio, objetivo: objetivo, diasSemana: dias, racha: racha, sinAnotar: sin,
                 meta: meta, metaHechas: hechas, metaTotal: 5, novedad: novedad)
    }

    static let pacientes: [Paciente] = {
        var l: [Paciente] = [
            {
                var s = p("sofia", "Sofía Benítez", foto: "av-sofia", edad: 36, desde: "2026-08-04", objetivo: "Comer más ordenado y llegar con energía a la tarde",
                          dias: 6, racha: 12, sin: 0, meta: "Fruta en la merienda", hechas: 3, tel: "+54 223 541-2208")
                s.comoCome = "Salteaba el desayuno y picoteaba a la tarde. Almuerza en la oficina."
                s.restricciones = ["Sin lactosa"]
                s.saludConectada = true
                s.pasos = 7840
                s.notas = [Nota(fecha: "2026-11-11", texto: "Viene muy bien con las viandas. Le cuesta la merienda en la oficina: probar fruta cortada desde casa."),
                           Nota(fecha: "2026-10-28", texto: "Se siente con más energía. Duerme mejor desde que cena más temprano."),
                           Nota(fecha: "2026-08-04", texto: "Primera consulta. Quiere ordenarse, sin dietas. Le gusta cocinar los domingos.")]
                return s
            }(),
            p("martin", "Martín Acosta", foto: "av-martin", edad: 47, sexo: .hombre, desde: "2026-06-16", objetivo: "Cuidar el azúcar en sangre",
              dias: 0, racha: 0, sin: 10, meta: "Caminar después de cenar", hechas: 0, tel: "+54 223 615-0931"),
            p("ana", "Ana Domínguez", foto: "av-ana", edad: 41, desde: "2026-05-12", objetivo: "Sentirse mejor de la panza",
              dias: 7, racha: 23, sin: 0, meta: "Dos litros de agua", hechas: 5, novedad: "Cumplió su meta", tel: "+54 223 588-7714"),
            p("rocio", "Rocío Medina", tono: .az, edad: 29, desde: "2026-09-22", objetivo: "Rendir en el hockey",
              dias: 2, racha: 0, sin: 1, meta: "Desayunar antes de entrenar", hechas: 1, tel: "+54 223 430-1166"),
            p("julian", "Julián Pereyra", tono: .az, edad: 33, sexo: .hombre, desde: "2026-11-24", servicio: "control", objetivo: "Ordenarse con las comidas",
              dias: 3, racha: 1, sin: 0, tel: "+54 223 690-2245"),
            p("carla", "Carla Ruiz", tono: .lo, edad: 52, desde: "2026-03-03", objetivo: "Acompañar el colesterol",
              dias: 6, racha: 9, sin: 0, meta: "Legumbres dos veces por semana", hechas: 2, tel: "+54 223 501-3380"),
            p("diego", "Diego Sosa", tono: .lo, edad: 44, sexo: .hombre, desde: "2026-07-07", objetivo: "Cenar más temprano",
              dias: 1, racha: 0, sin: 4, tel: "+54 223 477-9012"),
            p("valeria", "Valeria Gómez", edad: 38, desde: "2026-04-21", objetivo: "Comer más ordenado",
              dias: 0, racha: 0, sin: 6, tel: "+54 223 552-6630"),
            p("lucas", "Lucas Ferrari", tono: .az, edad: 27, sexo: .hombre, desde: "2026-09-01", objetivo: "Ganar masa muscular",
              dias: 4, racha: 2, sin: 0, tel: "+54 223 698-4471"),
            p("paula", "Paula Ríos", edad: 35, desde: "2026-10-06", objetivo: "Tener más energía",
              dias: 3, racha: 1, sin: 1, tel: "+54 223 512-0087"),
            p("marina", "Marina Castro", tono: .lo, edad: 49, desde: "2026-02-17", objetivo: "Acompañar la menopausia",
              dias: 4, racha: 3, sin: 0, tel: "+54 223 469-3321"),
            p("tomas", "Tomás Herrera", tono: .az, edad: 31, sexo: .hombre, desde: "2026-08-25", objetivo: "Comer mejor en la oficina",
              dias: 3, racha: 0, sin: 2, tel: "+54 223 620-5560"),
            p("florencia", "Florencia Díaz", edad: 26, desde: "2026-10-20", objetivo: "Vegetariana, sin perder hierro",
              dias: 4, racha: 2, sin: 0, tel: "+54 223 581-7745"),
            p("gabriel", "Gabriel Romero", tono: .lo, edad: 55, sexo: .hombre, desde: "2026-01-13", objetivo: "Cuidar la presión",
              dias: 4, racha: 1, sin: 0, tel: "+54 223 437-2218"),
        ]
        let nombres = ["Lucía Fernández", "Mariano López", "Agustina Martínez", "Federico García", "Camila Pérez", "Nicolás Gutiérrez",
                       "Belén Álvarez", "Santiago Torres", "Micaela Ramírez", "Pablo Flores", "Victoria Morales", "Ezequiel Ortiz",
                       "Julieta Silva", "Matías Rojas", "Daniela Molina", "Leandro Suárez", "Romina Castillo", "Hernán Vega",
                       "Natalia Acuña", "Gonzalo Benítez", "Carolina Luna", "Sebastián Navarro", "Eugenia Cabrera", "Ignacio Paz",
                       "Silvina Giménez", "Martina Correa", "Facundo Ibarra", "Jimena Arias"]
        let hombres: Set<String> = ["Mariano", "Federico", "Nicolás", "Santiago", "Pablo", "Ezequiel", "Matías", "Leandro", "Hernán",
                                    "Gonzalo", "Sebastián", "Ignacio", "Facundo"]
        let objetivos = ["Comer más ordenado", "Tener más energía", "Cuidar el peso, sin dietas", "Rendir en el deporte",
                         "Sentirse mejor de la panza", "Acompañar el colesterol", "Ordenar las cenas"]
        let tonos: [TonoAvatar] = [.durazno, .az, .lo]
        for (i, n) in nombres.enumerated() {
            let primero = String(n.split(separator: " ")[0])
            let id = primero.lowercased().folding(options: .diacriticInsensitive, locale: nil) + "-\(i)"
            let mes = 1 + (i * 5) % 10
            l.append(p(id, n, tono: tonos[i % 3], edad: 24 + (i * 7) % 34, sexo: hombres.contains(primero) ? .hombre : .mujer,
                       desde: String(format: "2026-%02d-%02d", mes, 3 + (i * 3) % 24), servicio: i % 3 == 0 ? "control" : "plan3",
                       objetivo: objetivos[i % objetivos.count], dias: 5 + i % 3, racha: 4 + (i * 3) % 19, sin: 0,
                       tel: String(format: "+54 223 %03d-%04d", 400 + (i * 37) % 300, 1000 + (i * 613) % 9000)))
        }
        return l
    }()

    // MARK: - Turnos

    /// Hoy, igual que la agenda del diseño. El resto de la semana y la que viene, completados.
    static let turnos: [Turno] = {
        var t: [Turno] = [
            Turno(id: "t-carla", pacienteId: "carla", fecha: hoy, hora: "09:00", modalidad: .consultorio, estado: .confirmado, pagado: true),
            Turno(id: "t-julian", pacienteId: "julian", fecha: hoy, hora: "10:00", modalidad: .consultorio, tipo: "Primera vez", estado: .confirmado, pagado: false, monto: 65_000),
            Turno(id: "t-sofia", pacienteId: "sofia", fecha: hoy, hora: "11:30", modalidad: .enLinea, estado: .confirmado),
            Turno(id: "t-libre", pacienteId: nil, fecha: hoy, hora: "13:00"),
            Turno(id: "t-martin", pacienteId: "martin", fecha: hoy, hora: "15:00", modalidad: .consultorio, estado: .confirmado),
            Turno(id: "t-ana", pacienteId: "ana", fecha: hoy, hora: "16:30", modalidad: .consultorio, estado: .confirmado),
            Turno(id: "t-rocio", pacienteId: "rocio", fecha: hoy, hora: "18:00", modalidad: .enLinea, estado: .sinConfirmar, monto: 45_000),
        ]
        let ids = pacientes.map(\.id).filter { !["sofia", "martin", "ana", "rocio", "julian", "carla"].contains($0) }
        let horas = ["09:00", "10:00", "11:30", "15:00", "16:30", "18:00"]
        var k = 0
        for d in -8...10 where d != 0 {
            let f = Fecha.sumar(d, a: hoy)
            let ds = Fecha.diaSemana(f)
            guard ds <= 5 else { continue }
            for (j, h) in horas.enumerated() where (j + d + 9) % 5 != 0 {
                let id = ids[k % ids.count]; k += 1
                let pasado = d < 0
                t.append(Turno(id: "t\(d)-\(j)", pacienteId: id, fecha: f, hora: h, modalidad: (j + k) % 3 == 0 ? .enLinea : .consultorio,
                               estado: pasado || (j + k) % 4 != 0 ? .confirmado : .sinConfirmar,
                               pagado: pasado ? (k % 9 != 0) : nil))
            }
        }
        return t
    }()

    // MARK: - Comidas

    static let registros: [Registro] = {
        let ayer = Fecha.sumar(-1, a: hoy)
        var r: [Registro] = [
            Registro(id: "r-sofia-des", pacienteId: "sofia", momento: .desayuno, fecha: hoy, hora: "08:20", foto: "plato-desayuno",
                     descripcion: "Mate con pan y queso untable", sensacion: .bien, enPlan: "Café con leche y pan integral con queso", comoElPlan: true),
            Registro(id: "r-sofia-alm", pacienteId: "sofia", momento: .almuerzo, fecha: ayer, hora: "13:24", foto: "plato-milanesa",
                     descripcion: "Milanesa al horno con ensalada", nota: "Comí en la oficina", sensacion: .bien,
                     enPlan: "Milanesa al horno con ensalada", comoElPlan: true),
            Registro(id: "r-ana-cena", pacienteId: "ana", momento: .cena, fecha: ayer, hora: "21:10", foto: "plato-tarta",
                     descripcion: "Tarta de acelga casera", sensacion: .bien, enPlan: "Tarta de verdura con ensalada", comoElPlan: true),
            Registro(id: "r-ana-alm", pacienteId: "ana", momento: .almuerzo, fecha: ayer, hora: "13:05", foto: "plato-vianda",
                     descripcion: "Vianda de arroz con pollo y verduras", sensacion: .lleno, enPlan: "Pollo con arroz y verduras", comoElPlan: true),
            Registro(id: "r-carla-mer", pacienteId: "carla", momento: .merienda, fecha: ayer, hora: "17:40", foto: "taza",
                     descripcion: "Café con leche y una mandarina", sensacion: .hambre, enPlan: "Yogur con fruta", comoElPlan: false),
        ]
        // Historia ya revisada.
        let fotos = ["plato-tarta", "plato-vianda", "plato-guiso", "plato-lentejas", "ensalada", "olla", "wok", "plato-desayuno", "tomates", "mesa"]
        let platos = ["Tarta de acelga", "Vianda de pollo con verduras", "Guiso de lentejas", "Lentejas con arroz", "Ensalada completa",
                      "Estofado de carne", "Salteado de verduras", "Tostadas con queso", "Ensalada de tomate y cebolla", "Fideos con tuco"]
        let quienes = ["sofia", "sofia", "ana", "carla", "lucas", "marina", "sofia", "paula", "florencia", "gabriel"]
        for i in 0..<24 {
            let quien = quienes[i % quienes.count]
            let m: Momento = [.almuerzo, .cena, .desayuno, .merienda][i % 4]
            r.append(Registro(id: "h\(i)", pacienteId: quien, momento: m, fecha: Fecha.sumar(-(2 + i / 3), a: hoy),
                              hora: m.horaSugerida, foto: fotos[i % fotos.count], descripcion: platos[i % platos.count],
                              sensacion: [.bien, .bien, .lleno, .hambre][i % 4], comoElPlan: i % 5 != 0, revisada: true,
                              respuesta: i % 2 == 0 ? "¡Bien ahí!" : nil, bienAhi: i % 2 == 0))
        }
        return r
    }()

    // MARK: - Planes

    static let almuerzoMilanesa = OpcionPlato(id: "op-mila", nombre: "Milanesa al horno", partes: [
        ParteArmado(tipo: .proteina, fraccion: 0.25, nombre: "Milanesa al horno", detalle: "del tamaño de tu mano"),
        ParteArmado(tipo: .almidon, fraccion: 0.25, nombre: "Papa o arroz", detalle: "un puñado"),
        ParteArmado(tipo: .verdura, fraccion: 0.5, nombre: "Medio plato de verdura", detalle: "tomate y zanahoria"),
    ])
    static let almuerzoTarta = OpcionPlato(id: "op-tarta", nombre: "Tarta de verdura", partes: [
        ParteArmado(tipo: .proteina, fraccion: 0.25, nombre: "Tarta de acelga o zapallito", detalle: "una porción"),
        ParteArmado(tipo: .almidon, fraccion: 0.25, nombre: "La masa ya cuenta", detalle: "sin pan aparte"),
        ParteArmado(tipo: .verdura, fraccion: 0.5, nombre: "Medio plato de ensalada", detalle: "lechuga, tomate, zanahoria"),
    ])

    static let planSofia = PlanAlimentario(id: "plan-sofia-3", pacienteId: "sofia", nombre: "Plan de la semana 3", semana: 3,
                                           desde: "2026-12-01", comidas: [
        ComidaPlan(id: "c-des", momento: .desayuno, hora: "8:00", items: [
            ItemPlan(id: "i1", nombre: "Mate o café con leche", porcion: "1 taza"),
            ItemPlan(id: "i2", nombre: "Pan integral con queso", porcion: "2 rodajas"),
        ]),
        ComidaPlan(id: "c-alm", momento: .almuerzo, hora: "13:00", opciones: [almuerzoMilanesa, almuerzoTarta]),
        ComidaPlan(id: "c-mer", momento: .merienda, hora: "17:00", items: [
            ItemPlan(id: "i3", nombre: "Yogur con durazno", porcion: "1 pote"),
        ]),
        ComidaPlan(id: "c-cen", momento: .cena, hora: "21:00", items: [
            ItemPlan(id: "i4", nombre: "Guiso de lentejas", porcion: "1 plato hondo"),
        ]),
    ], nota: "si un día no sale, seguís en la próxima comida.", guardado: "11:48")

    static let modelos: [PlanAlimentario] = [
        PlanAlimentario(id: "m-base", pacienteId: nil, nombre: "Base para adultos", semana: 1, desde: hoy, comidas: [
            ComidaPlan(momento: .desayuno, hora: "8:00", items: [ItemPlan(nombre: "Infusión con leche", porcion: "1 taza"), ItemPlan(nombre: "Pan con queso", porcion: "2 rodajas")]),
            ComidaPlan(momento: .almuerzo, hora: "13:00", opciones: [almuerzoMilanesa]),
            ComidaPlan(momento: .merienda, hora: "17:00", items: [ItemPlan(nombre: "Fruta de estación", porcion: "1 unidad")]),
            ComidaPlan(momento: .cena, hora: "21:00", opciones: [almuerzoTarta]),
        ]),
        PlanAlimentario(id: "m-veg", pacienteId: nil, nombre: "Vegetariano", semana: 1, desde: hoy, comidas: [
            ComidaPlan(momento: .desayuno, hora: "8:00", items: [ItemPlan(nombre: "Avena con banana", porcion: "1 bowl")]),
            ComidaPlan(momento: .almuerzo, hora: "13:00", items: [ItemPlan(nombre: "Guiso de lentejas", porcion: "1 plato hondo")]),
            ComidaPlan(momento: .cena, hora: "21:00", items: [ItemPlan(nombre: "Tortilla de verduras", porcion: "1 porción")]),
        ]),
        PlanAlimentario(id: "m-dep", pacienteId: nil, nombre: "Para entrenar", semana: 1, desde: hoy, comidas: [
            ComidaPlan(momento: .desayuno, hora: "7:30", items: [ItemPlan(nombre: "Tostadas con huevo", porcion: "2 tostadas")]),
            ComidaPlan(momento: .almuerzo, hora: "13:00", items: [ItemPlan(nombre: "Arroz con pollo", porcion: "1 plato")]),
            ComidaPlan(momento: .merienda, hora: "17:30", items: [ItemPlan(nombre: "Yogur con granola", porcion: "1 pote")]),
        ]),
        PlanAlimentario(id: "m-tacc", pacienteId: nil, nombre: "Sin TACC", semana: 1, desde: hoy, comidas: [
            ComidaPlan(momento: .desayuno, hora: "8:00", items: [ItemPlan(nombre: "Tostadas de pan sin TACC", porcion: "2 rodajas")]),
            ComidaPlan(momento: .almuerzo, hora: "13:00", items: [ItemPlan(nombre: "Papa al horno con carne", porcion: "1 plato")]),
        ]),
    ]

    // MARK: - Medidas (nunca balanza: la curva)

    static func medidasSofia() -> [Medicion] {
        let fechas = ["2026-08-04", "2026-08-18", "2026-09-01", "2026-09-15", "2026-09-30", "2026-10-07", "2026-10-14", "2026-10-28", "2026-11-11", hoy]
        let cintura = [94, 93.4, 92.6, 92.8, 91.5, 90.4, 90.1, 89.2, 88.5, 88]
        let cadera = [108, 107.5, 106.6, 106, 104, 103.5, 103, 102, 101.6, 101]
        let brazo = [31, 30.8, 30.6, 30.6, 30.2, 30, 29.8, 29.6, 29.4, 29.2]
        let peso = [78.4, 78, 77.5, 77.6, 76.9, 76.2, 76, 75.4, 75.1, 74.8]
        return fechas.enumerated().map { i, f in
            Medicion(id: "m-sofia-\(i)", pacienteId: "sofia", fecha: f, modalidad: [4, 7].contains(i) ? .consultorio : (i == 9 ? .enLinea : .consultorio),
                     cintura: cintura[i], cadera: cadera[i], brazo: brazo[i], peso: peso[i])
        }
    }

    static let mediciones: [Medicion] = {
        var m = medidasSofia()
        for (j, id) in ["ana", "carla", "martin", "lucas"].enumerated() {
            for i in 0..<5 {
                m.append(Medicion(pacienteId: id, fecha: Fecha.sumar(-14 * (4 - i) - j, a: hoy), modalidad: .consultorio,
                                  cintura: 96 - Double(i) * 0.9 - Double(j), cadera: 106 - Double(i) * 0.6, brazo: 31 - Double(i) * 0.2,
                                  peso: 80 - Double(i) * 0.5 - Double(j) * 2))
            }
        }
        return m
    }()

    // MARK: - Plata

    static let servicios: [Servicio] = [
        Servicio(id: "control", nombre: "Control", detalle: "Consultorio o en línea", monto: 48_000),
        Servicio(id: "plan3", nombre: "Plan 3 meses", detalle: "3 controles y mensajes", monto: 135_000, meses: 3, controles: 3),
        Servicio(id: "primera", nombre: "Primera consulta", detalle: "Una hora, con plan incluido", monto: 65_000),
    ]

    /// 27 pagos del mes (19 Mercado Pago, 6 transferencia, 2 efectivo) que suman $1.284.000, y 7 por cobrar ($336.000).
    static let cobros: [Cobro] = {
        var c: [Cobro] = [
            Cobro(id: "co-julian", pacienteId: "julian", concepto: "Primera consulta", monto: 65_000, fecha: hoy),
            Cobro(id: "co-rocio", pacienteId: "rocio", concepto: "Plan 3 meses · cuota 3", monto: 45_000, fecha: "2026-11-11", vence: "2026-11-25"),
            Cobro(id: "co-martin", pacienteId: "martin", concepto: "Control", monto: 48_000, fecha: "2026-11-18"),
            Cobro(id: "co-lucas", pacienteId: "lucas", concepto: "Control", monto: 48_000, fecha: "2026-11-20"),
            Cobro(id: "co-paula", pacienteId: "paula", concepto: "Plan 3 meses · cuota 2", monto: 45_000, fecha: "2026-11-21", vence: "2026-11-30"),
            Cobro(id: "co-diego", pacienteId: "diego", concepto: "Plan 3 meses · cuota 3", monto: 45_000, fecha: "2026-11-14"),
            Cobro(id: "co-valeria", pacienteId: "valeria", concepto: "Control a precio viejo", monto: 40_000, fecha: "2026-11-10"),
        ]
        let quienes = pacientes.map(\.id).filter { !["julian", "rocio", "martin", "lucas", "paula", "diego", "valeria"].contains($0) }
        let montos = Array(repeating: 48_000, count: 3) + Array(repeating: 45_000, count: 21) + Array(repeating: 65_000, count: 3)
        let medios: [MedioPago] = Array(repeating: .mercadoPago, count: 19) + Array(repeating: .transferencia, count: 6) + [.efectivo, .efectivo]
        for i in 0..<27 {
            let f = String(format: "2026-11-%02d", 3 + (i * 7) % 22)
            let concepto = montos[i] == 45_000 ? "Plan 3 meses · cuota" : montos[i] == 65_000 ? "Primera consulta" : "Control"
            c.append(Cobro(id: "pago-\(i)", pacienteId: quienes[(i * 5) % quienes.count], concepto: concepto, monto: montos[i],
                           fecha: f, pagado: true, medio: medios[(i * 7) % 27], pagadoEl: f))
        }
        // Carla pagó el control de hoy.
        c[7].pacienteId = "carla"; c[7].fecha = hoy; c[7].pagadoEl = hoy
        // Meses anteriores de Sofía.
        for (i, mes) in ["2026-08-04", "2026-09-04", "2026-10-04"].enumerated() {
            c.append(Cobro(id: "sofia-\(i)", pacienteId: "sofia", concepto: i == 0 ? "Primera consulta" : "Plan 3 meses · cuota \(i)",
                           monto: i == 0 ? 65_000 : 45_000, fecha: mes, pagado: true, medio: .mercadoPago, pagadoEl: mes))
        }
        return c
    }()

    // MARK: - Mensajes

    static let chatSofia: [Mensaje] = [
        Mensaje(id: "s1", deNutri: false, fecha: hoy, hora: "13:24", foto: "plato-milanesa", pieFoto: "Almuerzo"),
        Mensaje(id: "s2", deNutri: true, fecha: hoy, hora: "14:02", texto: "¡Bien ahí! Esa ensalada con zanahoria está perfecta."),
        Mensaje(id: "s3", deNutri: false, fecha: hoy, hora: "18:03", texto: "El sábado tengo un cumpleaños con asado. ¿Qué hago?"),
        Mensaje(id: "s4", deNutri: true, fecha: hoy, hora: "18:09", texto: "Disfrutalo. Un asado con amigos no borra un mes de trabajo."),
        Mensaje(id: "s5", deNutri: true, fecha: hoy, hora: "18:10", audio: 42, leido: false),
    ]

    static let chats: [String: [Mensaje]] = [
        "sofia": [
            Mensaje(id: "n1", deNutri: false, fecha: Fecha.sumar(-1, a: hoy), hora: "13:24", foto: "plato-milanesa", pieFoto: "Almuerzo"),
            Mensaje(id: "n2", deNutri: true, fecha: Fecha.sumar(-1, a: hoy), hora: "14:02", texto: "¡Bien ahí! Esa ensalada con zanahoria está perfecta."),
            Mensaje(id: "n3", deNutri: false, fecha: hoy, hora: "09:03", texto: "El sábado tengo un cumpleaños con asado. ¿Qué hago?", leido: false),
        ],
        "ana": [
            Mensaje(id: "a1", deNutri: false, fecha: hoy, hora: "08:41", texto: "¡Cumplí los dos litros toda la semana! 💧", leido: false),
        ],
        "rocio": [
            Mensaje(id: "ro1", deNutri: true, fecha: Fecha.sumar(-2, a: hoy), hora: "10:15", texto: "¿Cómo te fue con el desayuno antes del entrenamiento?"),
            Mensaje(id: "ro2", deNutri: false, fecha: hoy, hora: "07:58", texto: "Hoy no llegué, salí corriendo. Mañana pruebo con la banana.", leido: false),
        ],
        "lucas": [
            Mensaje(id: "l1", deNutri: false, fecha: hoy, hora: "10:20", texto: "¿Puedo cambiar el arroz por fideos en el almuerzo?", leido: false),
        ],
        "martin": [
            Mensaje(id: "ma1", deNutri: true, fecha: "2026-11-15", hora: "19:02", texto: "Martín, ¿cómo venís con las caminatas?"),
        ],
    ]

    static let avisosNutri: [AvisoApp] = [
        AvisoApp(tipo: .comida, titulo: "5 comidas para mirar", texto: "De Sofía, Ana y Carla.", fecha: hoy, hora: "08:45"),
        AvisoApp(tipo: .turno, titulo: "Rocío no confirmó", texto: "Su turno es hoy a las 18:00, en línea.", fecha: hoy, hora: "08:00"),
        AvisoApp(tipo: .pago, titulo: "Carla pagó el control", texto: "$48.000 por Mercado Pago.", fecha: hoy, hora: "09:52", leido: true),
        AvisoApp(tipo: .logro, titulo: "Ana cumplió su meta", texto: "Dos litros de agua, cinco días de cinco.", fecha: hoy, hora: "08:41"),
        AvisoApp(tipo: .mensaje, titulo: "Lucas te escribió", texto: "¿Puedo cambiar el arroz por fideos en el almuerzo?", fecha: hoy, hora: "10:20"),
        AvisoApp(tipo: .sistema, titulo: "Te quedan 9 días de prueba", texto: "Elegí un plan cuando quieras. Sin apuro.", fecha: Fecha.sumar(-1, a: hoy), hora: "10:00", leido: true),
    ]

    static let integraciones: [Integracion] = [
        Integracion(id: "gcal", nombre: "Google Calendar", detalle: "Tus turnos en tu calendario", conectada: true, cuenta: "laura.ferreyra@gmail.com"),
        Integracion(id: "mp", nombre: "Mercado Pago", detalle: "Cobrás consultas y planes", conectada: true, cuenta: "Laura Ferreyra · CVU …4471"),
        Integracion(id: "wa", nombre: "WhatsApp", detalle: "Recordatorios desde tu número", conectada: true, cuenta: "+54 223 512-4470"),
        Integracion(id: "salud", nombre: "Apple Salud", detalle: "Pasos y sueño de tus pacientes, si lo permiten", conectada: true, cuenta: nil),
    ]

    static let nutri = PanelNutri(
        nombre: "Laura", nombreCompleto: "Laura Ferreyra", foto: "av-laura", hoy: hoy, ahora: "11:12",
        pacientes: pacientes, turnos: turnos,
        espera: [Espera(pacienteId: "lucas", preferencia: "Mediodía"), Espera(pacienteId: "paula", preferencia: "Cualquier horario"),
                 Espera(pacienteId: "tomas", preferencia: "Después de las 12")],
        registros: registros, planes: [planSofia] + modelos, mediciones: mediciones, cobros: cobros, servicios: servicios,
        chats: chats, avisos: avisosNutri, integraciones: integraciones,
        mediosDelMes: [.mercadoPago: 19, .transferencia: 6, .efectivo: 2],
        historico: [980, 1_050, 1_120, 1_190, 1_310, 1_284])

    // MARK: - El paciente (Sofía)

    static let logros: [Logro] = [
        Logro(id: "semana1", titulo: "Primera semana", detalle: "4 de agosto", icono: .turno, conseguido: true),
        Logro(id: "fotos10", titulo: "10 comidas con foto", detalle: "12 de agosto", icono: .foto, conseguido: true),
        Logro(id: "nuevo", titulo: "Probaste algo nuevo", detalle: "Tarta de acelga", icono: .brote, conseguido: true),
        Logro(id: "agua7", titulo: "Agua 7 días", detalle: "3 de octubre", icono: .agua, conseguido: true),
        Logro(id: "volviste", titulo: "Volviste después de una pausa", detalle: "Ayer", icono: .vuelta, conseguido: true, nuevo: true),
        Logro(id: "bienahi3", titulo: "Tres «bien ahí»", detalle: "De Laura", icono: .mensaje, conseguido: true),
        Logro(id: "mes", titulo: "Un mes seguido", detalle: "Faltan 18 días", icono: .logro, conseguido: false),
        Logro(id: "fotos50", titulo: "50 comidas con foto", detalle: "Vas 41", icono: .foto, conseguido: false),
        Logro(id: "medida", titulo: "Medida nueva", detalle: "En tu próximo turno", icono: .cinta, conseguido: false),
        Logro(id: "bienahi10", titulo: "Diez «bien ahí»", detalle: "Vas 6", icono: .bocado, conseguido: false),
        Logro(id: "cuatro7", titulo: "Las cuatro comidas, 7 días", detalle: "Vas 4", icono: .plan, conseguido: false),
        Logro(id: "verduras5", titulo: "Cinco verduras nuevas", detalle: "Vas 2", icono: .brote, conseguido: false),
        Logro(id: "agua30", titulo: "Agua 30 días", detalle: "Vas 12", icono: .agua, conseguido: false),
        Logro(id: "cien", titulo: "Cien días anotando", detalle: "Vas 88", icono: .turno, conseguido: false),
    ]

    static let registrosSofia: [Registro] = {
        var r: [Registro] = [
            Registro(id: "p-des", pacienteId: "sofia", momento: .desayuno, fecha: hoy, hora: "08:20", foto: "plato-desayuno",
                     descripcion: "Mate con pan y queso untable", sensacion: .bien, comoElPlan: true, revisada: true),
            Registro(id: "p-alm", pacienteId: "sofia", momento: .almuerzo, fecha: hoy, hora: "13:24", foto: "plato-milanesa",
                     descripcion: "Milanesa al horno con ensalada", nota: "Comí en la oficina", sensacion: .bien, comoElPlan: true,
                     revisada: true, respuesta: "¡Bien ahí! Esa ensalada con zanahoria está perfecta.", bienAhi: true),
        ]
        // Lunes: las cuatro.
        let lunes = Fecha.sumar(-1, a: hoy)
        let delLunes: [(Momento, String, String)] = [(.desayuno, "taza", "Café con leche y tostadas"), (.almuerzo, "plato-tarta", "Tarta de acelga"),
                                                     (.merienda, "tomates", "Yogur con durazno"), (.cena, "plato-lentejas", "Guiso de lentejas")]
        for (i, x) in delLunes.enumerated() {
            r.append(Registro(id: "p-lun-\(i)", pacienteId: "sofia", momento: x.0, fecha: lunes, hora: x.0.horaSugerida, foto: x.2 == "" ? nil : x.1,
                              descripcion: x.2, sensacion: .bien, comoElPlan: true, revisada: true))
        }
        // Semanas anteriores.
        let fotos = ["plato-vianda", "plato-guiso", "ensalada", "olla", "wok", "plato-desayuno", "plato-tarta", "plato-milanesa"]
        let platos = ["Vianda de pollo con verduras", "Guiso de lentejas", "Ensalada completa", "Estofado", "Salteado de verduras",
                      "Tostadas con queso", "Tarta de zapallito", "Milanesa al horno"]
        for i in 0..<30 {
            let m: Momento = Momento.principales[i % 4]
            r.append(Registro(id: "p-h\(i)", pacienteId: "sofia", momento: m, fecha: Fecha.sumar(-2 - i / 3, a: hoy), hora: m.horaSugerida,
                              foto: i % 3 == 2 ? nil : fotos[i % fotos.count], descripcion: platos[i % platos.count],
                              sensacion: .bien, comoElPlan: i % 6 != 0, revisada: true, bienAhi: i % 7 == 0))
        }
        return r
    }()

    static let paciente = PanelPaciente(
        id: "sofia", nombre: "Sofía Benítez", foto: "av-sofia",
        nutri: NutriDelPaciente(nombre: "Laura", nombreCompleto: "Laura Ferreyra", titulo: "Lic.", matricula: "MP 2174", foto: "av-laura",
                                responde: "Responde de lunes a viernes", telefono: "+54 223 512-4470", lugar: "Consultorio Güemes · Güemes 2870"),
        hoy: hoy, ahora: "17:05", desde: "2026-08-04",
        registros: registrosSofia, plan: planSofia,
        agua: 5, aguaMeta: 8, meta: "Fruta en la merienda", metaHechas: 3, metaTotal: 5,
        racha: 12, mejorRacha: 15, comodines: 1, comodinUsado: "2026-11-19",
        dias14: [.anotado, .no] + Array(repeating: .anotado, count: 7) + [.comodin, .anotado, .anotado, .anotado, .hoy],
        semanas: [3, 4, 2, 5, 6, 5, 4, 6, 7, 5, 6, 7, 7, 6, 7, 5],
        nivel: 3, faltanNivel: 2, logros: logros,
        destacados: [Destacado(titulo: "Tres semanas", bajada: "anotando. Bien ahí.", partes: 3, llenas: 3, fuerte: true),
                     Destacado(titulo: "Primera tarta casera", bajada: "De acelga, el domingo.", partes: 4, llenas: 1),
                     Destacado(titulo: "8 vasos", bajada: "Cinco días", partes: 2, llenas: 1)],
        mediciones: medidasSofia(), mostrarPeso: false, saludConectada: true, pasos: 7_840, sueno: 430,
        turno: Turno(id: "t-sofia-jue", pacienteId: "sofia", fecha: "2026-11-26", hora: "11:30", duracion: 30, modalidad: .enLinea),
        servicios: servicios.filter { $0.id != "primera" }, contratado: nil,
        pagos: [
            Cobro(id: "sp1", pacienteId: "sofia", concepto: "Primera consulta", monto: 65_000, fecha: "2026-08-04", pagado: true, medio: .mercadoPago, pagadoEl: "2026-08-04"),
            Cobro(id: "sp2", pacienteId: "sofia", concepto: "Control", monto: 45_000, fecha: "2026-09-01", pagado: true, medio: .mercadoPago, pagadoEl: "2026-09-01"),
            Cobro(id: "sp3", pacienteId: "sofia", concepto: "Control", monto: 45_000, fecha: "2026-09-30", pagado: true, medio: .transferencia, pagadoEl: "2026-09-30"),
            Cobro(id: "sp4", pacienteId: "sofia", concepto: "Control", monto: 48_000, fecha: "2026-10-28", pagado: true, medio: .mercadoPago, pagadoEl: "2026-10-28"),
        ],
        mensajes: chatSofia,
        avisos: [
            AvisoApp(tipo: .comida, titulo: "¿Ya merendaste?", texto: "Sacale una foto a la merienda. Con eso alcanza.", fecha: hoy, hora: "17:00"),
            AvisoApp(tipo: .mensaje, titulo: "Laura te mandó un audio", texto: "0:42", fecha: hoy, hora: "18:10"),
            AvisoApp(tipo: .turno, titulo: "Turno el jueves 11:30", texto: "En línea con Laura. ¿Confirmás?", fecha: hoy, hora: "10:00", leido: true),
            AvisoApp(tipo: .logro, titulo: "Volviste después de una pausa", texto: "Lo difícil es volver. Bien ahí.", fecha: Fecha.sumar(-1, a: hoy), hora: "21:00", leido: true),
            AvisoApp(tipo: .plan, titulo: "Tu plan de la semana 3", texto: "Laura ya lo armó. Arranca el lunes.", fecha: Fecha.sumar(-1, a: hoy), hora: "11:50", leido: true),
        ],
        bienAhi: [BienAhi(fecha: hoy, por: "la ensalada"), BienAhi(fecha: "2026-11-21", por: "la tarta casera"), BienAhi(fecha: "2026-11-14", por: "los ocho vasos")],
        avisosPrendidos: true)

    // MARK: - Perfil profesional y suscripción

    static let perfilLaura = PerfilNutri(
        nombre: "Laura Ferreyra", titulo: "Lic. en Nutrición", matricula: "MP 2174", foto: "av-laura",
        frase: "Comer mejor se hace de a poco.",
        sobreMi: "Soy nutricionista desde 2014. Trabajo sin dietas de moda: armamos juntos un plan con la comida que ya te gusta, y lo vamos ajustando consulta a consulta.",
        especialidades: ["Adultos", "Deportiva", "Trastornos digestivos"],
        lugares: [LugarAtencion(nombre: "Consultorio Güemes", direccion: "Güemes 2870, Mar del Plata", dias: "Lunes a viernes, de 9 a 19")],
        enLinea: true, aceptaNuevos: true, slug: "laura", whatsapp: "+54 223 512-4470", instagram: "@laura.nutri.mdp",
        email: "laura.ferreyra@gmail.com", desde: 2014)

    /// En la prueba de Profesional: le quedan 9 días (vence el 3/12).
    static let suscripcion = Suscripcion(plan: .gratis, pruebaHasta: "2026-12-03", pruebaUsada: true, precioFijoHasta: "2027-05-24")

    // MARK: - Perfiles de onboarding (para abrir directo un lado)

    static let perfilNutri: Perfil = {
        var p = Perfil(lado: .nutri)
        p.nombre = "Laura Ferreyra"
        p.matricula = "MP 2174"
        p.especialidades = ["Adultos", "Deportiva", "Trastornos digestivos"]
        p.modalidades = [.consultorio, .enLinea]
        p.cantidadPacientes = 40
        p.conectadas = ["gcal"]
        return p
    }()

    static let perfilPaciente: Perfil = {
        var p = Perfil(lado: .paciente)
        p.nombre = "Sofía"
        p.sexo = .mujer
        p.edad = 36
        p.objetivo = .ordenarme
        p.comoCome = [.salteo, .picoteo]
        p.restricciones = ["Sin lactosa"]
        p.saludConectada = true
        return p
    }()

    // MARK: - Tips

    static let tipsPaciente: [Tip] = [
        Tip(texto: "Una foto alcanza. No hace falta que sea linda.", tema: "Laura"),
        Tip(texto: "Si un día no sale, seguís en la próxima comida.", tema: "Laura"),
        Tip(texto: "Dejá la botella de agua a la vista. Se toma sola.", tema: "Laura"),
        Tip(texto: "Medio plato de verdura y el resto se acomoda.", tema: "Laura"),
        Tip(texto: "Cocinar el domingo te salva el miércoles.", tema: "Laura"),
        Tip(texto: "Comé sentada y sin pantalla. Te llena más.", tema: "Laura"),
        Tip(texto: "La fruta cortada en la heladera se come. La entera, no tanto.", tema: "Laura"),
        Tip(texto: "Un asado con amigos no borra un mes de trabajo.", tema: "Laura"),
        Tip(texto: "Si llegás con mucha hambre a la cena, mirá la merienda.", tema: "Laura"),
        Tip(texto: "El mate cuenta como agua. El azúcar, no.", tema: "Laura"),
        Tip(texto: "Anotá también lo que no salió. Me sirve más que lo perfecto.", tema: "Laura"),
        Tip(texto: "Una lista de compras corta es una semana más fácil.", tema: "Laura"),
        Tip(texto: "Las legumbres llenan, son baratas y rinden en el freezer.", tema: "Laura"),
        Tip(texto: "Dormir bien también es parte del plan.", tema: "Laura"),
        Tip(texto: "Probá una verdura nueva por semana. Una sola.", tema: "Laura"),
        Tip(texto: "El desayuno puede ser simple: algo, y no nada.", tema: "Laura"),
        Tip(texto: "Servite en plato chico. El ojo también come.", tema: "Laura"),
        Tip(texto: "Si tenés antojo de algo dulce, comelo despacio y en un plato.", tema: "Laura"),
        Tip(texto: "Caminar después de cenar ayuda a la digestión.", tema: "Laura"),
        Tip(texto: "Tres días seguidos anotando ya merecen un «bien ahí».", tema: "Laura"),
    ]

    static let tipsNutri: [Tip] = [
        Tip(texto: "Un «bien ahí» a tiempo vale más que un plan nuevo.", tema: "Pacientes"),
        Tip(texto: "Escribile a quien aflojó antes del día 7. Después cuesta más volver.", tema: "Pacientes"),
        Tip(texto: "Los recordatorios del día anterior bajan las faltas a la mitad.", tema: "Agenda"),
        Tip(texto: "Ofrecé el hueco libre a la lista de espera: se llena solo.", tema: "Agenda"),
        Tip(texto: "El plan de 3 meses sostiene más que la consulta suelta.", tema: "Cobros"),
        Tip(texto: "Mandá el link de pago junto con el recordatorio del turno.", tema: "Cobros"),
        Tip(texto: "Actualizá tus precios con aviso: un mes antes, por WhatsApp.", tema: "Cobros"),
        Tip(texto: "Armá modelos de plan y ajustalos por paciente. Ganás horas.", tema: "Planes"),
        Tip(texto: "Platos armados antes que gramos: se entienden en la cocina.", tema: "Planes"),
        Tip(texto: "La curva de medidas motiva más que el número de la balanza.", tema: "Medidas"),
        Tip(texto: "Pedí la foto de verdad, no la perfecta.", tema: "Comidas"),
        Tip(texto: "Revisá las comidas en un solo momento del día, no a cada rato.", tema: "Comidas"),
        Tip(texto: "Tu página con foto y matrícula convierte más consultas nuevas.", tema: "Perfil"),
        Tip(texto: "Contestá con audios cortos: se sienten cercanos y te llevan menos.", tema: "Mensajes"),
        Tip(texto: "Marcá tus horarios de respuesta. Cuidarte también es parte.", tema: "Mensajes"),
        Tip(texto: "Una meta por semana, chica y concreta, se cumple.", tema: "Pacientes"),
        Tip(texto: "Festejá la racha, no el peso.", tema: "Pacientes"),
        Tip(texto: "Cobrá la primera consulta al reservar: casi nadie falta.", tema: "Cobros"),
        Tip(texto: "Dejá una hora libre por día para urgencias y lista de espera.", tema: "Agenda"),
        Tip(texto: "Al cerrar el mes, mirá quién no volvió y escribile.", tema: "Pacientes"),
    ]
}
