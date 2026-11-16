# Diseño del juego (resumen de trabajo)

Fuente de verdad del detalle: los PDF en `docs/referencias/` (Fase 0, 1 y 2, pantallas 2D y plano, del 14-nov) y la maqueta `Landing Site Selection.html`. Este archivo resume, junta las propuestas de los audios de **Leticia** y lo que Isaac decidió sobre ellas (capturas en `docs/referencias/capturas-whatsapp/`) y marca los conflictos.

## Idea en una línea
Hasta 4 jugadores (Captain, Engineer, Life Support, Botanist) preparan una nave en la Tierra, eligen dónde alunizar en el polo sur de la Luna, construyen la base y sobreviven. Cada decisión tiene ventaja y costo, con datos reales de la NASA.

## Reglas generales
- Roblox, **solo PC** (teclado y ratón), un place, máximo 4 jugadores por servidor. Debe poder jugarse solo (los roles libres se reparten).
- Juego en **inglés**; comentarios del código en **español**.
- Sin chat de voz (menores). Chat de texto de Roblox sí.
- Paleta: morado, lavanda, rosa, celeste, amarillo + rojo/azul/blanco estilo NASA. **Sin logo ni nombre NASA** en pantallas (etiqueta "MOON BASE SURVIVAL").
- Título del juego: pendiente (`[GAME TITLE]`). Ideas en `docs/nombres.md`.
- Barras desde la Fase 1: oxígeno, agua, radiación (energía como cálculo). Muerte = espectador, deja su cinturón.

## Flujo completo
| Fase | Qué | Tiempo |
| --- | --- | --- |
| 0 Lanzamiento | Título → rol → briefing (2D) → cada uno elige en su cuarto (3D) → Captain lanza | ~2:30 |
| 1 Alunizaje | Pantalla de paso → Captain elige sitio en Luna 3D → aterrizaje → cada rol coloca lo suyo en 1 de 3 puntos | 1:00 + 5:00 |
| 2 Construir base | Una misión por rol (mantener E) + reparaciones; energía calculada | 4:00 |
| 3 Sobrevivir | **Sin diseñar.** Emergencias: sombra larga, reactor shutdown, sin contacto con la Tierra, noche helada, polvo; apagones; nave de carga; final | ? |

## Fase 0 — Lanzamiento
- **Pantallas 2D**: Título (PLAY, "1–4 players · PC"), Elección de rol (doble clic en tarjeta, 30 s, roles libres se asignan solos), Briefing (YOUR MISSION / HOW TO PLAY / WATCH OUT, READY, 20 s).
- **Edificio 3D** (lo construye un script): pasillo 86×14 studs, 4 cuartos 26×24 con puerta del color del rol, sala de control ~20×34 con pantalla grande, consola de lanzamiento (solo Captain) y ventana con la nave elegida.
- **Elegir**: en cada cuarto, 3 (o 4) **pedestales** con la opción en 3D encima (maqueta, no se agarra) y un **cartel** al lado (nombre, cuándo se usó, dato real). **Clic** = panel de ventajas/desventajas. **Doble clic** = elegir (se ilumina con el color del rol). Solo el dueño del rol elige; otros pueden mirar.
- Al elegir: **animación corta de la opción subiendo a la nave** (de abajo hacia arriba), no 3D complejo. La ventana muestra la nave; si es pesado, se ve más lleno.
- Pantalla grande (sala de control): 4 roles con su elección o "—", barra de carga usada/capacidad, tiempo, castigo en vivo ("TOO HEAVY: −15% oxygen and water").
- Al llegar a 0:00 las elecciones quedan fijas: "CAPTAIN: LAUNCH NOW! 15". Captain activa la consola → buen final; si pasan 15 s → **MISSION FAILED** ("The ship left without you…", TRY AGAIN).
- Quien no elige recibe una opción al azar.

### Opciones (peso)
| Rol | Ligera 20 | Media 40 | Pesada 60 |
| --- | --- | --- | --- |
| Captain (capacidad) | Light Lander **100** | Cargo Lander **160** | Starship HLS **240** (llega 1 sol tarde: −10 % O₂/agua) |
| Engineer | Solar Panels | Solar Panels + Batteries | Fission Reactor (80 fijos) |
| Life Support | Electrolyzer Only (tanques 70 %) | Recycler + Electrolyzer (50 %) | Full Tanks (100 %) · Regolith Oxygen Plant (30 %, 60) |
| Botanist | Regolith Kit (comida 2 soles) | Hydroponic Racks (4 soles) | Packaged Food (toda la partida) |

