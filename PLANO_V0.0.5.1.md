# Civiz Imperium — Plano V0.0.5.1

- Versão alvo: **0.0.5.1**, escolhida pelo usuário para este pacote.
- Revisão compartilhada: **12**.
- Par: [ASSETS_V0.0.5.1.md](ASSETS_V0.0.5.1.md).
- Base: V0.0.5 entregue.
- Estado: **planejamento encerrado pelo usuário; escopo aprovado abaixo fechado para entrega à IA implementadora; jogo não alterado nesta etapa**.

## Escopo fechado — referência principal para implementação

Esta seção prevalece sobre propostas e sequências exploratórias abaixo. Encerrar o planejamento não aprova o pacote inteiro. Implementar somente:

1. Exigir depósito de comida nível 2 para criar novas hortas, preservando coleta, plantio e renovação de árvores.
2. Avisos nos prédios com o motivo real do impedimento e acesso ao menu pertinente: falta de trabalhador leva a Habitantes; depósito cheio informa falta de espaço. Não sugerir contratar/alocar mais gente quando isso não resolve o impedimento.
3. Mostrar o benefício concreto do próximo nível antes de gastar, em inglês e português; usar valores atuais e futuros reais quando houver alteração numérica. Não anunciar benefícios ainda propostos.
4. Preservar alocação escolhida em Habitantes, execução automática dentro de cada atividade, metas opcionais existentes e funcionamento atual de encomendas/metas da oficina. Não criar troca automática de profissão nem controles adicionais de mínimos.

5. Adicionar a ação manual “Cortar agora” na árvore com frutas, permitindo obter madeira sem colher primeiro todo o alimento. O trabalhador de madeira executa o corte; as frutas restantes são perdidas. Ver contrato abaixo.

6. Na ferramenta de expansão, permitir segurar Shift e arrastar com o botão de colocação pressionado para marcar expansões sucessivas ao longo do percurso do mouse, contornando o terreno, sem clicar novamente em cada posição.

Não alterar custos. Não incluir novos bônus, teto de prédio ligado à vila, novos requisitos de evolução, mudanças na coleta costeira, políticas logísticas, novos sistemas do nível 3, comércio ou famílias. Essas ideias ficam no registro de propostas para outra discussão, fora desta entrega. Não há lista adicional de correções de bugs reproduzidos aprovada neste fechamento.

Reutilizar assets existentes; o arquivo de assets permanece sem encomendas novas. Inspecionar os balões existentes antes de usar. Detalhes de apresentação podem ser resolvidos sem inventar regras de gameplay. Se surgir decisão de gameplay indispensável não definida, consultar o usuário; **migração aprovada:** hortas já existentes em partidas antigas continuam funcionando normalmente, mesmo com depósito de comida nível 1. Exigir nível 2 somente para criar novas hortas; preservar as existentes e seu funcionamento, incluindo plantio, colheita e replantio. O usuário esclareceu que as partidas atuais são de teste, mas aprovou essa preservação. Não apagar ou invalidar patrimônio automaticamente.

Validação desta entrega: bloquear criação de horta no nível 1 tanto na interface quanto na ação; permitir no nível 2; verificar avisos com motivos reais e atalhos corretos; conferir benefícios exibidos contra as regras do jogo; manter alocações e automação existentes; verificar traduções e compatibilidade de saves conforme decisão específica. O fechamento do documento não representa implementação nem testes executados.

## Adendo aprovado — cortar árvore com frutas

O usuário acrescentou esta mudança ao escopo fechado da V0.0.5.1. A V0.0.6 permanece intacta.

