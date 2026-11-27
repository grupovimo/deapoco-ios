import SwiftUI
import UIKit

// MARK: - Banda

/// La banda verde de arriba (lado de la nutri): radio 28 abajo, 20 de aire al pie, y se extiende detrás de la
/// barra de estado (también al estirar la lista hacia abajo).
struct Banda<Contenido: View>: View {
    var abajo: CGFloat = 20
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contenido()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, abajo)
        .background(alignment: .bottom) {
            UnevenRoundedRectangle(bottomLeadingRadius: Radio.banda, bottomTrailingRadius: Radio.banda, style: .continuous)
                .fill(Color.banda)
                .padding(.top, -1200)
        }
        .environment(\.sobreBanda, true)
    }
}

private struct SobreBandaClave: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    /// Dentro de la banda verde: los controles cambian a crema y vidrio.
    var sobreBanda: Bool {
        get { self[SobreBandaClave.self] }
        set { self[SobreBandaClave.self] = newValue }
    }
}

// MARK: - Tarjeta y filas

/// Tarjeta blanca (superficie), radio 20, sombra cálida; en oscuro, con borde.
struct Tarjeta<Contenido: View>: View {
    var relleno: CGFloat = 0
    var radio: CGFloat = Radio.tarjeta
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { contenido() }
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.superficie, in: RoundedRectangle(cornerRadius: radio, style: .continuous))
            .sombraTarjeta(radio: radio)
    }
}

/// Divisor de 1 entre filas (salvia-200).
struct Divisor: View {
    var body: some View { Rectangle().fill(Color.borde).frame(height: 1) }
}

/// La fila (.fila): 12 entre piezas, 12/16 de relleno, 64 de alto mínimo.
struct Fila<Contenido: View>: View {
    var alto: CGFloat = 64
    var vertical: CGFloat = 12
    var horizontal: CGFloat = 16
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        HStack(spacing: 12) { contenido() }
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
            .frame(minHeight: alto)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Nombre y bajada de una fila (.txt b + span): 15/600 y 13 secundario.
struct NomSub: View {
    let nombre: String
    var sub: String? = nil
    var colorSub: Color = .texto2
    var pesoSub: CGFloat = 400
    var lineas = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(nombre).tipo(.texto(15, 600)).foregroundStyle(Color.texto).lineLimit(lineas)
                .fixedSize(horizontal: false, vertical: lineas > 1)
            if let sub {
                Text(sub).tipo(.texto(13, pesoSub)).foregroundStyle(colorSub).lineLimit(lineas)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Título de sección (.titsec): Nunito 20 a la izquierda y un dato o enlace a la derecha.
struct TituloSeccion: View {
    let texto: String
    var dato: String? = nil
    var accion: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(texto).font(Estilo.titulo(20).font()).tracking(-0.3).foregroundStyle(Color.titulo)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let dato {
                if let accion {
                    Button(action: { Haptico.seleccion(); accion() }) {
                        Text(dato).tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                            .frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(Apretable())
                    .padding(.vertical, -12)
                } else {
                    Text(dato).tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, -2)
    }
}

// MARK: - Avatares

enum TonoAvatar: String, Codable, Hashable { case mandarina, az, lo }

/// Avatar (.av): foto redonda o iniciales sobre mandarina, verde-100 o crema 300.
struct Avatar: View {
    var foto: String? = nil
    var iniciales: String = ""
    var tono: TonoAvatar = .mandarina
    var tamano: CGFloat = 40
    var anillo: Color? = nil
    var anilloAncho: CGFloat = 2

    var body: some View {
        Group {
            if let foto, UIImage(named: foto) != nil {
                Image(foto).resizable().scaledToFill()
            } else if let foto, let data = Archivos.leer(foto), let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Text(iniciales)
                    .font(Estilo.texto(tamano >= 56 ? 18 : tamano <= 32 ? 12 : 14, 700).font())
                    .foregroundStyle(frente)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fondo)
            }
        }
        .frame(width: tamano, height: tamano)
        .clipShape(Circle())
        .overlay { if let anillo { Circle().strokeBorder(anillo, lineWidth: anilloAncho).padding(-anilloAncho) } }
        .accessibilityHidden(true)
    }

    private var fondo: Color {
        switch tono { case .mandarina: return .mandarina; case .az: return .verde100; case .lo: return .crema300 }
    }
    private var frente: Color {
        switch tono { case .mandarina: return .verde900; case .az: return .verde900; case .lo: return .salvia700 }
    }
}

/// Foto recortada con un punto de foco (el `background-position` del CSS).
struct FotoRecortada: View {
    let nombre: String
    var foco: UnitPoint = .center

