# Civiz Imperium — Assets V0.0.5

- Versão alvo: **0.0.5**.
- Revisão compartilhada: **20**.
- Plano correspondente: [PLANO_V0.0.5.md](PLANO_V0.0.5.md).
- Estado: **encomendas documentadas; imagens ainda não produzidas**.
- Este documento contém apenas arte a criar. Alterações sem arte nova ficam no plano.

## Contexto para a IA de arte

Civiz Imperium é um jogo de vila e automação em pixel art 2D. Os habitantes produzem ferramentas em uma oficina e as usam para obter recursos. As ferramentas já funcionam no código, mas sua interface usa principalmente texto. Precisamos criar dois ícones próprios, machado e picareta, para estoque, encomendas da oficina e inspeção do habitante. Não se trata de armas de combate.

O pedido de arte das ferramentas foi incluído pelo usuário. As especificações abaixo são o contrato inicial de ícones estáticos; não há encomenda de animações equipadas nesta revisão. Mudanças no contrato devem ser refletidas no plano antes da integração.

## Referências a examinar antes de desenhar

Caminhos relativos à raiz do projeto:

- `Scenes/buildings_exemples.tscn` e `Assets/Houses`: vila com prédios em tons terrosos, referência de materiais e linguagem visual.
- `Scenes/Objects_Exemple.tscn` e `Assets/Tiles`: referência dos recursos naturais e escala de detalhes.
- `Scenes/menu_ex.tscn`, `Assets/UI/Inventory/Banner.png`, `Assets/UI/Extras.png`: contexto da interface clara com bordas pixeladas.
- `Scripts/menu_theme.gd`: cores do tema, incluindo contorno/texto castanho `#543126`, texto secundário `#795345` e destaque `#914629`.
- `Assets/Characters/char-1`, `char-2`, `char-3`: referência de densidade de pixels; não redesenhar personagens.

Usar essas referências para compatibilidade, preservando os originais. O ícone deve ser legível sobre o painel claro atual. Não adicionar uma moldura ou fundo à imagem: isso é responsabilidade da interface.

## Contrato dos ícones de ferramentas A005-02 e A005-03

| Parâmetro | Especificação |
|---|---|
| Funcionalidade | F005-09 |
| Tipo | Ícone estático de ferramenta, uma imagem por arquivo |
| Resolução nativa | 32 × 32 pixels exatos |
| Formato | PNG RGBA, fundo totalmente transparente |
| Margem | Pelo menos 2 pixels transparentes em todos os lados; desenho contido entre x/y 2 e 29 |
| Estilo | Pixel art nítida, contornos e agrupamentos de pixels coerentes com as referências |
| Material | Cabo de madeira castanha e cabeça de pedra cinza, coerentes com a receita atual de madeira e pedra; amarração simples se necessária à leitura |
| Luz | Destaques discretos no alto/esquerda; sombra no lado oposto, sem sombra projetada fora do objeto |
| Composição | Ferramenta inteira, diagonal com empunhadura embaixo/esquerda e cabeça em cima/direita |
| Centro de apresentação | (16,16), coordenadas em pixels a partir do canto superior esquerdo |
| Apresentação nominal | 32 × 32 unidades lógicas, proporção preservada |
| Importação prevista | Nearest, sem mipmaps; não suavizar ou ampliar o raster para fingir maior resolução |
| Quadros, direções e estados | Um quadro; sem animação, espelhamento obrigatório ou variantes de desgaste |
| Texto e elementos extras | Sem texto, números, watermark, fundo, borda de botão, mão ou personagem |
| Colisão e ocupação | Não se aplicam: ícones de HUD, não objetos colocados no mapa |

Durabilidade, quantidade, seleção e estado desabilitado são elementos dinâmicos do jogo e não devem ser pintados dentro do ícone. Não juntar as entregas num atlas: cada ferramenta precisa do seu PNG independente. Prancha ampliada de comparação é opcional, nunca substitui os arquivos finais nativos.

## A005-02 — Criar o machado

**Arquivo final:** `Assets/Items/Tools/axe.png`.

**Recurso no jogo:** `axe`. Produzido na oficina com 2 madeiras e 1 pedra; usado por lenhadores. Esses valores contextualizam o material, não devem aparecer na imagem.

**Desenho:** machado rústico de uma lâmina, com cabo de madeira visível e cabeça de pedra compacta, mais larga que o cabo. A lâmina deve ter uma borda externa larga e reconhecível, sem parecer uma picareta ou um martelo. Sugestão de distribuição dentro do quadro: empunhadura próxima de (8,26), encaixe próximo de (21,10), cabeça concentrada na região superior direita, sempre respeitando as margens comuns. Essas posições orientam a composição; o centro de apresentação contratado permanece (16,16).

**Características obrigatórias:** silhueta simples; cabo contínuo; cabeça com volume por poucos tons; separação clara entre madeira e pedra. Evitar ornamentos, metal brilhante, aparência de arma fantástica ou uma segunda lâmina.