- Ao selecionar uma árvore em produção, oferecer “Cortar agora” (inglês: “Cut down now”). Explicar junto da ação que as frutas restantes serão perdidas, idealmente mostrando a quantidade real.
- A ordem autoriza o trabalhador de madeira a cortar aquela árvore sem esperar esgotar as frutas. Não entrega madeira instantaneamente: manter trabalho físico, ferramentas, transporte e regras existentes de corte aplicáveis.
- Frutas restantes na árvore são perdidas, não convertidas em madeira nem transferidas ao estoque. Frutas já recolhidas permanecem preservadas.
- Somente a árvore explicitamente marcada recebe a exceção. As outras mantêm o ciclo normal: produzir frutas e depois servir para madeira. Não permitir que trabalhadores decidam sacrificar árvores frutíferas por conta própria.
- Não alterar automaticamente profissões nem criar novos custos, rendimentos, bônus ou tempos de corte. A aprovação cobre árvores com frutas; não define novos rendimentos de madeira para mudas ou árvores em crescimento.
- Integrar a ordem com as reservas de coleta para impedir colher e cortar simultaneamente ou duplicar recursos; preservar cargas já recolhidas e o estado da ordem em salvamento/carregamento. **Aprovado:** permitir cancelar a ordem até antes da primeira machadada, preservando as frutas ainda presentes. Na primeira machadada, perder as frutas restantes e tornar a ordem irreversível; não permitir cancelar depois que o trabalho de corte começou. Marcar a ordem não perde frutas por si só. Impedir novas coletas concorrentes na árvore marcada, preservando cargas já recolhidas; cancelar antes do início restabelece a coleta normal.
- Para voltar a produzir frutas naquele local após iniciar o corte, concluir a retirada da árvore e liberar o local conforme as regras existentes, depois plantar uma árvore nova, respeitando custo e crescimento existentes. Não restaurar a árvore cortada ao desativar uma opção. A ordem manual vale somente para a árvore escolhida; não é um modo permanente de cortar automaticamente as próximas árvores. Preservar a renovação de pomar existente quando habilitada, sem plantar duplicado.
- Reutilizar a apresentação e os recursos visuais existentes de árvore/corte; nenhuma encomenda de asset novo foi aprovada para este adendo.

Verificação necessária na implementação: árvore com frutas aceita a ordem; trabalhador de madeira realiza o corte; alimento restante não entra no estoque; alimento já coletado não desaparece; outras árvores continuam normais; reservas concorrentes e salvamento não duplicam alimento/madeira. Verificar também falta de trabalhador, ferramenta e acesso. Estes testes ainda não foram executados.

## Adendo aprovado — expansão com Shift e arraste

Com a ferramenta de expansão selecionada, segurar Shift e arrastar o mouse com o botão de colocação pressionado deve marcar expansões sucessivas ao longo do trajeto. O objetivo é acompanhar o contorno do terreno sem repetir cliques ou selecionar a ferramenta novamente. Trata-se de expansão ao longo do percurso, não de preencher automaticamente toda a área interna de um contorno fechado.

- Reutilizar tamanho de expansão e regras existentes de custo, recursos disponíveis, reservas, terreno e acesso. A interação não concede terreno gratuito nem ignora restrições.
- Não cobrar ou enfileirar novamente a mesma área ao passar sobre ela mais de uma vez. Mostrar prévia clara de posições válidas e impedidas; não criar ordens ao arrastar sobre a interface.
- Soltar o botão encerra o arraste; não continuar criando expansões apenas por mover o cursor. Preservar colocação simples e repetição existentes fora do gesto.
- Enfileirar as ordens válidas; a execução física continua seguindo o sistema atual, sem conclusão instantânea.
- Não aprovar implicitamente expansão remota ou dependências entre áreas ainda não construídas. Se acompanhar o contorno exigir mudar essas regras, consultar o usuário antes de ampliar a mecânica.
- Validar percurso contínuo, retorno sobre área já marcada, recursos insuficientes, posições inválidas, passagem sobre menus e término do gesto. Nenhum teste foi executado nesta etapa documental.

## Destino das próximas alterações

O usuário confirmou que **V0.0.5.1 reunirá as novas atualizações e correções**. A V0.0.5 permanece como referência da entrega anterior. Registrar aqui as novas decisões e os defeitos confirmados; o documento par recebe somente encomendas de arte necessárias. A inclusão da versão não aprova automaticamente todas as sugestões de progressão.

Para cada correção, registrar comportamento observado, resultado esperado, reprodução quando disponível e verificação da solução. Não rotular uma mudança de design como bug para executá-la sem decisão. Não há, nesta revisão, uma lista adicional de bugs reproduzidos: as constatações de progressão abaixo são análise de design, e os novos problemas serão acrescentados conforme forem identificados.

