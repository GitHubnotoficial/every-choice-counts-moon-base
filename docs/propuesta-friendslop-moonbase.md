# Auditoría friendslop de Every Choice Counts: Moon Base + qué agregar

Fecha: 2026-11-15, 22:20 (cierre de cambios a las 23:10). Base: `docs/investigacion-friendslop.md` (12 pilares).

## 1. Auditoría del juego contra los 12 pilares

| Pilar | Cómo está hoy | Nota | Hueco principal |
|---|---|---|---|
| P1 Idea de una frase | "Construye una base en la Luna: cada decisión cuenta" | Fuerte | — |
| P2 Entrada fácil | Roles con READY y reparto al azar, briefing, unirse nativo de Roblox | Bien | La partida dura 18–27 min (un poco larga) |
| P3 Comunicación | Solo el chat de texto de Roblox | **Débil** | Sin voz por proximidad, sin pings ni marcadores |
| P4 Comedia física | Aplastón (sin probar con 2), cargar bloques de hielo en la mano | Regular | Pocos objetos con física que se carguen entre varios |
| P5 Presión | 7 días con reloj, barras, reserva, comida y energía | Fuerte | — |
| P6 Interdependencia | Emergencias solo para el rol dueño, cinturón al morir | Bien | Ninguna tarea exige a 2 personas a la vez |
| P7 Amenaza | Emergencias con datos reales (clima espacial NASA DONKI en vivo) | Fuerte y único | — |
| P8 Muerte | Espectador y cinturón que pasa el rol a otro | Bien | El muerto no puede ayudar en nada |
| P9 Aleatoriedad | Emergencias al azar y decisiones distintas por partida | Bien | — |
| P10 Progresión | No hay entre partidas | Débil (no crítico en hackathon) | Récord de tripulación |
| P11 Clipeable | Pantalla final con "why you lost", easter eggs, aplastón | Regular | Ningún momento hecho para compartir (foto, premios graciosos) |
| P12 Lanzamiento | Repo público, presentación y video | En curso | Ver pendientes críticos abajo |

## 2. Pendientes críticos de la entrega (antes que cualquier mecánica nueva)
1. **La presentación tiene 8 diapositivas y Space Apps permite máximo 7:** si no se corrige, no entra al juzgamiento global (00-ESTADO).
2. **Aplastón sin probar con 2 jugadores** (Test → 2 Players).
3. **El repo público todavía tiene logos en el historial** (primer commit): decisión de Isaac (rehacer el repo o dejarlo).

## 3. Qué agregar (de más valor a menos), con esfuerzo estimado

| # | Mecánica | Pilar | Por qué ayuda a lo social o viral | Esfuerzo |
|---|---|---|---|---|
| 1 | **Premios graciosos al final** por jugador: "Saved the base 3 times", "Flattened 4 crewmates", "Never refilled once", "Fell like Apollo 16" | P11 | Cada partida produce una frase para compartir. Los contadores ya existen casi todos | Bajo (~45 min) |
| 2 | **Ping de equipo** (tecla G o botón): marca un punto que ven todos durante 6 s, con frases rápidas ("Help here!", "Low O₂!", "Emergency!") | P3, P6 | Coordinación sin voz (niños sin voz verificada), muy usado en los juegos del género | Bajo-medio (~1 h) |
| 3 | **Radio vs. proximidad + la llamarada corta la radio**: voz espacial de Roblox; en la emergencia FLARE se pierde la "radio" y solo funciona hablar de cerca | P3, P7 | Mezcla lo más viral del género (proximidad) con ciencia real: las llamaradas cortan las comunicaciones de radio | Medio-alto (la voz necesita cuentas verificadas y es difícil de probar) |
| 4 | **El muerto pasa a Mission Control**: ve el mapa desde arriba y puede hacer pings y avisar de peligros (como la terminal de Lethal Company) | P8, P6 | Nadie se aburre al morir; el muerto sigue en el equipo | Medio (~1,5 h) |
| 5 | **Tareas de 2 personas**: cargar la batería pesada entre dos, o girar dos válvulas a la vez | P6, P4 | Obliga a hablar y coordinar; genera momentos torpes y graciosos | Medio (~1,5 h) |
| 6 | **Foto de tripulación al final**: pose grupal frente a la base con marco "Shackleton Crew · Day 7" y los premios | P11 | La captura que la gente sube a redes | Bajo-medio (~1 h) |
| 7 | **Salto de canguro del Apolo** (emote o forma de correr): así se movían los astronautas en la Luna | P4 | Gracioso y educativo; combina con el aplastón | Bajo (~30 min) |
| 8 | **Récord de tripulaciones** (DataStore): mejor día alcanzado y tripulaciones que sobrevivieron los 7 días | P10 | Competencia entre grupos de amigos | Medio |

9. **Finales escalonados** (pedido de Isaac, después de entregar): PERFECT MISSION / MISSION COMPLETE con bajas / LONE SURVIVOR; en la derrota, título según el día. Solo textos en Phase3HUD y Config (~20 min).

**Qué no recomiendo:** traidor o sabotaje (choca con el reto educativo), monstruos (rompe el rigor) y progresión con compras.

## 4. Recomendación
- **Antes del cierre de las 23:10:** nada de mecánicas nuevas. Lo crítico es la presentación de 7 diapositivas y probar el aplastón con 2.
- **Después de entregar:** 1 → 2 → 6 → 7 (bajo esfuerzo y gran efecto), luego 4 y 5. La 3 (radio y llamarada) es la más potente para el pitch, pero también la más difícil de probar.
