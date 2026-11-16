# Investigación: "Friendslop" — mecánicas, razones y plantilla aplicable a cualquier juego

Fecha: 2026-11-15. Fuentes al final. Marcas usadas:
- **[F]** = dato con fuente.
- **[A]** = análisis o inferencia propia (razonado, no medido).

---

## 1. Qué es (definición operativa)

**Friendslop** es una etiqueta informal, nacida como burla, para juegos cooperativos baratos y pequeños cuya diversión depende sobre todo de **con quién juegas**, no de la profundidad del sistema. **[F]**

- Origen: un tuit de @wooosaaaahhhhh (marzo 2025) que mostraba *Lethal Company*, *R.E.P.O.* y *Content Warning*: "I call this genre of game 'Friendslop'". Luego añadió que su único fin era el "friendfarming" y aclaró que era broma. Se hizo viral sobre todo por la gente que se burló de él. **[F] Aftermath**
- Explotó con el éxito de *Peak* (junio 2025) y la prensa lo aplicó a casi cualquier cooperativo indie. **[F]**
- Algunos ubican el arranque del fenómeno en *Among Us* (2018) y la pandemia. **[F] Wikipedia**, con fuente débil.
- Varios desarrolladores adoptaron el término (Aggro Crab, Panic Stations!). Otros rechazan "slop" porque implica descuido (House House). **[F]**

**Definición útil para diseñar [A]:** un juego en el que *el sistema pone el problema y los amigos ponen la comedia*. Caelan Pollock (Aggro Crab) lo dijo así: son juegos que asumen que los amigos llenarán los huecos de comedia e interacción que el juego deja abiertos. **[F] Dexerto**

### Rasgos comunes (lista de identificación) **[F]**
1. Entrada muy fácil: cualquier nivel de habilidad puede jugar (Ley de Bushnell: "fácil de aprender, difícil de dominar").
2. Objetivo compartido de equipo.
3. Chat de voz por proximidad, a veces con boca que se mueve al hablar.
4. Física torpe y caótica.
5. Gráficos 3D de baja fidelidad.
6. Precio ≤ 20 USD (casi siempre 5–10 USD).
7. Poco divertido en solitario.
8. Muchas veces con estructura de "extracción": entrar, sacar botín, salir vivo.

---

## 2. Casos de estudio (qué hace cada uno y por qué funciona)

| Juego | Año | Bucle central | Gancho social | Datos |
|---|---|---|---|---|
| *Lethal Company* (Zeekerss, ex-Roblox, Unity) | 2023 | Recoger chatarra en lunas → volver a la nave antes de medianoche → vender → cumplir una cuota creciente cada 3 días; si fallas, game over | Voz por proximidad, terminal de la nave (uno guía desde la nave, abre puertas y apaga torretas), monstruos que castigan al que se separa | ~10 M copias estimadas (ene-2024), 100 k jugadores simultáneos, Stream Game of the Year **[F]** |
| *Content Warning* (Landfall) | 2024 | Bajar con una cámara, grabar cosas aterradoras, subir el video a "SpookTube" → las vistas dan dinero → mejoras; cuota de vistas en 3 días | **El juego produce el clip por ti**: el contenido es el resultado de la partida | Gratis 24 h en el lanzamiento → ~6 M reclamos (dato de Landfall), 200 k simultáneos; luego 7,99 USD **[F]** |
| *R.E.P.O.* (Semiwork, Unity) | 2025 | Hasta 6 jugadores cargan objetos frágiles con física hasta puntos de extracción; el daño baja su valor; tienda entre niveles; niveles aleatorios | Cargar entre varios cosas pesadas, romperlas, gritar, monstruos que cazan; humor + horror | ~230 k simultáneos el primer fin de semana (sin cita firme); el juego de pago que más recaudó en Steam la semana del 11 al 18 de marzo de 2025; actualizaciones constantes (0.4.0 en may-2026) **[F]** |
| *Peak* (Aggro Crab + Landfall) | 2025 | Escalar una montaña entre todos con estamina limitada, comida y heridas | Ayudarse físicamente (tirar del otro, objetos que dan estamina al grupo); la voz se pierde si te quedas atrás | Hecho en ~1 mes; 100 k copias en 24 h, 1 M en 6 días, >5 M en junio; 7,99 USD **[F]** |
| *Meccha Chameleon* (dev. solo japonés) | 2026 | Escondite: los escondidos pintan su cuerpo blanco para imitar el escenario; los buscadores tienen tiempo límite | Asimetría escondido/buscador; momentos de "lo tenía enfrente y no lo vi" | 2–24 jugadores, ~6 USD, 1 M copias en 4 días, PC Gamer 82/100 (concepto excelente, software torpe) **[F]** |
| *Among Us* | 2018 | Tripulantes hacen tareas; impostores sabotean; votación | Discusión y mentira en grupo | Considerado precursor **[F]** |