**Uso:** ícone ao lado da quantidade de machados no estoque, nas encomendas/metas da oficina e na inspeção de um habitante equipado com machado. A imagem não será sobreposta à mão do personagem nesta especificação.

**Aceite específico:** reconhecível como machado sem legenda e distinto da picareta pela cabeça larga. Cumprir integralmente o contrato comum.

## A005-03 — Criar a picareta

**Arquivo final:** `Assets/Items/Tools/pickaxe.png`.

**Recurso no jogo:** `pickaxe`. Produzida na oficina com 1 madeira e 2 pedras; usada por mineiros em jazidas e pedreiras. Não colocar receita ou números na imagem.

**Desenho:** picareta rústica com cabo de madeira e cabeça de pedra transversal, alongada e afilada nas pontas. A silhueta precisa destacar a diferença em relação à lâmina larga do machado. Sugestão de composição: empunhadura próxima de (8,26), encaixe próximo de (20,12), cabeça atravessando a região superior do quadro sem encostar nas bordas. Centro de apresentação (16,16).

**Características obrigatórias:** duas extremidades distinguíveis na cabeça, uma delas mais pontuda; cabo contínuo; amarração discreta compatível com o machado. Mesma iluminação, espessura visual de contorno e escala de detalhe da outra ferramenta. Evitar cabeça retangular de martelo, ornamentação ou materiais que sugiram uma nova tecnologia não existente.

**Uso:** ícone de estoque, encomendas/metas de picaretas na oficina e inspeção de habitante equipado. Não inclui animação de mineração nem ferramenta na mão.

**Aceite específico:** reconhecível como picareta no tamanho nativo e imediatamente distinguível do machado. Cumprir integralmente o contrato comum.

## Novas encomendas — materiais e pilhas (F005-10)

**Agrupamento aprovado em A005-04 e A005-07:** árvore e horta abastecem o mesmo recurso “Produce” / “Hortifruti”, ID alvo `produce`. As fichas abaixo substituem a representação exclusiva de frutas. Não gerar recursos individuais de cenoura. Carne, peixe e refeições ficam para o futuro, sem encomenda de arte nesta versão.

Além das ferramentas, criar representações dos materiais atuais. Um depósito demolido perde a construção, mas deixa seu estoque no chão para transporte. Cancelar uma construção antes da primeira martelada também deixa os materiais entregues no chão, usando estas mesmas pilhas. As pilhas abaixo representam itens já coletados, não fontes que geram novos recursos. As quantidades são controladas pelo jogo, nunca pelo número de peças desenhadas. Novos materiais de atividades futuras receberão novas fichas quando forem decididos.

### Contrato dos ícones de materiais A005-04 a A005-06

PNG RGBA de **32 × 32 pixels**, transparente, uma imagem estática por arquivo, com margem transparente mínima de 2 pixels. Centro de apresentação (16,16), origem no canto superior esquerdo. Uso em estoque e informações de recursos; apresentação nominal 32 × 32 unidades lógicas. Sem moldura, texto, números, personagem ou fundo. Mesma linguagem de pixel art das ferramentas e do tema existente, iluminação discreta superior esquerda. Nearest, sem mipmaps, sem animação. Não há ocupação ou colisão de mapa. Não adicionar estados de desgaste ou variações por quantidade.

### A005-04 — Hortifruti, ícone

- **Arquivo:** `Assets/Items/Resources/produce.png`.
- **Recurso:** `produce`; alimento compartilhado das árvores e da horta, nome exibido Produce / Hortifruti.
- **Desenho:** pequeno conjunto misto, com uma fruta vermelha/alaranjada arredondada e um vegetal folhoso verde distinguível. Formas compactas, poucos elementos, sem cesta ou embalagem. Referência de fruta em `Scenes/Objects_Exemple.tscn`; a folhagem deve manter a mesma densidade de pixel. Os elementos representam a categoria, não ingredientes separados do jogo.
- **Aceite:** reconhecer alimento vegetal misto, sem carne, peixe, prato cozido ou dependência de um cultivo específico; respeitar o contrato de ícones de materiais.

### A005-05 — Madeira, ícone

- **Arquivo:** `Assets/Items/Resources/wood.png`.
- **Recurso:** `wood`; madeira obtida no último estágio das árvores.
- **Desenho:** dois ou três pequenos troncos cortados agrupados, casca castanha e seção de corte mais clara. Evitar tábuas industrializadas, árvore viva, folhas ou toco enraizado; trata-se de material transportável.
- **Aceite:** madeira cortada reconhecível na escala real, distinta de cabo de ferramenta; respeitar o contrato de ícones de materiais.

### A005-06 — Pedra, ícone

- **Arquivo:** `Assets/Items/Resources/stone.png`.
- **Recurso:** `stone`; pedra extraída de jazidas e pedreiras.
- **Desenho:** três fragmentos irregulares de pedra em tons cinza/cinza quente, com faces claras e escuras compatíveis com a fonte de pedra existente. Sem minério colorido, metal, joias, terreno ou cava.
- **Aceite:** fragmentos de material prontos para transporte, e não uma pedreira; respeitar o contrato de ícones de materiais.

