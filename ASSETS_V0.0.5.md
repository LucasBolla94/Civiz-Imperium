# Civiz Imperium — Assets V0.0.5

- Versão alvo: **0.0.5**.
- Revisão compartilhada: **43**.
- Plano correspondente: [PLANO_V0.0.5.md](PLANO_V0.0.5.md).
- Estado: **duas composições produzidas, integradas e validadas na V0.0.5**.
- Este documento contém apenas arte a criar. Alterações sem arte nova ficam no plano.


## Correção visual — revisão 37 (20/09/2026)

O usuário pediu explicitamente refazer o Hortifruti sem fundo branco. A005-04 e A005-07 substituídos nos mesmos caminhos, via ferramenta imagegen integrada. Normalização mecânica no Godot por nearest, preservando alpha: 32×32, silhueta (2,6,28,24), e 16×16, silhueta (1,4,14,11). Fruta vermelho-alaranjada e vegetal verde, sem embalagem. Os originais gerados foram mantidos no diretório de imagens do Codex.

Além da arte, o plano registra a referência persistente das texturas e a horta abaixo dos personagens. Validação visual em `Tests/v005_visual_fix.png`: pilhas sobre grama sem quadrados brancos e personagens inteiros nas quatro células. Teste automatizado valida dimensões, transparência, cores, retenção das texturas e pixels visíveis dos personagens.

### Prompts finais usados na ferramenta integrada

**Ícone:** Create a polished production-ready tiny pixel-art game inventory sprite of mixed harvested produce, ONE red-orange round tomato fruit in front of ONE small leafy green cabbage, no container. Output ONE standalone RGBA PNG with genuinely transparent alpha background, absolutely NO white rectangle, no checkerboard painted into image, no backdrop, no ground shadow, no text. Draw it as a clean manually crafted 32 by 32 pixel sprite with a 2 pixel transparent margin, crisp stair-step pixels, dark brown-green outline, tiny top-left highlights, restrained 12-color palette warm red/orange and leaf green to match a cozy top-down 16px-tile farming colony game. Compact balanced silhouette; simple recognizable individual fruit and folded leaves, avoid noisy details. Canvas square, asset centered and filling 85% of width. Desired final native size 32x32; if generating at a larger resolution, emulate exactly that low-resolution pixel grid without smoothing.

**Pilha:** Create ONE tiny standalone game-world ground loot sprite: a small red-orange harvested tomato with a compact folded green leafy vegetable tucked just behind it. No container or basket. This is the 16x16-pixel world version of a mixed produce resource for a top-down pixel-art farming colony game. Genuinely transparent RGBA PNG alpha background, no white rectangle or checkerboard backdrop, no text, no surrounding scene, no ground patch, no cast shadow. Very simple chunky pixel-art silhouette, dark warm brown/green one-pixel outline and readable red-orange plus green blocks, only a few highlight pixels on upper left. Must be designed for 16x16 native resolution, not a detailed illustration shrunk down: use approximately 14 by 12 visible chunky pixels centered in square transparent canvas, 1px minimum margin, base near y14, pivot8,12. If output resolution is larger, emulate that exact low-resolution logical pixel grid with crisp square blocks and no antialiasing. Polished matching cozy RPG tileset art; one fruit and one leafy vegetable only, approximately equal size.

## Entrega — revisão 36

A005-04 e A005-07 foram produzidos com referências do pacote existente e integrados. Os PNGs finais foram normalizados aos tamanhos contratados com nearest, preservando transparência real; originais do pacote mantidos. A revisão 36 acompanha a entrega do plano e o pedido adicional de população conforme casas disponíveis, que não requer imagem nova.

Conferidos: 32×32 e 16×16, RGBA, margens de 2/1 px, ícone no HUD, pilha com pivô (8,12), legibilidade em escala nativa e ampliada, terrenos claros/grama, quantidades e recuperação logística. Captura do pacote jogável: `Tests/v005_portable.png`; testes `test_v005.gd` e `test_v005_edges.gd`. Não há placeholder nem encomenda visual pendente.

## Encomendas restantes após revisão do pacote adicionado

Machado, picareta, madeira, pedra e cultivos possuem sprites existentes; suas reutilizações estão no plano do jogo e não são mais encomendas de geração. Restam abaixo somente a composição do ícone e da pilha de Hortifruti (Produce). Preferir adaptar os elementos existentes; não gerar recursos individuais por cultivo.

Referências: árvores em Scenes/Objects_Exemple.tscn; colheitas em Assets/Crops/Spring/Carrot.png, Assets/Crops/Spring/Cabbage.png e Assets/Crops/Summer/Tomato.png; tema em Scripts/menu_theme.gd. Manter os arquivos originais.

## Composição de Hortifruti (F005-10)

**Agrupamento aprovado em A005-04 e A005-07:** árvore e horta abastecem o mesmo recurso “Produce” / “Hortifruti”, ID alvo `produce`. As fichas abaixo substituem a representação exclusiva de frutas. Não gerar recursos individuais de cenoura. Carne, peixe e refeições ficam para o futuro, sem encomenda de arte nesta versão.

