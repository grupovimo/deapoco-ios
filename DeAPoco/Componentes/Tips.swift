import SwiftUI

/// Un tip corto (.tip): tarjeta blanca, la foto de la nutri (o el rayo) y la etiqueta en rabanito 700.
struct TipVista: View {
    let tip: Tip
    var foto: String? = nil
    var etiqueta: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let foto {
                Avatar(foto: foto, tamano: 48)
            } else {
                IconoCirculo(icono: .rayo, tono: .dur, tamano: 48, tamanoIcono: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Etiqueta(etiqueta ?? "Tip · \(tip.tema)", color: .acentoTexto)
                Text(tip.texto)
                    .tipo(.texto(15, 400))
                    .foregroundStyle(Color.texto)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.superficie, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sombraMedia()
        .accessibilityElement(children: .combine)
    }
}

/// La carga breve al abrir (p15): el plato que se sirve, «Servimos tu día.», los puntos y un tip.
struct CargaInicial: View {
    var lado: Lado = .paciente
    let tip: Tip?
    var foto: String? = "av-laura"
    var nutri: String = "Laura"
    @State private var paso = 0

    var body: some View {
        ZStack {
            Color.fondo.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 28) {
                    Plato(partes: 4, llenas: 1 + paso % 3, hoy: 1 + paso % 3, servir: true)
                        .frame(width: 168, height: 168)
                        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.6), value: paso)
                    Titulo(lado == .nutri ? "Armamos tu día." : "Servimos tu día.", tamano: 28, centrado: true)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle().fill(i <= paso % 3 ? Color.marca : Color.manteca300).frame(width: 8, height: 8)
                        }
                    }
                    .accessibilityHidden(true)
                }
                .padding(.horizontal, 32)
                Spacer()
                if let tip {
                    TipVista(tip: tip, foto: lado == .paciente ? foto : nil,
                             etiqueta: lado == .paciente ? "Tip de \(nutri)" : nil)
                        .padding(.horizontal, Espacio.margen)
                        .padding(.bottom, 36)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .barraClara(false)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeOut(duration: 0.2)) { paso += 1 }
            }
        }
    }
}
