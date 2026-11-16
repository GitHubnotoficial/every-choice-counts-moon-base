# Curiosidades del Apolo y de la Luna (para usar en el juego)

Fecha: 2026-11-15. Pedido de Isaac. Cada dato tiene fuente y un nivel de confianza:
- **A** = fuente primaria NASA (o agencia) con el dato textual.
- **B** = varias fuentes serias coinciden, pero no encontré la página NASA exacta.
- **C** = popular pero sin confirmar. **No usar en el juego** hasta tener fuente.

La columna "Frase para el juego" está en inglés corto, apta para niños. Si alguna se usa, va a `Config.luau` y a `docs/06-fuentes.md`.

---

## 1. Lo que hicieron los astronautas del Apolo

| # | Dato | Confianza | Frase para el juego | Dónde encaja |
|---|---|---|---|---|
| 1 | **Martillo y pluma (Apolo 15, 2-ago-1971).** Dave Scott soltó a la vez un martillo y una pluma de halcón frente a la cámara. Cayeron juntos, como predijo Galileo: sin aire, todo cae igual de rápido. La pluma era de halcón porque el módulo lunar se llamaba *Falcon*. | A | "Apollo 15: a hammer and a feather fell at the same speed. No air on the Moon!" | Al soltar o colocar objetos en la Fase 1 (Placement). Pantalla de carga. |
| 2 | **Golf en la Luna (Apolo 14, 1971).** Alan Shepard llevó escondida la cabeza de un palo de golf (hierro 6) y dos pelotas. Las pelotas siguen allá. Las distancias que se cuentan varían mucho según la fuente. | B (el hecho) / C (la distancia) | "Apollo 14: Alan Shepard played golf on the Moon. The balls are still there." | Pantalla de carga. Objeto escondido en el mapa (easter egg). |
| 3 | **Caídas (dato que ya usa el aplastón).** Ninguna caída conocida en el Apolo 11; 2 probables en el 12; ninguna en el 14; 4 en el 15; **12 en el 16**; 9 en el 17. Ninguna causó heridas ni fugas en el traje: "the multi-layered, soft suit was forgiving". | A | (ya está en `Config.Stomp.Fact`) | Aplastón. |
| 4 | **Guardabarros arreglado con mapas (Apolo 17).** Gene Cernan rompió sin querer el guardabarros del vehículo lunar con el martillo que llevaba en el bolsillo. La cinta adhesiva no pegaba por el polvo. Por consejo de Control de Misión, pegaron 4 mapas plastificados con forma de guardabarros y los sujetaron con 2 pinzas. Los mapas están hoy en el museo del Smithsonian. | A | "Apollo 17: astronauts fixed their Moon buggy with maps and tape." | Misiones de reparación de la Fase 2. Encaja con "Build a filter from spare parts". |
| 5 | **El polvo lunar huele a pólvora quemada.** Varios astronautas (Charlie Duke en el Apolo 16, Harrison Schmitt en el 17) lo notaron al quitarse el casco dentro del módulo. | B | "Astronauts said Moon dust smells like burnt gunpowder." | Al entrar al hábitat o a la nave. |
| 6 | **Alergia al polvo lunar.** Harrison Schmitt (Apolo 17) estornudó, con ojos rojos y nariz tapada, después de quitarse el casco. Se le llama la primera "fiebre del heno extraterrestre". | B | "Apollo 17: Harrison Schmitt got 'hay fever' from Moon dust." | Tarea diaria "Check the hatch seals" (ya habla del polvo). |
| 7 | **Espejos que todavía se usan.** El Apolo 11 dejó reflectores, y el 14 y el 15 dejaron más. Desde la Tierra se les dispara un láser y, por el tiempo de ida y vuelta, se mide la distancia. Así se sabe que **la Luna se aleja unos 3,8 cm por año**. | A | "Apollo left mirrors on the Moon. Lasers from Earth still bounce off them!" | Emergencia de la antena o el Captain. Hecho de la pantalla final. |
| 8 | **382 kg de muestras.** Las 6 misiones que alunizaron trajeron 382 kg de rocas y suelo (2.196 muestras, según la página NASA de muestras lunares). **12 personas** caminaron en la Luna, entre 1969 y 1972. | A (382 kg en NASA Moon Facts) / B (2.196 y 12) | "Apollo brought back 382 kg of Moon rocks." | Pantalla final. Misión de recoger muestras. |
| 9 | **La Luna "suena como campana".** Los sismómetros del Apolo registraron sismos lunares que duraban mucho más que en la Tierra, porque la Luna es seca y rígida. Algunos sismos superficiales duraron más de 10 minutos. El famoso "casi una hora" del impacto del Apolo 12 **no está confirmado**: no usar. | B (lo de la campana y los más de 10 minutos) / C (la hora) | "Moonquakes can shake for more than 10 minutes." | Idea de emergencia nueva: sismo lunar. |