## Limites e decisões confirmadas

O usuário pediu um pacote conjunto para todos os prédios, buscando uma partida interessante por mais tempo, com trabalhadores autônomos e jogador administrador. Não alterar custos nesta discussão. Novas ideias devem ser aprovadas antes de virar regras de implementação. Escolhas internas de programação não autorizam inventar preços, bônus ou requisitos de evolução.

**Aprovado:** depósito de comida nível 1 organiza a coleta de árvores; nível 2 libera criar hortas. Preservar plantio e renovação das árvores. A versão atual permite horta já no primeiro nível: esse comportamento será alterado somente quando a nova regra for implementada.

**Direção desejada:** níveis liberam atividades; aperfeiçoamentos dentro dos níveis melhoram seu funcionamento. O usuário citou coleta mais rápida e melhoria do cultivo como exemplos, sem aprovar valores ou efeitos exatos.

**Princípio aprovado para os prédios:** manter a execução autônoma desde o início e usar evoluções para liberar opções de organização que reduzam ordens repetidas. O exemplo aceito foi a oficina: no nível 1, o jogador encomenda uma quantidade e os trabalhadores fabricam; no nível 2, define um estoque desejado e a oficina repõe automaticamente conforme houver recursos e capacidade. Cinco machados foi apenas um exemplo, não uma meta obrigatória. Preservar esse comportamento já existente da oficina. A aprovação desta lógica não aprova automaticamente os benefícios específicos dos demais prédios, bônus numéricos, nem a vinculação dos níveis dos prédios ao nível da vila.

**Proposto, ainda a confirmar:** o nível da vila determina o nível máximo dos prédios. O usuário considerou boa a ideia, mas pediu decidir o que cada melhoria oferece.

**Decisão vigente — alocação manual em Habitantes:** cada trabalhador permanece na atividade escolhida pelo jogador. Não implementar ajuda temporária, troca automática entre profissões nem um segundo controle de mínimos. Esta decisão substitui expressamente a aprovação anterior de ajuda automática, após esclarecimento do funcionamento. Preservar execução automática das tarefas dentro da atividade e as metas opcionais existentes; não bloquear essas metas atrás de nova evolução.

**Aprovado — avisos úteis nos prédios:** mostrar o motivo real de uma parada, por exemplo falta de trabalhador, ferramenta ou espaço; evitar um pedido genérico de ajuda quando mais trabalhadores não resolveriam. Um balão discreto abre, ao clicar, o motivo e um atalho para o menu pertinente; o jogador continua decidindo a alocação. Exemplos aprovados: oficina com materiais e sem trabalhador mostra “Falta trabalhador”, com atalho para Habitantes; armazenamento sem espaço mostra “Depósito cheio”, sem sugerir mais trabalhadores como solução. Os avisos informam e não alteram alocações. Como proposta de apresentação, agrupar avisos e removê-los quando resolvidos, sem exigir dispensar mensagens repetidas; detalhes visuais e prioridade entre avisos ainda serão refinados. Existe o arquivo Assets/UI/speech bubble, emojis, reaction.png; inspecionar seus quadros antes de especificar reutilização ou arte nova.

Não mudar o executável, nem declarar a V0.0.5.1 entregue durante o planejamento. Esta proposta sucede as notas de progressão registradas provisoriamente nas revisões 38–40 do plano V0.0.5.

## Objetivo de experiência

Uma melhoria permite crescer, mas revela outra decisão: mais alimento permite mais habitantes; mais habitantes precisam de casas, ferramentas e transporte; maior território aumenta distâncias. O jogador planeja essa organização. Os habitantes executam as tarefas sozinhos.

Não prolongar a partida apenas com esperas, custos maiores ou bônus infinitos. Preservar automação básica, renovação de pomares, replantio opcional, prioridades e transporte físico. Não obrigar o jogador a clicar repetidamente para manter a vila funcionando.

## Diagnóstico da versão atual