**Lecciones transversales [A]:**
- Ninguno gana por gráficos ni por contenido abundante. IGN dijo que *Lethal Company* "trasciende su contenido limitado". **[F]**
- Todos tienen **una sola idea central fácil de explicar en una frase** ("escondite pintándote", "escalar con amigos", "grabar monstruos para YouTube").
- Todos son **cortos de hacer**: *Peak* tardó ~1 mes. El consejo de Aggro Crab es empezar pequeño. **[F]**
- Meccha Chameleon muestra que un concepto fuerte supera a la ejecución técnica floja. **[F]** Aun así, las quejas por controles torpes y por falta de moderación en lobbies públicos se repiten.

---

## 3. Los 12 pilares (mecánica → razón → acciones concretas)

Cada pilar dice qué hacer, por qué funciona y cómo implementarlo paso a paso.

### P1. Una idea central de una frase
- **Razón [A]:** se entiende en 3 segundos de clip de TikTok o en el título de un stream. La viralidad depende de que el espectador entienda la gracia sin explicación.
- **Acciones:**
  1. Escribir el pitch en ≤ 10 palabras: "[verbo físico] + [con amigos] + [giro absurdo]".
  2. Probarlo: si alguien que no juega no lo entiende al ver 5 s de video, reescribirlo.
  3. Todo lo que no sirva a esa frase se recorta.

### P2. Entrada sin fricción
- **Razón [F]:** baja dificultad de entrada (Bushnell) y precio bajo. El grupo entero tiene que poder entrar, incluido el amigo que no juega. **Un grupo avanza al ritmo de su miembro menos hábil [A].**
- **Acciones:**
  1. Controles: moverse, saltar, agarrar/usar, hablar. Máximo 4–5 acciones.
  2. Tutorial de ≤ 60 s o ninguno: aprender jugando o mirando al amigo.
  3. Unirse a la partida de un amigo en ≤ 2 clics (código de sala o invitación). *Meccha Chameleon* recibió quejas por joins rotos. **[F]**
  4. Partidas de 10–25 min.
  5. Precio bajo o gratis (en Roblox: gratis, con monetización cosmética).

### P3. Voz por proximidad (el pilar más citado)
- **Razón [F]:** da a cada conversación un lugar físico. Si te quedas atrás o caes por un acantilado, de repente no oyes a nadie, y eso crea aislamiento y pánico. **[A]** Convierte la distancia en una mecánica: separarse tiene un costo emocional sin necesidad de reglas.
- **Acciones:**
  1. Volumen según distancia (audio 3D) con un corte a X metros.
  2. Que los muros/puertas atenúen el sonido.
  3. Herramientas que rompen la regla con un costo: walkie-talkie (*Lethal Company*), radio con batería, megáfono.
  4. Los muertos o espectadores no deben oírse con los vivos, o solo deben oírse distorsionados. Así se preserva la tensión. **[A]**
  5. Boca o animación que se mueva al hablar, para saber quién habla. **[F]**
  6. **Plan B sin voz:** emotes, señales (apuntar, ping), chat de texto por proximidad (*Lethal Company* lo tiene **[F]**). En Roblox la voz está restringida por edad y verificación, así que el juego debe funcionar sin voz. **[A]**

### P4. Física torpe y comedia física
- **Razón [F]:** los mejores del género se diseñan alrededor de momentos emergentes de comedia física. **[A]** La torpeza iguala a expertos y novatos, y un fallo se vuelve chiste en lugar de frustración.
- **Acciones:**
  1. Objetos con física real (ragdoll, inercia, rebotes).
  2. Cargar cosas pesadas entre 2+ jugadores (*R.E.P.O.*).
  3. Objetos frágiles cuyo valor baja al golpearse (*R.E.P.O.* **[F]**), para que la torpeza tenga consecuencia y genere gritos.
  4. Ragdoll al morir o caer. El cuerpo queda en el mundo y se puede cargar.
  5. Animaciones exageradas y algo lentas.