---

## 2. Datos de la Luna

| # | Dato | Confianza | Frase para el juego |
|---|---|---|---|
| 10 | Gravedad: **1/6** de la de la Tierra. | A | (el juego ya la usa) |
| 11 | Siempre vemos la misma cara: la Luna tarda **27 días** en dar una vuelta a la Tierra y lo mismo en girar sobre sí misma (rotación sincrónica). Las fases se repiten cada **~29 días**. | A | "The Moon always shows us the same face." |
| 12 | Temperatura: **~127 °C al sol** y **~-173 °C a oscuras** (NASA Moon Facts). | A | "Sun side: 127 °C. Dark side: -173 °C." |
| 13 | Distancia media: **384.400 km**. Entre la Tierra y la Luna caben unos **30 planetas Tierra**. | A | "You could fit 30 Earths between Earth and the Moon." |
| 14 | Sin aire que respirar: solo una "exosfera" finísima. Sin aire tampoco hay sonido ni viento. | A (exosfera) | "No air on the Moon: no wind, no sound." |
| 15 | Agua: Chandrayaan-1 (2008) detectó hidroxilo, más concentrado en los polos, y SOFIA confirmó moléculas de agua en el cráter Clavius (2020). | A | "Scientists found water on the Moon in 2020." |
| 16 | Más de **105 naves robóticas** han ido a la Luna. | A | — |

### Cráter Shackleton (donde está nuestra base)
| # | Dato | Confianza | Frase para el juego |
|---|---|---|---|
| 17 | Está en el **polo sur**. Su interior **nunca recibe luz del Sol** por la poca inclinación de la Luna (~1,5°), y el borde recibe luz casi todo el tiempo. Por eso se eligió como posible zona de alunizaje de Artemis III. | A (página NASA del cráter) / B (Artemis III) | "Inside Shackleton crater the Sun never shines." |
| 18 | Tamaño: unos **21 km de ancho y 4 km de hondo**. Las fuentes dan cifras algo distintas (20–21 km). | B | "Shackleton crater is about 21 km wide." |
| 19 | En sus zonas de sombra permanente puede haber **hielo de agua**, porque los gases que llegan se congelan. ShadowCam no vio hielo evidente en la superficie. Es tema abierto. | B | "Shadowed craters may hide ice. Scientists are still checking." |
| 20 | Un estudio (Schörghofer, Weizmann) dice que el cráter lleva unos 3.500 millones de años en sombra, pero que solo es "trampa fría" desde hace unos 500 millones. | B | — |

### Lo más reciente
| # | Dato | Confianza | Frase para el juego |
|---|---|---|---|
| 21 | **Artemis II (abril de 2026):** Reid Wiseman, Victor Glover, Christina Koch (NASA) y Jeremy Hansen (CSA) rodearon la Luna. El 6 de abril superaron el récord de distancia del Apolo 13 de 1970: llegaron a unos **406.771 km** de la Tierra (las cifras varían un poco según el medio). | A (comunicado NASA) | "In 2026, Artemis II flew farther from Earth than any humans ever." |

---

## 3. Popular pero sin confirmar (no usar todavía)
- "Las huellas duran millones de años": la idea (sin viento ni lluvia) es correcta, pero no encontré una cifra de la NASA. Si se usa, decir solo "Footprints can last a very long time because there is no wind."
- La distancia exacta del golpe de golf de Shepard.
- El "casi una hora" del sismo del Apolo 12.

---