    var body: some View {
        GeometryReader { g in
            if let ui = UIImage(named: nombre) ?? Archivos.leer(nombre).flatMap(UIImage.init(data:)) {
                let escala = max(g.size.width / ui.size.width, g.size.height / ui.size.height)
                let w = ui.size.width * escala, h = ui.size.height * escala
                Image(uiImage: ui)
                    .resizable()
                    .frame(width: w, height: h)
                    .offset(x: -(w - g.size.width) * foco.x, y: -(h - g.size.height) * foco.y)
            } else {
                Color.superficie2
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// La foto de una comida (`.foto`): crema 300 de fondo, radio 14, o el ícono si todavía no hay foto.
struct FotoComida: View {
    var foto: String?
    var lado: CGFloat = 44
    var radio: CGFloat = 13
    var icono: Icono = .foto

    var body: some View {
        ZStack {
            Color.superficie2
            if let foto {
                FotoRecortada(nombre: foto)
            } else {
                IconoVista(icono, tamano: 20).foregroundStyle(Color.texto2)
            }
        }
        .frame(width: lado, height: lado)
        .clipShape(RoundedRectangle(cornerRadius: radio, style: .continuous))
    }
}

// MARK: - Controles redondos, chips, íconos en círculo

/// Círculo de 40 (.redondo): vidrio sobre la banda, blanco (cl) sobre crema, oscuro sobre fotos.
struct Redondo: View {
    enum Variante { case vidrio, claro, oscuro, marca }
    let icono: Icono
    var variante: Variante = .vidrio
    var tamano: CGFloat = 40
    var tamanoIcono: CGFloat = 24
    var badge: Int = 0
    var etiqueta: String
    var accion: () -> Void

    var body: some View {
        Button(action: { Haptico.seleccion(); accion() }) {
            IconoVista(icono, tamano: tamanoIcono)
                .foregroundStyle(frente)
                .frame(width: tamano, height: tamano)
                .background(fondo, in: Circle())
                .modifier(SombraSiClaro(activa: variante == .claro))
                .overlay(alignment: .topTrailing) {
                    if badge > 0 { Badge(n: badge, aro: variante == .vidrio ? .banda : .fondo).offset(x: 3, y: -3) }
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(badge > 0 ? "\(etiqueta), \(badge) sin leer" : etiqueta)
    }

    private var fondo: Color {
        switch variante {
        case .vidrio: return .vidrio
        case .claro: return .superficie
        case .oscuro: return Color.verde950.opacity(0.55)
        case .marca: return .marca
        }
    }
    private var frente: Color {
        switch variante {
        case .vidrio: return .crema
        case .claro: return .marca
        case .oscuro: return .white
        case .marca: return .sobreMarca
        }
    }
}

private struct SombraSiClaro: ViewModifier {
    let activa: Bool
    func body(content: Content) -> some View {
        if activa { content.sombraChica() } else { content }
    }
}

/// El número rojo (.badge): naranja 700 con aro del color de lo que tiene detrás.
struct Badge: View {
    let n: Int
    var aro: Color = .banda
    var body: some View {
        Text("\(n)")
            .font(Estilo.texto(11, 700).font())
            .monospacedDigit()
            .foregroundStyle(Color.sobreBadge)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(Color.badge, in: Capsule())
            .overlay(Capsule().stroke(aro, lineWidth: 2))
            .contentTransition(.numericText(value: Double(n)))
            .accessibilityHidden(true)
    }
}

/// Chip de estado (.chip): siempre con ícono y palabra, nunca sólo color.
struct ChipEstado: View {
    enum Tipo { case ok, aviso, info, crema, dur, error, vidrio, banda }
    let texto: String
    var icono: Icono? = nil
    var tipo: Tipo = .ok
    var alto: CGFloat = 26
    var tamano: CGFloat = 12.5

    var body: some View {
        HStack(spacing: 4) {
            if let icono { IconoVista(icono, tamano: 14, grosor: 2.4) }
            Text(texto).tipo(.texto(tamano, 600)).lineLimit(1)
        }
        .foregroundStyle(frente)
        .padding(.leading, icono == nil ? 9 : 7)
        .padding(.trailing, 9)
        .frame(height: alto)
        .background(fondo, in: Capsule())
        .fixedSize()
    }

    private var fondo: Color {
        switch tipo {
        case .ok: return .okFondo
        case .aviso: return .avisoFondo
        case .info: return .suave
        case .crema: return .superficie2
        case .dur: return .logroSuave
        case .error: return .errorFondo
        case .vidrio: return Color.white.opacity(0.16)
        case .banda: return .vidrio
        }
    }
    private var frente: Color {
        switch tipo {
        case .ok: return .ok
        case .aviso: return .aviso
        case .info: return .sobreSuave
        case .crema: return .texto3
        case .dur: return .logroTexto
        case .error: return .error
        case .vidrio: return .white
        case .banda: return .crema
        }
    }
}

/// Ícono en círculo de 40 (.icono-c).
struct IconoCirculo: View {
    enum Tono { case aviso, az, dur, ok, salud, crema }
    let icono: Icono
    var tono: Tono = .az
    var tamano: CGFloat = 40
    var tamanoIcono: CGFloat = 20

    var body: some View {
        IconoVista(icono, tamano: tamanoIcono)
            .foregroundStyle(frente)
            .frame(width: tamano, height: tamano)
            .background(fondo, in: Circle())
    }

    private var fondo: Color {
        switch tono {
        case .aviso: return .avisoFondo
        case .az: return .suave
        case .dur: return .logroSuave
        case .ok: return .okFondo
        case .salud: return Color(claro: 0xFDE7EA, oscuro: 0x3A1A22)
        case .crema: return .superficie2
        }
    }
    private var frente: Color {
        switch tono {
        case .aviso: return .aviso
        case .az: return .sobreSuave
        case .dur: return .logroTexto
        case .ok: return .ok
        case .salud: return Color(hex: 0xD5223F)
        case .crema: return .texto2
        }
    }
}

/// El interruptor del diseño (.toggle): 50 × 30, verde prendido, salvia-200 apagado.
struct Interruptor: View {
    @Binding var prendido: Bool
    var etiqueta: String

    var body: some View {
        Button {
            Haptico.seleccion()
            withAnimation(.snappy(duration: 0.22)) { prendido.toggle() }
        } label: {
            ZStack(alignment: prendido ? .trailing : .leading) {
                Capsule().fill(prendido ? Color.marca : Color.borde)
                Circle().fill(prendido ? Color.sobreMarca : Color.white).frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                    .padding(3)
            }
            .frame(width: 50, height: 30)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etiqueta)
        .accessibilityValue(prendido ? "Prendido" : "Apagado")
        .accessibilityAddTraits(.isToggle)
    }
}

/// Pastillas (.seg): 34 de alto; la elegida en verde.
struct Pastillas<T: Hashable>: View {
    let opciones: [(T, String)]
    @Binding var elegida: T
    var sobreBanda = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(opciones, id: \.0) { o in
                    let on = o.0 == elegida
                    Button {
                        Haptico.seleccion()
                        withAnimation(.snappy(duration: 0.2)) { elegida = o.0 }
                    } label: {
                        Text(o.1).tipo(.texto(14, 600))
                            .foregroundStyle(frente(on))
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(fondo(on), in: Capsule())
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(Apretable())
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func fondo(_ on: Bool) -> Color {
        if sobreBanda { return on ? .crema : .vidrio12 }
        return on ? .marca : .superficie2
    }
    private func frente(_ on: Bool) -> Color {
        if sobreBanda { return on ? .verde900 : .verde100 }
        return on ? .sobreMarca : .texto3
    }
}

/// Selector chico (.mini-seg): crema 300 con la opción elegida en blanco.
struct MiniSeg<T: Hashable>: View {
    let opciones: [(T, String)]
    @Binding var elegida: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(opciones, id: \.0) { o in
                let on = o.0 == elegida
                Button {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.2)) { elegida = o.0 }
                } label: {
                    Text(o.1).tipo(.texto(13, 600))
                        .foregroundStyle(on ? Color.titulo : Color.texto3)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.superficie).sombraChica()
                            }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 3)
        .frame(height: 34)
        .background(Color.superficie2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .fixedSize()
    }
}

// MARK: - Navegación propia

/// «‹ Pacientes» a la izquierda (16/600) y algo a la derecha. Sobre la banda va en crema.
struct NavAtras<Derecha: View>: View {
    var atras: String?
    var icono: Icono = .atras
    var accionAtras: (() -> Void)?
    @ViewBuilder var derecha: () -> Derecha
    @Environment(\.sobreBanda) private var sobreBanda
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        HStack {
            Button {
                Haptico.seleccion()
                if let accionAtras { accionAtras() } else { cerrar() }
            } label: {
                HStack(spacing: 2) {
                    IconoVista(icono, tamano: 24)
                    if let atras { Text(atras).tipo(.texto(16, 600)) }
                }
                .foregroundStyle(sobreBanda ? Color.crema : Color.marca)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
            .accessibilityLabel(atras.map { "Volver a \($0)" } ?? (icono == .x ? "Cerrar" : "Volver"))
            Spacer()
            derecha()
        }
        .padding(.leading, 12)
        .padding(.trailing, 20)
        .frame(height: 44)
    }
}

extension NavAtras where Derecha == EmptyView {
    init(atras: String?, icono: Icono = .atras, accionAtras: (() -> Void)? = nil) {
        self.atras = atras; self.icono = icono; self.accionAtras = accionAtras; self.derecha = { EmptyView() }
    }
}

/// Cabecera (.cab): la fecha chica arriba y el título grande; algo a la derecha.
struct Cabecera<Derecha: View>: View {
    var fecha: String?
    let titulo: String
    var tamano: CGFloat = 32
    @ViewBuilder var derecha: () -> Derecha
    @Environment(\.sobreBanda) private var sobreBanda

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let fecha {
                    Text(fecha).tipo(.texto(14, 600)).foregroundStyle(sobreBanda ? Color.sobreBanda2 : Color.texto2)
                }
                Titulo(titulo, tamano: tamano, color: sobreBanda ? .crema : .titulo)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            derecha()
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 6)
    }
}

extension Cabecera where Derecha == EmptyView {
    init(fecha: String? = nil, titulo: String, tamano: CGFloat = 32) {
        self.fecha = fecha; self.titulo = titulo; self.tamano = tamano; self.derecha = { EmptyView() }
    }
}

/// La marca arriba de los inicios (.marca-app): la rodaja y «de a poco» en un renglón, 24 de alto. En color sobre
/// crema; en negativo sobre la banda y en modo oscuro.
struct MarcaApp: View {
    @Environment(\.sobreBanda) private var sobreBanda
    @Environment(\.colorScheme) private var esquema
    var body: some View {
        Image(sobreBanda || esquema == .dark ? "horizontal-negativo" : "horizontal-color")
            .resizable().scaledToFit()
            .frame(height: 24)
            .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            .padding(.horizontal, Espacio.margen)
            .accessibilityLabel("De a Poco")
            .accessibilityAddTraits(.isHeader)
    }
}

/// Cabecera de la banda con el título abajo a la izquierda y un dato a la derecha («Agenda · Noviembre»).
struct CabeceraBanda: View {
    let titulo: String
    var dato: String?
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Titulo(titulo, tamano: 32, color: .crema)
            Spacer(minLength: 8)
            if let dato { Text(dato).tipo(.texto(15, 600)).foregroundStyle(Color.sobreBanda2).padding(.bottom, 4) }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 6)
    }
}

// MARK: - Pie con degradé

/// El pie fijo (.pie): degradé desde el fondo para que el contenido se vaya antes de pasar por debajo.
struct Pie<Contenido: View>: View {
    @ViewBuilder var contenido: () -> Contenido
    var body: some View {
        contenido()
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background {
                LinearGradient(stops: [.init(color: Color.fondo.opacity(0), location: 0), .init(color: Color.fondo, location: 0.22)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
    }
}

// MARK: - Aviso (toast)

/// Aviso corto arriba («Listo, le llegó a Martín.»).
struct AvisoFlotante: View {
    let texto: String
    var body: some View {
        HStack(spacing: 8) {
            IconoVista(.check, tamano: 20).foregroundStyle(Color.mandarina)
            Text(texto).tipo(.texto(15, 600)).foregroundStyle(Color.crema).multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(Color.verde850, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.verde950.opacity(0.3), radius: 16, y: 10)
        .padding(.horizontal, 20)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Estado vacío

/// Estado vacío con una acción: el plato limpio, una frase y qué hacer.
struct Vacio: View {
    let titulo: String
    var texto: String?
    var accion: String?
    var icono: Icono? = nil
    var hacer: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            if let icono {
                IconoCirculo(icono: icono, tono: .az, tamano: 64, tamanoIcono: 28)
            } else {
                Gajos(partes: 4, llenas: 0).frame(width: 72, height: 72)
            }
            Text(titulo).font(Estilo.titulo(22).font()).foregroundStyle(Color.titulo).multilineTextAlignment(.center)
            if let texto {
                Text(texto).tipo(.texto(15, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let accion, let hacer {
                Boton(titulo: accion, variante: .prim, accion: hacer).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
    }
}

// MARK: - Hápticos

enum Haptico {
    static func suave() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7) }
    static func exito() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func seleccion() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Distribución en filas

/// Distribución que acomoda a los hijos en renglones (chips).
struct Fluir: Layout {
    var espacio: CGFloat = 8
    var espacioVertical: CGFloat? = nil

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ancho = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, alto: CGFloat = 0
        for s in subviews {
            let t = s.sizeThatFits(.unspecified)
            if x > 0 && x + t.width > ancho { x = 0; y += alto + (espacioVertical ?? espacio); alto = 0 }
            x += t.width + espacio
            alto = max(alto, t.height)
        }
        return CGSize(width: ancho, height: y + alto)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, alto: CGFloat = 0
        for s in subviews {
            let t = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + t.width > bounds.maxX { x = bounds.minX; y += alto + (espacioVertical ?? espacio); alto = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(t))
            x += t.width + espacio
            alto = max(alto, t.height)
        }
    }
}

// MARK: - Barra de estado

/// La barra de estado clara (sobre la banda o fotos) u oscura (sobre crema). En modo oscuro, siempre clara.
private struct BarraDeEstado: ViewModifier {
    let clara: Bool
    @Environment(\.colorScheme) private var esquema
    func body(content: Content) -> some View {
        content
            .onAppear { aplicar() }
            .onChange(of: esquema) { aplicar() }
    }
    private func aplicar() {
        EstiloBarra.poner(clara || esquema == .dark ? .lightContent : .darkContent)
    }
}

extension View {
    func barraClara(_ clara: Bool = true) -> some View { modifier(BarraDeEstado(clara: clara)) }
}

enum EstiloBarra {
    @MainActor static func poner(_ s: UIStatusBarStyle) {
        // Con UIViewControllerBasedStatusBarAppearance en NO, la barra la maneja la app (API vieja pero vigente).
        let app = UIApplication.shared
        guard app.responds(to: NSSelectorFromString("setStatusBarStyle:")) else { return }
        app.setValue(s.rawValue, forKey: "statusBarStyle")
    }
}

// MARK: - Volver con el gesto aunque la barra de navegación esté oculta

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
