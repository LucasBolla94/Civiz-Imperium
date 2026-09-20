# Civiz Imperium — Plano V0.0.6.1

- Revisão compartilhada: **18**.
- Par: [ASSETS_V0.0.6.1.md](ASSETS_V0.0.6.1.md).
- Estado: **implementado e em validação final; revisão humana da experiência pendente. Escopo da revisão 18 preservado**.
- V0.0.6 permanece separada e inalterada.

## 1. Autorizações e leitura deste documento

O usuário pediu uma proposta completa com valores de teste. Já aprovou: desbloqueio de ouro/fundição na base 3; investigação compartilhada com pedra mais comum e ouro mais raro; resultado fixo por local; mineração de ouro separada; fundição obrigatória consumindo madeira e minério, produzindo barras; controle central em Habitantes com atalhos nos prédios; porto único escolhido na costa; visitas a cada 5 minutos com janela de 2 minutos para confirmar negócios, estendendo a permanência para concluir entregas confirmadas; comércio manual de madeira, pedra e hortifruti; arte própria do ouro e saldo no topo. Também determinou que vender exige carregador, que busca no galpão e entrega ao barco a quantidade correta.

O usuário autorizou fechar o documento após receber a proposta e corrigir a espera do barco. Os números e detalhes operacionais abaixo compõem a especificação inicial de teste para esta entrega; não representam balanceamento final nem aprovações individuais anteriores. Este plano substitui as anotações exploratórias desta versão. Implementar somente este escopo, sem acrescentar novas mecânicas por conta própria. Organização interna de código pode mudar, mas o comportamento descrito deve permanecer coerente. Todos os tempos são de simulação e respeitam pausa/velocidade.

## 2. Experiência da partida

### Solicitação adicional do usuário — revisão 18

