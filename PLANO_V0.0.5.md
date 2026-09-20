# Civiz Imperium — Plano V0.0.5

- Versão alvo: **0.0.5**.
- Revisão do contrato compartilhado: **43**.
- Estado: **V0.0.5 entregue conforme registro anterior; planejamento posterior separado na V0.0.5.1**.
- Documento par obrigatório: [ASSETS_V0.0.5.md](ASSETS_V0.0.5.md).
- Base de desenvolvimento: V0.0.4. Versão executável entregue: **0.0.5**.


## Progressão posterior separada

As discussões de progressão registradas provisoriamente nas revisões 38–40 pertencem agora à V0.0.5.1, conforme decisão do usuário. Consulte [PLANO_V0.0.5.1.md](PLANO_V0.0.5.1.md) e [ASSETS_V0.0.5.1.md](ASSETS_V0.0.5.1.md). Não tratar essas propostas como mudanças já entregues na V0.0.5.

## Zoom e construção na expansão — revisão 43 (20/09/2026)

**Q/E suave:** aproximação/afastamento por interpolação gradual, usando tempo real mesmo na pausa. Um toque mantém o fator anterior de 1,12; segurar a tecla ajusta continuamente a 0,8 unidades logarítmicas por segundo, sem depender da repetição do teclado. Limites 0,8–5 preservados. Abrir modal/perder foco interrompe o movimento; centrar ou carregar partida elimina uma transição anterior. A roda mantém o passo anterior, e Ctrl + roda continua exclusivo do pincel no modo de aterro.

**Moradias na expansão:** investigada uma cópia local do save, sem modificar a partida original. Havia recursos suficientes e 12 posições válidas de moradia, quatro delas na expansão. A maior restrição era espaço livre: moradia ocupa 5×4 células, mais entrada frontal; água, jazidas, construções e materiais no chão impedem a colocação. Não foi identificado teto de casas nem proibição de construir em aterros concluídos. A prévia agora informa dimensões, destaca células ocupadas e a célula da entrada, e distingue água de terreno ocupado. Mantidos os tamanhos e a proteção da circulação. Construtor completou uma moradia no aterro e liberou quatro vagas tanto em cenário novo quanto na cópia do save.

**Verificação:** `test_smooth_zoom.gd` (11 checks), `test_expanded_construction.gd` (10 com a cópia local opcional; 5 sem ela), além das regressões de interface, expansão e salvamento. O save usado no diagnóstico é ignorado pelo Git e não faz parte de nenhum pacote. Solicitação de commit/push engloba a entrega V0.0.5 e preservação separada dos documentos de planejamento futuro; estes documentos não representam funcionalidades implementadas.

## Pincel de aterro — entrega na revisão 42 (20/09/2026)

Pedido explícito do usuário: permitir corrigir buracos deixados pelas expansões, sobrepor terra existente e ajustar o tamanho/custo com Ctrl + roda do mouse. Implementado em **Ampliar costa**, com pincel quadrado de **1×1 até 9×9**, inicial 3×3 e variação de uma célula por passo da roda. Ctrl + roda sobre o mapa altera apenas o pincel; roda sem Ctrl mantém o zoom. Shift repete a colocação; Esc cancela. A prévia contorna o pincel e colore somente as células de água, mostrando quantidade, materiais, trabalho e motivo de bloqueio antes do clique.

**Custo e duração:** cobram apenas água que se tornará terra, preservando a referência de nove células = 10 pedras + 5 madeiras e 10 segundos-base. Para N células, pedra = teto(10N/9), madeira = teto(5N/9) e trabalho = 10N/9 segundos. Exemplos: 1 célula = 2 pedras + 1 madeira / 1,1s; 4 = 5 + 3 / 4,4s; 9 = 10 + 5 / 10s; 81 = 90 + 45 / 90s. A interface mostra tempo arredondado a uma casa decimal; o trabalho usa o valor preciso. Materiais são reservados ao colocar a obra e transportados fisicamente pelo sistema existente.

**Terreno e acesso:** terra sob o pincel não entra na obra; prédios, hortas, recursos, trabalhadores e cargas sobre ela são preservados. Cada trecho separado de água precisa tocar margem acessível pela vila, inclusive margens dentro do pincel. Não permite mar isolado, sair da região, duplicar aterros pendentes ou ocupar água já reservada por recurso/obra. O construtor trabalha de uma margem alcançável; ao terminar somente as células registradas recebem terra, bordas e navegação são recalculadas.

**Jazidas:** a geração automática anterior permanece apenas em expansões completas 3×3 de nove células novas. Pincéis de outros tamanhos e reparos parciais não avançam esse contador e não geram jazida bloqueando o preenchimento.

**Persistência:** cada ordem congela suas células, tamanho, materiais, duração e elegibilidade de descoberta. Mudar o pincel depois não muda obras colocadas. Novos campos opcionais no save formato 5 preservam ordens parciais/grandes; saves V0.0.5 anteriores continuam carregando, com obras antigas inferidas como 3×3 sem alterar progresso ou preço. Ilhas antigas com buracos podem ser reparadas. Não implementa o planejamento independente V0.0.5.1.

**Validação:** 43 verificações de expansão (custos, bolsões de água, preservação, reservas, transporte/construtor, saves antigos/novos, obra 9×9 em andamento e navegação) e 20 de UI (Ctrl/roda, zoom, Shift, Esc, limites, preço, modal e dois idiomas). Regressões V005, V004, interface V005 e casos extremos também executadas. Capturas `Tests/expansion_brush_1_pt.png`, `Tests/expansion_brush_5_pt.png` e `Tests/expansion_brush_5_en.png`. Sem encomenda de arte nova: reutiliza o terreno e as bordas existentes. Pacotes Windows/projeto atualizados.

## Menu pelo Esc — entrega na revisão 41 (20/09/2026)

Pedido explícito do usuário: Esc continua fechando os menus; quando não houver menu ou seleção/colocação abertos, Esc abre uma janela de salvar/fechar jogo. Implementado menu modal com **Salvar jogo**, **Fechar jogo** e **Continuar jogando**, traduzido em inglês/português. A partida pausa enquanto a janela está aberta e recupera o estado anterior ao continuar, fechar pelo X ou pressionar Esc. Salvar mantém a janela aberta e confirma sucesso ou falha; fechar encerra o aplicativo. Nenhum salvamento automático é associado ao botão Fechar jogo. Diálogos existentes consomem seu próprio Esc sem abrir outro por baixo; repetição da tecla não abre o menu.

Validação: `test_escape_menu.gd`, 19 verificações com eventos reais de teclado/clique, salvamento e recarregamento, pausa, sequência de fechamento, tradução e janela pequena. Teste separado do botão Fechar jogo encerrou o processo com sucesso. Regressão da interface V005: 72 verificações; casos extremos/traduções: 19, todos sem falhas. Capturas `Tests/escape_menu_pt.png` e `Tests/escape_menu_en.png`. Pacotes V0.0.5 atualizados, saves compatíveis; planejamento V0.0.5.1 preservado.

## Correção visual — revisão 37 (20/09/2026)

Pedido explícito após a entrega: substituir a arte de Hortifruti por PNGs bonitos sem fundo branco e desenhar trabalhadores acima da horta. A005-04 e A005-07 foram refeitos com imagegen, mantendo 32×32/16×16, margens, transparência e pivô. O carregamento mantém referência forte às texturas: comandos de desenho não podem perder a imagem após retornar de `_draw`, causa do quadrado branco nas pilhas. Simulation usa profundidade 1; a horta usa -1 relativo, acima do terreno pela ordem da cena e abaixo de todos os trabalhadores. Navegação e seleção permanecem na mesma posição.

Validação desta correção: 24 verificações de arte/camada, incluindo comparação dos pixels dos personagens nas quatro células, ausência de branco opaco, margens transparentes e caminhos transitáveis; 68 verificações V005, 19 de casos extremos e 9 de profundidade das árvores, sem falhas. Captura: `Tests/v005_visual_fix.png`. Pacotes Windows/projeto atualizados. Versão 0.0.5 e saves existentes desta versão continuam compatíveis.

## Integração autorizada — revisão 35

