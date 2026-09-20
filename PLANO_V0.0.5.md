# Civiz Imperium — Plano V0.0.5

- Versão alvo: **0.0.5**.
- Revisão do contrato compartilhado: **20**.
- Estado: **planejamento em andamento; recursos, ferramentas visuais e fluxo básico de demolição definidos; sem implementação**.
- Documento par obrigatório: [ASSETS_V0.0.5.md](ASSETS_V0.0.5.md).
- Base existente: V0.0.4; este documento não muda a versão executável.

## Objetivo deste par

Coordenar duas IAs: uma implementa o jogo e a outra produz os assets. Este arquivo define o funcionamento; o documento par define a entrega visual compatível. As decisões são registradas durante a conversa; a implementação ainda não foi iniciada.

## Base que deve ser preservada

Vila com Rei e dois trabalhadores iniciais; profissões e experiência; fome, energia, moradia e descanso; imigração por barco; transporte físico e estoques limitados; ferramentas e oficinas; árvores com sete fases; expansão costeira e pedreiras; prioridades, metas e renovação de pomares; salvamento; menus contextuais e interface adaptável.

Referência vigente: [PLANO_V0.0.4.md](PLANO_V0.0.4.md). Os planos antigos e o brief contêm informações históricas e não substituem a leitura do código atual.

## Decisões e propostas de escopo

| ID | Ponto | Situação atual | Assets relacionados |
|---|---|---|---|
| F005-01 | Clareza do estoque disponível e reservado | Decidido: barra mostra saldo livre; tooltip detalha armazenado e reservado | Reutiliza UI; sem encomenda de arte |
| F005-02 | Cancelamento de obras e demolição | Demolição com mudança prévia e 10s de trabalho; cancelável antes da primeira martelada. Cancelar construção antes do trabalho preserva materiais no chão; após começar, perde materiais da obra | Pilhas de F005-10 |
| F005-03 | Horta e legumes | Aprovado o ciclo: trabalhador planta, espera crescer e colhe legumes. Cultivo e regras em refinamento | Necessidade visual identificada; encomenda completa após escolher cultivo e estágios |
| F005-04 | Progressão e novas atividades | Três níveis; definir o que muda concretamente ao evoluir | A definir após desbloqueios |
| F005-05 | Economia monetária | Roadmap antigo; não implementada | A definir se entrar no escopo |
| F005-06 | Famílias e gerações | Não implementadas; sucessão simples já existe | A definir se entrar no escopo |
| F005-07 | Outras ilhas e comércio marítimo | Apenas imigração marítima existe hoje | A definir se entrar no escopo |
| F005-08 | Atualização do brief | Ainda descreve V0.0.3 e ausência de save | Não exige arte por si só |
| F005-09 | Assets das ferramentas | Incluído pelo usuário: criar arte de machado e picareta; especificação inicial abaixo | A005-02 e A005-03 |
| F005-10 | Assets dos materiais e pilhas recuperáveis | Incluído: representar todos os recursos atuais, inclusive estoque deixado no chão após demolição | A005-04 a A005-11 |
| F005-11 | Inglês e português | Usuário definiu inglês como idioma principal e português também disponível; alcance da migração nesta versão a detalhar | Arte sem texto fixo; nenhuma encomenda nova por enquanto |

Esta tabela é uma lista de possibilidades, não uma promessa de incluir tudo na versão.

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

**Decisão do usuário:** o jogo terá inglês como idioma principal e também estará disponível em português. A documentação da conversa pode continuar em português. Esta decisão orienta o planejamento; a migração do texto existente e o seletor de idioma ainda precisam ter seu alcance fechado para a V0.0.5.

**Direção técnica proposta:** textos de interface, nomes exibidos, avisos e tooltips devem usar chaves de tradução, com inglês de referência e equivalente em português. IDs internos de recursos e dados de save não mudam ao trocar idioma. A variante regional do português ainda não foi especificada. Preparar layout para comprimentos diferentes e evitar texto embutido em imagens.

**Terminologia aprovada:** “Produce” em inglês e “Hortifruti” em português para o recurso alimentar compartilhado entre árvores e horta. “Vegetables” / “Vegetais” e cenoura como recurso individual não são a nomenclatura escolhida.

