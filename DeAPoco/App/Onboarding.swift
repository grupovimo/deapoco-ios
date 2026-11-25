import SwiftUI

struct Onboarding: View {
    var lado: Lado = .nutri
    var paso: Int = 0
    var perfil: Perfil? = nil
    var terminar: (Perfil) -> Void
    var body: some View { Text("Onboarding") }
}