Em 20/09/2026 o usuário autorizou implementar esta versão e confirmou: cercado em 10 segundos-base; plantio em 4 segundos-base; hortas transitáveis para permitir adjacência; profissão preservada com outro local de trabalho ou base; insumos de oficina preservados e receita da produção incompleta devolvida ao chão; cancelar demolição mantém mudanças concluídas e cancela as em andamento; saves V0.0.4 preservados em separado, com nova partida na V0.0.5. Não há migração silenciosa. Estado: integrado e validado na entrega.

Detalhes internos: horta usa quatro células de 16 px, cercado decorativo com passagem, plantio manual no canteiro vazio e primeiro plantio solicitado após instalação. Disponível pelo depósito de comida concluído, sem novo nível de desbloqueio. Colheita mantém a prioridade por proximidade e reserva alimentar existente. Crescimento da árvore distribui 180 s em 30/40/50/60 s; estados maduros e madeira não envelhecem por tempo.

## Entrega V0.0.5 — revisão 36 (20/09/2026)

Esta seção registra a implementação final e prevalece sobre estados de planejamento, propostas substituídas e pendências históricas abaixo. Não há requisito aprovado pendente nesta entrega.

**F005-14 — população conforme moradia:** pedido adicional explícito do usuário durante a implementação. Removido o limite fixo de sete pessoas e o controle de meta populacional. Casas concluídas liberam vagas para novos habitantes; alimentação, acesso e chegada por barco continuam necessários. Reservas de mudança de residência contam na ocupação, impedindo disputa de vagas com imigração. Esta decisão substitui a meta populacional anterior e não adiciona outra trava arbitrária.

**Implementação:** horta em `Scripts/garden.gd`; demolição em prédio/trabalhador/moradia; reservas imediatas de pedidos na mesma consulta usada pelos pagamentos; `produce` em estoques, cargas, receitas, metas e saves; apresentação em inglês/português pelo catálogo `Assets/Localization/en_pt.tsv`, com preferência independente em `language.cfg`. Nomes próprios e IDs permanecem estáveis.

**Arte integrada:** A005-04 e A005-07 nos caminhos do documento par. Ícone 32×32 com margem de 2 px, pilha 16×16 com margem de 1 px e pivô (8,12), RGBA e nearest. Recortes de ferramentas/materiais: primeiro quadro 16×16 das folhas existentes. Solo `(32,16,16,16)` de Tilled Soil; cultivos Carrot/Cabbage, quadros 1–5 no crescimento e 6 na maturidade (quadro 7 de item colhido não é planta). Cercado reutiliza `(48,0,16,16)` e `(0,16,16,16)` de Fence Wood; abertura frontal e passagem entre canteiros são preservadas. Fontes originais mantidas, incluindo a copa branca que não aparece no ciclo ativo.

**Conservação:** cancelamento de obra usa `work_started`; demolição usa `demolition_started`, ambos persistentes. Cargas interrompidas ficam em pilhas recuperáveis, reservas são liberadas e seleção/caminhos/referências são limpos. Oficina devolve receita de produção incompleta; produto já concluído à espera de espaço é preservado como ferramenta, sem duplicar insumos. Upgrades em andamento precisam terminar antes da demolição; cancelamento não foi estendido a upgrades, expansões ou plantios.

**Saves:** formato 5, arquivo `civilization_v005.save`, gravação temporária e cópia de segurança. Formato 4 é rejeitado sem alterar a vila em execução; `civilization_v004.save` permanece intacto. A primeira partida desta versão é nova, conforme aprovado. O carregamento reconstrói reservas e movimentos, preservando cargas, materiais entregues, estoques e progresso.

**Validação:** `test_v005.gd` (68 verificações), `test_v005_edges.gd` (19), `test_v005_ui.gd` (72), regressões V003 (72), V004 (44), IA de trabalho (31), UI V004 (16) e interface adaptável (460), todos sem falhas. Incluem clique real com Shift, zoom bloqueado em modais/campos de texto, fases da horta/árvore, trabalho físico, cancelamentos, duas mudanças simultâneas, imigração, população acima de sete, idiomas e save/load. Teste independente do pacote Windows confirmou versão, assets, horta, português e salvamento. Capturas em `Tests/v005_*.png`. O Godot local emite aviso de leitura do armazenamento de certificados do Windows; não houve erro de script nos testes finais.

**Distribuição:** `Builds/Civiz-Imperium-V0.0.5/`, com `.exe`, `.pck`, instruções e avisos do motor; ZIP jogável em `Builds/Civiz-Imperium-V0.0.5-Windows.zip`. O pacote local usa o binário Godot 4.7.2 disponível, que também contém o editor, para executar os dados exportados; não depende de instalar Godot. Não é uma exportação otimizada pelo template release (templates não estavam instalados). O projeto editável permanece em `project.godot`.

## Objetivo deste par

**Limite de execução para a IA que recebe este documento:** implementar somente a tabela de escopo fechado abaixo e as regras expressamente aprovadas que a detalham. Não adicionar sistemas do roadmap, novas mecânicas, novos tipos de recurso, custos, bônus, desbloqueios ou mudanças de balanceamento por iniciativa própria. Propostas técnicas não são decisões do usuário. O histórico ao final explica a conversa, mas não autoriza executar regras substituídas.

Detalhes internos sem efeito nas regras (organização de código, testes e correções necessárias à integração) podem ser resolvidos tecnicamente. Se uma lacuna exigir escolher uma regra de jogo, duração ainda não definida, perda de itens, comportamento novo ou incompatibilidade com saves, pedir decisão antes de implementar essa parte. Continuar o trabalho independente já especificado. Não marcar a versão como completa enquanto houver requisito aprovado não implementado ou decisão indispensável pendente. As únicas encomendas visuais ativas são as do manifesto do documento par; não gerar novamente assets existentes.

Coordenar duas IAs: uma implementa o jogo e a outra produz os assets. Este arquivo define o funcionamento; o documento par define a entrega visual compatível. As decisões e a entrega final estão registradas na seção de revisão 36.

## Fechamento da V0.0.5 — referência vigente

O usuário encerrou a definição de escopo desta versão. Esta seção consolida o resultado e prevalece sobre propostas iniciais e pendências já resolvidas no histórico abaixo. A implementação e a validação foram concluídas na revisão 36; o executável está na V0.0.5.

| Incluído | Regra final aprovada |
|---|---|
| Recursos e experiência de uso | Mostrar saldo disponível na barra e explicar armazenado/reservado no tooltip |
| População | Casas concluídas com vagas liberam mais trabalhadores; sem teto fixo de sete habitantes |
| Idiomas | Inglês principal e português disponível; traduzir interface e mensagens da versão |
| Demolição | Selecionar prédio e solicitar; construtor trabalha 10 segundos-base; base principal protegida |
| Casas ocupadas | Realocar moradores antes da demolição; aguardar vagas automaticamente quando faltarem |
| Cancelar demolição | Somente antes da primeira martelada |
| Materiais de prédio demolido | Perder materiais de construção; preservar estoque de depósito em pilhas no chão |
| Cancelar construção | Antes da primeira martelada, materiais entregues ficam no chão; depois dela, materiais da obra são perdidos. Estoque reservado e cargas ainda em trânsito são preservados |
| Horta | Canteiro fixo de 2 × 2, criado pelo depósito de comida; pode haver vários, adjacentes ou separados, em locais válidos |
| Instalação da horta | Construtor faz o cercado por 10 madeiras, uma vez; trabalhador de Comida planta e colhe |
| Plantio da horta | 2 Hortifruti por ciclo, 60 segundos de crescimento, 15 unidades colhíveis por canteiro; replantio automático opcional como pomar |
| Alimento compartilhado | Horta e árvore abastecem o mesmo Produce / Hortifruti; não separar cultivos em ingredientes |
| Árvore | 180 segundos até produção; 50 unidades por árvore; permanece adulta até esgotar pela colheita, só então libera corte. Sem copa branca/neve |
| Controles | E aproxima, Q afasta; Shift mantém colocação para repetir prédios e expansões |
| Arte | Reutilizar pacote adicionado para solo, cultivos, ferramentas e materiais. As duas composições de Hortifruti do documento par foram integradas |