### P5. Objetivo compartido con presión (cuota + reloj)
- **Razón [A]:** sin presión no hay historias. La cuota creciente obliga a arriesgarse y el reloj obliga a decidir. Las dos cosas producen discusiones ("¡vámonos ya!" / "uno más").
- **Acciones:**
  1. Meta colectiva medible (dinero, vistas, altura, objetos).
  2. Límite de tiempo visible (medianoche en *Lethal Company*, 3 días en *Content Warning*). **[F]**
  3. La cuota sube en cada ciclo.
  4. Fracaso total si no se cumple (reinicio). Le da peso a cada ronda.
  5. Riesgo/recompensa: más botín = más peso, más tiempo y más peligro. **[F] R.E.P.O.**

### P6. Interdependencia: los compañeros deben ser necesarios
- **Razón [F]:** la crítica de *YapYap* dice que cuando el juego permite hacer todo solo (cargar varias varitas), los compañeros sobran y el juego se siente vacío. **[F]** *Peak* premia quedarse cerca para ayudarse a escalar.
- **Acciones:**
  1. Tareas que exigen 2+ personas (objeto pesado, abrir puerta doble, subir a alguien).
  2. Roles de información: uno ve el mapa y otro actúa (terminal de *Lethal Company* **[F]**).
  3. Recursos que afectan al grupo (un objeto que da estamina a los cercanos, como el Bugle de *Peak* **[F]**).
  4. Revivir o rescatar al caído con una acción interesante, no con un botón.
  5. Regla de diseño: **si un jugador experto puede ganar solo, hay que rediseñar.**

### P7. Amenaza que castiga la separación (horror + humor)
- **Razón [F]:** estar solo convierte unos pasos en terror. **[A]** El monstruo es un "generador de anécdotas": cada encuentro produce una historia para contar. El humor sale del contraste entre el miedo y la torpeza. Por eso *R.E.P.O.* se elogia por su equilibrio entre horror y humor.
- **Acciones:**
  1. 3–6 tipos de amenaza, cada una con **una regla simple y legible** (no mirarla, no hacer ruido, no correr).
  2. Que las amenazas prefieran al jugador aislado.
  3. Sonido anticipatorio (pasos, respiración) antes del ataque.
  4. Muerte rápida y absurda, no humillante a largo plazo.
  5. Alguna amenaza ridícula o tonta mezclada con las serias (contraste cómico).

### P8. La muerte no expulsa: espectar y molestar
- **Razón [A]:** si el muerto se aburre, se va del grupo. Si puede mirar, comentar y reírse, la muerte se vuelve un rato de espectáculo.
- **Acciones:**
  1. Cámara de espectador sobre los vivos.
  2. Chat de muertos separado (P3.4).
  3. Opcional: el muerto interviene un poco (fantasma con un susto, una pista o un sonido).
  4. Rondas cortas para que la espera sea breve.
  5. Mostrar el resumen o la repetición de "cómo murió X" al final.

### P9. Aleatoriedad que fabrica historias
- **Razón [F]:** mapas modulares aleatorios (*R.E.P.O.*) y lunas distintas (*Lethal Company*). **[A]** Hacen que cada partida sea diferente y que el clip "nunca había pasado esto" se repita.
- **Acciones:**
  1. Generación por módulos o salas (barato de producir).
  2. Elegir al azar la posición del botín y de los enemigos.
  3. Eventos raros (1 de cada 20 partidas) que la gente quiera grabar.
  4. Modificadores de ronda (apagón, gravedad baja, niebla).

### P10. Progresión ligera entre rondas
- **Razón [A]:** da un motivo para "una más" sin crear brecha de habilidad entre amigos nuevos y viejos.
- **Acciones:**
  1. Tienda entre niveles con herramientas, consumibles y mejoras del grupo (no individuales). **[F] R.E.P.O.**
  2. Cosméticos y decoración de la base (*Lethal Company*: muebles que incluso afectan la suerte **[F]**).
  3. Progreso por partida (se pierde al fracasar) más cosméticos permanentes.