**Requisito acrescentado pelo usuário:** pensar nomes e organização dos alimentos para as futuras cadeias de produção. Houve aceitação provisória de “Vegetables” / “Vegetais”, condicionada a essa coerência; o catálogo final ainda não foi escolhido.

**Direção revisada pelo usuário:** manter tipos amplos de alimento, sem separar cenoura e outros cultivos em ingredientes individuais. O usuário sugeriu que árvore e horta possam fornecer o mesmo tipo, deixando espaço para criação de animais/carne e pesca/peixe no futuro. A proposta anterior de identificar cada cultivo como recurso foi rejeitada e não deve orientar implementação ou arte.

**Decisão aprovada:** árvore e horta produzem o mesmo recurso e abastecem o mesmo estoque de “Produce” / “Hortifruti”. Manter o sistema amplo e simples nesta etapa. As fontes continuam distintas no mundo e podem ter tempos, espaço e rendimento próprios; a árvore mantém seu ciclo e madeira no estágio final. Carne (“Meat”), peixe (“Fish”), criação de animais, pesca e refeições ficam para expansão futura, sem implementação nem encomenda de assets nesta versão por esta decisão.

**Contrato de integração proposto:** adotar `produce` como ID interno compartilhado e mapear o legado `fruit` para ele na migração quando suportada. Revisar alimentação, plantio, imigração, metas, custos, cargas, reservas e saves sem duplicar estoques ou perder quantidades; não basta trocar a legenda. A política de compatibilidade de saves da V0.0.4 ainda deve ser fechada. A005-04 e A005-07 passam a representar hortifruti com os caminhos correspondentes do documento par.

## F005-03 — Horta e nova fonte de alimento

**Decisão aprovada:** acrescentar uma horta em que o trabalhador planta, aguarda o crescimento e colhe legumes, ampliando a alimentação hoje baseada em frutas. O usuário quer discutir e refinar todas as propostas antes de decidir o escopo final da versão; isso não aprova automaticamente comércio, famílias ou toda a progressão.

**Refinamento aprovado:** horta e árvores produzem o mesmo recurso amplo “Produce” / “Hortifruti”, conforme F005-11. Não introduzir estoque separado de legumes ou cenoura. A aparência do canteiro continua a definir, independentemente do nome do recurso.

**Trabalhadores — decisão aprovada:** todos os tipos de comida compartilham a mesma atividade de trabalho. Na V0.0.5, os trabalhadores de Comida (`food`) cuidam tanto das árvores quanto da horta, incluindo plantio e colheita; não criar profissão separada de agricultor nem nova alocação de pessoas só para a horta. A direção para futuros alimentos também é manter a mesma atividade Comida, sem implementar agora criação de animais ou pesca. A distribuição entre fontes, acesso e prioridades ainda precisa ser refinada; compartilhar profissão não significa usar um único tipo de recurso para todos os alimentos futuros.

**Criação — fluxo aprovado:** selecionar o depósito de comida, escolher **Criar horta** no menu contextual e marcar o local no mapa. O botão inicia posicionamento; não cria uma horta pronta instantaneamente. Os trabalhadores de Comida executam o plantio conforme as regras de trabalho definidas. Texto correspondente proposto em inglês: **Create Garden**, a alinhar com a terminologia final de localização.

**Integração proposta do posicionamento:** reutilizar a prévia de colocação e cancelamento antes de marcar o pedido, validar terreno/acesso e explicar bloqueios. A área ocupada, custos, duração de instalação e eventual requisito de nível ainda não estão definidos; não supor valores para implementar ou gerar arte. Acesso pela base ou por outros menus não foi incluído nesta decisão. Não encomendar um novo ícone de botão apenas por existir essa ação; a arte do canteiro será especificada quando suas dimensões e fases forem fechadas.

**Ainda a decidir, uma questão por vez:** aparência do cultivo; tamanho/forma do canteiro; custo de instalação e plantio; fases e duração do crescimento; rendimento e nutrição; replantio manual ou automático; momento de desbloqueio e prioridades entre fontes. O acesso pelo depósito de comida já está definido. Sementes, água, estações e novas ferramentas não estão aprovadas por esta decisão.

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

**Decisão do usuário:** incluir a criação de assets das ferramentas existentes na V0.0.5. Machados e picaretas já têm produção, estoque, equipamento e durabilidade; falta uma representação própria na interface.

