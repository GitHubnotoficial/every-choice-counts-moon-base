# Every Choice Counts: Moon Base

**The only Moon base game where the Sun is real.** Its space weather follows live NASA DONKI data: the solar flares, CMEs and geomagnetic storms your crew survives are the ones the real Sun produced this week.

A cooperative Roblox game for kids aged 7 to 12, made for the **NASA Space Apps Challenge 2026**, challenge
**"Build a Junior Astronaut Mission Trainer"**.

Four players form a lunar crew. Each player has a role: **Captain, Engineer, Life Support or Botanist**.
Together they choose what to bring, where to land and how to build a base near the Moon's south pole. Then they
have to keep it alive for 7 days. Every choice changes oxygen, water, food, energy and radiation, and the game
always explains **why** with a real fact from NASA.

> Team: Isaac Gerardo Daniel Romero Alviarez, Leticia Fernández, María Celeste Salinas Viloria, Ramón Gregorio Araujo Mayorca, Yamir Jhosue Soteldo León and Larry Jesus Sanchez Silva.

## How a game goes (18 to 28 minutes)

| Phase | What the crew does |
| --- | --- |
| 0. Earth | Each role picks one option in its own room (ship, power source, life support, food). Every option shows where it was used for real. The Captain launches. |
| Launch | Inside the capsule the crew lies on their backs (as in a real launch), with a countdown and shaking. Then the rocket lifts off and flies to the Moon. |
| 1. Moon | The Captain picks a landing site among 5 real Artemis candidate regions. The crew places the habitat, power, life support and greenhouse. Placing things in the wrong spot has a cost. |
| 2. Missions | One hands-on mission per role (beacons, solar panels or radiators, filters and ice drilling, planting). Unfinished missions make the next phase harder. |
| 3. Survival | 7 short days. Daily maintenance tasks, harvests, blackouts, and **space weather emergencies**: solar flare, coronal mass ejection, high CO₂, radiation alarm, mold and freezing night. Each emergency gives 3 choices (A, B, C) with real consequences. |
| End | The rescue ship arrives (mission complete) or the crew is lost. Either way, the end screen explains what happened and gives a tip and a real fact. |

## What players learn

- **Resources are linked.** Energy runs the machines that make oxygen and water; choices in one role affect the others.
- **Space weather is real.** Solar flares cut radio contact; radiation storms send the crew to the shelter.
- **Communication has a delay.** Messages to and from Mission Control take about 1.3 s each way (384,400 km at the speed of light). Players can call Earth from the antenna and feel the round trip.
- **Teamwork matters.** Any player can help another role, and a fallen player's belt can be picked up to keep their role alive.

## NASA data and resources used

- **NASA DONKI** (Space Weather Database Of Notifications, Knowledge, Information): the solar flare and coronal mass ejection emergencies are based on real DONKI event types, with real dates and classes (for example the X9.0 flare of October 3, 2024).
- **NASA SDO / Scientific Visualization Studio** (animation 11270): reference for how the Sun looks during a flare.
- **Artemis III candidate landing regions** (NASA, 2022 and 2024): the 5 landing sites.
- **LRO Diviner** temperature data: day and night temperatures for the freezing-night emergency.
- **ISS ECLSS** (98 % water recovery), **CaRD** (oxygen from lunar soil simulant), **Veggie / Advanced Plant Habitat**, **KRUSTY / Fission Surface Power**, **BEAM**, Apollo, Artemis and commercial lander missions: facts shown with every option.
- **Apollo Lunar Surface Journal**: falls on the Moon during Apollo.

The full list with links is in [`docs/06-fuentes.md`](docs/06-fuentes.md). Game numbers (weights, timers, energy
values) are game balance, not real data.

## Use of AI

AI was used as a tool, never to invent the solution idea. The game design came from the team's own phase
documents. Claude (Anthropic, through Claude Code) helped write and debug Luau scripts from those documents,
built some low-poly models by code and drafted documents. Some 3D models and slide backgrounds were made with
image and 3D AI tools. No AI content uses NASA logos, flags or mission identifiers. The complete log is in
[`docs/05-registro-ia.md`](docs/05-registro-ia.md).

## Code

- `src/` is the source of truth (Luau). Studio receives copies.
  - `ServerScriptService/` game flow (`GameManager`), phases, missions, emergencies, day cycle, communication delay.
  - `StarterPlayer/StarterPlayerScripts/` HUD, lighting, capsule scene.
  - `ReplicatedStorage/Config.luau` every number and text of the game.
- `docs/` design, architecture, sources, AI log and the 7-slide presentation.
- `tools/` helper scripts (3D models by code, Studio bridge).

## License

Apache License 2.0. See [`LICENSE`](LICENSE).
