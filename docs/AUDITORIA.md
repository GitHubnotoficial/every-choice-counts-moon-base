# Auditoría del juego (15-nov, tarde)

Revisión de la lógica de los scripts, los tiempos y los eventos posibles. Fuente: `src/` y los scripts del equipo en "00 Inicio".

## 1. Tiempos de una partida

| Fase | Duración | ¿Termina antes? |
|---|---|---|
| Título | hasta que alguien pulsa PLAY | — |
| Elección de rol | 30 s | no |
| Instrucciones (Briefing) | 20 s | sí, cuando todos pulsan READY |
| Fase 0: elegir equipo | 1:30 | no (tiempo fijo para hablar y elegir) |
| Lanzamiento | 15 s | sí, cuando el Captain lanza. Si no lanza: **Mission Failed** |
| Paso 0 → 1 | 10 s | sí, todos CONTINUE |
| Elegir sitio | 1:00 | sí, cuando el Captain elige |
| Aterrizaje | hasta 8 s | sí, al tocar suelo |
| Colocar módulos | 5:00 | **sí (nuevo):** 10 s después de colocar los 4 objetos |
| Paso 1 → 2 | 10 s | sí, todos CONTINUE |
| Inicio Fase 2 | 10 s | sí, todos READY |
| Fase 2: misiones | 4:00 | **sí (nuevo):** 10 s después de completar las 4 misiones |
| Paso 2 → 3 | 10 s | sí, todos CONTINUE (**pantalla nueva**) |
| Fase 3: 7 días × 2:00 | 14:00 | no (si muere toda la tripulación, termina antes) |
| Rescate (si ganan) | 12 s | no |
| Pantalla final | hasta que todos pulsan PLAY AGAIN | — |

- **Partida completa, lenta (todo el tiempo):** ~27,5 min.
- **Partida rápida (todos atentos):** ~18 min.
- La Fase 3 es casi la mitad del juego.

## 2. Eventos que pueden ocurrir

**Fase 0**
- Carga de más: por cada 10 de exceso, −5 % de oxígeno y agua iniciales (mínimo 40 %).
- Starship HLS: llega un día tarde (−10 % de oxígeno y agua).
- Si alguien no elige, se le asigna una opción al azar.
- Si el Captain no lanza en 15 s: **MISSION FAILED** y se vuelve a elegir rol.

**Fase 1**
- Aterrizaje inclinado si el terreno del sitio es < 5 (Nobile 3,5 y Malapert 4): −5 % de oxígeno.
- Mover un objeto ya colocado lo puede dañar: 20 % la 1.ª vez, 40 % la 2.ª, 60 % la 3.ª o más.
- Si se acaba el tiempo, lo que falta se coloca solo en el punto más cercano.
- Barras de oxígeno y agua: bajan a la mitad de velocidad en las Fases 1 y 2.

**Fase 2**
- Misiones: balizas (Captain), paneles/batería/radiador (Engineer), filtros/válvulas/hielo/regolito (Life Support), sembrar o contar comida (Botanist).
- Reparaciones: cualquiera, mantener E 10 s.
- Misión sin hacer: la máquina produce la mitad en la Fase 3; sin balizas no llega la nave de carga; sin misión del Engineer la eyección de masa coronal no está protegida.

**Fase 3 (cada día)**
- Día 1: siempre tranquilo.
- Días 2 a 6: puede salir **una** emergencia entre el segundo 20 y el 80 del día (unas 4 de cada 10 veces). Tras 2 días tranquilos seguidos, sale una sí o sí.
- Día 7: siempre sale una, del rol con más problemas (dañado, sin misión, apagón o respondió C).
- **Emergencias (6):**
  - Solar flare (Captain, 10 %): corta la radio; la antena se desalinea. A = subir a la antena.
  - Coronal mass ejection (Engineer, 8 %): sobrecarga. Si el Engineer hizo su misión: PROTECTED.
  - High CO₂ (Life Support, 8 %, si hay máquina): el oxígeno de todos baja ×1,5 hasta arreglarlo.
  - Radiation alarm (Life Support, 7 %): los medidores; afuera sube más la radiación.
  - Mold (Botanist, 7 %, si hay bandejas): se pierden bandejas.
  - Freezing night (Botanist, 7 %): el frío daña cultivos o comida (más si el invernadero es inflable).
- Un objeto dañado sube +5 puntos la probabilidad de la emergencia de ese rol.
- **Apagón:** si la energía usada > producida, cada día se apaga una cosa por turnos: invernadero → máquina → hábitat.
- **Día 4:** nave de carga (+15 % de reserva) si el Captain puso las 3 balizas.
- Cosechas: cada bandeja crece en 2:30 y se cosecha con E (+0,5 de comida, +2 % de oxígeno).
- Sin comida: todos caminan lento.
- Muerte: oxígeno en 0, o agua en 0 durante 2 min. Con radiación al 100 % el oxígeno baja ×2,5. Al morir se ve por qué; queda un cinturón que otro puede recoger para elegir en las emergencias de ese rol.
- Si muere toda la tripulación: MISSION FAILED con la sección WHY YOU LOST.
- Día 7 completo: nave de rescate y MISSION COMPLETE.

## 3. Lo que se arregló en esta auditoría

1. La pantalla final podía no salir si moría toda la tripulación en la Fase 3 (el juego quedaba trabado).
2. Partida nueva: quedaban naves, cinturones y jugadores muertos invisibles.
3. Studio a medias: Bars nuevo sin sus textos en Config (la primera muerte detenía las barras de todos).
4. El paso de la Fase 2 a la 3 no tenía pantalla (10 s en blanco y nadie podía pulsar CONTINUE).
5. La colocación y la Fase 2 esperaban siempre el tiempo completo aunque todo estuviera hecho.
6. Paneles solares de espaldas al Sol; maquetas del Engineer mirando a la pared.
7. Datos curiosos: duraban 6 s; ahora entre 12 y 25 s según el largo.
8. Mission Failed: ahora dice qué hacer la próxima vez y trae un dato real.

## 4. Pendiente / para tener en cuenta

- **Días vacíos en la Fase 3:** resuelto con tareas diarias de mantenimiento (DailyTasks).
- **Texturas MoonRegolith / MoonRock** (MaterialService → AssistantMaterials): son de otra cuenta y no cargan para Isaac ni en el juego publicado.
- **RoleSelectGui (Celeste):** busca "Background" y su marco se llama "background".
- La Fase 0 no tiene forma de terminar antes (1:30 fijos).
- Textos sueltos en el HUD que deberían ir en Config ("Days: …", "ran out of oxygen").
- Emergencias con objetos y animaciones como las misiones: hecho (15-nov noche).
- 10 emergencias más: tarea para las IAs del equipo (`docs/tareas/IAS-PENDIENTES.md`).
