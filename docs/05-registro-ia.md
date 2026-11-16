# Registro de uso de IA ("Super Intelligence") para la entrega

La entrega exige decir dónde y cómo se usó IA. Imágenes/videos generados: marca de agua visible. Audio, código y datos: reconocerlo en texto y metadatos. La IA no inventa la idea de la solución.

| Fecha | Herramienta | Qué hizo | Dónde quedó | Revisado por |
| --- | --- | --- | --- | --- |
| 14-nov | Claude (Claude Code) | Organizó documentos de trabajo y resumió las especificaciones escritas por el equipo | `docs/` | Isaac |
| 14-nov | Claude (Claude Code) | Escribió los scripts del núcleo y de la Fase 3 (GameManager, RolesAndSuits, Energy, BuildMoonSite, Bars, Resources, DayCycle) a partir de las especificaciones del equipo | `src/` | Isaac (pendiente de prueba) |
| 15-nov | Leonardo AI | Generó el modelo 3D de la nave de carga (NASA_Cargo_Lander.glb). Trae logo NASA y bandera: hay que quitar la textura antes de usarlo | `assets/` | Isaac |
| 15-nov | Claude (Claude Code) | Escribió Missions (Fase 2), arreglos de Placement/Phase1UI, puente de pantallas y respaldo de bandejas | `src/` y Studio | Isaac |
| 15-nov | Claude (Claude Code) | Escribió MoonExtras (cráter, hábitat con interior, nave elegida), cielo con estrellas reales y animaciones de misiones | `src/` y Studio | Isaac |
| 15-nov | IA de imágenes (usada por Celeste; herramienta por confirmar) | Generó 8 ilustraciones de base lunar usadas como fondos de la presentación | `assets/slides/bg*.jpg` | Celeste, Isaac |
| 15-nov | Claude (Claude Code) | Armó la presentación de 7 diapositivas en inglés con datos del juego real (`docs/make_deck.js`) | `docs/Every_Choice_Counts_Moon_Base.pptx` | Isaac |
| 15-nov | IA usada por Ramón (por confirmar) | Modelos 3D de la Tierra, el Sol y el Sol en tormenta solar | `assets/ramon/`, Studio `SO_SkyModels` | Ramón, Isaac |
| 15-nov | Claude (Claude Code) | Generó por código (sin IA de imágenes) 3 modelos low-poly estilo caricatura: planta de O₂ de regolito, estación de recarga O₂/agua y reactor con aletas radiadoras, según el prompt de Isaac | `assets/claude/*.glb`, `tools/modelos3d/make_models.js` | Isaac |
| 15-nov | Claude (Claude Code) | Generó por código el tanque de electrólisis (agua → O₂ + H₂) para decorar el cuarto de Soporte Vital | `assets/claude/Electrolysis_Water_Tank.glb` | Isaac |
| 15-nov | Claude (Claude Code) | Escribió el aplastón (SO_Stomp, SO_StompClient, Config.Stomp), idea de Leticia + Isaac | `src/` y Studio | Isaac |
| 15-nov | Claude (Claude Code) | Escribió SO_EasterEggs, SO_DidYouKnow y sus textos en Config (datos con fuente) | `src/` y Studio | Isaac |
| 15-nov | Claude (Claude Code) | Escribió las animaciones de las emergencias, la cabina del cohete (SO_Cockpit), el retraso de comunicación (CommsDelay) y redactó README, LICENSE y los textos del formulario (`docs/SUBMISSION.md`) | `src/`, raíz y `docs/` | Isaac |
| 15-nov | Claude (Claude Code) | Easter eggs v3: modelos de martillo, pluma y reflector; SO_EggsClient (brazos y láser); Config.MoonSky | `src/` y Studio | Isaac |