**Ficam para versões futuras:** novas etapas gerais de evolução/tecnologia, economia monetária/comércio, famílias/gerações, outras ilhas, animais/carne, pesca/peixe, cozinha/refeições e novos sistemas de água, sementes ou estações. Foram possibilidades discutidas, não escopo aprovado para executar nesta entrega.

**Acabamento de entrega:** atualizar README e brief para refletir somente o que for realmente implementado; atualizar versão executável e exemplos de controles no momento da entrega, não agora. Preservar regressões relevantes e testar conjuntamente horta, árvores, recursos, cancelamentos, moradia, logística, idiomas e save/load.

**Detalhes técnicos que ainda exigem resolução na implementação, sem reabrir a lista de funcionalidades:** duração de trabalho da instalação/plantio, recortes e fases do canteiro, acesso a hortas adjacentes, destino profissional de moradores de prédios removidos, insumos/produção parcial de oficina, estabilização de mudanças de residência canceladas, e compatibilidade de saves antigos. Não inventar que esses valores foram aprovados pelo usuário. Propor defaults coerentes com os sistemas existentes e documentar escolhas antes da integração dependente; mudanças que alterem as regras aprovadas precisam voltar à decisão do usuário. Cancelamento de upgrades, plantios e expansões não foi explicitamente aprovado como extensão do cancelamento de construção; não presumir essa abrangência.

**Par de arte:** revisão 36, A005-04 (ícone de Hortifruti) e A005-07 (pilha de Hortifruti) foram produzidos, integrados e conferidos. Reutilizações e IDs antigos permanecem apenas no plano como histórico e inventário, não são pedidos para outra IA gerar novamente.

## Base que deve ser preservada

### F005-12 — Ciclo de árvore orientado pela colheita

**Decisão do usuário:** a árvore cresce, chega à fase adulta com estoque de **50 unidades** e permanece nessa fase até toda a colheita acabar. Somente quando o estoque chega a zero passa ao estágio destinado ao corte para madeira. Remover a fase visual de copa branca/neve do ciclo do jogo, preservando o arquivo original do asset. O ciclo antigo de sete fases e envelhecimento por tempo é substituído por esta regra.

**Integração com o alimento decidido:** as frutas da árvore representam 50 unidades de Produce / Hortifruti no estoque compartilhado. Não criar recurso separado de frutas nem aplicar o bônus antigo de 20 unidades por nível: cada árvore tem 50 unidades por ciclo, inclusive após evolução. Coleta transfere unidades da árvore para carga; só a entrega entra no saldo gastável. A fase adulta não se esgota por tempo, não perde frutos por envelhecimento e não regenera automaticamente seu estoque. Colheita parcial mantém a árvore adulta.

**Transição e trabalho:** o último recolhimento dispara a mudança para madeira, sem passar pela copa branca. O coletor preserva e entrega a carga de alimento já retirada; reservas de coleta da fonte devem ser revalidadas, sem transformar a carga em madeira. Apenas a atividade Madeira trabalha a árvore no estágio de corte; até esgotar o alimento, corte não é permitido. Preservar o comportamento de liberar o tronco após cortar e a renovação opcional do pomar. Não redefinir duração, estoque ou recurso repetidamente ao restaurar um save.

**Crescimento — duração aprovada:** **3 minutos (180 segundos de simulação)** do término do plantio até atingir a fase adulta produtiva. O transporte e o trabalho de plantar não integram esse tempo de crescimento. Valor inicial ajustável para testes; o usuário mencionou que poderá diminuir, mas pediu manter três minutos por enquanto. Não implementar redução automática por evolução, tecnologia ou experiência sem uma decisão posterior. A distribuição dos 180 segundos entre os visuais de crescimento ainda será ajustada na implementação, preservando o total. O ciclo atual de 56 segundos (8 + 12 + 16 + 20) será substituído.

Validar o ritmo considerando reserva inicial, consumo por habitante, implantação da horta e disponibilidade de madeira, sem criar espera inevitavelmente fatal. Pausar interrompe o crescimento; 2× acelera os segundos de simulação, sem alterar a duração-base. Na fase adulta, a interface mostra alimento restante e condição para corte, não contagem regressiva fictícia de envelhecimento. Testar que não há produção antes de completar os 180 segundos e que, após isso, surgem exatamente 50 unidades, mantendo as demais regras de F005-12.

**Arquivos a revisar:** `Scripts/game_data.gd`, `Scripts/resource_source.gd`, `Scripts/example_catalog.gd`, reservas de coleta em `Scripts/work_planner.gd`, estados de `Scripts/worker.gd`, renovação e `Scripts/save_game.gd`. Trocar a dependência de índices fixos de sete fases por estados coerentes ou mapeamento explícito. Na compatibilidade de partidas antigas, tratar fase branca e reservas acima de 50 por regra de migração documentada antes de carregar; compatibilidade ainda precisa de escopo definido.

**Arte:** reutilizar as fases de crescimento, árvore adulta/frutífera e estágio de corte já existentes; omitir o visual branco. Nenhuma nova encomenda por esta alteração.

**Aceite:** 50 unidades ao atingir maturidade; esperar não reduz alimento nem libera corte; colher 49 mantém fase adulta com 1; colher a última libera madeira e preserva a carga alimentar do trabalhador; nenhuma copa branca aparece; evolução não aumenta o estoque; pausa, renovação e save/load não duplicam recursos.

### F005-13 — Zoom por teclado e colocação repetida

**Decisões do usuário:** **E** aproxima o zoom; **Q** afasta. **Shift** permite colocar várias construções sem selecionar novamente; também funciona para expansão do território.

**Contrato proposto de interação:**

- Q/E usam o mesmo passo e limites da roda do mouse, que permanece disponível. No código atual, passo 1,12 e limites 0,8–5,0. Não mudar velocidade de simulação nem posição dos painéis. Bloquear atalhos enquanto houver digitação ou janela modal; manter câmera utilizável durante pausa quando não houver modal.
- Ler Shift no clique de colocação. Após um pedido válido com Shift pressionado, manter o mesmo tipo selecionado e a prévia ativa para outro clique. Sem Shift, manter o comportamento de colocação única. Soltar Shift não coloca nada sozinho; o próximo clique sem Shift faz uma colocação única e encerra o modo. Esc/botão direito encerram imediatamente.
- Cada clique cria no máximo um pedido. Não implementar pintura por arraste, distribuição automática ou cobrança duplicada. Pedido inválido mostra o motivo e não cria entidade; com Shift, não perder o tipo escolhido por causa de uma tentativa inválida.
- Abranger prédios e blocos de expansão; aplicar o mesmo padrão à colocação da nova horta para coerência. Repetição de plantios de árvore e investigações pode seguir o mesmo controlador, sem introduzir novos atalhos ou ações involuntárias.
- Continuar respeitando recursos, reservas, sobreposição, portas e acesso. Vários cliques não autorizam gastar a mesma reserva duas vezes; obras continuam recebendo materiais fisicamente pelas regras existentes.
- Expansões repetidas ainda precisam obedecer ao acesso válido atual. Esta decisão não autoriza marcar um bloco isolado no mar dependendo de aterros ainda não construídos; dependências entre expansões seriam outra regra a definir.
- Atualizar ajuda e tooltips em inglês e português, exibindo Shift para repetir e Q/E para zoom. O modo de colocação é transitório e não deve ser restaurado como pedido extra ao carregar uma partida.

**Integração prevista:** entrada e colocação em `Scripts/main.gd`, zoom em `Scripts/colony_camera.gd` e ajuda em `Scripts/hud.gd`. Não criar assets novos; textos e prévias existentes atendem ao fluxo.

**Aceite:** Q/E aproximam/afastam com limites e sem atuar em campo de texto; roda continua funcionando; três cliques válidos com Shift criam três pedidos sem nova seleção; clique inválido não cria pedido; clique seguinte sem Shift encerra após colocar; Esc encerra; verificar prédios, horta e expansões, bloqueio pelo HUD, pause e reservas.

### Revisão dos assets recém-adicionados — contrato visual vigente

Esta revisão substitui as encomendas de criação de ferramentas, madeira e pedra descritas nas especificações iniciais abaixo. Esses trechos permanecem como contexto do pedido original; a origem dos sprites passa a ser o pacote existente. Não gerar cópias redundantes. Reutilizações ficam neste plano, não no documento de encomendas.