**Escopo visual inicial proposto para cumprir a decisão:** dois ícones estáticos, A005-02 (machado) e A005-03 (picareta), de 32 × 32 pixels, PNG RGBA transparente. O documento de assets contém os briefs completos. A produção será feita pela outra IA; aqui registramos a encomenda, sem gerar imagens nem implementar.

**Integração prevista:** associar o machado ao recurso `axe` e a picareta a `pickaxe`, por caminhos `Assets/Items/Tools/axe.png` e `Assets/Items/Tools/pickaxe.png`. Usar os ícones junto aos nomes/quantidades na interface de estoque, encomendas da oficina e inspeção de ferramenta do habitante. Preservar nomes e informações textuais; não depender só de imagens. Reorganizar controles apenas no necessário para os ícones não alargarem a HUD além da tela.

**Regras preservadas:** receitas, durabilidade, produtividade, consumo e logística não mudam por adicionar arte. A ferramenta quebrada continua sendo um estado da simulação, não uma nova classe de recurso. Durabilidade continua exibida por texto/indicador dinâmico. Save/load mantém os mesmos IDs; os ícones não introduzem dados de partida.

**Contrato:** um quadro por arquivo, origem de coordenadas no canto superior esquerdo, centro de apresentação (16,16), margem transparente mínima de 2 pixels, filtro nearest, sem mipmaps, proporção preservada e apresentação nominal de 32 × 32 unidades lógicas. Não há colisão, ocupação no mapa ou ponto de interação.

**Ainda não incluído nesta especificação:** animação da ferramenta na mão dos três personagens, sprites de carga e versões visuais por desgaste. Se forem desejados, definir ações, quadros e alinhamentos em fichas próprias; os ícones não prometem resolver animação equipada.

**Aceite:** os dois arquivos devem ser reconhecíveis e distintos, compatíveis com a arte existente, entregues no formato/dimensões previstos e integrados ao recurso certo em todos os pontos definidos. Conferir leitura no tamanho de jogo e ausência de cortes, distorção ou fundo indevido. Situação atual: encomenda documentada; arquivos não produzidos.

## Ficha obrigatória de cada funcionalidade escolhida

Preencher antes da implementação dependente:

1. **ID e nome:** conservar o identificador nos dois documentos.
2. **Objetivo para o jogador:** problema resolvido e resultado esperado.
3. **Fluxo:** onde começa, comandos, respostas, estados e finalização.
4. **Regras:** custos, tempos, capacidades, requisitos, prioridades e efeitos.
5. **Exceções:** falta de recurso, rota bloqueada, cancelamento, morte, pausa e mudança de profissão, quando aplicáveis.
6. **Integração:** scripts/cenas afetados, navegação, logística, necessidades e interface.
7. **Persistência:** dados novos, comportamento de save/load e compatibilidade com partidas existentes.
8. **Contrato visual:** IDs de assets do documento par, ocupação em células, colisão, acesso, pivô e estados exigidos. Distinguir visual de área navegável.
9. **Critérios de aceite:** cenários verificáveis de comportamento, integração e apresentação.
10. **Estado:** proposta, definida, em implementação, em validação ou entregue; registrar decisões e pendências reais.

## Coordenação da implementação e da arte

- Mecânicas e parâmetros compartilhados são definidos aqui e repetidos com os mesmos valores na ficha de asset.
- A IA de assets recebe o par completo, não apenas uma descrição resumida.
- Um ID de asset deve apontar para uma ficha do documento par; nomes e caminhos previstos devem coincidir.
- Não consumir arte marcada como rascunho como se fosse aprovada para integração.
- Mudanças em dimensões, estados, quadros, pivôs ou nomes exigem atualizar o par e incrementar sua revisão compartilhada.
- Se houver placeholder, documentar seu ID, limitações e substituição. Não declarar uma funcionalidade visualmente concluída com placeholder sem registrar essa condição.

## Validação prevista

Definir testes conforme o escopo escolhido. Preservar regressões relevantes da V0.0.4, verificar os fluxos novos, save/load, recursos reservados e transportados, e interface nas resoluções suportadas. Conferir visualmente cada asset integrado em sua escala de jogo, inclusive seleção, profundidade e animação, quando aplicáveis.

## Registro de decisões

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