### P11. Diseñado para ser clipeado (streamer bait)
- **Razón [F]:** los streamers adoptaron *Lethal Company* por sus narrativas emergentes, entre aterradoras e hilarantes. Los clips generan más popularidad y más streamers. *Content Warning* lleva esto al extremo: **el bucle del juego es crear el clip.** **[A]**
- **Acciones:**
  1. Momentos legibles en tercera persona (se ve claro qué pasó).
  2. Sonidos y reacciones exagerados (gritos, ragdoll, explosión de confeti).
  3. Repetición o "foto final" automática compartible.
  4. Una mecánica de "trampa" o traición ligera (empujar, robar, mentir) que genere drama sin romper la cooperación.
  5. Pantalla final con estadísticas graciosas ("murió 3 veces por la misma puerta").

### P12. Lanzamiento y vida: pequeño, rápido, actualizado
- **Razón [F]:** *Peak* se hizo en ~1 mes. *Content Warning* salió gratis 24 h y se volvió viral. *R.E.P.O.* sigue vigente gracias a actualizaciones frecuentes (cosméticos, tienda nueva, modo carreras). *Lethal Company* y *R.E.P.O.* empezaron en acceso anticipado.
- **Acciones:**
  1. Versión mínima jugable en 2–4 semanas con 1 mapa, 2–3 amenazas y 1 bucle.
  2. Lanzamiento con un gancho (gratis por tiempo limitado, código para streamers).
  3. Roadmap de actualizaciones pequeñas cada 2–4 semanas (un monstruo, un mapa o un modo).
  4. Escuchar los clips: lo que la gente graba más se amplía.
  5. Moderación en lobbies públicos (votar expulsión, silenciar). Es una queja recurrente. **[F]**

---

## 4. Anti-patrones (lo que hace fallar a un friendslop)

| Anti-patrón | Por qué falla | Ejemplo |
|---|---|---|
| Compañeros innecesarios | Se vuelve un juego en solitario "con Discord de fondo" | Crítica a *YapYap* **[F]** |
| Bucle repetitivo sin presión | Sin riesgo no hay historias | *YapYap* (colectar o destruir "caos") **[F]** |
| Comunicación forzada que suena igual | Hablar deja de ser divertido | Hechizos hablados en *YapYap* **[F]** |
| Estética copiada | Se ve como un cash-in y activa el uso despectivo de "slop" | **[F]** |
| Controles imprecisos en la mecánica central | Frustra, en lugar de dar risa | Pintar con stick en *Meccha Chameleon* **[F]** |
| Unirse con amigos difícil | Mata el pilar entero | Quejas en *Meccha Chameleon* **[F]** |
| Lobbies públicos sin moderación | Los desconocidos arruinan la experiencia | **[F]** |
| Demasiado contenido y sistemas antes de validar el bucle | Gasta meses sin saber si da risa | Lección de *Peak* (empezar pequeño) **[F]** |

---

## 5. Plantilla para aplicar a cualquier juego

Copiar y rellenar:

```
NOMBRE:
PITCH (≤10 palabras):
JUGADORES: mín __ / ideal __ / máx __
DURACIÓN DE RONDA: __ min

P1 Idea central: __________________
P2 Entrada: controles = [ ], tiempo hasta jugar = __ s, cómo se une un amigo = __
P3 Comunicación: voz por proximidad (radio de __ m) / herramienta que la rompe = __ / plan sin voz = __
P4 Física/comedia: objetos con física = __, qué pasa al fallar = __
P5 Presión: meta = __, reloj = __, cuota creciente = sí/no, fracaso = __
P6 Interdependencia: tareas de 2+ = __, rol de información = __, rescate = __
   ¿Un experto puede ganar solo? (debe ser NO)
P7 Amenaza: lista con su regla de 1 frase = __
P8 Muerte: espectador = __, chat de muertos = __, interacción fantasma = __
P9 Aleatoriedad: qué cambia por partida = __, evento raro = __
P10 Progresión: tienda = __, cosméticos = __, qué se pierde al fracasar = __
P11 Clipeable: momento "wow" esperado = __, pantalla final = __
P12 Plan: MVP en __ semanas, gancho de lanzamiento = __, ritmo de updates = __
```

### Checklist de prueba (con jugadores reales)
- [ ] Un no-jugador entiende el juego viendo 5 s.
- [ ] El grupo se ríe en voz alta antes del minuto 3.
- [ ] Al menos una historia por partida ("¿viste cuando…?").
- [ ] Nadie puede ganar solo.
- [ ] El que muere se queda mirando y no se va.
- [ ] Piden "una más" sin que nadie lo sugiera.
- [ ] Funciona sin voz (emotes/ping/texto).
- [ ] Jugado en solitario se siente incompleto (esto es esperado y confirma el diseño).