### Contrato das pilhas de mundo A005-07 a A005-11

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

### A005-08 — Madeira no chão

**Arquivo:** `Assets/Items/Piles/wood_pile.png`. **Recurso:** `wood`.

Desenhar dois pequenos troncos empilhados baixos, com seção cortada clara e casca castanha, coerentes com A005-05. Sem raízes ou folhagem; diferenciar do último estágio da árvore que ainda precisa ser cortado. Cumprir o contrato de pilhas.

### A005-09 — Pedra no chão

**Arquivo:** `Assets/Items/Piles/stone_pile.png`. **Recurso:** `stone`.

Desenhar pequeno monte baixo de fragmentos soltos, coerente com A005-06, menor e visualmente distinto da jazida natural. Sem base de terreno ou buraco. Cumprir o contrato de pilhas.

### A005-10 — Machados no chão

**Arquivo:** `Assets/Items/Piles/axe_pile.png`. **Recurso:** `axe`.

Desenhar um machado deitado em diagonal, com cabo castanho e cabeça de pedra larga, mantendo a identidade de A005-02 numa composição própria de 16 × 16. A imagem representa uma pilha lógica mesmo contendo apenas uma ferramenta desenhada. Não incluir mão, pessoa, pedestal ou ferramenta quebrada. Cumprir o contrato de pilhas.

### A005-11 — Picaretas no chão

**Arquivo:** `Assets/Items/Piles/pickaxe_pile.png`. **Recurso:** `pickaxe`.

Desenhar uma picareta deitada em diagonal, com cabo castanho e cabeça alongada afilada, coerente com A005-03 e distinguível do machado em 16 × 16. Uma ferramenta desenhada representa qualquer quantidade lógica positiva. Sem pessoa, pedestal ou estado quebrado. Cumprir o contrato de pilhas.

### Integração e aceite das novas encomendas

Funcionalidade F005-10; as pilhas também atendem F005-02. A IA de arte entrega PNGs individuais nos caminhos exatos. A implementação associa cada arquivo ao respectivo recurso em dados/HUD e `Scripts/resource_pile.gd`; deve preservar as quantidades, reservas e recuperação logística. Conferir em escala real sobre grama e terreno claro, seleção, pivô e profundidade. Salvar/carregar não pode mudar tipo ou quantidade. Nenhum dos arquivos foi produzido ainda.

## Manifesto e conferência para entrega

| ID | Funcionalidade | Arquivo | Quantidade | Estado |
|---|---|---|---|---|
| A005-02 | F005-09 | `Assets/Items/Tools/axe.png` | 1 PNG de 32 × 32 | A produzir |
| A005-03 | F005-09 | `Assets/Items/Tools/pickaxe.png` | 1 PNG de 32 × 32 | A produzir |
| A005-04 | F005-10 / F005-03 | `Assets/Items/Resources/produce.png` | 1 PNG de 32 × 32 | A produzir |
| A005-05 | F005-10 | `Assets/Items/Resources/wood.png` | 1 PNG de 32 × 32 | A produzir |
| A005-06 | F005-10 | `Assets/Items/Resources/stone.png` | 1 PNG de 32 × 32 | A produzir |
| A005-07 | F005-10 / F005-02 / F005-03 | `Assets/Items/Piles/produce_pile.png` | 1 PNG de 16 × 16 | A produzir |
| A005-08 | F005-10 / F005-02 | `Assets/Items/Piles/wood_pile.png` | 1 PNG de 16 × 16 | A produzir |
| A005-09 | F005-10 / F005-02 | `Assets/Items/Piles/stone_pile.png` | 1 PNG de 16 × 16 | A produzir |
| A005-10 | F005-10 / F005-02 | `Assets/Items/Piles/axe_pile.png` | 1 PNG de 16 × 16 | A produzir |
| A005-11 | F005-10 / F005-02 | `Assets/Items/Piles/pickaxe_pile.png` | 1 PNG de 16 × 16 | A produzir |

Antes de entregar, conferir dimensões, transparência real, margens, nomes, legibilidade em 1× e consistência entre os dois ícones. A implementação deverá conferir no painel real, ligar cada imagem ao recurso correto e preservar rótulos textuais. Só marcar como integrado após essa verificação; arquivo produzido não significa funcionalidade concluída.

## Histórico do contrato

- Revisões 01–02: estrutura inicial; ainda não havia encomendas de arte.
- Revisão 03: usuário solicitou que este documento contenha apenas assets a produzir e incluiu as ferramentas. Removida a ficha de reutilização A005-01; seu ID não foi reciclado. Criadas A005-02 e A005-03, ligadas a F005-09 do plano.
- Revisão 04: sincronização com a definição inicial de demolição no plano, sem nova encomenda visual.
- Revisão 05: usuário definiu estoque de depósito demolido no chão e pediu assets dos materiais. Acrescentados três ícones e cinco pilhas; ferramentas da revisão anterior preservadas. Novos recursos de próximas decisões serão adicionados sem antecipar seu desenho.
