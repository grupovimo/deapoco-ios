import SwiftUI

/// Acción rápida (p8): la hoja «¿Qué hacemos?» sobre el inicio desenfocado, con el plato en cruz.
struct MenuRapido: View {
    @Environment(Estado.self) private var estado
    @Environment(NavNutri.self) private var nav

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Titulo("¿Qué hacemos?", tamano: 26).padding(.horizontal, 4)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                tile(.turno, "Dar un turno", "Le llega por WhatsApp", .az) { nav.hoja = .darTurno(paciente: nil, fecha: nil, hora: nil) }
                tile(.pago, "Cobrar", "Link de Mercado Pago", .az) { nav.hoja = .cobrar(nil) }
                tile(.persona, "Sumar paciente", "Con su ficha", .dur) { nav.hoja = estado.puedeSumarPaciente ? .nuevoPaciente : .tope("") }
                tile(.plan, "Armar un plan", "Desde un modelo", .dur) { nav.hoja = .elegirPaciente(.plan) }
                tile(.cinta, "Anotar medidas", "Cintura y cadera", .az) { nav.hoja = .elegirPaciente(.medidas) }
                tile(.mensaje, "Mensaje", "A uno o a varios", .dur) { nav.hoja = .mensajeVarios }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .background {
            // La sombra va en la forma, no en el contenido: si no, cada tarjeta proyecta la suya sobre la hoja.
            RoundedRectangle(cornerRadius: Radio.hoja, style: .continuous).fill(Color.fondo)
                .shadow(color: Color.verde950.opacity(0.35), radius: 30, y: 30)
        }
    }

    private func tile(_ i: Icono, _ t: String, _ s: String, _ tono: IconoCirculo.Tono, _ accion: @escaping () -> Void) -> some View {
        Button {
            Haptico.seleccion()
            withAnimation(.spring(duration: 0.3)) { nav.menuAbierto = false }
            accion()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                IconoCirculo(icono: i, tono: tono)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t).tipo(.texto(16, 700)).foregroundStyle(Color.texto).lineLimit(1).minimumScaleFactor(0.85)
                    Text(s).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(1).minimumScaleFactor(0.85)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.superficie, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .sombraChica()
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
    }
}

/// Para «Armar un plan» y «Anotar medidas» desde el plato: primero, a quién.
struct HojaElegirPaciente: View {
    let accion: AccionRapida
    @Environment(NavNutri.self) private var nav
    @Environment(\.dismiss) private var cerrar
    @State private var elegido: String?
    @State private var modelo: String?
    @Environment(Estado.self) private var estado

    var body: some View {
        HojaBaseN(titulo: accion == .plan ? "Armar un plan" : "Anotar medidas",
                 bajada: accion == .plan ? "¿Para quién? Arrancás desde un modelo o desde su plan anterior." : "¿De quién? Nunca balanza: la curva.") {
            SelectorPacienteN(elegido: $elegido)
            if accion == .plan {
                Etiqueta("Desde").padding(.top, 4)
                Fluir(espacio: 8) {
                    ChipOpcion(titulo: "Su plan anterior", elegido: modelo == nil) { modelo = nil }
                    ForEach(estado.modelosDePlan) { m in ChipOpcion(titulo: m.nombre, elegido: modelo == m.id) { modelo = m.id } }
                }
            }
        } pie: {
            PieHojaN {
                Boton(titulo: "Seguir", iconoDerecha: .flecha, variante: .prim, alto: .alto, ancho: true, habilitado: elegido != nil) {
                    guard let p = elegido else { return }
                    if accion == .plan {
                        cerrar()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { nav.cubierta = .armarPlan(paciente: p, modelo: modelo) }
                    } else {
                        nav.hoja = .anotarMedidas(p)
                    }
                }
            }
        }
    }
}

/// Un mensaje a uno o a varios (por cómo vienen, o a todos).
struct HojaMensajeVarios: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var cerrar
    @State private var grupo = "aflojo"
    @State private var texto = "Hola, ¿cómo venís con las comidas? Si la semana se complicó, no pasa nada: seguimos de a poco."

    var body: some View {
        HojaBaseN(titulo: "Mensaje", bajada: "Les llega en De a Poco y por WhatsApp.") {
            Etiqueta("A quiénes")
            Pastillas(opciones: [("aflojo", "Aflojaron (\(estado.pacientes(.aflojo).count))"), ("medias", "A medias (\(estado.pacientes(.medias).count))"),
                                 ("bien", "Vienen bien (\(estado.pacientes(.bien).count))"), ("todos", "Todos (\(estado.pacientesActivos.count))")],
                      elegida: $grupo)
            CampoN(etiqueta: "Mensaje", texto: $texto, prompt: "Escribí algo corto", multilinea: true)
            Fluir(espacio: 8) {
                ForEach(["¡Bien ahí esta semana!", "Mañana no atiendo: reprogramamos.", "Ya está tu plan nuevo."], id: \.self) { t in
                    ChipOpcion(titulo: t, elegido: texto == t, alto: 36) { texto = t }
                }
            }
        } pie: {
            PieHojaN {
                Boton(titulo: "Mandarlo a \(ids.count)", icono: .enviar, variante: .prim, alto: .alto, ancho: true,
                      habilitado: !ids.isEmpty && !texto.trimmingCharacters(in: .whitespaces).isEmpty) {
                    estado.mensajeAVarios(ids, texto); cerrar()
                }
            }
        }
    }

    private var ids: [String] {
        switch grupo {
        case "aflojo": return estado.pacientes(.aflojo).map(\.id)
        case "medias": return estado.pacientes(.medias).map(\.id)
        case "bien": return estado.pacientes(.bien).map(\.id)
        default: return estado.pacientesActivos.map(\.id)
        }
    }
}
