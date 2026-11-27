import SwiftUI

/// Tu perfil (y los ajustes): tu nutri, lo tuyo, los avisos y, al pie, la cuenta con «Cerrar sesión».
struct PerfilPaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @Environment(\.openURL) private var abrir

    var body: some View {
        let p = estado.paciente
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Hoy")
            HStack(spacing: 14) {
                Avatar(foto: p.foto, iniciales: "SB", tamano: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Titulo(p.nombre, tamano: 28)
                    Text("Con \(p.nutri.nombre) desde \(Fecha.meses[Fecha.mes(p.desde) - 1])").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                }
            }
            .padding(.horizontal, Espacio.margen)
        } cuerpo: {
            TituloSeccion(texto: "Tu nutri")
            Tarjeta(relleno: 16) {
                HStack(spacing: 12) {
                    Avatar(foto: p.nutri.foto, tamano: 48)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(p.nutri.titulo) \(p.nutri.nombreCompleto)").tipo(.texto(15, 700)).foregroundStyle(Color.texto)
                        Text("Nutricionista · \(p.nutri.matricula)").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        Text(p.nutri.lugar).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    ChipEstado(texto: "Tu nutri", icono: .check, tipo: .ok)
                }
                HStack(spacing: 8) {
                    Boton(titulo: "Mensaje", icono: .mensaje, variante: .suave, alto: .medio, ancho: true) { nav.ir(.laura) }
                    Boton(titulo: "WhatsApp", icono: .wa, variante: .suave, alto: .medio, ancho: true, colorIcono: .whatsapp) {
                        if let u = estado.whatsapp(p.nutri.telefono, "Hola \(p.nutri.nombre), ") { abrir(u) }
                    }
                }
                .padding(.top, 12)
            }
            TituloSeccion(texto: "Lo tuyo")
            Tarjeta {
                fila(.turno, "Tu próxima consulta", p.turno.map { "\(Fecha.diaLargo($0.fecha).capitalized) \(Fecha.dia($0.fecha)) · \($0.hora)" } ?? "Sin turno") { nav.empujar(.turno) }
                Divisor()
                fila(.pago, "Tus pagos", p.contratado != nil ? "Plan 3 meses, al día" : "\(p.pagos.count) pagos") { nav.empujar(.pagos) }
                Divisor()
                fila(.foto, "Tus comidas", "\(estado.comidasConFoto) con foto") { nav.empujar(.historial) }
                Divisor()
                fila(.persona, "Tus datos", "Objetivo, cómo comés, alergias y horarios") { nav.empujar(.tusDatos) }
            }
            TituloSeccion(texto: "Ajustes")
            Tarjeta {
                Fila(alto: 60) {
                    IconoCirculo(icono: .campana, tono: .az)
                    NomSub(nombre: "Avisos", sub: "Turnos y comidas")
                    Interruptor(prendido: Binding(get: { estado.paciente.avisosPrendidos }, set: { estado.prenderAvisosPaciente($0) }), etiqueta: "Avisos")
                }
                Divisor()
                fila(.salud, "Apple Salud", p.saludConectada ? "Conectada · sólo la ve \(p.nutri.nombre)" : "Sin conectar", tono: .salud) { nav.empujar(.salud) }
                Divisor()
                fila(.candado, "Privacidad", "Tus fotos y medidas las ve sólo tu nutri") { nav.empujar(.privacidad) }
                Divisor()
                fila(.ayuda, "Ayuda", "Escribinos y te contestamos") {
                    if let u = URL(string: "mailto:hola@deapoco.com.ar") { abrir(u) }
                }
            }
            SeccionCuenta()
        }
    }

    private func fila(_ i: Icono, _ t: String, _ s: String, tono: IconoCirculo.Tono = .az, accion: @escaping () -> Void) -> some View {
        Button { Haptico.seleccion(); accion() } label: {
            Fila(alto: 60) {
                IconoCirculo(icono: i, tono: tono)
                NomSub(nombre: t, sub: s)
                IconoVista(.chev, tamano: 16).foregroundStyle(Color.salvia400)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
    }
}

/// Tus pagos: lo que pagaste y, si tenés un plan, lo próximo que se cobra.
struct PagosPaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav
    @State private var cancelar = false

    var body: some View {
        let p = estado.paciente
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Volver")
            Cabecera(titulo: "Tus pagos", tamano: 30).padding(.top, -6)
        } cuerpo: {
            if let c = p.contratado, let s = p.servicios.first(where: { $0.id == c }) {
                Tarjeta(relleno: 16) {
                    Etiqueta("Tu plan")
                    HStack(alignment: .lastTextBaseline) {
                        Text(s.nombre).tipo(.texto(17, 700)).foregroundStyle(Color.texto)
                        Spacer()
                        Numero(valor: Formato.plata(s.precioMes), tamano: 20, unidad: " /mes", tamanoUnidad: 13)
                    }
                    .padding(.top, 4)
                    Text("Próximo cobro: \(Fecha.diaMes(Fecha.sumarMeses(1, a: p.turno?.fecha ?? p.hoy))). Se cobra solo.")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 2)
                    Boton(titulo: "Cancelar el plan", variante: .texto, alto: .chico) { cancelar = true }.padding(.top, 4).padding(.leading, -12)
                }
            } else {
                Tarjeta {
                    Fila {
                        IconoCirculo(icono: .pago, tono: .dur)
                        NomSub(nombre: "Con el plan de 3 meses ahorrás", sub: "Y no tenés que pagar cada consulta", lineas: 2)
                        Boton(titulo: "Ver", variante: .suave, alto: .chico) { nav.empujar(.turno) }
                    }
                }
            }
            TituloSeccion(texto: "Pagado")
            if p.pagos.isEmpty {
                Tarjeta { Vacio(titulo: "Todavía no pagaste nada", texto: "Cuando pagues una consulta, el recibo queda acá.", icono: .pago) }
            } else {
                Tarjeta {
                    ForEach(Array(p.pagos.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Divisor() }
                        Fila(alto: 60) {
                            IconoCirculo(icono: .check, tono: .ok)
                            NomSub(nombre: c.concepto, sub: "\(Fecha.diaMes(c.pagadoEl ?? c.fecha)) · \(c.medio?.rawValue ?? "")")
                            Text(Formato.plata(c.monto)).tipo(.texto(15, 700)).monospacedDigit().foregroundStyle(Color.texto)
                        }
                    }
                }
            }
        }
        .confirmationDialog("¿Cancelar el plan?", isPresented: $cancelar, titleVisibility: .visible) {
            Button("Cancelar el plan", role: .destructive) {
                withAnimation { estado.paciente.contratado = nil }
                estado.avisar("Listo. No se cobra más. Lo que pagaste sigue valiendo.")
            }
            Button("Volver", role: .cancel) {}
        } message: { Text("No se cobran más cuotas. Las consultas que ya pagaste siguen valiendo.") }
    }
}

