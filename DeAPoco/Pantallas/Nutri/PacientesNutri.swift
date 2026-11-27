import SwiftUI

/// Pacientes (p20): quién viene bien y quién aflojó, con búsqueda. Nunca ordena por peso: por lo que anotan.
struct ListaPacientes: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @State private var busca = ""
    @State private var filtro: Ritmo?

    var body: some View {
        PantallaBandaN(abajoBanda: 16) {
            CabeceraBanda(titulo: "Pacientes", dato: "\(estado.pacientesActivos.count) activos")
            BuscadorBanda(texto: $busca)
            ResumenRitmo(filtro: $filtro)
        } cuerpo: {
            if !busca.isEmpty {
                resultados
            } else {
                ForEach(orden, id: \.self) { r in
                    let lista = estado.pacientes(r)
                    if !lista.isEmpty && (filtro == nil || filtro == r) {
                        TituloSeccion(texto: titulo(r), dato: "\(lista.count)")
                        Tarjeta {
                            ForEach(Array(lista.enumerated()), id: \.element.id) { i, p in
                                if i > 0 { Divisor() }
                                FilaPacienteN(paciente: p)
                            }
                        }
                    }
                }
                let pausados = estado.nutri.pacientes.filter { $0.estado != .activo }
                if !pausados.isEmpty && filtro == nil {
                    TituloSeccion(texto: "En pausa", dato: "\(pausados.count)")
                    Tarjeta {
                        ForEach(Array(pausados.enumerated()), id: \.element.id) { i, p in
                            if i > 0 { Divisor() }
                            FilaPacienteN(paciente: p)
                        }
                    }
                }
                Boton(titulo: "Sumar paciente", icono: .mas, variante: .suave, alto: .medio, ancho: true) {
                    nav.hoja = estado.puedeSumarPaciente ? .nuevoPaciente : .tope("")
                }
                .padding(.top, 8)
            }
        }
    }

    private var orden: [Ritmo] { [.aflojo, .medias, .bien] }

    private func titulo(_ r: Ritmo) -> String {
        switch r { case .aflojo: return "Aflojaron esta semana"; case .medias: return "A medias"; case .bien: return "Vienen bien" }
    }

    @ViewBuilder private var resultados: some View {
        let lista = estado.nutri.pacientes.filter { $0.nombre.localizedCaseInsensitiveContains(busca) }
        TituloSeccion(texto: "Resultados", dato: "\(lista.count)")
        Tarjeta {
            if lista.isEmpty {
                Vacio(titulo: "No hay nadie con ese nombre", texto: "¿Es alguien nuevo?", accion: "Sumarlo como paciente") { nav.hoja = .nuevoPaciente }
            }
            ForEach(Array(lista.enumerated()), id: \.element.id) { i, p in
                if i > 0 { Divisor() }
                FilaPacienteN(paciente: p)
            }
        }
    }
}

