# Arquitectura técnica (Roblox)

## Principios
- **Un solo place**, un servidor manda (todo lo importante se decide en el servidor; el cliente solo muestra y pide).
- **Una máquina de estados** central: cada fase es un módulo con `start()`, `stop()` y su reloj.
- **Todos los números y textos en `Config`** (ModuleScript). Balancear = editar un archivo.
- Reutilizar piezas: un solo panel de pros/contras, un solo creador de puntos "mantener E", una sola pantalla de paso.
- Mapas y edificio **construidos por script** al inicio (rápido de cambiar, sin depender del guardado de piezas en Studio). Luego se pueden cambiar por modelos.
- Código comentado en español; textos del juego en inglés.

## Árbol en Roblox (y su copia en `src/`)
```
ReplicatedStorage/
  Shared/
    Config          (ModuleScript)  roles, opciones, pesos, sitios, puntos, misiones, energía, textos EN
    Energy          (ModuleScript)  cálculo de energía generada/pedida (lo usan servidor y cliente)
    Util            (ModuleScript)  formato de tiempo, colores, helpers
  Remotes/          (carpeta con RemoteEvents/RemoteFunctions, la crea el servidor)
ServerScriptService/
  Main              (Script)        arranque: crea remotes, construye mapas, inicia GameManager
  GameManager       (ModuleScript)  estados: Lobby → Phase0 → Phase1 → Phase2 → Phase3 → End; estado de partida
  Roles             (ModuleScript)  reparto de roles, auto-asignación, salida de jugadores, traje y etiqueta
  Phases/
    Phase0          (ModuleScript)  reloj, elecciones, carga, castigo, lanzamiento, finales
    Phase1          (ModuleScript)  sitio, aterrizaje, colocación, daño
    Phase2          (ModuleScript)  misiones, reparaciones, energía
    Phase3          (ModuleScript)  supervivencia (pendiente)
  World/
    BuildEarthBase  (ModuleScript)  pasillo, cuartos, pedestales, carteles, sala de control
    BuildMoonSite   (ModuleScript)  terreno lunar único, nave, puntos
  Bars              (ModuleScript)  oxígeno, agua, radiación, muerte/espectador
  HoldPoints        (ModuleScript)  fábrica de ProximityPrompt "mantener E"
StarterPlayer/StarterPlayerScripts/
  ClientMain        (LocalScript)   arranca los controladores de UI
  UI/               (ModuleScripts) TitleScreen, RoleSelect, Briefing, ProsConsPanel, Timer,
                                    SiteSelect (Luna en ViewportFrame), Transition, MissionList, Bars, Results
StarterGui/         (vacío: la UI se crea por código)
```

## Comunicación (Remotes)
| Remote | Dirección | Para qué |
| --- | --- | --- |
| `StateChanged` | servidor → todos | fase actual, reloj, datos públicos (elecciones, carga) |
| `RequestRole` | cliente → servidor | tomar/soltar rol |
| `ReadyUp` | cliente → servidor | READY en briefing y pantallas de paso |
| `ChooseOption` | cliente → servidor | doble clic en pedestal (servidor valida rol y tiempo) |
| `Launch` | cliente → servidor | consola del Captain (o ProximityPrompt en servidor) |
| `SiteNav` / `SiteChoose` / `SiteSuggest` | cliente → servidor | Luna 3D |
| `Toast` | servidor → cliente | avisos cortos ("Your item got damaged!") |

Clic en pedestal: `ClickDetector` (clic = pedir info, local; doble clic = `ChooseOption`). Mantener E: `ProximityPrompt.HoldDuration`.

## Cómo se pasa el código a Studio
- **Fuente de verdad: los archivos `src/**/*.luau` de esta carpeta** (se guardan en OneDrive y en git; sobreviven a cambios de cuenta o caídas de Studio).
- Claude escribe/edita el archivo y luego lo **sube a Studio por MCP** (crear/actualizar el Script con su `Source`). Nunca se edita solo en Studio sin copiar de vuelta al archivo.
- Si Isaac cambia algo a mano en Studio, se avisa y Claude lo copia de vuelta a `src/`.
- Opción más adelante: **Rojo** (sincronización automática archivo ↔ Studio). Requiere instalar el plugin; solo si el MCP se vuelve lento.
- **Cualquier acción en Studio por MCP solo con permiso explícito de Isaac** (regla actual).

## Pruebas
- Studio → Test → servidor local con 2 y 4 jugadores.
- Por MCP: `start_stop_play`, `get_console_output` y `screen_capture` para revisar errores.
- Cada fase se puede arrancar sola con un atajo de depuración (`Config.Debug.StartPhase`) para no jugar todo desde el inicio.

## Lecciones técnicas del prototipo (detalle en `lecciones-prototipo.md`)
- `Workspace.StreamingEnabled = false` (con streaming el personaje caía al vacío al teletransportarse).
- ProximityPrompt solo aparece si su objeto se ve: objetos bajos, sin nada delante; `RequiresLineOfSight = false` o `AlwaysShow` si algo tapa.
- Gravedad lunar usada: `Workspace.Gravity = 32.4` (1/6 de 196.2).
- `start_stop_play` del MCP abre un solo jugador; la prueba con 2–4 la hace Isaac en Studio (Test > Clients and Servers).
- Guardar: confirmar "Saved" en el log; con Collaborate no avisa. Por eso el código vive en `src/`.
- Licencia del repo: Apache 2.0 (OSI). No usar CC0 para recursos.