Entregar a versão pronta com melhoria de UX, organização de menus, barra superior, fontes e uma logo visual própria. IDs adicionais: UX-01 (hierarquia, barra superior e contexto), UX-02 (tipografia legível e foco de teclado), BRAND-01 (emblema e título editável). Integrar essas melhorias às telas de produção, equipes e comércio deste plano; não substituir nem reduzir a cadeia econômica. Contrato da logo no documento par. Pesquisa de acessibilidade: contraste de texto mínimo 4,5:1 em painéis sólidos, controles consistentes e detalhes apresentados no contexto, mantendo o mapa utilizável. Referências: [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/provide-high-contrast-between-text-ui-and-background/), [Xbox XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101), [visibilidade do estado](https://www.nngroup.com/articles/visibility-system-status/) e [divulgação progressiva](https://www.nngroup.com/articles/progressive-disclosure/).

A revisão 18 registra o pedido explícito de implementação e identidade visual feito após o fechamento da revisão 17. Os valores econômicos e os critérios de entrega abaixo continuam obrigatórios; testes parciais não significam versão concluída.

Base 3 → investigar terrenos → revelar ouro → abrir jazida e construir posto de mineração → extrair minério → fundir com madeira → guardar barras → construir porto → negociar com visitantes. A primeira barra não exige porto nem importação. O jogador decide equipes, construções e cada negócio; habitantes realizam coleta, produção e transporte sozinhos.

Não adicionar carvão, moedas, cunhagem, online, profissões temporárias automáticas ou ferramentas especiais nesta etapa. Reutilizar picareta existente para ouro; ferramenta de prospecção inicialmente mencionada fica substituída nesta proposta pela investigação existente, sem um novo item.

## 3. Valores iniciais de teste

| Elemento | Custo / quantidade | Tempo e limite |
|---|---|---|
| Investigar terreno | Sem material, como atualmente | 12 s de trabalho; área 3 × 3; mineiro de Pedra; manter depósito de pedra 2 necessário |
| Nova descoberta após base 3 | 75% pedra, 25% ouro, com proteção inicial abaixo | Pedra conserva reservas atuais; ouro 120/180/240 minérios, tamanhos equiprováveis |
| Abrir jazida de ouro revelada | 10 madeiras + 10 pedras | 15 s de trabalho de construtor |
| Posto de mineração de ouro | 25 madeiras + 20 pedras | 20 s de construção; terreno 3 × 3; até 3 mineiros; estoque de 100 minérios |
| Extração de ouro | 1 minério por ciclo, reduzindo a reserva em 1 | 6 s de trabalho base; viagem/descanso adicionais; até 2 postos de extração simultâneos por jazida |
| Fundição | 30 madeiras + 30 pedras | 25 s de construção; terreno 3 × 3; até 2 trabalhadores, uma bancada por trabalhador |
| Receita de uma barra | 5 minérios + 2 madeiras → 1 barra | 15 s de trabalho base por bancada; entradas até 30 minérios + 12 madeiras; saída até 20 barras |
| Porto | 40 madeiras + 30 pedras + 5 barras | 30 s de construção; um por ilha incluindo obra; área 5 × 5 detalhada abaixo |
| Primeira visita | 60 s após porto concluído e acessível | Depois, chegadas espaçadas em pelo menos 300 s; 120 s para confirmar negócios; espera entregas já confirmadas |
| Comerciante por visita | 60 madeiras, 60 pedras, 60 hortifruti à venda; orçamento de compra de 30 barras | Compra até 60 unidades de cada recurso do jogador |

Tempos são de trabalho efetivo, sem incluir busca/entrega de materiais. Preservar fome, descanso, experiência, ferramentas e carga existentes. Ouro usa durabilidade e penalidades de falta de picareta existentes para mineração; não acrescentar ferramenta exigida na fundição. Custos de prédios já existentes e ritmo de consumo de comida não mudam. Novos prédios não recebem níveis extras nesta versão.

### Proteção contra azar e repetição da investigação

Antes da base 3, descoberta continua sendo pedra. Depois, sortear apenas terrenos ainda não investigados; se as três primeiras descobertas novas forem pedra, a quarta revela ouro. Proteção usada uma vez por ilha para destravar a cadeia; depois vale 25%. Persistir resultado e sorteio por célula no início da investigação, contador da proteção e estado aleatório; cancelar/recarregar não rerrola. Uma área investigada não pode sobrepor células de outra descoberta para tentar obter novo resultado. Uma jazida esgotada nunca recupera reserva por liberar, reconstruir ou investigar novamente. Resultados antigos de pedra não são convertidos em ouro.

Preservar a possibilidade atual de liberar terreno investigado sem extrair; manter histórico subterrâneo por célula. Após esgotamento, retirar a marcação da jazida por ação Liberar terreno, sem custo nem rendimento, permitindo outros usos do solo sem recriar minério.

## 4. Prédios, equipes e logística de produção

O posto de mineração armazena minério e organiza mineiros de ouro. Após abrir uma jazida, trabalhadores do posto escolhem automaticamente a jazida acessível mais próxima, usando reserva de posto para evitar ocupação duplicada; não há raio artificial. Entregam carga no próprio posto. Sem jazida, ferramenta ou espaço, mostrar o motivo real e aplicar comportamento existente de ferramentas. Não trocar para pedra sozinho.

Carregadores levam minério e madeira de estoque livre à fundição. A fundição cria pedidos até os limites de entrada; insumos já reservados por outra tarefa não podem ser usados duas vezes. Cada bancada reserva receita completa e uma vaga de saída antes de começar; consome insumos ao iniciar, salva trabalho em andamento e entrega uma barra ao terminar. Sem trabalhador, suspende progresso; realocação permite retomada sem duplicar receita. Saída cheia impede novo lote. Carregadores escoam barras para galpão geral; o posto de mineração não aceita barras e a fundição não compra material magicamente do estoque global.

Galpões gerais aceitam minério e barras dentro da capacidade atual; base pode guardá-los conforme aceitação geral já existente. Exportação comercial é exclusivamente a partir de galpões gerais, conforme pedido do usuário. Se um material estiver só em depósito especializado/base, um pedido explícito de abastecimento comercial pode transferir material livre para um galpão geral acessível antes da confirmação; não confirmar venda de quantidade que ainda não está nele. Mostrar “Leve este material ao galpão para vender”, com ação para solicitar a transferência. Essa transferência não é venda e não paga ouro.

## 5. Habitantes: administração central

Uma tela central controla todas as funções. Linhas: Construção, Comida, Madeira, Pedra, Mineração de ouro, Fundição, Oficina e Transporte. Mostrar total de pessoas, livres, atribuídas, ativas e temporariamente indisponíveis. Descansar não altera a função atribuída.

Cada linha tem quantidade com +/−, capacidade de postos e resumo de impedimentos. + atribui uma pessoa livre a posto válido; − libera uma daquela atividade, preferindo sem carga. Se houver carga, terminar entrega segura e então mudar; mostrar “mudança pendente”. Nunca retirar pessoa de outra atividade sem ordem. Para transferir entre atividades, jogador reduz uma e aumenta outra, mantendo o fluxo familiar.

Expandir uma linha mostra prédios da atividade, equipes e acesso para ajustar a quantidade local. Ajustar no prédio ou no painel usa o mesmo estado; soma dos prédios coincide com o total da atividade, sem contar pessoas em trânsito duas vezes. Destino automático escolhe posto acessível com menor ocupação relativa, desempate por caminho. Postos lotados impedem adição e explicam. Capacidade de prédios antigos continua a regra atual; limites novos são os da tabela.

Se o posto for demolido, afetados tornam-se livres após finalizar entrega segura, sem migração automática de profissão. O porto não cria profissão própria: utiliza Transporte. Seleção individual não é necessária para operações comuns. O painel mostra “trabalhando”, “a caminho”, “descansando” ou “aguardando: motivo”. Não dizer “livre” para alguém apenas esperando insumo.

## 6. Porto e navegação

Escolher posição na costa e orientação em quatro direções, com rotação por R e botão visível no menu. Área lógica 5 × 5: faixa traseira de 5 × 2 em terra para acesso/armazenamento; faixa frontal de 5 × 3 em água para píer. Definir ponto de carga central no limite terra/píer e ponto de atracação na água em frente. Exigir terra acessível aos trabalhadores e rota aquática entre atracação e mar conectado à borda do mapa. Lago fechado não aceita porto.

Prévia mostra células válidas, inválidas, direção e impedimento. Reservar células do porto, atracação e corredor de aproximação; futuras construções/expansões não podem ocupá-los. Não quebrar expansão existente para viabilizar um porto. Quatro orientações têm máscaras rotacionadas consistentes, não apenas imagem virada.

Galpões podem ser escolhidos automaticamente por caminho; o porto mostra de onde virá cada carga. Área de recebimento do porto: 200 unidades totais, com capacidade reservada por transação. Carregadores retiram entradas para galpões automaticamente. Não é um depósito de exportação geral nem fonte de consumo da vila enquanto uma transação estiver pendente.

O barco chega fisicamente por água; pode usar navegação atual como base, sem substituir os barcos de imigração. Um comerciante por vez. Aos 120 s atracado, encerra a aceitação de novos negócios. Se houver negócios confirmados pendentes, permanece atracado até sua conclusão ou cancelamento; caso contrário, parte. Primeira tentativa de chegada 60 s após construção; se acesso inválido, aviso e tentar novamente a cada 30 s, sem acumular barcos. Após uma chegada real, próxima elegível em 300 s; nunca sobrepor barcos se o anterior ainda não saiu; se passar o intervalo durante a espera, não acumular visitas: depois da saída, reagendar uma chegada para 300 s adiante. Viagem fora da área visível não gera mercadorias antecipadas.

## 7. Ofertas e preços de teste

Negociar em lotes de 10 unidades para manter barras inteiras e eliminar arredondamento escondido. Interface mostra quantidade real (10, 20, 30...), não apenas “1 lote”.

| Material | Jogador VENDE 10 unidades e recebe | Jogador COMPRA 10 unidades pagando |
|---|---|---|
| Madeira | 1 barra | 2 barras |
| Pedra | 2 barras | 3 barras |
| Hortifruti | 1 barra | 2 barras |

Estoque/ofertas e orçamento são novos por visita; não persistem para o próximo comerciante. Limites de 60 por material e 30 barras são compartilhados entre todos os pedidos daquela visita e reservados na confirmação. Não aumentar orçamento de compra ao receber ouro de compras do jogador, nem revender na mesma visita material comprado dele. Isso evita circuito ilimitado. Ordens aceitam quantidades limitadas pelo saldo, ofertas, orçamento, espaço e reservas efetivamente disponíveis.

Para hortifruti, exportar somente excedente acima da reserva alimentar atual de 3 unidades por habitante, além de reservas de tarefas. Revalidar antes de retirar cada carga; se um novo habitante ou consumo reduzir margem, suspender e explicar, não tomar comida já reservada. Política mantém consumo normal enquanto transporte está em curso.

## 8. Transação física e conservação

### Confirmação

Com barco atracado e pelo menos um carregador vivo atribuído a Transporte com rota possível, selecionar compra/venda, quantidade em múltiplos de 10 e total em barras. Se todos descansam ou estão ocupados, permitir enfileirar com aviso de espera e prazo; sem nenhum carregador, bloquear confirmação e oferecer atalho para Habitantes. Confirmar uma vez cria ordem com identidade estável, reservas de origem, oferta/orçamento, saída e destino. Não altera riqueza nem conclui troca.

Ordens executadas em ordem de confirmação; cada uma concluída antes de começar transporte da próxima, evitando várias entregas pela metade. Necessidades urgentes de sobrevivência mantêm prioridade sobre comércio. Capacidade de carga e duração das viagens continuam as existentes: uma venda de 20 unidades exige tantas viagens quanto necessário, nunca uma carga ilimitada.

### Venda — galpão até barco

1. Reservar exatamente o material livre em galpão(s) geral(is), e as barras correspondentes do comerciante. Reservar espaço de chegada do ouro no porto e galpão(s) de destino.
2. Carregadores buscam as unidades reservadas nos galpões e levam ao ponto de carga do barco, mostrando progresso entregue/total. Material entregue fica em custódia, ainda propriedade do jogador até concluir a ordem; não pode ser consumido nem vendido novamente.
3. Somente quando a quantidade inteira chega, concluir a troca uma única vez: material passa ao comerciante, barras passam para o recebimento do porto. Carregadores levam as barras do porto ao galpão. A etapa curta de descarga no mesmo ponto de atracação não permite pular viagens galpão↔barco.
4. Saldo disponível no topo inclui apenas barras já guardadas em estoque utilizável, não pagamento prometido ou carga em trânsito. Mostrar valores em trânsito separadamente no detalhamento.

### Compra — ouro até barco, material até galpão

1. Reservar barras livres de galpão(s) geral(is), estoque do barco e espaço no recebimento e galpão de destino. Ouro ainda na fundição/base precisa chegar ao galpão primeiro, como outros itens de exportação.
2. Carregadores levam o pagamento ao barco. Até chegar todo o ouro, ele fica em custódia do jogador, e a mercadoria continua reservada no barco.
3. Ao entregar todas as barras, concluir uma única vez: ouro do comerciante, mercadoria do jogador no recebimento do porto. Carregadores levam a quantidade exata ao galpão. A compra pode ser descarregada após o barco partir porque a carga já pertence ao jogador e está em terra.

Não permitir saldo negativo, duplicar carga, reservar mais capacidade do que existe, somar itens em custódia ao estoque livre ou concluir negócio por simples clique. Cada unidade deve estar em exatamente um lugar e com um proprietário. Usar reservas/logística existentes com extensão explícita, não dois inventários incompatíveis.

## 9. Cancelamento, partida do barco e falhas

- Antes da liquidação integral, Cancelar negócio interrompe novas retiradas e libera reservas não utilizadas. Cargas em viagem voltam a um galpão válido; custódia junto ao barco volta ao recebimento do porto, depois ao galpão. Nenhum ouro é ganho e nada é perdido por cancelamento. Após encerrar o prazo de novos negócios, o barco pode partir assim que não houver mais transações pendentes; a carga devolvida em terra continua a ser recolhida.
- **Correção aprovada pelo usuário:** os 120 s são prazo para confirmar a venda, não para terminar o transporte. Venda confirmada dentro do prazo mantém o barco esperando até a entrega integral e pagamento; não cancelar por tempo esgotado. Encerrado o prazo, impedir novos negócios e alterações que aumentem os pedidos. Sem pedidos pendentes, partir. Mostrar aviso a 30 s e, depois do prazo, estado “Aguardando entregas”, sem contagem negativa. Processar fechamento antes de confirmações com horário igual ou posterior ao limite. Aplicar a mesma regra às compras confirmadas para manter comportamento consistente: o prazo fecha novas negociações, mas não cancela as já aceitas.
- Se origem/destino perde acesso ou trabalhador descansa, pausar e mostrar motivo; tempo da visita continua. Se todos saem de Transporte, fila confirmada aguarda até voltar alguém ou o jogador cancelar; não expira pelo prazo da visita. O barco espera, com motivo visível e opção de cancelar, sem contratar pessoas ou consumir recursos automaticamente. Não atribuir trabalhador automaticamente.
- Morte preserva carga em pilha e transfere corretamente a reserva conforme sistema existente; rota inacessível não apaga carga. Pilhas originadas de devoluções não continuam comprometidas com barco já ausente.
- Cancelar/devolver reserva primeiro em demolição de galpão; mercadorias existentes ficam no chão conforme regra geral, e comércio afetado cancela se não puder ser atendido por outra origem livre. Não resgatar material consumido por outra tarefa para honrar venda.
- Porto permite demolição pelas regras atuais de construtor, dez segundos, cancelável antes do primeiro golpe. Enquanto houver visitante ou transação/carga vinculada, pedido aguarda; interromper novas negociações e visitas, cancelar negócios incompletos, devolver cargas. Prosseguir quando tudo estiver em terra e sem carregador dependente do cais. Estoque restante vira pilha acessível em terra; não apagar cargas na água. Só após remoção libera outro porto.
- Posto/fundição usam demolição existente. Batches iniciados perdem insumos já consumidos; cancelar obra usa regras atuais; inventário não consumido fica no chão. Galpão cheio impede novo pedido de comércio, sem expulsar estoque para abrir vaga.

## 10. Clareza visual, recursos e arte

Barra superior: barras de ouro disponíveis, ícone GOLD-02; detalhe armazenado/reservado/em trânsito, sem somar minério. Estoques, fundição e painel de produção mostram minério como recurso separado. Rótulos em inglês principal e português: Gold ore / Minério de ouro; Gold bars / Barras de ouro; Gold mining / Mineração de ouro; Smelter / Fundição; Trading port / Porto comercial.

Porto: abas Comprar e Vender, estoque e orçamento do barco, quantidade, preço total, tempo restante, origem/destino e fila com progresso. Mensagens específicas: sem carregador, material no depósito errado, estoque reservado, falta de espaço, caminho bloqueado ou visita encerrada. Abrir Habitantes por atalho sem confirmar negociação automaticamente.

Prédios: mostrar requisitos/desbloqueio, custo, equipe, estoque, receita e motivo de espera. Animação do forno só durante produção, brilho da jazida legível sem excesso. Não gerar alertas por unidade transportada. Dar confirmação visual discreta na liquidação de negócio, não na mera criação da ordem.

Arte vinculada: GOLD-01 minério; GOLD-02 barra; GOLD-03 jazida; GOLD-04 posto de mineração; GOLD-05 fundição; GOLD-06 porto. Foram inspecionadas folhas existentes de minerais, objetos de mina, Furnace.png e Wood Boat.png; ver documento par para adaptações e especificações. Reutilizar o barco existente, sem encomendar substituto por padrão. Sprites dos habitantes e ferramentas existentes atendem as funções novas; não é necessária roupa nova.

## 11. Persistência e integração

Integrar sobre o estado real do projeto e os cinco saves da V0.0.6. Persistir por ilha: recursos, prédios, alocações, jazidas e reservas, resultados de investigação e proteção inicial, lotes em processamento, contador de visita, barco/ofertas, fila de negócios, proprietário/localização de cargas e estágio de liquidação. Ao carregar, reconstruir reservas a partir de entidades estáveis e reconciliar ordens, sem pagar duas vezes ou rerrolar visita. Não avançar comércio pelo tempo real fora do jogo.

Saves antigos recebem estoque de ouro/minério zero, nenhum novo prédio, nenhuma visita até construir porto e proteção inicial ainda não usada; conservar pedra já descoberta e demais sistemas. Informações inválidas de ordem devem cancelar preservando bens do jogador, não fabricar pagamento. Identidades de ilhas não dependem de nome.

Reutilizar o ciclo de ferramentas, fome/energia, navegação, jobs e reservas; evitar mudanças paralelas no balanceamento antigo. Configurar números desta proposta em uma fonte central para ajuste posterior. O desenho de sprites respeita máscaras de ocupação e pontos de carga descritos, sem usar tamanho da imagem como colisão automática.

## 12. Critérios de entrega e testes

1. Demonstrar partida de teste chegando da base 3 à primeira venda com ouro minerado/fundido, sem comandos que criem recursos durante a demonstração. Fixtures automatizadas podem preparar casos isolados.
2. Testar ouro bloqueado antes do nível, investigação repetida/cancelada/sobreposta, save/load e quarta descoberta garantida; esgotar jazida sem regeneração por reconstrução.
3. Verificar receita exata, dois trabalhadores/bancadas sem duplicação, falta de cada insumo, saída cheia, ferramenta e descanso; realocação e demolição no meio de lote.
4. Habitantes e prédio sempre exibem a mesma equipe; alterações com carga em trânsito, múltiplos postos, lotação e ausência de livres.
5. Validar quatro orientações do porto, costa irregular, lago fechado, caminho terrestre, bloqueio de expansão no cais, limite durante obra e demolição/reconstrução.
6. Confirmar primeira visita, periodicidade, orçamento/estoque por visita, aviso e pausa. Testar ausência de carregador, carregador ocupado e viagem que ultrapassa o prazo mantendo o barco presente; partida sem pedidos e impossibilidade de criar novos pedidos após o prazo.
7. Venda/compra de vários lotes: conservar cada material e barra em estoque, reserva, pessoa, custódia, barco e recebimento; entregar exatamente o total e liquidar uma vez.
8. Testar clique duplo, cancelar antes/depois de carga parcial, fechamento no instante da confirmação e entrega após o prazo, morte, bloqueio de caminho, galpão demolido/cheio e reserva alimentar.
9. Salvar/carregar em cada etapa, inclusive imediatamente antes/depois de liquidação e durante devolução. Confirmar que cinco ilhas não compartilham ouro, barcos ou ofertas.
10. Revisar ícones, sprites, camadas, escala, tradução e painel em resoluções suportadas; ouvir/ver avisos sem spam. Fazer sessão humana para avaliar entendimento e duração dos trajetos. Ajustes de valores devem ser relatados, não ocultos.

Relatar o que foi realmente implementado/testado e quaisquer falhas restantes. O planejamento está fechado e seus valores iniciais estão definidos, mas isso não é evidência de testes nem garantia de ausência de bugs. Implementação, produção de arte e validação ainda serão realizadas; alterações de escopo devem voltar à revisão do usuário.

## Revisão 16 — correção do prazo comercial

O usuário determinou que venda confirmada faz o barco esperar a entrega. O prazo só limita quando o jogador pode negociar. Essa decisão substitui a proposta anterior de cancelar entregas incompletas ao terminar os dois minutos. Pagamento permanece após entrega integral, sem duplicação. Persistir também o estado de espera após o prazo em save/load.


## Fechamento — revisão 17

Documentos sincronizados e prontos para entrega. Conferida a substituição da regra antiga de expiração: negócios confirmados aguardam transporte; prazo encerrado impede novos negócios. Nenhuma alteração no código do jogo, imagem gerada ou teste de gameplay foi realizada neste fechamento. V0.0.6 e V0.0.5.1 não foram modificadas. Valores de teste permanecem centralizados e ajustáveis; não há nova pergunta obrigatória de design para iniciar o escopo descrito.