/// Avisos: lo que te mandó la app y tu nutri. Tocar uno te lleva a lo suyo.
struct AvisosPaciente: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav

    var body: some View {
        let avisos = estado.paciente.avisos
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Hoy") {
                if estado.avisosSinLeerPaciente > 0 {
                    Button("Marcar leídos") { estado.leerTodosLosAvisos() }
                        .font(Estilo.texto(15, 600).font()).foregroundStyle(Color.enlace).frame(minHeight: 44)
                }
            }
            Cabecera(titulo: "Avisos", tamano: 30).padding(.top, -6)
        } cuerpo: {
            if avisos.isEmpty {
                Tarjeta { Vacio(titulo: "Estás al día", texto: "Cuando haya algo de tu turno o de tus comidas, te avisamos acá.", icono: .campana) }
            } else {
                Tarjeta {
                    ForEach(Array(avisos.enumerated()), id: \.element.id) { i, a in
                        if i > 0 { Divisor() }
                        Button { abrir(a) } label: {
                            Fila(alto: 64) {
                                IconoCirculo(icono: a.tipo.icono, tono: a.leido ? .crema : .az)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(a.titulo).tipo(.texto(15, a.leido ? 600 : 700)).foregroundStyle(Color.texto)
                                    Text(a.texto).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(Fecha.dias(entre: a.fecha, y: estado.paciente.hoy) == 0 ? a.hora : Fecha.relativa(a.fecha, hoy: estado.paciente.hoy))
                                        .tipo(.texto(12, 600)).monospacedDigit().foregroundStyle(Color.texto2)
                                    if !a.leido { Circle().fill(Color.acento).frame(width: 8, height: 8).accessibilityLabel("Sin leer") }
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(Apretable())
                    }
                }
            }
        }
    }

    private func abrir(_ a: AvisoApp) {
        Haptico.seleccion()
        estado.marcarAvisoLeido(a.id)
        switch a.tipo {
        case .comida: nav.cubierta = .foto(estado.proximaComida, muestra: false)
        case .mensaje: nav.ir(.laura)
        case .turno, .pago: nav.empujar(.turno)
        case .logro: nav.pestana = .avance; nav.avance = [.logros]
        case .plan: nav.pestana = .plan
        case .sistema: break
        }
    }
}

