import SwiftUI

/// Lo que va al pie de Ajustes en los dos lados: apariencia, ver el otro lado (es una maqueta), rehacer el inicio
/// y «Cerrar sesión», siempre a la vista.
struct SeccionCuenta: View {
    @Environment(Estado.self) private var estado
    @AppStorage("lado") private var lado = ""
    @AppStorage("apariencia") private var apariencia = Apariencia.sistema.rawValue
    @State private var confirmarSalida = false
    @Environment(\.dismiss) private var cerrar

    private var otro: Lado { lado == Lado.nutri.rawValue ? .paciente : .nutri }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "Apariencia")
            Tarjeta {
                Fila(alto: 60) {
                    IconoCirculo(icono: apariencia == Apariencia.oscuro.rawValue ? .luna : .sol, tono: .az)
                    NomSub(nombre: "Modo", sub: "Automático sigue al teléfono")
                    MiniSeg(opciones: Apariencia.allCases.map { ($0.rawValue, $0.titulo) }, elegida: $apariencia)
                }
            }
            TituloSeccion(texto: "Tu cuenta")
            Tarjeta {
                botonFila(.vuelta, otro == .paciente ? "Ver la app del paciente" : "Ver la app de la nutri",
                          "Es una maqueta: mirá los dos lados") {
                    withAnimation(.easeInOut(duration: 0.3)) { lado = otro.rawValue }
                    cerrar()
                }
                Divisor()
                botonFila(.girar, "Rehacer el inicio", "Volvés a las preguntas del principio") {
                    withAnimation { estado.borrarPerfil(); lado = "" }
                }
                Divisor()
                Button { Haptico.seleccion(); confirmarSalida = true } label: {
                    Fila(alto: 56) {
                        IconoVista(.salir, tamano: 20).foregroundStyle(Color.error).frame(width: 40, height: 40)
                            .background(Color.errorFondo, in: Circle())
                        Text("Cerrar sesión").tipo(.texto(15, 600)).foregroundStyle(Color.error)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
            }
            Text("De a Poco 1.0 · de Grupo Vimo")
                .tipo(.texto(12, 400)).foregroundStyle(Color.texto2)
                .frame(maxWidth: .infinity).padding(.top, 8)
        }
        .confirmationDialog("¿Cerrar sesión?", isPresented: $confirmarSalida, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive) {
                withAnimation { estado.borrarPerfil(); lado = "" }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tus datos quedan guardados. Para volver, entrás con tu cuenta.")
        }
    }

    private func botonFila(_ icono: Icono, _ titulo: String, _ sub: String, accion: @escaping () -> Void) -> some View {
        Button { Haptico.seleccion(); accion() } label: {
            Fila(alto: 60) {
                IconoCirculo(icono: icono, tono: .az)
                NomSub(nombre: titulo, sub: sub)
                IconoVista(.chev, tamano: 16).foregroundStyle(Color.salvia400)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
    }
}