- Vila nível 2 libera transportadores e carga de 7, em vez de 5. Não foi identificado benefício funcional novo no nível 3.
- Melhorias dos prédios independem do nível da vila; os seis tipos construíveis estão disponíveis inicialmente, sujeitos a recursos e terreno.
- Casa: vagas 4/6/8. Depósitos: capacidade 200/300/400. Vários avanços só aumentam espaço.
- Oficina: encomendas no nível 1, metas no 2, reserva por profissões no 3. Pedra nível 2 libera investigação e pedreira. Esses são exemplos de progressão funcional já existente.
- Melhorias não mudam a aparência do prédio. O benefício nem sempre aparece claramente antes da compra.
- Coleta costeira dá alimento instantâneo; destoa da coleta física. Não retirar essa recuperação sem testar o começo da partida.

## Estrutura proposta

| Vila | Experiência | Desbloqueios propostos |
|---|---|---|
| 1 — Fundação | Alimentar, abrigar, coletar e manter ferramentas | Prédios nível 1 e aperfeiçoamentos simples; renovação básica preservada |
| 2 — Desenvolvimento | Separar produção de transporte e sustentar crescimento | Autoriza prédios nível 2, transportadores; horta via depósito de comida 2; pedreira via depósito de pedra 2; metas via oficina 2 |
| 3 — Organização | Coordenar vários locais de trabalho sem microgerenciar pessoas | Autoriza prédios nível 3; políticas opcionais para estoques e preparação de novas áreas, preservando alocação manual |

Evoluir a vila autoriza a melhoria, não melhora todos os prédios automaticamente. Cada prédio ainda recebe materiais e trabalho. Não exigir comprar todos os aperfeiçoamentos para avançar.

Proposta de requisitos funcionais, ainda não aprovada: demonstrar moradia, alimentação e oficina funcionando para passar ao nível 2; demonstrar agricultura, mineração e transporte para o 3. Não esconder requisitos nem exigir fabricar coisas inúteis. Exibir uma lista clara antes de bloquear a evolução. Manter os custos existentes enquanto esses requisitos são discutidos.

## Matriz completa de melhorias propostas

Estão aprovados a horta no depósito de comida 2 e o princípio de organização progressiva, exemplificado pelas encomendas da oficina 1 e metas da oficina 2 já existentes. Os demais benefícios da tabela continuam propostas, inclusive velocidade de fabricação, prioridade automática e mudanças na reserva por profissão.

| Área | Nível 1 | Nível 2 | Nível 3 |
|---|---|---|---|
| Base | Diagnóstico de necessidades e próximos desbloqueios | Visão de produção/consumo e transporte liberado | Benefício a definir; excluída redistribuição automática de trabalhadores |
| Casa | Aperfeiçoamento de conforto reduz trabalho de descanso, sem criar energia instantânea | Realocação opcional para aproximar residência e emprego, reservando vaga antes da mudança | Descanso normal escalonado para evitar toda uma equipe parar junta; fome/exaustão continuam prioritárias |
| Comida | Coleta eficiente reduz tempo de colher árvores, mantendo 50 unidades por árvore | Libera horta; Cultivo preparado reduz trabalho de plantio, sem alterar automaticamente 60s de crescimento ou 15 unidades | Plantio escalonado entre canteiros para espalhar colheitas; manter replantio simples como opção |
| Madeira | Corte eficiente reduz trabalho de corte, sem corte automático de árvore com alimento; respeitar a exceção manual aprovada “Cortar agora” | Reserva configurável para abastecer obras, distinguida de material já reservado por tarefas | Renovação coordenada de lotes entre comida e madeira, mantendo o ciclo de frutas salvo ordem manual “Cortar agora” |
| Pedra | Extração eficiente reduz tempo por unidade; não aumenta a jazida | Investigar/abrir pedreiras existentes, mostrando reserva e acesso | Preparar o próximo local autorizado pelo jogador quando a reserva ativa baixar; não investigar o mapa inteiro sozinho |
| Oficina | Bancada organizada reduz trabalho de fabricação; mesmas receitas | Metas existentes com prioridade para ferramentas em falta | Reserva por profissões existente complementada por demanda e desgaste, com limite do jogador |
| Depósito geral | Organização do espaço como aperfeiçoamento local de capacidade | Mínimo/máximo por recurso no depósito | Transferências entre depósitos para abastecer áreas de produção; evitar transporte de ida e volta sem utilidade |
| Construção e território | Prioridades e materiais pendentes claros | Ordem de obras configurável, executada automaticamente | Plano de expansões dependentes: só executar próximo bloco quando o anterior permitir acesso |

