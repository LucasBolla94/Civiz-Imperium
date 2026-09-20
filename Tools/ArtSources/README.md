# V0.0.6.1 — fontes da arte

`export_art_references.gd` extrai os exemplos já pintados no projeto, sem coordenadas inventadas das folhas. `build_gold_assets.py` compõe GOLD-01 a GOLD-05 com os pixels desses exemplos, dos minerais e do forno existentes. O corpo e a atividade do forno são camadas separadas; os quatro quadros de fogo preservam seu registro. O script gera PNGs RGBA nas dimensões contratuais e a folha de revisão `Tests/v0061_gold_assets.png`.

Os minerais usam a região (32,16,16,16) de `stone with minerals.png`, deslocada dois pixels para cima para apoiar a carga em (8,12); os exemplos Building-3 e Stone vêm das cenas originais. O lingote foi gerado como um único sprite transparente, preservado em `gold_bar_original.png`, depois ajustado à área útil de 14 × 11 pixels dentro da pilha 16 × 16. A integração usa amostragem nearest, sem suavizar os pixels. Nenhuma alteração foi feita nas folhas originais.

## Prompt do lingote — GOLD-02

Create ONE inventory sprite for Civiz Imperium, a cozy top-down pixel-art colony game. A single small trapezoidal GOLD INGOT, warm yellow upper plane, ochre side, very dark brown clean outline, lit from upper left. Match the simple chunky square pixel clusters and earthy palette of the reference spritesheet. This new deliverable is ONLY one isolated ingot, not a sheet and not a rock. No text, numerals, symbols, sparkles, glow, shadow outside the sprite, UI frame, or scenery. Authentic very low resolution 16-by-16-pixel sprite design shown enlarged with hard square pixel edges: keep the silhouette and three flat planes legible when reduced to a native 16 px game item. Center horizontally, resting around three quarters down the image, with even generous empty transparent margins. Actual transparent RGBA background with no white fill or baked checkerboard. Output a single finished polished sprite.

Referência enviada: `Assets/Objects/Exterior/Mine and Dungeon/stone with minerals.png`.

## Prompt do emblema — BRAND-01

Use case: logo-brand. Create a polished visual emblem for the cozy pixel-art island colony strategy game Civiz Imperium. This is a standalone emblem to sit beside an independently rendered editable game title, so NO lettering or text in the image. A small warm sandstone castle tower crowned with a simple gold crown, on a grassy island above two elegant teal wave shapes, framed by a restrained pair of leafy branches. A strong memorable silhouette, cohesive compact heraldic composition, welcoming and dignified rather than aggressive. Genuine crisp pixel art with intentional square pixel clusters, a restrained ochre/gold, warm brown, forest green and deep teal palette, upper-left illumination, dark clean outline. No gradients, no blur, no photorealistic or 3D treatment, no loose tiny decorative particles. Center the emblem with generous even transparent margins. Truly transparent RGBA background, not white, no checkerboard pattern baked in. The emblem must remain recognizable when displayed at 96px tall in a game menu. Deliver one finished emblem, not a mockup, not multiple variants.

Arquivo final: `Assets/UI/Brand/civiz_emblem.png`. PNG RGBA original, 1254 × 1254, alfa real de 0 a 255; o nome do jogo continua editável no menu.

## Fontes e licenças

- [Atkinson Hyperlegible, repositório Google Fonts](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegible): leitura e controles, versões Regular e Bold. Copyright Braille Institute of America, Inc.; licença SIL OFL em `Assets/UI/Fonts/Atkinson-OFL.txt`.
- [Cinzel, repositório Google Fonts](https://github.com/google/fonts/tree/main/ofl/cinzel): título e identidade. Copyright The Cinzel Project Authors; licença SIL OFL em `Assets/UI/Fonts/Cinzel-OFL.txt`.

Arquivos obtidos dos respectivos diretórios oficiais em 20/09/2026. As licenças completas acompanham os arquivos no projeto.

## Porto — GOLD-06

`Tools/build_port_assets.py` recompõe pixels nativos de `Bridge Beach Tileset.png`, `Fence Wood.png`, `Fish Crate.png` e `Building-1.png` exportado do catálogo. As quatro imagens mantêm luz e telhado na mesma perspectiva; apenas as posições lógicas do píer, entreposto e caixas mudam com a costa. Nenhuma água, terreno ou personagem é incorporado ao PNG. Saídas: quatro sprites RGBA de 80×96, ícone 32×32 e `trading_port_layout.json` com origem de grade (0,16), apoio (40,96), máscaras de terra/água, carga, atracação e aproximação. `Tests/v0061_port_assets.png` é uma folha de revisão separada dos arquivos de produção. O jogo usa os quatro quadros existentes de `Wood Boat.png` em escala 0,25 (44×28 por quadro), mantendo as mesmas cores e filtragem nearest.