Arquivos inspecionados visualmente e dimensões conferidas:

| Uso | Arquivo existente | Dimensão da imagem | Situação |
|---|---|---|---|
| Solo preparado | `Assets/Tileset/Tilled Soil and wet soil.png` | 384 × 128 | Contém terreno preparado e variantes; escolher recortes para o canteiro |
| Cultivo visual | `Assets/Crops/Spring/Carrot.png` | 128 × 16 | Fases de crescimento e colheita visíveis |
| Cultivo visual | `Assets/Crops/Spring/Cabbage.png` | 128 × 16 | Fases de crescimento e colheita visíveis |
| Cultivo visual | `Assets/Crops/Summer/Tomato.png` | 160 × 16 | Fases de crescimento e colheita visíveis |
| Machado | `Assets/Icons/RPG icons/Weapons and Armor/1. Wood/Axe.png` | 32 × 16 | Dois sprites lado a lado; selecionar primeiro recorte de 16 × 16 |
| Picareta | `Assets/Icons/RPG icons/Weapons and Armor/1. Wood/Pickaxe.png` | 32 × 16 | Dois sprites lado a lado; selecionar primeiro recorte de 16 × 16 |
| Madeira | `Assets/Icons/RPG icons/Extras/Wood.png` | 64 × 48 | Variantes de madeira; primeiro recorte de 16 × 16 é candidato para estoque/pilha |
| Pedra | `Assets/Icons/RPG icons/Extras/Stones.png` | 64 × 32 | Variantes de pedra; primeiro recorte de 16 × 16 é candidato para estoque/pilha |

Usar recortes/AtlasTexture preservando fontes, em vez de carregar a folha inteira como ícone. Para ferramentas, madeira e pedra, arte nativa de 16 × 16 pode aparecer em 32 × 32 no HUD com escala inteira 2× e nearest; no chão usar escala nativa e alinhar pivô/seleção na integração. Não impor a cabeça de pedra desenhada do brief antigo quando reutilizar a variante existente: a aparência não cria uma receita ou tecnologia nova. A005-02/03/05/06/08/09/10/11 deixam de ser encomendas de geração; nomes de destino propostos anteriormente não são obrigatórios se a integração usa o atlas original.

O ícone e a pilha mistos de Produce / Hortifruti (A005-04/07) ainda precisam de composição/adaptação, que pode usar as colheitas existentes. Permanecem no documento de assets como as únicas entregas novas atualmente especificadas. Não foram gerados arquivos.

Para a horta, já há solo e crescimento visual utilizáveis. Escolher depois o arranjo do canteiro, recortes e correspondência entre fases e tempos. Ter cenoura, repolho ou tomate na arte não cria recursos separados: todos continuam abastecendo Produce. Não interpretar o último quadro de colheita como planta no solo nem impor sistema de estações só porque o pacote separa arquivos por estação.

Também foram encontrados diretórios com animais de fazenda, peixes, árvores adicionais e cenários. Sua presença permite avaliar reutilização futura, mas não aprova implementar animais, pesca, inimigos ou novas cadeias nesta versão; não foi feita inspeção individual de todo esse catálogo.

Vila com Rei e dois trabalhadores iniciais; profissões e experiência; fome, energia, moradia e descanso; imigração por barco; transporte físico e estoques limitados; ferramentas e oficinas; árvores com sete fases; expansão costeira e pedreiras; prioridades, metas e renovação de pomares; salvamento; menus contextuais e interface adaptável.

Referência vigente: [PLANO_V0.0.4.md](PLANO_V0.0.4.md). Os planos antigos e o brief contêm informações históricas e não substituem a leitura do código atual.

## F005-01 — Recursos compreensíveis para o jogador

**Estado:** decisão aprovada em conversa; apenas documentação, sem implementação nesta etapa.

**Decisão do usuário:** mostrar na barra somente o que pode ser gasto, com detalhamento ao passar o mouse. Melhorar a experiência de compreensão dos recursos.

**Comportamento definido:**

- Identificar a barra como recursos disponíveis, evitando apresentar esse número como o total de bens da vila.
- Para cada recurso, usar o mesmo saldo livre que valida pagamentos: soma dos estoques acessíveis à economia, descontadas as reservas ativas ainda não retiradas. A fonte de cálculo deve ser compartilhada com a validação, não uma fórmula independente no HUD.
- No tooltip, informar por recurso: **Disponível para gastar**, **Total armazenado** e **Reservado para tarefas**. Exemplo: 20 pedras armazenadas, 8 reservadas, 12 disponíveis.
- Cargas em transporte, materiais já entregues a obras e itens no chão não entram no saldo livre. Se o detalhamento exibir transporte, apresentar em linha separada, sem somá-lo ao armazenado. Uma reserva já retirada não pode ser descontada novamente do estoque.
- Atualizar valores quando houver reserva, retirada, entrega, consumo e liberação de reserva, inclusive durante mudanças de tarefa e após carregar uma partida.
- Preservar os requisitos específicos de cada ação: saldo suficiente não substitui moradia, nível, acesso ou outros requisitos. O motivo mostrado deve distinguir falta de saldo de outros bloqueios.

**Integração prevista:** `Scripts/hud.gd`, `Scripts/main.gd` e `Scripts/logistics.gd`. A mudança esclarece a apresentação e compartilha a leitura do saldo; não muda custos, prioridades ou regras de reserva. Não exige novos dados persistentes; valores são derivados da simulação restaurada.

**Contrato visual:** reutilizar o tema atual com texto dinâmico, sem encomenda de imagens novas e sem ficha no documento de assets. Preservar legibilidade e adaptação às resoluções suportadas; o tooltip não pode ficar cortado fora da tela. Não depender somente de cores para explicar o estado.

**Critérios de aceite:**

1. Sem reservas, disponível e armazenado coincidem.
2. Com 20 pedras armazenadas e 8 reservadas, a barra mostra 12; tooltip explica os três valores.
3. Após retirar as 8 reservadas, permanecem 12 armazenadas e disponíveis; não há desconto duplicado.
4. Liberar uma reserva não retirada devolve disponibilidade sem criar recursos.
5. Estoques distribuídos entre depósitos, entregas, consumo e save/load mantêm barra e validação consistentes.
6. O jogador consegue distinguir falta de recursos de outros requisitos de uma ação.
7. Texto e tooltip permanecem legíveis e dentro da tela nas resoluções suportadas.

Outras melhorias gerais de experiência continuam abertas à discussão; esta aprovação não inclui reformular toda a interface.

## F005-11 — Idiomas do jogo

**Decisão do usuário:** o jogo terá inglês como idioma principal e também estará disponível em português. A tradução está incluída no trabalho planejado para a V0.0.5, não apenas como intenção futura. A documentação da conversa pode continuar em português. Nenhum texto do jogo foi traduzido ou implementado nesta etapa de planejamento.

**Escopo de localização:** traduzir toda a interface atual e as funcionalidades novas desta versão: menu inicial, HUD, construções, recursos, profissões, botões, tooltips, objetivos, notificações, motivos de bloqueio, estados dos habitantes, oficina, políticas, moradores, confirmações, salvamento/carregamento e fim de partida. Cobrir textos dinâmicos e quantidades, sem deixar mensagens de lógica fixas em português no modo inglês. Manter o nome próprio Civiz Imperium.

**Fluxo proposto:** inglês como idioma inicial quando não houver preferência salva; seletor English / Português acessível no menu, com persistência da preferência separada do progresso da civilização. Trocar idioma atualiza a interface sem reiniciar ou alterar recursos, profissões ou estado da partida. A variante regional de português ainda não foi escolhida; manter os termos já usados durante a definição da tradução.

**Aceite:** iniciar em inglês sem preferência anterior; selecionar português e verificar atualização e persistência; conferir todos os fluxos listados em ambos os idiomas, inclusive mensagens de erro e bloqueio; preservar saves e IDs internos; nenhuma chave de tradução bruta aparece ao jogador; textos e tooltips cabem nas resoluções suportadas. Não são necessárias imagens novas para traduzir rótulos dinâmicos.

**Direção técnica proposta:** textos de interface, nomes exibidos, avisos e tooltips devem usar chaves de tradução, com inglês de referência e equivalente em português. IDs internos de recursos e dados de save não mudam ao trocar idioma. A variante regional do português ainda não foi especificada. Preparar layout para comprimentos diferentes e evitar texto embutido em imagens.