Casas e estoques mantêm os aumentos de capacidade existentes. Hortas continuam unidades de 2 × 2 sem níveis próprios; melhorias alimentares são organizadas pelo depósito responsável. Não inventar novo prédio para cada menu ou política.

## Como funcionariam os aperfeiçoamentos

- Proposta inicial: um aperfeiçoamento por nível por instância do prédio, aplicado uma vez. Forma de aquisição e custo ainda não definidos.
- Efeito pequeno e específico: melhorar trabalho, capacidade ou organização, sem combinar silenciosamente velocidade, rendimento e crescimento.
- Percentuais ainda a testar e aprovar; não há bônus numérico fechado neste plano.
- Bônus produtivo pertence ao local de trabalho; conforto à residência; capacidade ao depósito. Não empilhar por proximidade nem por construir cópias.
- Preservar experiência individual e definir teto/composição de bônus antes de balancear. Mostrar efeito final e benefício do próximo nível.
- Políticas avançadas são opcionais: desligá-las preserva operação manual atual, sem apagar pessoas, recursos ou tarefas.

## Desafio e decisões de administração

O desafio vem de pessoas, espaço e deslocamento: investir na produção atual ou abrir outro núcleo; guardar madeira para obras ou abastecer oficina; alocar transporte ou mais coletores. Melhorar velocidade não resolve depósito cheio, fonte distante ou falta de ferramenta.

Adicionar diagnóstico compreensível: produção e consumo recentes, saldo disponível/reservado, espaço, gente trabalhando/descansando/aguardando e motivo de espera. Estimativas precisam indicar quando ainda não há histórico suficiente.

As alocações de Habitantes só mudam por decisão do jogador. Avisos e políticas de estoque não podem transferir trabalhadores entre atividades. Preservar cargas, reservas, fome e descanso ao executar as alterações manuais existentes.

Não acrescentar desastres, desgaste obrigatório de prédios ou doenças para fabricar dificuldade. Não bloquear inteligência básica de rotas e reservas atrás de upgrades.

## Revisão de opções e apresentação

- **Coleta costeira:** estudar tarefa física de recuperação em vez de recompensa instantânea; rendimento baixo, trabalhador e acesso à costa. Gatilho e profissão ainda não escolhidos. Preservar saída para crise alimentar até validar a substituição.
- **Aprovado — explicar melhorias antes de gastar:** ao selecionar um prédio, apresentar claramente o benefício do próximo nível junto da ação de melhorar, antes de confirmar o gasto. Usar linguagem curta, concreta e acessível, com o nome da função liberada. Exemplo aprovado: “Nível 2: libera hortas”. Evitar descrições vagas como “produção melhorada”. Se o benefício for uma mudança numérica já definida, mostrar o valor atual e o próximo; não inventar bônus para preencher a interface. Exibir somente benefícios realmente definidos para aquele nível, nunca propostas futuras como se fossem entregues. Manter inglês como idioma principal e português disponível. Essa aprovação é da clareza da apresentação, não das melhorias ainda em discussão. Como refinamento proposto, apresentar também requisitos, custo e duração de forma legível, explicando impedimentos sem alterar os custos existentes.
- **Menus:** produção primeiro, administração agrupada e demolição separada. Ações bloqueadas explicam o prédio/nível necessário.
- **Metas:** distinguir limite de produção, reserva de tarefa e estoque mínimo configurável.
- **Moradores:** manter inspeção e despertar; explicar que acordar não restaura energia.
- **Salvar:** acesso por menu geral, preservando os meios existentes.

## Feedback visual e sonoro — propostas

Pequena mudança visual por nível, sinal discreto de obra concluída, transporte legível, bancada trabalhando, aviso de falta de ferramenta e resumo opcional de acontecimentos. Evitar spam por entrega e efeitos que precisam de clique para conceder recursos.