Produzir somente as duas composições do manifesto: ícone e pilha de Hortifruti. A pilha representa alimento já coletado, inclusive o que fica no chão após demolição de depósito ou cancelamento de construção antes do início do trabalho. Sua quantidade é controlada pelo jogo, nunca pelo número de peças desenhadas. Não criar ferramentas, materiais ou cultivos adicionais: reutilizações estão no plano. Novos pedidos exigem atualização aprovada deste manifesto.

### Contrato do ícone A005-04

PNG RGBA de **32 × 32 pixels**, transparente, uma imagem estática por arquivo, com margem transparente mínima de 2 pixels. Centro de apresentação (16,16), origem no canto superior esquerdo. Uso em estoque e informações de recursos; apresentação nominal 32 × 32 unidades lógicas. Sem moldura, texto, números, personagem ou fundo. Mesma linguagem de pixel art das ferramentas e do tema existente, iluminação discreta superior esquerda. Nearest, sem mipmaps, sem animação. Não há ocupação ou colisão de mapa. Não adicionar estados de desgaste ou variações por quantidade.

### A005-04 — Hortifruti, ícone

- **Arquivo:** `Assets/Items/Resources/produce.png`.
- **Recurso:** `produce`; alimento compartilhado das árvores e da horta, nome exibido Produce / Hortifruti.
- **Desenho:** pequeno conjunto misto, com uma fruta vermelha/alaranjada arredondada e um vegetal folhoso verde distinguível. Formas compactas, poucos elementos, sem cesta ou embalagem. Referência de fruta em `Scenes/Objects_Exemple.tscn`; a folhagem deve manter a mesma densidade de pixel. Os elementos representam a categoria, não ingredientes separados do jogo.
- **Aceite:** reconhecer alimento vegetal misto, sem carne, peixe, prato cozido ou dependência de um cultivo específico; respeitar o contrato de ícones de materiais.

### Contrato da pilha de mundo A005-07

- PNG RGBA de **16 × 16 pixels**, um quadro estático por arquivo, fundo transparente.
- Origem de coordenadas: canto superior esquerdo. Margem transparente mínima de 1 pixel; silhueta dentro de x/y 1 a 14.
- **Pivô (8,12)**, alinhado ao ponto lógico da pilha no mundo; a implementação usa esse mesmo pivô no desenho e na profundidade. Manter a parte inferior dos objetos junto à linha y=12, permitindo até y=14 para volume frontal.
- Exibição em escala nativa 1× no mundo antes do zoom de câmera; nearest, sem mipmaps. Não esticar ícones de 32 × 32: produzir versões legíveis próprias para 16 × 16.
- Pilha visual próxima de uma célula de terreno de 16 × 16, **sem bloquear passagem**; colisão física, porta e área de construção não se aplicam. Interação/seleção é responsabilidade do jogo.
- Sem números, caixas, etiquetas, fundo de grama/areia, moldura, contorno de seleção ou sombra que pareça terreno fixo. A seleção será desenhada por código.
- Um sprite representa qualquer quantidade positiva; quantidade zero remove a pilha. Sem variantes por tamanho de estoque, sem animações, direções ou quadros extras nesta revisão.
- Cada pilha deve combinar com o ícone do respectivo recurso. Usar tons compatíveis, silhueta simples e contraste suficiente tanto sobre grama quanto sobre terreno claro.

### A005-07 — Hortifruti no chão

**Arquivo:** `Assets/Items/Piles/produce_pile.png`. **Recurso:** `produce`.

Desenhar uma pequena pilha de alimento misto com volume arredondado vermelho/alaranjado e elemento folhoso verde, coerente com A005-04, simplificada para 16 × 16. Sem planta enraizada, sementes brotando ou recipiente. Deve ser reconhecida como alimento já colhido e transportável, não como canteiro ou arbusto. Cumprir o contrato de pilhas.

### Integração e aceite das novas encomendas

Funcionalidade F005-10; as pilhas também atendem F005-02. A IA de arte entrega PNGs individuais nos caminhos exatos. A implementação associa cada arquivo ao respectivo recurso em dados/HUD e `Scripts/resource_pile.gd`; deve preservar as quantidades, reservas e recuperação logística. Conferir em escala real sobre grama e terreno claro, seleção, pivô e profundidade. Salvar/carregar não pode mudar tipo ou quantidade. Os dois arquivos foram produzidos, integrados e validados.

## Manifesto e conferência para entrega

| ID | Funcionalidade | Arquivo | Quantidade | Estado |
|---|---|---|---|---|
| A005-04 | F005-10 / F005-03 | `Assets/Items/Resources/produce.png` | 1 PNG de 32 × 32 | Integrado e validado |
| A005-07 | F005-10 / F005-02 / F005-03 | `Assets/Items/Piles/produce_pile.png` | 1 PNG de 16 × 16 | Integrado e validado |

Antes de entregar, conferir dimensões, transparência real, margens, nomes, legibilidade em 1× e consistência entre os dois ícones. A implementação deverá conferir no painel real, ligar cada imagem ao recurso correto e preservar rótulos textuais. Só marcar como integrado após essa verificação; arquivo produzido não significa funcionalidade concluída.

## Estado vigente — revisão 36

A005-04 e A005-07 estão entregues, com os parâmetros acima. As outras encomendas foram retiradas após inspeção dos sprites recém-adicionados. Seus IDs ficam históricos e não serão reaproveitados. As duas composições estão integradas à versão executável 0.0.5.