Textos exactos en inglés (cartel y panel) y "combina bien/mal": PDF Fase 0, capítulo 8.

### Carga y castigo — **CONFLICTO A RESOLVER**
- PDF Fase 0: "todos pagan": cada 10 de exceso = −5 % O₂ y agua; Starship −10 %; mínimo 40 % (propuesta).
- Audio de Leticia (guía): en vez de explotar, si se pasan **empiezan con −15 % de oxígeno y −15 % en las barras**.
- **Isaac (14-nov):** de acuerdo con que no explote y empiecen con desventaja de oxígeno (y agua). Falta fijar si es escalado o fijo.

### Tiempos — **CONFLICTO A RESOLVER**
- PDF: 1:30 para decidir. Audios: **1:20** ("nada más tienen que hacer clic").
- Audio: **cambiar de opción cuesta tiempo** (−10 s, quizá −30 s) y la animación también resta tiempo. El PDF dice que cambiar es libre mientras quede tiempo.

## Fase 1 — Alunizaje y sitio
- Pantalla 2D con **Luna 3D en ViewportFrame** que gira hacia el sitio seleccionado (ver maqueta HTML). Flechas + nombre + CHOOSE (solo Captain, definitivo). Otros: "SUGGEST THIS SITE" (punto/chip de su color). 6 barras 0–10 sin total. 1:00; al azar si no elige.
- 5 sitios (estudio del equipo):

| Sitio | Sol | Hielo | Comms | Terreno | Distancias | Ciencia | Luz paneles |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CONNECTING RIDGE | 9.5 | 7 | 9.5 | 7.5 | 8 | 7 | 88 |
| SHACKLETON RIM | 9 | 8.5 | 9 | 5 | 9 | 8 | 85 |
| NOBILE | 7.5 | 8.5 | 8 | 3.5 | 8 | 9 | 70 |
| FAUSTINI | 1.5 | 10 | 3 | 9 | 10 | 9.5 | 18 |
| MALAPERT | 9 | 4 | 10 | 4 | 3.5 | 6 | 85 |

- Terreno < 5 → "ROUGH LANDING! … Repairs cost 5% oxygen." Comms → probabilidad de "sin contacto" en Fase 3. Distancias → lejanía del hielo.
- **Un solo mapa** para los 5 sitios; cambian números y posiciones.
- Gravedad lunar (salto ~2×), "Gravity: 1/6 of Earth". Fuera de la nave O₂ y agua bajan el doble. Agua en 0 → 2 min para recargar.
- **Colocación (5:00)**: cada rol ve sus 3 puntos; al entrar en el círculo sale la tabla de pros/contras; **E** = martillo 5 s (10 s semienterrado), aparece pieza por pieza. Peso ralentiza (16/14/12/10; Captain 12). Mover lo colocado: 20/40/60 % de daño.
- Puntos por rol (efectos en PDF Fase 1 cap. 6): Captain hábitat (Open Field ×1.5 rad, Crater Wall ×1, Half-Buried ×0.5); Engineer fuente (Sunny Ridge ×1, Next to Lander ×0.7 / reactor rad ×1.5, Behind Rock Wall ×0.85); Life Support máquinas (Inside Lander, Next to Habitat, Ice Crater Edge); Botanist cultivo (Inside Habitat 2 bandejas, Attached Module 4 +10 energía, Inflatable 6 +15 energía, noche helada).
- Pantallas de paso 0→1 y 1→2 con "Did you know?" (datos reales).

## Fase 2 — Construir la base (4:00)
- Todo es **mantener E** (ProximityPrompt con HoldDuration). Cualquiera ayuda; roles sin jugador: "(no player — anyone can do it)".
- Captain: 3 balizas (4 s) → nave de carga a mitad de Fase 3 (+15 % O₂/agua).
- Engineer: según fuente (inclinar panel / revisar batería / radiador), 1–3 puntos según luz del sitio → protege de "sombra larga" / "reactor shutdown".
- Life Support: filtros / manguera hielo / manguera regolito / válvulas → máquina al 100 % y segundo punto de recarga.
- Botanist: sembrar 2/4/6 bandejas (3 s o 5 s) o contar 3 cajas.
- Reparaciones: 10 s manteniendo E.
- **Energía**: generada (paneles = luz × lugar; reactor 80; dañado −20 %) vs pedida (hábitat 20, reciclador 25, electrolizador 15, planta O₂ 40, hidroponía 15, kit 5, anexo +10, inflable +15). Si no alcanza → apagones por turnos en Fase 3.