## 4. Revisión de un dato que ya está en el juego
- La emergencia FREEZING NIGHT dice "-133 °C" cerca del ecuador de noche, y **no tenía fuente en `06-fuentes.md`**. Ya se la puse: hoja de datos de la NASA sobre el Diviner del LRO, que da -208 °F (unos -133 °C, 140 K) de noche en el ecuador. NASA Moon Facts da -173 °C "en la oscuridad" en general, y el mínimo justo antes del amanecer es aún menor (~95 K, Paige et al. 2016). No se contradicen: hablan de lugares y momentos distintos. El texto del juego dice "near the Moon's equator", así que está bien.

---

## 5. Cómo meterlo en el juego (de menos a más trabajo)
1. **Pantallas de carga y transiciones** (Transition12, Transition23): rotar 1 dato al azar de la tabla. Es lo más barato y lo que más enseña.
2. **Hecho final**: en la pantalla de victoria o derrota, añadir "Did you know?" con un dato al azar.
3. **Dato en el momento justo**: el martillo y la pluma al soltar un objeto en Placement; el guardabarros con mapas en una reparación; el olor del polvo al entrar al hábitat.
4. **Easter egg**: una pelota de golf escondida cerca de la nave con un ProximityPrompt que cuenta lo del Apolo 14.
5. **Emergencia nueva**: un sismo lunar (más trabajo, por eso para después de la entrega).

---

## Fuentes
- NASA NSSDC — The Apollo 15 Hammer-Feather Drop: https://nssdc.gsfc.nasa.gov/planetary/lunar/apollo_15_feather_drop.html
- NASA Solar System — The Apollo 15 Hammer-Feather Drop: https://solarsystem.nasa.gov/resources/329/the-apollo-15-hammer-feather-drop
- NASA ALSJ — Working on the Moon: Grab, Kneel, Fall, Rise: https://nasa.gov/wp-content/uploads/static/history/alsj/WOTM/WOTM-GrabKneelFallRise.html
- NASA ALSJ — Apollo 17 New Fender: https://www.nasa.gov/history/alsj/a17/A17NewFender.html
- Smithsonian NASM — Duct Tape Auto Repair on the Moon: https://airandspace.si.edu/stories/editorial/duct-tape-auto-repair-moon
- History.com — cosas que hicieron los astronautas (golf): https://www.history.com/articles/things-moon-astronauts-apollo
- AP/ClickOnDetroit — Shepard puso el golf en la Luna hace 50 años: https://www.clickondetroit.com/sports/2021/02/05/out-of-this-world-shepard-puts-golf-on-moon-50-years-ago/
- Nautilus — The Moon Smells Like Gunpowder: https://nautil.us/the-moon-smells-like-gunpowder-261483
- Mental Floss — The Apollo astronaut who was allergic to the Moon: https://www.mentalfloss.com/science/space/apollo-astronaut-who-was-allergic-moon
- NASA JPL — The Apollo experiment that keeps on giving: https://jpl.nasa.gov/news/the-apollo-experiment-that-keeps-on-giving/
- NASA Goddard — Measuring the Moon's Distance: https://eclipse.gsfc.nasa.gov/help/ApolloLaser.html
- NASA Moon Facts: https://science.nasa.gov/moon/facts/
- NASA JSC — muestras lunares del Apolo: https://ares.jsc.nasa.gov/Astromaterials3D/apollo-lunar.htm
- Smithsonian Magazine — datos sísmicos de hace 50 años: https://www.smithsonianmag.com/smart-news/50-year-old-moon-data-reveals-new-seismic-activity-180956722/
- Popular Science — ¿La Luna suena como campana?: https://www.popsci.com/does-moon-sound-like-bell/
- NASA Science — Shackleton Crater's Illuminated Rim, Shadowed Interior: https://science.nasa.gov/resource/shackleton-craters-illuminated-rim-shadowed-interior/
- NASA — ShadowCam y regiones en sombra permanente: https://www.nasa.gov/blogs/missions/2023/02/09/nasas-shadowcam-images-permanently-shadowed-regions-from-lunar-orbit
- Weizmann Institute — The Moon's dark secret: https://weizmann-usa.org/news-media/feature-stories/the-moon-s-dark-secret/
- NASA — Artemis II crew eclipses record for farthest human spaceflight: https://www.nasa.gov/news-release/nasas-artemis-ii-crew-eclipses-record-for-farthest-human-spaceflight