/// El buscador sobre la banda (.busca).
private struct BuscadorBanda: View {
    @Binding var texto: String
    var body: some View {
        HStack(spacing: 8) {
            IconoVista(.buscar, tamano: 20).foregroundStyle(Color.sobreBanda2)
            TextField("", text: $texto, prompt: Text("Buscar por nombre").foregroundColor(.sobreBanda2))
                .font(Estilo.texto(15, 400).font())
                .foregroundStyle(Color.crema)
                .tint(Color.mandarina)
                .autocorrectionDisabled()
            if !texto.isEmpty {
                Button { texto = "" } label: {
                    IconoVista(.x, tamano: 16).foregroundStyle(Color.sobreBanda2).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Borrar la búsqueda")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.vidrio12, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 14)
    }
}

/// Los tres números (.resumen-s): vienen bien, a medias y aflojaron (en mandarina, para mirar).
private struct ResumenRitmo: View {
    @Binding var filtro: Ritmo?
    @Environment(Estado.self) private var estado

    var body: some View {
        HStack(spacing: 8) {
            ForEach([Ritmo.bien, .medias, .aflojo], id: \.self) { r in
                let ojo = r == .aflojo
                let on = filtro == r
                Button {
                    Haptico.seleccion()
                    withAnimation(.snappy) { filtro = on ? nil : r }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(estado.pacientes(r).count)").tipo(.numero(24))
                        Text(r.titulo).tipo(.texto(12.5, 600)).lineLimit(1)
                    }
                    .foregroundStyle(ojo ? Color.verde900 : Color.crema)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ojo ? Color.mandarina : Color.crema.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(on ? Color.crema : .clear, lineWidth: 2))
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("\(estado.pacientes(r).count) \(r.titulo)")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }
}

/// Un paciente (.pac .fila): foto, cómo viene, su platito de la semana y una acción según cómo viene.
struct FilaPacienteN: View {
    let paciente: Paciente
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @Environment(\.openURL) private var abrir

    var body: some View {
        let p = paciente
        HStack(spacing: 10) {
            Button { Haptico.seleccion(); nav.abrir(.ficha(p.id)) } label: {
                HStack(spacing: 10) {
                    Avatar(foto: p.foto, iniciales: p.iniciales, tono: p.tono)
                    NomSub(nombre: p.nombre, sub: p.estado == .activo ? p.resumenRitmo : p.estado.titulo)
                    Gajos(partes: 7, llenas: p.diasSemana, ahora: .no, chico: true).frame(width: 34, height: 34)
                        .accessibilityLabel("\(p.diasSemana) de 7 días")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
            if p.ritmo == .bien {
                Boton(titulo: "Bien ahí", icono: .bocado, variante: .crema, alto: .chico, colorIcono: .acento) { estado.mandarBienAhi(p.id) }
                    .accessibilityLabel("Mandarle un bien ahí a \(p.primerNombre)")
            } else {
                BotonWA(titulo: "Escribile") {
                    if let u = estado.whatsapp(p.telefono, "Hola \(p.primerNombre), ¿cómo venís? Si la semana se complicó, no pasa nada: seguimos de a poco.") { abrir(u) }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(minHeight: 66)
    }
}

// MARK: - Sumar paciente

struct HojaPacienteNuevo: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav
    @Environment(\.dismiss) private var cerrar
    @State private var nombre = ""
    @State private var telefono = ""
    @State private var servicio = "plan3"
    @State private var objetivo = ""

    var body: some View {
        HojaBaseN(titulo: "Sumar paciente", bajada: "Le mandamos una invitación para que baje la app y vea su plan.") {
            CampoN(etiqueta: "Nombre y apellido", texto: $nombre, prompt: "Martina Correa", icono: .persona)
            CampoN(etiqueta: "WhatsApp", texto: $telefono, prompt: "+54 223 …", icono: .wa, teclado: .phonePad)
            CampoN(etiqueta: "Qué quiere lograr", texto: $objetivo, prompt: "Comer más ordenado", icono: .brote)
            Etiqueta("Qué contrata").padding(.top, 4)
            VStack(spacing: 8) {
                ForEach(estado.nutri.servicios) { s in
                    OpcionServicioN(servicio: s, elegido: servicio == s.id) { servicio = s.id }
                }
            }
            HStack(spacing: 8) {
                IconoVista(.candado, tamano: 16).foregroundStyle(Color.marca)
                Text("Sus fotos y medidas las ves sólo vos.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
            }
            .padding(.top, 4)
            if estado.activos >= estado.tope - 3 {
                ChipEstado(texto: "Te quedan \(max(0, estado.tope - estado.activos)) lugares en \(estado.planActual.nombre)", icono: .aviso, tipo: .aviso)
            }
        } pie: {
            PieHojaN {
                Boton(titulo: "Sumarlo y mandar la invitación", icono: .wa, variante: .prim, alto: .alto, ancho: true,
                      colorIcono: .mandarina, habilitado: nombre.trimmingCharacters(in: .whitespaces).count >= 3) {
                    if let id = estado.crearPaciente(nombre: nombre, telefono: telefono, servicioId: servicio,
                                                     objetivo: objetivo.isEmpty ? "A definir en la primera consulta" : objetivo) {
                        cerrar()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nav.abrirFicha(id) }
                    } else {
                        nav.hoja = .tope(nombre)
                    }
                }
            }
        }
    }
}

/// Opción de servicio (.opc): blanca, la elegida con borde verde y el círculo con tilde.
struct OpcionServicioN: View {
    let servicio: Servicio
    let elegido: Bool
    var accion: () -> Void

    var body: some View {
        Button { Haptico.seleccion(); withAnimation(.snappy(duration: 0.2)) { accion() } } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(servicio.nombre).tipo(.texto(15, 700)).foregroundStyle(Color.texto)
                    Text(servicio.detalle).tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                }
                Spacer()
                Text(Formato.plata(servicio.monto)).tipo(.numero(16)).foregroundStyle(Color.titulo)
                CirculoElegirN(elegido: elegido)
            }
            .padding(14)
            .background(elegido ? Color.infoSuave : Color.superficie, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(elegido ? Color.marca : Color.borde, lineWidth: elegido ? 2.5 : 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}

/// El círculo de elegir (.radio).
struct CirculoElegirN: View {
    let elegido: Bool
    var body: some View {
        ZStack {
            if elegido {
                Circle().fill(Color.marca)
                IconoVista(.check, tamano: 14, grosor: 2.8).foregroundStyle(Color.sobreMarca)
            } else {
                Circle().strokeBorder(Color.salvia400, lineWidth: 2)
            }
        }
        .frame(width: 22, height: 22)
    }
}
