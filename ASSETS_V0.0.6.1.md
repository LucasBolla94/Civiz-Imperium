# Civiz Imperium — Assets V0.0.6.1

- Revisão compartilhada: **18**.
- Par: [PLANO_V0.0.6.1.md](PLANO_V0.0.6.1.md).
- Estado: **produzido, integrado e em validação final; revisão humana da experiência pendente. Escopo da revisão 18 preservado**.

## Direção comum das encomendas

Pixel art compatível com o jogo, perspectiva superior com face frontal visível, contornos e sombras discretos, pixels nítidos, fundo transparente RGBA. Sem texto, números, moedas, logotipo, fundo branco, brilho desfocado ou elementos de interface embutidos. Grade do mundo de 16 pixels. Referência inspecionada: Assets/Icons/RPG icons/Extras/Stones.png; comparar também com pedras e terreno usados na cena antes da produção final. Paleta de rocha terrosa/cinza, ouro amarelo quente com sombra ocre e destaque claro. Diferenciar pela forma, não apenas pela cor.

Dimensões abaixo são contratos de integração propostos para estes assets; não alterar dimensões sem atualizar o plano e este documento juntos. Entregar PNGs individuais, sem margens variáveis, e preservar fontes editáveis quando houver. Verificar leitura no tamanho nativo e no zoom do jogo. Procurar equivalentes nos assets existentes antes de criar/adaptar cada item; reaproveitamento compatível satisfaz o contrato.

## GOLD-01 — minério de ouro

Uso: insumo extraído da jazida, transportado/armazenado e consumido pela fundição com madeira. Não é moeda e não pode parecer barra refinada.

- Ícone: Assets/Items/Resources/gold_ore.png, 32 × 32, centro (16,16). Rocha irregular com veios amarelos bem identificáveis, construída em pixel art coerente com os ícones atuais. Adaptar preferencialmente os minerais amarelos da folha inspecionada Assets/Objects/Exterior/Mine and Dungeon/stone with minerals.png, sem copiar regiões vizinhas.
- Pilha/carga: Assets/Items/Piles/gold_ore_pile.png, 16 × 16, ponto de apoio (8,12). Pequeno conjunto de fragmentos com veios dourados, legível sem número embutido. Quantidades são exibidas pelo jogo.

## GOLD-02 — barras de ouro

Uso: resultado da fundição e pagamento no comércio; ícone da quantidade na barra superior. Não criar moedas ou uma etapa de cunhagem.

- Ícone: Assets/Items/Resources/gold_bar.png, 32 × 32, centro (16,16). Lingote trapezoidal com topo e lateral visíveis, dourado quente, silhueta claramente diferente da rocha.
- Pilha/carga: Assets/Items/Piles/gold_bar_pile.png, 16 × 16, ponto de apoio (8,12). Pequena pilha de lingotes, sem brilho animado obrigatório e sem valor escrito.

## GOLD-03 — jazida de ouro no mundo

Uso: local revelado pela investigação, onde trabalhadores extraem minério. Compatível com a área de investigação atual de 3 × 3 células (48 × 48 pixels). Arte separada do prédio de mineração.

- Assets/Objects/Resources/Gold/gold_deposit.png, 48 × 48, ponto de apoio central inferior (24,48). Formação de rochas com veios dourados, áreas de terreno transparentes e frente visualmente clara para trabalho. Não desenhar construções, cercas ou trabalhadores no sprite.
- Assets/Objects/Resources/Gold/gold_deposit_depleted.png, mesmas dimensões, apoio e alinhamento. Rocha escavada/esgotada sem ouro visível; estado informativo, sem prometer nova reserva ou regeneração.
- Separar arte de colisão/acesso: a IA implementadora define células caminháveis segundo o sistema existente. Não incluir faixa de seleção, contador, balão ou botão no PNG.

Não encomendar estágios extras de riqueza ou animação antes de definir sua necessidade. Estados visuais não alteram a reserva de minério.

## Aceitação das entregas

Transparência real, sem halo claro; escala/paleta coerentes com os assets de referência; minério e barra reconhecíveis em tamanho nativo; jazida alinhada à grade e sem recorte de outro sprite. Conferir sobre grama e junto dos elementos atuais. Integrar pelos mesmos IDs GOLD-01/02/03 do plano. Os prédios novos estão especificados em GOLD-04/05/06 abaixo. Não encomendar barco novo: a proposta usa a folha existente já inspecionada, conforme plano.




## Referências adicionais inspecionadas

Foram vistas as folhas `Assets/Objects/Exterior/Mine and Dungeon/stone with minerals.png`, `Assets/Objects/Exterior/Mine and Dungeon/Mine props.png` e `Assets/Objects/Work Benches/Furnace.png`. Usar pedras minerais, estruturas de madeira e forno existente como matéria-prima para as composições solicitadas abaixo, preservando seus pixels. As encomendas são composições/adaptações, não exigência de gerar tudo de novo.

Convenção dos prédios: tela de 64 × 80 pixels; área lógica de terreno 3 × 3 células (48 × 48), com canto superior esquerdo da ocupação em (8,32) da imagem. Ponto de apoio (32,80). Entrada central voltada para baixo, fora da célula ocupada, definida pela implementação. Margens transparentes não bloqueiam passagem. Extras visuais podem ocupar a parte superior da tela sem aumentar colisão. Entregar frente e escala consistentes com os edifícios atuais. Estados de obra/seleção/demolição usam sistemas atuais, não novas pinturas obrigatórias.

