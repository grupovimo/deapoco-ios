import SwiftUI

/// La app de la nutri. (Esqueleto: la arma la tanda de pantallas de la nutri.)
struct RaizNutri: View {
    var pantalla: String?
    @State private var tab = 0
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Banda {
                        Cabecera(fecha: "Martes 25 de noviembre", titulo: "Hoy atendés a\u{00A0}seis.") {
                            Redondo(icono: .mensaje, badge: 4, etiqueta: "Mensajes") {}
                        }
                        HStack(spacing: 16) {
                            Plato(partes: 6, llenas: 2, hoy: 2, servir: true).frame(width: 112, height: 112)
                            VStack(alignment: .leading, spacing: 0) {
                                Etiqueta("Ahora · en 18 min", color: .durazno)
                                Text("Sofía Benítez").tipo(.texto(19, 600)).foregroundStyle(Color.mantecaFija).padding(.top, 4)
                                Text("11:30 · control en línea").tipo(.texto(14, 400)).foregroundStyle(Color.sobreBanda2).padding(.top, 2)
                                Boton(titulo: "Abrir la consulta", icono: .video, variante: .man, alto: .chico) {}.padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 18)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        TituloSeccion(texto: "Para hacer hoy", dato: "3")
                        Tarjeta {
                            Fila { Avatar(foto: "av-martin"); NomSub(nombre: "Martín no anota hace diez días.", sub: "¿Le escribís hoy?", lineas: 2); BotonWA {} }
                            Divisor()
                            Fila { IconoCirculo(icono: .reloj, tono: .aviso); NomSub(nombre: "2 sin confirmar", sub: "Julián y Rocío, para hoy"); Boton(titulo: "Recordar", variante: .suave, alto: .chico) {} }
                        }
                        Titulo("Laura te sumó a De\u{00A0}a\u{00A0}Poco.", tamano: 34)
                        Text("Tu plan, tus turnos y los mensajes con ella, en un lugar.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2)
                        HStack { Plato(partes: 7, llenas: 7, chico: true).frame(width: 30); Porciones(hechas: 3, total: 5); Vasos(tomados: 5) }
                        Curva(valores: [94,93.4,92.6,92.8,91.5,90.4,90.1,89.2,88.5,88], etiquetas: ["AGO","","SEP","","","OCT","","","NOV",""])
                        HStack { PlatoArmado().frame(width: 96); Dona(segmentos: [(19, .durazno), (6, .enlozado300), (2, .mantecaFija)], porcentaje: 79).background(Color.enlozado800) }
                        ChipEstado(texto: "Confirmó", icono: .check, tipo: .ok)
                        BannerGrupo(.movimiento, titulo: "¿Querés sumar movimiento?", texto: "Entrená con un profe.")
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 120)
                }
            }
            .background(Color.fondo)
            .barraClara()
            BarraMesa(izquierda: [ItemMesa(id: 0, titulo: "Hoy", icono: .inicio), ItemMesa(id: 1, titulo: "Agenda", icono: .turno)],
                      derecha: [ItemMesa(id: 2, titulo: "Pacientes", icono: .gente), ItemMesa(id: 3, titulo: "Cobros", icono: .pago, badge: 1)],
                      elegida: $tab, iconoPlato: .mas, etiquetaPlato: "Acción rápida", alTocarPlato: {})
        }
    }
}
