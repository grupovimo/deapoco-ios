import SwiftUI

/// Una pestaña de la barra «la mesa».
struct ItemMesa<T: Hashable>: Identifiable {
    let id: T
    let titulo: String
    let icono: Icono
    var badge: Int = 0
}

/// La barra «la mesa» (.mesa-nav): blanca, de borde a borde, con el ala del plato arriba. En el centro, el plato:
/// un gajo naranja hecho botón. La pestaña activa va sobre naranja 100.
/// Grilla 1fr 1fr 84 1fr 1fr, 90 de alto con el indicador de inicio.
struct BarraMesa<T: Hashable>: View {
    let izquierda: [ItemMesa<T>]
    let derecha: [ItemMesa<T>]
    @Binding var elegida: T
    var iconoPlato: Icono
    var etiquetaPlato: String
    var cerrar = false
    var alTocarPlato: () -> Void
    var alTocarActual: (T) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(izquierda) { item($0) }
            Color.clear.frame(width: 84)
            ForEach(derecha) { item($0) }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .frame(height: 64, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) { FondoMesa() }
        .overlay(alignment: .top) {
            PlatoBoton(icono: iconoPlato, etiqueta: etiquetaPlato, cerrar: cerrar, accion: alTocarPlato)
                .offset(y: -22)
        }
    }

    private func item(_ it: ItemMesa<T>) -> some View {
        let on = it.id == elegida
        return Button {
            if on { alTocarActual(it.id) } else { Haptico.seleccion(); elegida = it.id }
        } label: {
            VStack(spacing: 3) {
                IconoVista(it.icono, tamano: 24)
                    .frame(width: 48, height: 30)
                    .background(on ? Color.logroSuave : .clear, in: Capsule())
                    .overlay(alignment: .topTrailing) {
                        if it.badge > 0 { Badge(n: it.badge, aro: .superficie).offset(x: -2, y: -2) }
                    }
                Text(it.titulo)
                    .font(Estilo.texto(11.5, on ? 700 : 600).font())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(on ? Color.titulo : Color.texto2)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(it.badge > 0 ? "\(it.titulo), \(it.badge) sin leer" : it.titulo)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }
}

/// El fondo blanco con el radio de arriba, la sombra cálida y el ala (la línea crema 300 de arriba).
private struct FondoMesa: View {
    @Environment(\.colorScheme) private var esquema
    var body: some View {
        let forma = UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
        forma
            .fill(Color.superficie)
            .shadow(color: esquema == .dark ? .black.opacity(0.3) : Color.salvia700.opacity(0.10), radius: 17, y: -14)
            .overlay(alignment: .top) {
                forma.stroke(Color.borde, lineWidth: 1).mask(alignment: .top) { Rectangle().frame(height: 14) }
            }
            .overlay(alignment: .top) {
                Capsule().fill(esquema == .dark ? Color(hex: 0x24503D) : Color.superficie2.opacity(0.9)).frame(height: 3)
                    .padding(.horizontal, 22).padding(.top, 5)
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(height: 200, alignment: .top)
    }
}

/// El botón del centro (.plato-b): un gajo hecho botón. 66, naranja 500 con aro de 6 del color de la barra e ícono
/// verde; para cerrar, verde con el ícono crema.
struct PlatoBoton: View {
    let icono: Icono
    let etiqueta: String
    var cerrar = false
    var accion: () -> Void
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Button(action: { Haptico.suave(); accion() }) {
            ZStack {
                Circle().fill(Color.superficie).frame(width: 78, height: 78)
                Circle().fill(cerrar ? Color.verde900 : Color.naranja500)
                    .frame(width: 66, height: 66)
                    .shadow(color: esquema == .dark ? .black.opacity(0.35) : Color.naranja600.opacity(0.30), radius: 11, y: 10)
                IconoVista(cerrar ? .x : icono, tamano: 28, grosor: 2.4)
                    .foregroundStyle(cerrar ? Color.crema : Color.verde900)
                    .contentTransition(.symbolEffect)
            }
            .frame(width: 80, height: 80)
            .contentShape(Circle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(cerrar ? "Cerrar" : etiqueta)
    }
}