## Fase 3 — Sobrevivir (PDF Fase 3 de Leticia, 14-nov)
- 7 días de 2 min (14 min). El día 1 es tranquilo. Del día 2 al 6, máximo 1 emergencia por día, cada una con su probabilidad. El día 7 sale siempre, la del rol con más problemas. El día 4 llega la nave de carga si están las balizas.
- Se gana con al menos 1 jugador vivo al final del día 7 (nave de rescate → MISSION COMPLETE).
- Recursos: barras personales, **reserva de la base** (recargar cuesta reserva), comida en días, cosechas cada 2,5 min y apagones por turnos.
- 16 emergencias con datos de DONKI, RadLab y OSDR: tarjeta de 3 respuestas, 20 s para elegir y 40 s para ejecutar manteniendo E. Si nadie responde, se aplica la C.
- Una sola animación: la luz del color del rol cruza la Luna.
- Primera versión: 6 emergencias (llamarada, CME, CO alto, moho, noche helada y alarma de dosis).
- Reparto en `tareas/T6-FASE3-reparto.md`. Flujo visual en `referencias/flujo-misiones-emergencias.jpg`.
- Cubre lo que pide el reto: clima espacial real (DONKI) y comunicación (llamarada y "sin contacto").

## Propuestas de Leticia (audios del 14-nov) y respuesta de Isaac
| # | Propuesta | Isaac |
| --- | --- | --- |
| 1 | Pantallas de la Fase 0 en 2D; 3D solo visual (pedestales con maqueta) | Sí. Isaac ya hizo pedestales con maqueta 3D en el prototipo |
| 2 | Clic = pros/contras; doble clic = elegir | Sí |
| 3 | Si el Captain no lanza a tiempo, la nave se va sin ellos | Sí (le da tensión, aunque duda si encaja en un friendslop) |
| 4 | Sala principal donde se activa la nave y se ven las opciones de todos | Sí; el prototipo ya tiene algo parecido |
| 5 | Sin chat de voz; texto sí | Sí |
| 6 | La nave es la primera opción; ventana en la sala de control para verla | Sí; detalles se pulen luego |
| 7 | Cambiar de opción cuesta tiempo (10 s o 30 s) | **No**: cambio libre mientras dure la elección; se fija a las 0:00 |
| 8 | Sobrecarga no explota; empiezan con −15 % de oxígeno y de las barras | Sí |
| 9 | Luna 3D pequeña que gira según el Captain; al aterrizar cada rol arma lo suyo | Sí |
| 10 | Nombre | Por ahora **Shackleton One** |

## Dudas de diseño abiertas
- **¿Quién arma?** Isaac: el Botanist no puede plantar en el suelo lunar. Propuesta: en la Fase 1 cada rol coloca su **módulo** (el Botanist coloca el invernadero/inflable/módulo, no semillas en el suelo) y en la Fase 2 el Botanist siembra **dentro**. Con el kit de regolito se usa suelo lunar dentro del invernadero (experimento real de 2022). Alternativa: el Engineer arma todos los módulos y los demás solo los equipan.
- **Rooms/estación/paneles/cráter del prototipo "99 Dias en la luna"**: revisar para reutilizar el diseño.

## Zonas del mapa (decisión de Isaac, 14-nov)
- 4 zonas lejos entre sí para que **no se vea una desde otra**: Lobby (−3000, 0, 0), edificio en la Tierra (0, 0, 0), superficie lunar (3000, 0, 0) e interior de la base (6000, 0, 0). Cada zona cambia la luz y la niebla al entrar.
- **Interior de la base** con cuartitos vistos en corte, como en el prototipo (estilo de juego de cocina tipo "sushi"). A Isaac le gusta y se mantiene.
- Isaac + Claude dejan la base de cada zona; los dueños construyen encima. **Aún no se ha hecho nada en Studio**: falta el permiso de Isaac.
