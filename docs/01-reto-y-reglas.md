# Reto y reglas oficiales (leído en la web el 14-nov-2026)

## El reto

**Build a Junior Astronaut Mission Trainer** (reto #3 de la lista de 14, por orden alfabético).
https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/
Dificultad: Intermediate / Beginner-Youth. Temas: Games, Planets & Moons, Software, Space Exploration, Sun.

### Objetivo (obligatorio)
- Juego o app interactiva para **niños de 7 a 12 años**.
- Gestionar un puesto en la **Luna o Marte** con decisiones reales sobre: **soporte vital, blindaje contra radiación, presupuesto de energía, producción de comida y retraso de comunicación**.
- Ver cómo esas decisiones se desarrollan durante una misión simulada.
- **Ninguna decisión es gratis.** El jugador debe salir entendiendo una restricción real, no solo haber jugado.
- Prototipo que funcione.

### Recomendado
- Datos abiertos reales de la NASA en vez de números inventados: **DONKI** (clima espacial: llamaradas, CME), **OSDR** (salud de astronautas), **RadLab** (dosis de radiación medidas en la ISS), datos de Artemis/Mars Trek.
- **Citar las fuentes dentro del juego.**
- Si no hay API en vivo: dataset real curado embebido, **sin presentarlo como en vivo**.
- Lenguaje simple; explicar en contexto términos como *radiation dose*, *sol*, *microgravity*.
- Baja barrera de entrada (prefieren navegador sin cuenta ni descarga; Roblox exige ambas → explicarlo en la página).
- Que sirva también a hermanos mayores, padres o clase.

### Evitar
- Una opción "segura" sin costo.
- Pulido visual en lugar de mecánica correcta.
- Demasiados sistemas a la vez: **2 o 3 recursos centrales** (soporte vital, energía, blindaje) funcionan mejor que 5 o 6.

### Qué hace destacar
- Conectar la decisión de blindaje con **clima espacial real** (DONKI).
- **Rejugabilidad**: eventos que varían entre partidas; aprender del fallo sin que castigue.
- Explicación corta de **qué datos NASA se usaron y por qué**.

### Recursos de la pestaña Resources
- NASA Open APIs: https://api.nasa.gov/ (APOD, Mars Rover Photos, DONKI; clave gratis)
- DONKI: https://ccmc.gsfc.nasa.gov/tools/DONKI/
- OSDR: https://osdr.nasa.gov/bio/repo/ · búsqueda: https://osdr.nasa.gov/osdr/data/search?term=KEYWORD
- RadLab (dosimetría ISS): https://visualization.osdr.nasa.gov/radlab/gui/data-api/
- Mars Trek: https://trek.nasa.gov/mars/
- CSA (Agencia Espacial Canadiense): recursos STEM y "Food production on the Moon": https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/

## Entrega (Project Submission Guide, 13-nov)

| Tema | Regla |
| --- | --- |
| Apertura | Sábado 14-nov 9:00 hora local |
| **Cierre** | **Domingo 15-nov 23:59** hora del Local Event (Universal Event: hora del Team Owner) |
| Demo | **Video de 30 s máximo** o **7 diapositivas máximo**. Si se pasa, no entra a juzgamiento global |
| Idioma | Todo en inglés. Video en otro idioma solo con subtítulos en inglés |
| Enlaces | Públicos, sin login ni permisos (YouTube, Drive, GitHub…). La página solo acepta imágenes (≤10 MB) |
| Link to Final Project | Enlace público al proyecto final (web, repo, etc.) |
| Campos | Nombre, resumen, demo, proyecto final, descripción detallada, uso de IA ("SI"), datos NASA, otras referencias |
| Datos NASA | **Obligatorio usar al menos 1 dato/recurso NASA** para premios globales |
| Menores | Nada de imágenes, video, audio ni parecido de menores de 18 |
| Originalidad | Casilla "todo es original"; listar todo recurso externo (código, texto, imágenes) aunque sea libre |
| Equipo | 1 a 6 personas, todos en el mismo Local Event (Universal: mínimo 2). No se agregan miembros tras el cierre |
| Reenvío | Se puede editar y reenviar hasta el cierre; cuenta el último |

### Uso de IA ("Super Intelligence", SI)
- Permitido como herramienta; **no para inventar la idea** de solución.
- Lo generado **no puede usar ni modificar marcas NASA** (logos, banderas, identificadores de misión).
- Imágenes y videos generados: **marca de agua visible**. Audio: reconocerlo en texto y metadatos. Código y datos: reconocerlo en texto y metadatos.
- Llevar el registro en `docs/05-registro-ia.md`.

## Criterios de evaluación (1 a 5 cada uno)
1. **Impact**: tamaño del problema y alcance.
2. **Creativity**: originalidad.
3. **Validity**: base científica, factible, usable, fácil.
4. **Relevance**: responde al reto y **los datos NASA son parte central**, no adorno.
5. **Presentation**: historia clara; cuenta el demo y el proyecto completo.

Fechas: Global Nominees se anuncian el 3-dic-2026.

## Consecuencias para nosotros
- El video de 30 s no puede "enseñar todo el juego": debe contar la idea y mostrar 3 o 4 tomas fuertes. La página del proyecto y el repositorio llevan el detalle.
- "Link to Final Project" público sin login: el juego de Roblox exige cuenta → enlazar un **repositorio público (GitHub) o página** con video largo de juego, capturas, código y explicación; el enlace al juego de Roblox va además.
- El reto pide **retraso de comunicación** y **blindaje contra radiación con clima espacial real**: hoy las fases 0–2 cubren energía, soporte vital, comida y radiación (hábitat). Falta meter **DONKI** (tormenta solar real) y el **retraso de comunicación** en la Fase 3.
- El equipo debe confirmar si es Local Event o Universal Event (cambia la zona horaria del cierre).