**Terminologia aprovada:** “Produce” em inglês e “Hortifruti” em português para o recurso alimentar compartilhado entre árvores e horta. “Vegetables” / “Vegetais” e cenoura como recurso individual não são a nomenclatura escolhida.

**Requisito acrescentado pelo usuário:** pensar nomes e organização dos alimentos para as futuras cadeias de produção. Houve aceitação provisória de “Vegetables” / “Vegetais”, condicionada a essa coerência; o catálogo final ainda não foi escolhido.

**Direção revisada pelo usuário:** manter tipos amplos de alimento, sem separar cenoura e outros cultivos em ingredientes individuais. O usuário sugeriu que árvore e horta possam fornecer o mesmo tipo, deixando espaço para criação de animais/carne e pesca/peixe no futuro. A proposta anterior de identificar cada cultivo como recurso foi rejeitada e não deve orientar implementação ou arte.

**Decisão aprovada:** árvore e horta produzem o mesmo recurso e abastecem o mesmo estoque de “Produce” / “Hortifruti”. Manter o sistema amplo e simples nesta etapa. As fontes continuam distintas no mundo e podem ter tempos, espaço e rendimento próprios; a árvore mantém seu ciclo e madeira no estágio final. Carne (“Meat”), peixe (“Fish”), criação de animais, pesca e refeições ficam para expansão futura, sem implementação nem encomenda de assets nesta versão por esta decisão.

**Contrato de integração proposto:** adotar `produce` como ID interno compartilhado e mapear o legado `fruit` para ele na migração quando suportada. Revisar alimentação, plantio, imigração, metas, custos, cargas, reservas e saves sem duplicar estoques ou perder quantidades; não basta trocar a legenda. A política de compatibilidade de saves da V0.0.4 ainda deve ser fechada. A005-04 e A005-07 passam a representar hortifruti com os caminhos correspondentes do documento par.

## F005-03 — Horta e nova fonte de alimento

**Decisão aprovada:** acrescentar uma horta em que o trabalhador planta, aguarda o crescimento e colhe legumes, ampliando a alimentação hoje baseada em frutas. O usuário quer discutir e refinar todas as propostas antes de decidir o escopo final da versão; isso não aprova automaticamente comércio, famílias ou toda a progressão.

**Refinamento aprovado:** horta e árvores produzem o mesmo recurso amplo “Produce” / “Hortifruti”, conforme F005-11. Não introduzir estoque separado de legumes ou cenoura. A aparência do canteiro continua a definir, independentemente do nome do recurso.

**Diferença de produção aprovada:** cada horta de **2 × 2** leva **60 segundos de crescimento** após concluir o plantio até ficar pronta para colher e fornece **15 unidades de Produce / Hortifruti por ciclo**. São valores iniciais para teste, não por cada uma das quatro células. A quantidade aprovada ao fim da conversa é quinze; a menção intermediária a dez não é a regra vigente. A árvore mantém 180 segundos e 50 unidades por ciclo.

O alimento maduro fica disponível para colheita física pelo trabalhador; não entra instantaneamente no estoque ao completar o minuto. Plantio, coleta e transporte têm seu próprio trabalho/deslocamento, fora dos 60 segundos de crescimento. Pausa interrompe o relógio de crescimento e 2× acompanha a velocidade da simulação. Esta decisão não altera a duração da ação de colher. Replantio opcional inicia outro ciclo após terminar a colheita e executar novo plantio. Balancear o ritmo total nos testes, preservando a utilidade das duas fontes.

**Aceite de crescimento/rendimento:** canteiro ainda não colhível antes de completar 60 segundos de crescimento; depois oferece exatamente 15 unidades por ciclo, compartilhadas entre todas as células da horta, sem multiplicar por quatro. Reserva, coleta parcial e save/load não duplicam a produção; apenas a entrega aumenta o estoque disponível.

**Custo de plantio aprovado:** plantar uma horta custa **2 unidades de Produce / Hortifruti**, como valor inicial para teste, seguindo o custo de plantio da árvore. O custo é por canteiro de 2 × 2, não por célula. Aplicar ao plantio de cada ciclo, inclusive ao replantio automático, seguindo o modelo do pomar; não acrescentar sementes ou moeda implicitamente. Materiais devem seguir a logística física e as reservas existentes, sem descontar novamente na conclusão do plantio. Sem saldo disponível, o pedido não pode consumir recursos inexistentes; a renovação automática também respeita a reserva alimentar, como o pomar.

**Instalação — decisão aprovada:** cada horta de 2 × 2 exige **10 unidades de madeira para construir o cercado**, pagas uma vez na instalação. O cercado permanece entre as colheitas; cada plantio custa separadamente 2 unidades de Hortifruti, sem cobrar novamente as 10 madeiras. Isso substitui a sugestão rejeitada de preparar o canteiro sem material e a sugestão não aceita de cinco madeiras. Separar os custos de instalação e plantio na interface e nas solicitações físicas de materiais. O primeiro ciclo completo exige 10 madeiras para instalação e 2 Hortifruti para plantio, sem cobrança duplicada. Pedra não foi incluída. Responsável e duração da instalação, posição da entrada e efeito da cerca na navegação ainda devem ser definidos, preservando hortas adjacentes e sua área de 2 × 2.

**Responsável pela instalação — confirmado no fechamento:** o construtor faz o cercado; depois o trabalhador de Comida planta e colhe. Esta confirmação resolve a referência anterior ao responsável ainda indefinido. Tempo de trabalho e acesso continuam detalhes de integração, sem mudar essa divisão de funções.

**Arte do cercado:** verificar `Assets/Objects/Exterior/Fence and Bridge/Fence Wood.png` já presente antes de encomendar peças. O arquivo foi localizado no inventário, mas os recortes e sua adequação a um canteiro de 2 × 2 ainda precisam de inspeção visual. Não criar pedido de imagem duplicado no documento de assets sem identificar uma lacuna real.

**Trabalhadores — decisão aprovada:** todos os tipos de comida compartilham a mesma atividade de trabalho. Na V0.0.5, os trabalhadores de Comida (`food`) cuidam tanto das árvores quanto da horta, incluindo plantio e colheita; não criar profissão separada de agricultor nem nova alocação de pessoas só para a horta. A direção para futuros alimentos também é manter a mesma atividade Comida, sem implementar agora criação de animais ou pesca. A distribuição entre fontes, acesso e prioridades ainda precisa ser refinada; compartilhar profissão não significa usar um único tipo de recurso para todos os alimentos futuros.

**Criação — fluxo aprovado:** selecionar o depósito de comida, escolher **Criar horta** no menu contextual e marcar o local no mapa. O botão inicia posicionamento; não cria uma horta pronta instantaneamente. Os trabalhadores de Comida executam o plantio conforme as regras de trabalho definidas. Texto correspondente proposto em inglês: **Create Garden**, a alinhar com a terminologia final de localização.

**Replantio — decisão aprovada:** oferecer uma opção de ligar/desligar o replantio automático da horta, seguindo o funcionamento de renovação do pomar. Não tornar o replantio obrigatoriamente automático. Com a opção ligada, após terminar a colheita, a vila agenda o próximo plantio no mesmo canteiro; trabalhadores de Comida executam a tarefa. Desligar preserva o cultivo e o trabalho já existentes, sem gerar novos ciclos automáticos.

**Tamanho — decisão aprovada:** cada horta ocupa 2 × 2 células de terreno. O jogador aumenta a produção criando outras hortas, ao lado das existentes ou em qualquer outro local válido do mapa. Cada canteiro conserva seu tamanho; não há upgrade de tamanho nem fusão automática entre hortas nesta decisão. Na grade atual de 16 × 16 pixels por célula, a ocupação corresponde a 32 × 32 pixels de mundo; isso não define sozinho a colisão ou a altura visual das plantas. Reutilizar o solo e os cultivos do pacote adicionado para compor o canteiro.

