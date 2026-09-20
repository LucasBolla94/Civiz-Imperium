# Civyz V0.0.2 — Ilha viva

## Ideia jogável

Uma vila que precisa renovar seus pomares para crescer. A mesma árvore ocupa espaço ao longo do tempo, oferece comida numa fase específica e, no último estágio, vira madeira. Com madeira e pedra, o jogador amplia a costa. Com mais espaço, planta novos pomares e evolui a vila.

O prazer que queremos testar é observar os habitantes executando um plano e perceber o resultado no mapa: um pomar cresce, uma entrega chega, a ilha aumenta e uma nova etapa abre. Isso é uma hipótese de design a validar jogando, não uma promessa de retenção ou sucesso comercial.

## Referências pesquisadas

- [The Colonists — página oficial na Steam](https://store.steampowered.com/app/677340/The_Colonists/): coleta, produção de comida, transporte, exploração e avanço por eras. A página consultada apresenta avaliação agregada Muito positiva. Para Civyz: tarefas visíveis e uma cadeia curta de produção que financia novos espaços.
- [Against the Storm — recursos, wiki oficial](https://wiki.hoodedhorse.com/Against_the_Storm/Gather_Resources): depósitos de recursos, movimentação por habitantes e produção renovável. Para Civyz: diferença clara entre reservas iniciais finitas e pomares que precisam ser replantados. Não copiamos a estrutura roguelite.
- [Kingdoms and Castles — página oficial na Steam](https://store.steampowered.com/app/569480/Kingdoms_and_Castles/): crescimento de um povoado por coleta, agricultura e construção. Para Civyz: metas de desenvolvimento compreensíveis e crescimento visível.

As adaptações acima são decisões próprias de projeto; as fontes descrevem os jogos e não demonstram que uma mecânica isolada causa seu sucesso.

## O que foi entregue

1. Menu contextual: selecionar um prédio troca a lista de construções pelas ações daquele prédio. Clicar no mapa vazio retorna à construção. Durante uma ordem de plantio/expansão, o clique marca o local; Esc ou botão direito cancela.
2. Base Building-6: recruta, expande a costa, evolui a vila e oferece coleta costeira emergencial.
3. Depósito de comida: permite marcar plantios. Os trabalhadores de Comida plantam antes de voltar à coleta.
4. Depósito de madeira: usa Building-1. Lenhadores só cortam árvores no último estágio.
5. Ciclo de sete estágios, com os visuais de Life_tree. Corrigida a leitura de dois exemplos encostados que antes viravam uma única árvore larga.
6. Obras de expansão 3 × 3, executadas por construtores, com costa atualizada e novas áreas caminháveis. Cada segunda expansão revela uma jazida de 40 pedras.
7. Três níveis de vila, com condições, custos e benefícios reais.

## Ciclo de vida das árvores

| Estágio visual | Tempo de simulação | Recurso disponível |
|---|---:|---|
| Broto | 8 s | Nenhum |
| Muda | 12 s | Nenhum |
| Jovem | 16 s | Nenhum |
| Adulta | 20 s | Nenhum |
| Frutificação | 160 s | 80 comidas; 100 se entrar nessa fase após evolução para nível 2 |
| Envelhecimento | 20 s | Nenhum |
| Último estágio | Até ser cortada | 30 madeiras; nunca comida |

Colher todas as frutas não pula os tempos. Frutas que não forem colhidas até terminar a fase deixam de estar disponíveis. Uma carga já coletada continua pertencendo ao trabalhador e é entregue normalmente. Cortar a madeira libera o espaço para replantar. Cada árvore reserva 3 × 4 células desde o plantio, evitando crescer dentro de um prédio.

O mapa começa com uma árvore frutificando e outra no estágio final, permitindo experimentar a madeira sem esperar um ciclo completo. Novas árvores passam por todas as fases. Pausar interrompe trabalho e crescimento; 2x acelera ambos.

## Economia e ações

Reserva inicial: 24 comidas e 80 pedras; uma base e um construtor.

| Ação | Custo | Execução |
|---|---|---|
| Recrutar | 4 comidas + 2 pedras | 6 s na base; máximo de 5 pedidos na fila, respeitando limite de população |
| Depósito de comida | 20 pedras | Construtor, 8 s |
| Depósito de pedra | 25 pedras | Construtor, 10 s |
| Depósito de madeira | 15 pedras | Construtor, 10 s |
| Plantar árvore | 2 comidas | Trabalhador de Comida, 4 s, mais deslocamento |
| Expandir 3 × 3 | 10 pedras + 5 madeiras | Construtor, 10 s, mais deslocamento |
| Coleta costeira | Gratuita | +4 comidas; intervalo de 60 s |

A coleta costeira é uma recuperação lenta para não ficar sem comida para replantar. O plantio e os depósitos são o caminho produtivo. Custos usam os estoques locais somados. Recursos transportados só contam depois da entrega.

## Evolução

| Nível | Requisitos e custo | Benefício |
|---|---|---|
| 1 — início | Inicial | Até 5 habitantes; carga de 5 |
| 2 — vila | Pagar 20 comidas, 25 pedras e 15 madeiras | Até 10 habitantes; carga de 7; novas frutificações rendem 100 |
| 3 — prosperidade | Pagar 40 comidas, 40 pedras e 30 madeiras | Até 16 habitantes; objetivo da versão concluído |

Correção de disponibilidade: plantios e expansões são orientações, não bloqueios de evolução. O atalho “Vila: expandir / evoluir” abre as ações da base. Expansão e evolução mostram a quantidade exata que falta; todos os depósitos entram no cálculo. O teste `Tests/test_resources.gd` cobre custos exatos divididos entre depósitos, atualização dos botões, cobrança única e ausência de requisitos ocultos.

O jogador decide entre recrutar, renovar pomares e poupar para evoluir. Pomares distantes aumentam o tempo de transporte; vários depósitos podem reduzir esses percursos. Plantios e obras que bloqueiam a circulação são recusados antes de cobrar recursos.

## Roteiro de teste

1. F5 no Godot. Construa os três depósitos e recrute três habitantes pela base.
2. Distribua um em Comida, um em Pedra e um em Madeira, mantendo o construtor.
3. Selecione o depósito de comida e plante duas árvores em espaços livres.
4. Observe os estágios e as entregas. Selecione uma árvore para consultar seu tempo e recurso disponível.
5. Selecione a base e marque uma expansão inteiramente no mar, encostada na costa.
6. Evolua para nível 2. Plante mais duas árvores e amplie mais duas vezes.
7. Economize para nível 3. Continue renovando os pomares se quiser prosseguir.

Uma simulação automatizada percorreu esse roteiro e chegou ao nível 3 sem injetar recursos. Ritmo sugerido para teste humano: cerca de 8–12 minutos a 1x, ajustável pela decisão e uso de 2x. Esse intervalo é estimativa de design, não medição de usuários.

## Arte e limites

Foram reutilizados os prédios, estágios de árvore, pedra, terreno e BG do menuEx. Não foi necessário criar novas imagens: as funções novas já têm representações adequadas nos assets existentes.

Não há salvamento nesta versão. O nível 3 é o marco final; não há combate, doenças, estações, comida consumida por habitante ou crescimento populacional automático. A expansão fica limitada à região próxima da ilha (até 12 células além dos limites iniciais). A mineração usa depósitos finitos; novas jazidas surgem a cada duas expansões.

## Validação

Passaram 51 verificações de simulação e 15 de interface. `Tests/test_v002.gd` verifica menu contextual, recursos por fase, passagem do tempo, pausa, plantio, liberação do terreno, filas, trabalhadores, expansão, novas jazidas e evolução. `Tests/test_v002_ui.gd` testa cliques reais enviados à interface, incluindo contratação, cancelamento, plantio, expansão e retorno à construção. `Tests/capture_v002.gd` realiza uma partida completa com os recursos normais e salva capturas renderizadas. Os testes antigos de V0.0.1 ficam como histórico e não descrevem as regras novas.

```powershell
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --fixed-fps 60 --path . --script res://Tests/test_v002.gd
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --fixed-fps 60 --path . --script res://Tests/test_v002_ui.gd
```

Os valores ajustáveis estão em `Scripts/game_data.gd`; o ciclo de árvores em `resource_source.gd`; os trabalhos de plantio/expansão em `world_job.gd`; o catálogo continua lendo os exemplos originais.
