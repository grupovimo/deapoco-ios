# De a Poco · iOS

Maqueta navegable de alta fidelidad de la app para nutricionistas y sus pacientes (SwiftUI, iOS 17+, sólo iPhone y vertical, modo claro y oscuro). No tiene backend: todo corre en memoria con los datos del diseño (`propuestas/nutricion/pantallas/app.html`) y la marca (`propuestas/nutricion/marca`).

## Generar y compilar

```sh
brew install xcodegen          # una vez
xcodegen generate              # crea DeAPoco.xcodeproj (no se versiona)
xcodebuild -project DeAPoco.xcodeproj -scheme DeAPoco -derivedDataPath build/dd \
  -destination 'platform=iOS Simulator,id=<simulador>' CODE_SIGNING_ALLOWED=NO test
```

Tests en Release (ahí se cerraba Tu Local Web): sumá `-configuration Release ENABLE_TESTABILITY=YES`. Para cuidar el Xcode de GitHub, compilá con `OTHER_SWIFT_FLAGS='-Xfrontend -warn-long-expression-type-checking=1000'` y partí lo que pase de un segundo.

Capturas: `./capturar.sh` (o `./capturar.sh n-inicio p-hoy`). Lee las pantallas de `pantallas-nutri.txt` y `pantallas-paciente.txt` (`nombre hora [oscuro]`) y saca además cada paso del onboarding. Quedan en `capturas/`. En esta Mac, antes de usar el simulador: `until mkdir ~/Trabajo/vimo/.sim-lock 2>/dev/null; do sleep 10; done` y al final `rmdir ~/Trabajo/vimo/.sim-lock`.

Para abrir una pantalla directo: argumento de arranque `-pantalla <nombre>` (las de la nutri empiezan con `n-`, las del paciente con `p-`; `carga`; `onboarding -paso N -ladoOnb nutri|paciente`) y `-oscuro YES` para el modo oscuro.

## Estructura

- `DeAPoco/App`: el punto de entrada, la raíz (onboarding o la app de cada lado, con la carga y su tip) y el onboarding: se elige el lado y después una pregunta por pantalla.
  - Nutri: nombre, matrícula, especialidades, dónde atiende, cuántos pacientes, «Traé lo que ya usás» (Google Calendar, Mercado Pago, WhatsApp).
  - Paciente: la invitación de su nutri, nombre, sexo, edad, objetivo, cómo come hoy, restricciones y alergias, horarios de comida, Apple Salud.
- `DeAPoco/Tema`: colores (escalas y roles que cambian en oscuro, igual que `tokens.css`), tipografía (Fraunces y Hanken Grotesk variables por `UIFontDescriptor`, títulos con interlineado 1,04 y renglones balanceados), radios, espacios y sombras cálidas.
- `DeAPoco/Componentes`: el plato (`plato.js` porteado), el plato armado, la curva de medidas (nunca balanza), la dona de cobros, la barra «la mesa», botones, chips, tarjetas, íconos del sistema de marca, la regla, el tip, la carga y la promo «De Grupo Vimo» hacia Otra Más.
- `DeAPoco/Nucleo`: modelos, el protocolo `Datos`, `DatosDeMuestra` y `Estado` (`@Observable`), que es lo único que leen las pantallas. También la suscripción de la nutri (Gratis hasta 10 pacientes, Profesional, Consultorio, prueba de 14 días).
- `DeAPoco/Pantallas/Nutri` y `DeAPoco/Pantallas/Paciente`: las pantallas de cada lado. `Comunes/Cuenta.swift` es el pie de Ajustes de los dos lados (apariencia, ver el otro lado, rehacer el inicio y cerrar sesión).

## Conectar datos reales

1. Escribí una implementación nueva del protocolo `Datos` (`Nucleo/Datos.swift`), por ejemplo `DatosApi`. Tiene que devolver `PanelNutri`, `PanelPaciente`, `PerfilNutri` y `Suscripcion`, y persistir las acciones (turnos, comidas, planes, medidas, cobros, mensajes, pagos).
2. Pasala al crear el estado: en `DeAPocoApp`, `Estado(datos: DatosApi())`.

Con eso alcanza: las pantallas no cambian. `Estado` aplica cada acción en memoria al instante y después llama a `datos`. Al arrancar, `Estado.cargar()` trae lo último.

Regla: nunca uses `async let`, porque cierra la app en Release. Las cargas van una detrás de otra.

## TestFlight

`.github/workflows/testflight.yml` compila, corre los tests, firma con el perfil `ar.com.deapoco.app App Store` (equipo M6935MSNQB) y sube. Necesita los secretos `ASC_KEY_P8`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `DIST_P12`, `DIST_P12_CLAVE` y `PERFIL_APP` en el repo.