**Expansão por novos canteiros — decisão aprovada:** usar novamente Criar horta no depósito de comida e escolher outro local, sem exigir proximidade de uma horta existente. Permitir canteiros encostados desde que mantenham acesso de trabalho e não se sobreponham. “Qualquer lugar” respeita terreno disponível, ocupação e circulação; não autoriza plantio sobre água, prédios ou outros objetos. Cada horta mantém seleção, ciclo e opção de replantio próprios. Verificar especialmente que canteiros adjacentes não tornem as hortas internas inacessíveis; a navegação da horta ainda deve ser definida para atender essa possibilidade sem bloquear o trabalho.

**Integração proposta:** opção no menu contextual da horta, com rótulos traduzidos (proposta: Auto-replant / Replantio automático e estado ligado/desligado). Respeitar acesso, trabalhador, materiais e reserva alimentar conforme custos a definir; sem condições, aguardar e informar o motivo, sem duplicar ordens nem interromper o posicionamento ativo do jogador. Persistir a opção e o ciclo em save/load. Seguir o padrão atual do pomar, inicialmente desligado, permitindo colheita sem replantio; a forma de solicitar outro plantio manual ainda deve ser detalhada. Nenhum ícone novo necessário para esta opção.

**Aceite:** opção ligada repete plantio após a colheita completa quando há condições; desligada não agenda outro ciclo; desligar durante crescimento/colheita não destrói a produção; retomada após falta de recursos não cria ordens duplicadas; save/load preserva a escolha.

**Integração proposta do posicionamento:** reutilizar a prévia de colocação e cancelamento antes de marcar o pedido, validar terreno/acesso e explicar bloqueios. Cada horta ocupa 2 × 2; custos, duração de instalação e eventual requisito de nível ainda não estão definidos. Acesso pela base ou por outros menus não foi incluído nesta decisão. Não encomendar um novo ícone de botão apenas por existir essa ação; usar tiles existentes e definir sua composição e fases na integração.

**Ainda a decidir, uma questão por vez:** aparência do cultivo; custo de instalação e plantio; fases e duração do crescimento; rendimento e nutrição; solicitação de novo plantio manual; momento de desbloqueio e prioridades entre fontes. O tamanho fixo 2 × 2, expansão por novos canteiros, acesso pelo depósito de comida e opção de replantio automático já estão definidos. Sementes, água, estações e novas ferramentas não estão aprovadas por esta decisão.

**Integração a detalhar:** conectar a horta ao recurso compartilhado no catálogo alimentar, estoque, logística, consumo, metas e save/load; definir ocupação e acesso da horta e seu relacionamento com a coleta das árvores. Não definir custos, tempos ou novos recursos implicitamente durante a arte.

**Assets — orientação do usuário:** a arte da horta já existe na pasta Assets; localizar e reutilizar antes de solicitar qualquer arte nova de canteiro. A inspeção visual identificou `Assets/Tiles/Tileset Grass Summer.png` com vários terrenos e blocos de vegetação, candidato a confirmar para a horta; `Assets/Tiles/Barn tileset.png` contém terreno e estrutura de madeira. Ainda não foi confirmada uma sequência de crescimento específica da horta. Não confundir variações de terreno/folhagem com fases de crescimento sem verificar o recorte pretendido. Documentar aqui os tiles escolhidos quando confirmados. Somente lacunas visuais reais, após essa verificação, poderão virar encomendas no documento de assets. Ícone e pilha do hortifruti continuam nas fichas já definidas, independentes dos visuais do canteiro.

**Estado:** conceito aprovado, especificação em discussão; não implementar nem produzir arte da horta ainda.

**Esclarecimento do usuário sobre tiles:** verificar as peças já presentes no projeto e reutilizá-las quando servirem, sem pressupor um asset de horta completo pronto. A indicação anterior de assets existentes é uma orientação de busca e reaproveitamento. Terra e vegetação foram vistas nos tilesets citados; a adequação dos recortes a um canteiro e aos estados de crescimento ainda deve ser validada. Antes de encomendar cada nova peça, verificar também o inventário existente para evitar trabalho duplicado. Gerar apenas o que faltar ao resultado definido.

## F005-02 — Demolição simples por construtor

**Estado:** fluxo básico aprovado pelo usuário; regras complementares ainda pendentes. Somente planejamento, sem implementação nesta etapa.

**Decisão do usuário:** clicar no prédio, escolher **Demolir** em suas opções e enviar um construtor, que leva um tempo para concluir a demolição. O prédio não desaparece instantaneamente ao clicar.

**Base principal — decisão aprovada:** a base principal não pode ser demolida. Não oferecer a ação em seu menu e rejeitar qualquer solicitação de demolição da base na lógica do jogo. Os demais prédios seguem o fluxo definido, com as condições de moradores, estoque e trabalho aplicáveis. Validar que a proteção também se mantém após carregar uma partida.

**Obras inacabadas — decisão aprovada:** oferecer **Cancelar obra** no contexto de uma construção ainda não concluída. O construtor interrompe a tarefa; não devolver materiais já gastos na obra. Cancelamento de obra é distinto da demolição de um prédio concluído e não gera reembolso do custo original.

**Materiais por etapa — decisão vigente, substitui a revisão 10:** antes da primeira martelada efetiva, cancelar a construção preserva todos os materiais já entregues como pilhas no chão para recolher. Após a primeira martelada, cancelar perde os materiais da obra, sem devolução proporcional ao progresso. O início do trabalho é o marco de gasto; entrega e chegada do construtor sozinhas não contam. A construção continua exigindo todos os materiais entregues antes de começar. Persistir esse marco no save, sem depender apenas do quadro de animação.

Materiais ainda no depósito são preservados e suas reservas para a obra devem ser liberadas. Cargas em transporte também são preservadas; não podem continuar sendo entregues ao canteiro cancelado. Reencaminhá-las à logística de armazenamento e, sem destino com espaço/acesso, manter uma carga ou pilha recuperável conforme as regras existentes, sem duplicar ou apagar materiais. Nenhum reembolso abstrato do custo original deve ser criado. Materiais no chão só voltam ao saldo disponível após entrega a um depósito.

Ainda falta definir se o cancelamento vale para melhorias, plantios e expansões além das construções de prédios.

**Aceite do cancelamento:** antes da primeira martelada, 8 pedras no canteiro, 3 em transporte e 4 reservadas no depósito resultam em 8 pedras recuperáveis no chão, preservação das 3 transportadas e liberação da reserva das 4 armazenadas. Após a primeira martelada, os materiais entregues para aquela construção são perdidos ao cancelar, mesmo com progresso pequeno. Testar também a entrega completa sem início do trabalho: ainda deve preservar os materiais. Construtor e entregadores deixam de executar o pedido cancelado. Remover a reserva de terreno da obra, atualizar caminhos e limpar referências com segurança. Save/load não pode ressuscitar a obra, redefinir o marco de gasto ou duplicar materiais.

**Cancelar demolição — decisão aprovada:** permitido enquanto o construtor ainda não começou a demolir, inclusive durante espera por moradia, mudança de moradores, espera por trabalhador e deslocamento. A primeira martelada efetiva marca o início irreversível; a simples chegada ao prédio não basta enquanto não houver trabalho realizado. Após a primeira martelada, retirar/desabilitar o cancelamento com explicação clara e rejeitá-lo também na lógica, inclusive após pausa, troca de trabalhador ou save/load. Persistir esse marco independentemente de animação ou troca de tarefa. Cancelar antes dele preserva o prédio e não perde materiais de construção. Definir ainda como estabilizar mudanças de residência que já estiverem em andamento ao cancelar.

**Duração aprovada:** 10 segundos de trabalho-base do construtor como valor inicial de balanceamento, ajustável após testes. Deslocamento, espera por moradia e espera por trabalhador não fazem parte desses 10 segundos. A pausa interrompe o trabalho e a velocidade da simulação segue a regra global. Integrar os modificadores de produtividade do construtor de maneira coerente com as obras existentes; não tratar como dez segundos de relógio real independentemente da simulação.

**Fluxo definido:**

1. Selecionar um prédio e abrir seu menu contextual.
2. Clicar em **Demolir** para solicitar o serviço.
3. Um trabalhador alocado em Construção desloca-se até o prédio e executa a tarefa ao longo de um tempo de trabalho.
4. Ao concluir, remover o prédio e liberar seu terreno, depois de tratar estoques, moradores e vínculos de trabalho conforme as regras que ainda serão decididas.