/// Apple Salud: qué se lee, quién lo ve y el interruptor.
struct SaludPaciente: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let p = estado.paciente
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Perfil")
            Cabecera(titulo: "Apple Salud", tamano: 30).padding(.top, -6)
        } cuerpo: {
            Tarjeta {
                Fila(alto: 64) {
                    IconoCirculo(icono: .salud, tono: .salud)
                    NomSub(nombre: "Pasos y sueño", sub: "Sólo para \(p.nutri.nombre)")
                    Interruptor(prendido: Binding(get: { estado.paciente.saludConectada }, set: { estado.conectarSalud($0) }), etiqueta: "Apple Salud")
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                punto("Leemos sólo pasos y horas de sueño. Nada más.")
                punto("Lo ve \(p.nutri.nombre) en tu ficha, como promedio de la semana.")
                punto("No compartimos nada con nadie. Lo apagás cuando quieras.")
            }
            .padding(.top, 6)
            if p.saludConectada {
                Tarjeta {
                    HStack(spacing: 0) {
                        dato("Pasos", Formato.entero(p.pasos), " por día")
                        Rectangle().fill(Color.borde).frame(width: 1)
                        dato("Sueño", "\(p.sueno / 60) h \(p.sueno % 60)", " min")
                    }
                }
            }
        }
    }

    private func punto(_ t: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconoVista(.check, tamano: 20).foregroundStyle(Color.ok)
            Text(t).tipo(.texto(15, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func dato(_ e: String, _ v: String, _ u: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Etiqueta(e)
            Numero(valor: v, tamano: 22, color: .texto, unidad: u, tamanoUnidad: 13)
        }
        .padding(.horizontal, 16).padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Privacidad: quién ve qué, bajar tus datos y borrar la cuenta.
struct PrivacidadPaciente: View {
    @Environment(Estado.self) private var estado
    @AppStorage("lado") private var lado = ""
    @State private var borrar = false

    var body: some View {
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Perfil")
            Cabecera(titulo: "Privacidad", tamano: 30).padding(.top, -6)
        } cuerpo: {
            Tarjeta(relleno: 16) {
                HStack(alignment: .top, spacing: 10) {
                    IconoVista(.candado, tamano: 20).foregroundStyle(Color.marca)
                    Text("Tus fotos, tus medidas y tus mensajes los ve sólo \(estado.paciente.nutri.nombre). Nadie más.")
                        .tipo(.texto(15, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .top, spacing: 10) {
                    IconoVista(.escudo, tamano: 20).foregroundStyle(Color.marca)
                    Text("Tus datos están registrados ante la AAIP (Ley 25.326). Podés pedirlos o borrarlos cuando quieras.")
                        .tipo(.texto(15, 400)).foregroundStyle(Color.texto).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
            }
            Tarjeta {
                ShareLink(item: estado.exportarDatosPaciente()) {
                    Fila(alto: 60) {
                        IconoCirculo(icono: .bajar, tono: .az)
                        NomSub(nombre: "Bajar mis datos", sub: "Un archivo con todo lo tuyo")
                        IconoVista(.chev, tamano: 16).foregroundStyle(Color.salvia400)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
                Divisor()
                Button { Haptico.seleccion(); borrar = true } label: {
                    Fila(alto: 60) {
                        IconoVista(.basura, tamano: 20).foregroundStyle(Color.error).frame(width: 40, height: 40).background(Color.errorFondo, in: Circle())
                        NomSub(nombre: "Borrar mi cuenta", sub: "Se borra todo en 30 días", colorSub: .texto2)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
            }
        }
        .confirmationDialog("¿Borrar tu cuenta?", isPresented: $borrar, titleVisibility: .visible) {
            Button("Borrar mi cuenta", role: .destructive) {
                estado.avisar("Listo. Tu cuenta se borra en 30 días.")
                withAnimation { estado.borrarPerfil(); lado = "" }
            }
            Button("Volver", role: .cancel) {}
        } message: { Text("Se borran tus fotos, medidas y mensajes. \(estado.paciente.nutri.nombre) deja de verlos.") }
    }
}

/// Tus datos: lo del inicio (objetivo, cómo comés, alergias y horarios), para corregirlo.
struct TusDatos: View {
    @Environment(Estado.self) private var estado
    @State private var perfil = DatosDeMuestra.perfilPaciente
    @State private var cargado = false

    var body: some View {
        PantallaPaciente(abajo: 120) {
            NavAtras(atras: "Perfil")
            Cabecera(titulo: "Tus datos", tamano: 30).padding(.top, -6)
        } cuerpo: {
            Etiqueta("Cómo te llamás")
            TextField("", text: $perfil.nombre, prompt: Text("Tu nombre").foregroundColor(.texto2))
                .font(Estilo.texto(17, 600).font()).foregroundStyle(Color.texto)
                .padding(.horizontal, 14).frame(height: 52)
                .background(Color.superficie, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.borde, lineWidth: 1))
            Etiqueta("Qué querés lograr").padding(.top, 8)
            Fluir(espacio: 8) {
                ForEach(ObjetivoNutri.allCases, id: \.self) { o in
                    ChipOpcion(titulo: o.titulo, elegido: perfil.objetivo == o) { perfil.objetivo = o }
                }
            }
            Etiqueta("Cómo comés hoy").padding(.top, 8)
            Fluir(espacio: 8) {
                ForEach(ComoCome.allCases, id: \.self) { c in
                    ChipOpcion(titulo: c.titulo, elegido: perfil.comoCome.contains(c)) {
                        if let i = perfil.comoCome.firstIndex(of: c) { perfil.comoCome.remove(at: i) } else { perfil.comoCome.append(c) }
                    }
                }
            }
            Etiqueta("Restricciones y alergias").padding(.top, 8)
            Fluir(espacio: 8) {
                ForEach(restriccionesComunes, id: \.self) { r in
                    ChipOpcion(titulo: r, elegido: perfil.restricciones.contains(r)) {
                        if let i = perfil.restricciones.firstIndex(of: r) { perfil.restricciones.remove(at: i) } else { perfil.restricciones.append(r) }
                    }
                }
            }
            Etiqueta("Tus horarios").padding(.top, 8)
            Tarjeta {
                ForEach(Array(Momento.principales.enumerated()), id: \.element) { i, m in
                    if i > 0 { Divisor() }
                    Fila(alto: 56, vertical: 6) {
                        Text(m.titulo).tipo(.texto(15, 600)).foregroundStyle(Color.texto).frame(maxWidth: .infinity, alignment: .leading)
                        if let h = perfil.horarios[m] {
                            Boton(titulo: "", icono: .menos, variante: .crema, alto: .chico) { mover(m, -30) }
                                .accessibilityLabel("Más temprano")
                            Text(h).font(Estilo.texto(16, 600).font()).monospacedDigit().foregroundStyle(Color.texto).frame(width: 56)
                            Boton(titulo: "", icono: .mas, variante: .crema, alto: .chico) { mover(m, 30) }
                                .accessibilityLabel("Más tarde")
                        } else {
                            Boton(titulo: "No la hago", variante: .crema, alto: .chico) { perfil.horarios[m] = m.horaSugerida }
                        }
                    }
                }
            }
            Boton(titulo: "Guardar", variante: .prim, alto: .alto, ancho: true) {
                var p = perfil
                p.nombre = p.nombre.trimmingCharacters(in: .whitespaces)
                estado.guardarPerfil(p)
                Haptico.exito()
                estado.avisar("Guardado. Se lo contamos a \(estado.paciente.nutri.nombre).")
            }
            .padding(.top, 12)
        }
        .onAppear {
            guard !cargado else { return }
            cargado = true
            if let p = estado.perfil, p.lado == .paciente { perfil = p }
        }
    }

    private func mover(_ m: Momento, _ d: Int) {
        guard let h = perfil.horarios[m] else { return }
        let n = Fecha.minutos(h) + d
        Haptico.seleccion()
        perfil.horarios[m] = Fecha.hora(min(max(n, 5 * 60), 23 * 60 + 30))
    }
}

/// Tus comidas: todo lo anotado, por día, con la foto. Tocar una la abre.
struct HistorialComidas: View {
    @Environment(Estado.self) private var estado
    @Environment(NavPaciente.self) private var nav

    var body: some View {
        let dias = Dictionary(grouping: estado.paciente.registros, by: \.fecha).sorted { $0.key > $1.key }
        PantallaPaciente(abajo: 40) {
            NavAtras(atras: "Volver")
            Cabecera(fecha: "\(estado.comidasConFoto) con foto", titulo: "Tus comidas", tamano: 30).padding(.top, -6)
        } cuerpo: {
            if dias.isEmpty {
                Tarjeta {
                    Vacio(titulo: "Todavía no anotaste nada", texto: "Sacale una foto a la próxima comida. Con eso alcanza.", accion: "Sacar foto") {
                        nav.cubierta = .foto(estado.proximaComida, muestra: false)
                    }
                }
            }
            ForEach(dias, id: \.key) { fecha, rs in
                Etiqueta(Fecha.dias(entre: fecha, y: estado.paciente.hoy) <= 1 ? Fecha.relativa(fecha, hoy: estado.paciente.hoy) : Fecha.larga(fecha)).padding(.top, 6)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(rs.sorted { $0.hora < $1.hora }) { r in
                        Button { Haptico.seleccion(); nav.hoja = .registro(r.id) } label: {
                            FotoComida(foto: r.foto, lado: 80, radio: 14, icono: .plan)
                                .frame(maxWidth: .infinity)
                                .overlay(alignment: .bottomLeading) {
                                    Text(r.momento.titulo.prefix(3)).tipo(.texto(11, 700)).foregroundStyle(Color.verde900)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 7)).padding(6)
                                }
                        }
                        .buttonStyle(Apretable())
                        .accessibilityLabel("\(r.momento.titulo): \(r.descripcion)")
                    }
                }
            }
        }
    }
}