## GOLD-04 — posto de mineração de ouro

- Arquivo `Assets/Buildings/Gold/gold_mining_post.png`, 64 × 80 RGBA, apoio (32,80), ocupação acima.
- Pequeno abrigo de madeira com telhado na linguagem dos prédios existentes; caixas e bandeja com minério dourado junto à entrada, suporte de picareta. Deve comunicar coleta e armazenamento, sem parecer fundição, castelo ou entrada subterrânea gigante.
- Reutilizar objetos de mina inspecionados; não embutir trabalhador, contador, ouro flutuante, texto ou chão retangular opaco. A jazida GOLD-03 é separada e fica em outro local do mapa.
- Ícone de construção `Assets/UI/Buildings/gold_mining_post_icon.png`, 32 × 32 transparente; versão legível do mesmo abrigo, sem moldura/interface. Pode ser composição reduzida com revisão manual de legibilidade.

## GOLD-05 — fundição

- Corpo `Assets/Buildings/Gold/smelter.png`, 64 × 80 RGBA, apoio e ocupação comuns.
- Oficina baixa de pedra e madeira, telhado parcial que permita ler a boca do forno, chaminé, pequeno suporte de minério e lingote. Reaproveitar Furnace.png como referência central. Diferenciar do posto pela fornalha e chaminé, não só pela cor.
- Overlay de atividade `Assets/Buildings/Gold/smelter_fire.png`: folha horizontal de 4 quadros de 64 × 80 (total 256 × 80), transparência, registro idêntico ao corpo. Chama/brasas discretas na posição do forno, 6 quadros por segundo em loop; sem mover corpo do prédio entre quadros. Se animação já existente do forno atender, compor/reutilizar seus quadros em vez de gerar chama nova. Não embutir fumaça gigante ou efeitos sobre a interface.
- Prédio parado usa corpo sem overlay; ativo usa overlay. Até duas bancadas são lógica de produção, não exigem dois prédios ou duas animações independentes.
- Ícone `Assets/UI/Buildings/smelter_icon.png`, 32 × 32 transparente, forno/chaminé reconhecíveis, sem texto.

## GOLD-06 — porto comercial

- Quatro arquivos: `Assets/Buildings/Port/trading_port_north.png`, `trading_port_east.png`, `trading_port_south.png`, `trading_port_west.png`.
- Cada um: 80 × 96 RGBA. Área lógica 5 × 5 = 80 × 80 com origem em (0,16) da tela; apoio (40,96). O sufixo indica a direção do mar. Orientação south: duas linhas superiores em terra e três inferiores em água. Outras orientações giram a máscara lógica e são redesenhadas/compostas mantendo perspectiva e iluminação, não simplesmente girando o sprite acabado.
- Pequeno entreposto de madeira em terra e píer avançando sobre água, cordas, caixas e ponto claro de carregamento. Usar madeira/paleta dos prédios existentes. Frente ao cais deve sobrar água para atracação do barco; o barco não faz parte do PNG.
- Entregar arquivo de metadados `Assets/Buildings/Port/trading_port_layout.json` com dimensões, origem da grade, células de terra/água por orientação, posição do ponto de carga e margem visual. Metadados devem corresponder ao contrato 5 × 5 do plano; implementação valida acesso/água, sem deduzir colisão por transparência.
- Ícone `Assets/UI/Buildings/trading_port_icon.png`, 32 × 32 transparente, silhueta clara de píer/entreposto sem barco obrigatório ou texto.
- Não embutir mar, terreno, trabalhadores, botões ou nome. Manter pixels da água visíveis entre pilares quando apropriado.

## Validação adicional de integração

Verificar posto/fundição lado a lado com os prédios atuais, jazida na área de 3 × 3 e porto nas quatro costas. A posição de carregamento visual deve coincidir com a parada do trabalhador. Entregar contato visual de comparação sobre o terreno existente para revisão, sem apresentar essa imagem como parte do sprite final. Nenhum prédio deve aparecer cortado, flutuar ou incluir início de outro asset da folha.

A encomenda inclui GOLD-01 até GOLD-06 e BRAND-01. Menus, barras de quantidade, balões e seleção são componentes editáveis da interface, reorganizados conforme a solicitação adicional de UX. Fonte editável e PNG final devem concordar; não salvar apenas uma imagem de apresentação com todos os itens juntos.

## BRAND-01 — emblema de Civiz Imperium

Emblema original acolhedor, em pixel art: torre de arenito, coroa dourada, ilha verde e ondas em azul-petróleo, com folhagem discreta. PNG RGBA em `Assets/UI/Brand/civiz_emblem.png`; preservar resolução original e transparência. Exibir sem deformação, com altura aproximada de 96 pixels no menu e versão menor quando necessário. Não incluir letras: o nome do jogo permanece um Label editável, com fonte de título licenciada e distinta da fonte de leitura. Verificar contraste sobre os painéis, leitura reduzida e alinhamento com o título. A proibição de logotipo nos sprites GOLD continua válida.