**Detalhamento técnico proposto para manter coerência com o jogo:** solicitação única por prédio; progresso só avança com trabalho efetivo do construtor; pausa interrompe o avanço. Sem construtor ou sem acesso, o pedido aguarda com motivo visível. A remoção deve atualizar navegação, seleção e referências ao prédio. Save/load deve preservar pedido e progresso e retomar a alocação de trabalho sem duplicar a tarefa. São requisitos de integração a detalhar, não novas mecânicas aprovadas separadamente.

**Materiais — decisão aprovada:** demolir não devolve os materiais investidos na construção; não gerar reembolso de construção ou melhoria. O estoque guardado em um depósito não é destruído: fica no chão no local da demolição, separado por recurso, com as quantidades preservadas para recuperação logística. Não confundir estoque armazenado com materiais consumidos para erguer o prédio. A extensão dessa regra a insumos e produção parcial de oficinas ainda deve ser especificada.

**Integração das pilhas proposta:** ao concluir a demolição, transferir o estoque remanescente para pilhas físicas recuperáveis antes de remover a entidade. Liberar/reorganizar reservas e entregas que apontam ao prédio removido sem duplicar ou apagar cargas. Recursos no chão não entram no saldo disponível da barra até serem entregues em armazenamento. Sem espaço em outro depósito, permanecem no chão. Usar a logística de pilhas existente, com representação própria por recurso em F005-10. Posição exata das pilhas e tratamento de rotas devem manter acesso ao material. Essas condições detalham a conservação necessária; não autorizam geração de recursos extras.

**Casas ocupadas — decisão aprovada:** o pedido de demolição organiza uma mudança automática. Havendo vagas em outras residências, os moradores se mudam; o construtor só começa quando a casa estiver vazia. Sem vagas suficientes, o pedido aguarda e informa quantas pessoas ainda precisam de moradia, por exemplo: “Precisamos de moradia para 2 pessoas”. Ao concluir uma casa ou liberar capacidade habitacional suficiente, a mudança e depois a demolição prosseguem automaticamente, sem exigir novo clique. O pedido não expulsa habitantes para ficarem sem teto.

**Sequência e integração propostas para essa decisão:**

1. Exibir estados compreensíveis: aguardando moradia → moradores em mudança → aguardando construtor → demolindo → concluído.
2. Procurar vagas em residências concluídas, acessíveis e sem pedido de demolição. Reservar destino para todos os moradores remanescentes antes de iniciar a mudança; não disputar essas vagas com imigração ou outras mudanças simultâneas.
3. Mostrar os habitantes saindo e percorrendo o caminho até a nova residência com os personagens e animações de caminhada existentes. Troca de residência não altera identidade, profissão ou experiência.
4. Não entregar a casa ao construtor enquanto houver moradores dentro ou mudança ainda incompleta. Durante a espera, preservar a possibilidade de descanso dos moradores originais; impedir novas atribuições de residência ao prédio marcado para demolição.
5. Se o destino ou trajeto deixar de estar disponível, suspender a etapa, explicar o bloqueio e buscar outra vaga segura sem duplicar moradores ou deixar referências para uma casa removida.
6. Salvar pedido, progresso da mudança e destinos necessários; ao carregar, revalidar acesso/capacidade e retomar sem executar a demolição prematuramente.

**Aceite adicional:** casas ocupadas não desaparecem com moradores dentro; falta de vaga não produz moradores sem residência; novas vagas desbloqueiam o pedido automaticamente; duas demolições e a imigração não usam a mesma vaga; mudança funciona com morador descansando e após save/load. Tratamento de carga/trabalho em andamento deve preservar materiais e necessidades, seguindo as interrupções seguras já existentes.

O usuário aprovou o fluxo de realocação automática. Poeira, sons e outros efeitos de demolição foram sugestões de apresentação e ainda não têm encomenda definida; não acrescentar assets desses efeitos sem especificação posterior.

**Decisões pendentes antes da implementação:**

- Nenhuma diferença de tempo por tipo de prédio foi definida; usar os 10 segundos de trabalho-base aprovados como padrão inicial.
- Destino de entregas em andamento, insumos de oficinas e produção parcial; estoque de depósitos já está definido como pilhas no chão.
- Tratamento de trabalhadores vinculados profissionalmente ao prédio; moradores de casas seguem a mudança automática definida acima.
- Alcance do cancelamento a melhorias, plantios e expansões. Cancelamento de construção e de demolição já estão definidos acima; falta resolver a mudança de residência em andamento se a demolição for cancelada.

**Integração prevista:** menu contextual em `Scripts/hud.gd`, estado do prédio em `Scripts/building.gd`, escolha/execução de trabalho em `Scripts/worker.gd`, navegação em `Scripts/main.gd`, logística, residência e salvamento. Não apagar entidades antes de resolver referências e cargas.

**Arte:** botão, indicador de progresso e animação de trabalho podem reutilizar a interface atual. Não há pedido de ruína ou efeito novo. As pilhas de materiais exigem os assets de F005-10, descritos no documento par.

**Critérios de aceite do fluxo aprovado:** clicar solicita a tarefa sem remover o prédio; um construtor precisa chegar e trabalhar; a tarefa exige tempo; após concluir, o terreno fica disponível. Não reembolsar materiais de construção. Demolir um depósito com 12 pedras e 5 madeiras deve preservar exatamente essas quantidades no chão, recuperáveis por transporte, sem acrescentar o custo do prédio. Verificar depósitos vazios/cheios, reservas, carga já retirada, falta de espaço e save/load. Completar as regras pendentes antes da implementação dependente.

## F005-10 — Assets de recursos e pilhas no chão

**Decisão do usuário:** criar assets adequados para todos os materiais, incluindo os recursos deixados no chão por depósitos demolidos. Acrescentar futuras encomendas conforme forem escolhidos novos recursos; não inventar agora materiais de atividades ainda indefinidas.

**Catálogo alvo desta versão:** hortifruti (`produce`, unificando o atual `fruit` e a produção da horta), madeira (`wood`), pedra (`stone`), machado (`axe`) e picareta (`pickaxe`).

**Contrato inicial proposto:** ícones de interface de 32 × 32 e pilhas de mundo de 16 × 16, PNG RGBA transparente e filtro nearest. Ícones de ferramentas já são A005-02/03; acrescentar ícones de frutas, madeira e pedra (A005-04/05/06) e cinco pilhas de chão (A005-07 a A005-11). Caminhos exatos no documento par. Os ícones usam centro (16,16); as pilhas usam pivô (8,12), origem de coordenadas no canto superior esquerdo. Pilhas não bloqueiam navegação, como a logística existente.

**Integração:** registrar associação explícita recurso → ícone → sprite de pilha no catálogo de dados; usar na HUD e em `Scripts/resource_pile.gd`. Representar quantidades por dados e texto/tooltip, sem duplicar sprites a cada unidade ou pintar números na arte. Fruta caída é um item coletado, não uma nova árvore; pedra no chão não é jazida. Todos os itens continuam sujeitos às mesmas regras de armazenamento e transporte.

**Persistência e aceite:** preservar tipo, quantidade e localização da pilha ao salvar/carregar. Cada recurso deve ser reconhecível, recolhido e entregue sem duplicação; nenhuma mudança em receitas, quantidade, durabilidade ou saldo disponível decorre da troca visual. Os arquivos ainda não foram produzidos; toda execução permanece adiada enquanto discutimos a versão.

## F005-09 — Identidade visual das ferramentas

Reutilizar os sprites de machado e picareta identificados no inventário vigente acima, associando-os aos recursos existentes na interface de estoque, oficina e inspeção do habitante. Preservar rótulos, quantidades, receitas e durabilidade. Não gerar ferramentas novas nem adicionar animações equipadas. Os contratos de geração antigos foram substituídos pela reutilização e foram removidos desta especificação de entrega.

## Coordenação da implementação e da arte

- Mecânicas e parâmetros compartilhados são definidos aqui e repetidos com os mesmos valores na ficha de asset.
- A IA de assets recebe o par completo, não apenas uma descrição resumida.
- Um ID de asset deve apontar para uma ficha do documento par; nomes e caminhos previstos devem coincidir.
- Não consumir arte marcada como rascunho como se fosse aprovada para integração.
- Mudanças em dimensões, estados, quadros, pivôs ou nomes exigem atualizar o par e incrementar sua revisão compartilhada.
- Se houver placeholder, documentar seu ID, limitações e substituição. Não declarar uma funcionalidade visualmente concluída com placeholder sem registrar essa condição.