Reutilizar o pacote de assets antes de gerar. Não encomendar variantes, ícones ou sons ainda: escolher os efeitos e seus estados antes de especificar entregas no documento par. Arte de horta e ferramentas já existente não deve ser refeita sem necessidade.

## Ritmo e longevidade

Marcos propostos: alimentar e abrigar → sustentar produção contínua → coordenar vários locais. Objetivos opcionais medem resultados de administração, não cliques ou espera obrigatória.

Não é possível garantir muitas horas interessantes apenas com três níveis das cadeias atuais. Esta proposta melhora a base; animais, peixe, cozinha, comércio, famílias e exploração continuam possibilidades futuras, não inclusão automática. Avaliar duração em partidas humanas e só ampliar conteúdo onde houver decisões novas.

## Sequência exploratória do pacote futuro — fora do escopo fechado

1. Fechar matriz de benefícios e requisitos; confirmar ligação entre vila e prédios.
2. Regras de desbloqueio, apresentação dos benefícios e função efetiva do terceiro nível.
3. Aperfeiçoamentos locais e integração de experiência, sem bônus duplicados.
4. Políticas produtivas por prédio e estoques; depois políticas globais de trabalho e expansão dependente.
5. Feedback escolhido, traduções, compatibilidade e testes integrados.

Esta sequência não é autorização de execução. Não alterar o jogo durante a discussão. Custos dos novos aperfeiçoamentos, requisitos finais, percentuais, alcance por depósito e tratamento de saves são decisões de gameplay pendentes, não licença para inventar.

## Validação exploratória do pacote futuro

- Conferir bloqueios no menu e no controlador, sem evolução automática dos prédios.
- Definir compatibilidade de partidas com prédios já acima do novo teto; propor preservar existentes, sem demolir patrimônio por migração.
- Testar pouca comida, estoque cheio, falta de ferramenta, morte, caminhos bloqueados, demolição de locais de trabalho e carga em trânsito.
- Medir conservação de itens, produtividade, viagem, espera e trocas de atividade. Verificar trabalho físico e ausência de reservas duplicadas.
- Testar políticas ligadas/desligadas e save/load em cada estado; instruções e mensagens em inglês/português.
- Fazer testes humanos curtos e prolongados: clareza do próximo objetivo, escolhas diferentes, períodos de espera sem decisão e repetição de cliques. Testes automatizados não provam diversão.

## Referências de design

[Factorio — Research and Technology](https://www.factorio.com/blog/post/fff-376) discute automação para reduzir tarefas repetidas e progressão ligada a experiências práticas. [Against the Storm — Warehouse, wiki oficial](https://wiki.hoodedhorse.com/Against_the_Storm/Warehouse) descreve a importância da localização dos estoques no transporte. A adaptação para Civiz é uma proposta própria: liberar organização sem eliminar decisões de espaço e abastecimento. Não são provas de retenção para este jogo.

## Histórico

| Revisão | Registro |
|---|---|
| 01 | Usuário definiu V0.0.5.1 para o pacote completo de progressão. Separado da versão entregue; incluídos diagnóstico, proposta de todos os prédios, automação, feedback e testes. Horta no depósito de comida 2 permanece a aprovação específica; restante em discussão. |
| 02 | Usuário confirmou V0.0.5.1 como destino das novas atualizações e correções. Mantida distinção entre decisões aprovadas, propostas e bugs confirmados. |



| 08 | Planejamento encerrado por pedido do usuário. Consolidado escopo aprovado; propostas não decididas explicitamente excluídas da entrega. |


| 09 | Adendo aprovado: corte manual de árvore com frutas, com perda do alimento restante e execução pelo trabalhador de madeira. V0.0.6 preservada. |


| 10 | Adicionado Shift com arraste na expansão, acompanhando o percurso do mouse sem cliques repetidos, preservando custos e validações. |


| 11 | Aprovada preservação das hortas em partidas antigas; nível 2 exigido somente para criar novas hortas. |


| 12 | Aprovado cancelar corte somente antes da primeira machadada; frutas restantes perdidas ao iniciar. Para retomar produção no local, plantar nova árvore após liberar o espaço. |