### Orden de construcción recomendado [A]
1. Movimiento + física + 2 jugadores en red → ¿da risa moverse juntos?
2. Objetivo + reloj → ¿hay tensión?
3. Una amenaza → ¿hay historias?
4. Voz o señales por proximidad.
5. Muerte → espectador.
6. Tienda y progresión.
7. Aleatoriedad y contenido.
8. Pulido de clip (sonidos, pantalla final).

---

## 6. Notas para Roblox [A]

- Roblox ya da red, servidores y un chat de voz espacial (proximidad) nativo, pero la voz tiene restricciones de edad y verificación. Hay que diseñar el **P3 plan B** (emotes, pings, burbujas de chat) como camino principal.
- La física de Roblox (constraints, ragdoll) cubre P4 sin motor propio.
- El modelo gratuito con cosméticos sustituye al "precio ≤ 20 USD".
- Los "juegos inspirados" de Roblox basados en *Meccha Chameleon* muestran que el mercado copia rápido. **[F]** Importa más la idea central propia que clonar.
- Relación con *Every Choice Counts: Moon Base*: ya tiene P5 (fases, reloj, barras), P6 (roles con mochilas), P7 (emergencias), P8 (espectador al morir) y pantalla final (P11). Lo que más rendiría después de la entrega: P4 (física torpe), P3 (radio con alcance limitado en la superficie lunar) y P11 (estadísticas graciosas al final).

---

## 7. Fuentes

- Wikipedia — Friendslop: https://en.wikipedia.org/wiki/Friendslop
- Wikipedia — R.E.P.O.: https://en.wikipedia.org/wiki/R.E.P.O.
- Wikipedia — Lethal Company: https://en.wikipedia.org/wiki/Lethal_Company
- Aftermath — origen del término y discurso: https://aftermath.site/friendslop-peak-lethal-company-social-media-discourse
- Dexerto — cómo se hizo Peak: https://www.dexerto.com/gaming/embracing-friendslop-how-peaks-devs-turned-one-small-idea-into-the-next-big-thing-3228031/
- PC Gamer — entrevista al jefe de Peak: https://pcgamer.com/games/adventure/peak-boss-doesnt-mind-us-calling-it-friendslop-why-not-make-a-game-where-the-point-is-to-hang-out-with-your-friends
- SUPERJUMP — The Loneliness of Friendslop: https://www.superjumpmagazine.com/the-loneliness-of-friendslop/
- AV Club — Not Every Co-Op Game is Friendslop: https://www.avclub.com/not-every-co-op-game-is-friendslop
- Know Your Meme — Friendslop: https://knowyourmeme.com/memes/friendslop
- Steam — Meccha Chameleon: https://store.steampowered.com/app/4704690/MECCHA_CHAMELEON/
- PC Gamer — reseña de Meccha Chameleon: https://www.pcgamer.com/games/sports/meccha-chameleon-review/
- Mobalytics — guía de Meccha Chameleon: https://mobalytics.gg/news/guides/meccha-chameleon-tips-and-tricks
- Windows Central — Content Warning gratis 24 h: https://www.windowscentral.com/gaming/pc-gaming/co-op-horror-game-content-warning-launches-on-steam-for-free-but-only-for-24-hours
- PC Gamer — Content Warning en las listas de Steam: https://www.pcgamer.com/games/horror/content-warning-a-free-co-op-horror-game-where-you-go-viral-on-spooktube-or-die-trying-is-rapidly-climbing-the-steam-charts
- Peak: ventas en 24 h: https://ground.news/article/aggro-crab-and-landfall-side-hustle-peak-has-sold-100-000-copies-in-24-hours
- Sportskeeda — estamina en Peak: https://www.sportskeeda.com/esports/peak-how-get-unlimited-stamina
- Transcripción de videos aportada por Isaac (opinión de creador: R.E.P.O. y Meccha Chameleon como mejores ejemplos).

Advertencias: varias cifras (230 k de R.E.P.O., 10 M de Lethal Company, 6 M de Content Warning) son estimaciones o anuncios de los propios estudios. Las "razones" de viralidad las afirman comentaristas y no están medidas.