## Validação prevista

Definir testes conforme o escopo escolhido. Preservar regressões relevantes da V0.0.4, verificar os fluxos novos, save/load, recursos reservados e transportados, e interface nas resoluções suportadas. Conferir visualmente cada asset integrado em sua escala de jogo, inclusive seleção, profundidade e animação, quando aplicáveis.

## Histórico da conversa — não usar como instruções de implementação

| Revisão | Decisão |
|---|---|
| 01 | Criado o padrão obrigatório de dois documentos por versão. V0.0.5 ainda em discussão; nenhuma produção de assets ou implementação autorizada por este plano. |
| 02 | Usuário aprovou saldo livre na barra e detalhamento de armazenado/reservado ao passar o mouse. F005-01 documentada; A005-01 reutiliza o tema, sem arte nova. Implementação permanece para etapa posterior. |
| 03 | Usuário confirmou V0.0.5 e pediu assets apenas para arte a produzir. Retirada a ficha de reutilização A005-01, sem reaproveitar seu ID. Incluídas encomendas de machado e picareta (F005-09, A005-02/03). Dimensões e uso em UI são a especificação inicial proposta; animações equipadas permanecem fora do escopo definido. |
| 04 | Usuário definiu demolição pelo menu do prédio, executada por construtor com tempo de trabalho. Registrado o fluxo F005-02; materiais, moradores, duração e cancelamentos seguem pendentes. Nenhum asset adicional encomendado. |
| 05 | Usuário definiu perda dos materiais de construção e preservação do estoque do depósito no chão. Incluída F005-10 com ícones e pilhas dos cinco recursos atuais; futuros recursos serão especificados conforme as próximas decisões. |
| 06 | Usuário aprovou mudança automática dos moradores antes de demolir casas. Sem vagas, o pedido aguarda e informa a necessidade; com novas vagas, prossegue automaticamente. Reutilizar personagens e caminhada existentes; efeitos adicionais continuam como sugestões. |
| 07 | Usuário aprovou 10 segundos de trabalho do construtor como duração inicial da demolição, para ajuste em testes. |
| 08 | Usuário aprovou proteção da base principal: não pode ser demolida. Demolição permanece disponível para os demais prédios conforme suas condições. |
| 09 | Usuário aprovou cancelar obras inacabadas, interrompendo o construtor e sem recuperar materiais já gastos. Tratamento de materiais reservados, em trânsito e entregues ainda precisa ser explicitado. |
| 10 | Usuário definiu cancelamento da demolição somente antes da primeira martelada e aprovou perda apenas dos materiais já entregues ao cancelar uma construção. Estoque reservado e cargas em trânsito permanecem preservados. |
| 11 | Usuário revisou a regra de construção: antes da primeira martelada, materiais entregues ficam no chão ao cancelar; depois dela, materiais da obra são perdidos. Substitui a perda na simples entrega registrada na revisão 10. Regra de cancelamento da demolição permanece inalterada. |
| 12 | Usuário aprovou a ideia de horta com plantio, crescimento e colheita de legumes e pediu refinamento por sugestões. Cultivo, regras e contrato visual ainda serão definidos. Discutir todas as áreas propostas antes de fechar o escopo final. |
| 13 | Usuário definiu inglês como idioma principal e português como idioma adicional. Registrar localização e discutir nomes equivalentes antes de fechar o alimento da horta; cenoura permanece apenas sugestão. |
| 14 | Usuário pediu que os nomes considerem futuras cadeias de produção. Registrada a exigência e a proposta de separar categoria alimentar de ingrediente; definição final do primeiro cultivo permanece aberta. |
| 15 | Usuário rejeitou a separação por cultivo e pediu tipos amplos, sugerindo árvore e horta no mesmo tipo de alimento, com carne e peixe como possibilidades futuras. Registrada a nova direção; nomes, unificação e escopo futuro ainda em discussão. |
| 16 | Usuário aprovou árvore e horta no mesmo estoque de Produce / Hortifruti, mantendo tipos amplos. Carne e peixe ficam para o futuro. Atualizadas as fichas de ícone e pilha do alimento compartilhado; regras específicas da horta continuam em discussão. |
| 17 | Usuário definiu os mesmos trabalhadores de Comida para todos os tipos de alimento. Horta e árvores usam a atividade existente; não criar profissão adicional. Direção extensível aos alimentos futuros, sem antecipar sua implementação. |
| 18 | Usuário aprovou selecionar o depósito de comida, escolher Criar horta e marcar o lugar no mapa. Tamanho, custos e fases ainda em discussão. |
| 19 | Usuário informou que já possui assets da horta e pediu busca correta na pasta. Registrada prioridade de reutilização; folha Tileset Grass Summer identificada visualmente como candidata, recortes/fases ainda a confirmar. Nenhuma nova encomenda de canteiro criada. |
| 20 | Usuário esclareceu que é preciso verificar tiles existentes e reaproveitar o que servir. Não assumir conjunto completo de horta nem fases já confirmadas; encomendar apenas lacunas após inspeção. |
| 21 | Revisado o novo pacote: confirmados solo preparado, fases de cultivos, ferramentas, madeira e pedra. Priorizar recortes existentes; retiradas oito encomendas redundantes do documento de assets. Permanecem duas composições de Hortifruti. Horta ainda precisa de dimensões e regras; não implementada. |
| 22 | Esclarecido que a tradução integral da interface para inglês, mantendo português, integra o plano V0.0.5. Registrados abrangência, seletor/persistência propostos e critérios de teste; execução ainda não iniciada. |
| 23 | Usuário escolheu replantio automático opcional para a horta, seguindo a renovação do pomar: ligar/desligar, mantendo o cultivo atual. Registradas integração proposta e verificações. |
| 24 | Usuário aprovou horta inicial de 2 × 2 células e possibilidade de aumentar. Forma e regras da ampliação ainda serão decididas; não supor crescimento automático. |
| 25 | Usuário esclareceu que aumenta criando outras hortas, lado a lado ou em outros locais válidos. Cada canteiro permanece 2 × 2; retirada a proposta de upgrade de tamanho de uma única horta. |
| 26 | Usuário definiu árvore adulta com 50 unidades até esgotamento por colheita, sem copa branca, e pediu crescimento mais lento ainda a balancear. Incluídos E/Q para zoom e Shift para repetir construções/expansões. Mudanças documentadas, ainda não implementadas durante esta conversa de planejamento. |
| 27 | Usuário aprovou três minutos até a árvore começar a produzir, como valor inicial ajustável. Não foi definida mecânica de redução futura; manter 180 segundos de simulação por enquanto. |
| 28 | Usuário aprovou horta com crescimento mais rápido e menos alimento por colheita que a árvore. Tempo e quantidade por canteiro/ciclo ainda serão definidos. |
| 29 | Usuário aprovou, após explicação, um minuto de crescimento e quinze unidades de alimento por horta de 2 × 2 a cada ciclo, como valores iniciais ajustáveis. |
| 30 | Usuário aprovou duas unidades de Hortifruti para plantar a horta, como custo inicial ajustável, seguindo o plantio da árvore. |
| 31 | Usuário rejeitou instalação sem material e definiu madeira para o cercado da horta, além do custo de plantio. Quantidade e execução ainda a definir; verificar cerca existente antes de pedir arte. |
| 32 | Usuário definiu dez madeiras por horta para o cercado instalado uma vez; mantidas duas unidades de Hortifruti a cada plantio. |
| 33 | Usuário confirmou construtor para o cercado e trabalhador de Comida para plantio/colheita, e encerrou o escopo V0.0.5. Consolidado resumo vigente, separado roadmap futuro e explicitado que implementação/validação ainda não ocorreram. |

| 34 | Revisão para entrega a outra IA: execução restrita ao escopo aprovado, roadmap excluído, propostas não autorizam regras extras; removidas encomendas visuais substituídas e tabela antiga de possibilidades. Decisões indispensáveis ainda abertas devem ser consultadas, não inventadas. |
