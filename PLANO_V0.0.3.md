# Civiz Imperium V0.0.3 — auditoria e implementação

## Auditoria antes das alterações

O projeto é Godot 4.7, sem repositório Git nesta cópia. `main.tscn` instancia o terreno (`world.tscn`) e o personagem de referência. `main.gd` coordena o mapa, AStarGrid2D, economia agregada, colocação, expansão e evolução. `worker.gd` executa coleta/entrega e reserva obras; `building.gd` concentra depósitos e a antiga fila de recrutamento. `resource_source.gd` controla pedra e as sete fases de árvores. `world_job.gd` representa plantio/aterro. A HUD é construída por script; `menu_ex.tscn` é referência visual, não menu funcional. Não há save existente.

Antes da migração, `test_v002.gd` passou 51 verificações. Problemas a resolver: população inicial de um construtor, comida genérica, estoques ilimitados, cobrança imediata de obras, residência confundida com emprego, criação instantânea após fila e ausência de necessidades/ferramentas.

Inventário de Assets: 35 imagens (70 arquivos incluindo imports), distribuídas em Characters, Houses, Tiles e UI. As seis construções pintadas e sete árvores são recuperadas pelo catálogo existente. Casas e oficina reutilizam Building-4/5; depósito geral reutiliza Building-1. O personagem e animações permanecem. Banner/Extras e ícones HUD existentes servem à interface. Não há barco ou coroa apropriados nos sheets examinados: serão pequenos desenhos de retângulos/polígonos no renderer do jogo, sem novos bitmaps. Nada do roadmap monetário/social será implementado.

## Dependências e ordem

1. Catálogo de recursos e balanceamento; inventário limitado com reservas.
2. Identidade individual, profissão/XP, necessidades, residência e sucessão extensível.
3. Tickets logísticos: reserva → retirada física → entrega; obras só avançam após recebimento.
4. Máquina de estados existente evoluída para interrupção segura, descanso, ferramentas e oficina.
5. Imigração por barco com condições revalidadas; casas e melhorias; UI contextual e menu inicial.
6. Testes determinísticos das regras novas, regressões do ciclo de árvores/expansão, cliques e capturas reais.

Os scripts antigos de testes V0.0.1/2 são históricos: expectativas de fila, Food e capacidade por nível deixam de representar as regras solicitadas. A nova suíte deve cobrir as funcionalidades preservadas e as substituições explicitamente pedidas.

## Implementação entregue

- `resident.gd`: identidade estável, nome, profissão, XP por atividade, energia, nutrição, ferramenta, condição adulta e ID de residência. A condição adulta apenas prepara a elegibilidade; não existe simulação de idade.
- `settlement.gd`: atribuição de residência, alimentação por catálogo, capacidade habitacional, morte e sucessão. `succession_policy` é substituível para regras futuras de escolha do governante.
- `needs.gd`: relógio alimentar, produtividade reduzida, fraqueza, morte por inanição, viagem à residência e descanso. Acordar não retira atributos: apenas dá uma pequena janela antes de voltar a procurar descanso.
- `logistics.gd`: reservas de estoque e espaço, retirada física, entrega, prioridades iniciais (obras, oficina, cargas no chão), cancelamento seguro e preservação de cargas. Cada ticket identifica origem, destino, trabalhador, recurso, quantidade e etapa. O débito ocorre na retirada, a entrada no destino ocorre na chegada.
- `material_request.gd`: requisitos e entregas de construções, melhorias, plantio e expansão. Material em trânsito não conta como recebido.
- `building.gd`: inventários limitados, moradia, melhorias e oficina. Matérias-primas chegam fisicamente à oficina; metas globais também consideram lotes já em produção para não exceder a meta com oficinas paralelas.
- `worker.gd`: conserva personagem/animações e navegação anteriores; integra os estados novos. Interrupções liberam reservas e deixam carga física recuperável. Um caminho bloqueado nunca autoriza coleta/entrega remota.
- `immigration.gd`: chegada periódica condicionada, preparação de expedições e barco desenhado no mundo. Moradia, comida e acesso são revalidados ao desembarcar. Barcos aguardam se as condições mudarem.
- `main_menu.gd` e HUD: marca Civiz Imperium, menu inicial, inspeção individual, moradores por residência, ação de acordar, metas da oficina, entregas por obra, estoques/capacidade e tela de extinção.

O coordenador, mapa, catálogo de sprites, AStarGrid2D e ciclo de árvores existentes foram preservados. Os exemplos grandes de casa/oficina usam escala visual 0,5, com ocupação ajustada à ilha. Fundadores moram no abrigo da base; novas casas recebem os colonos. Emprego e residência são referências independentes.

## Regras de balanceamento

| Sistema | V0.0.3 |
|---|---|
| Início | Rei construtor, um coletor e um lenhador; todos trabalham na mesma arquitetura |
| Reserva inicial | 18 frutas, 45 pedras, 20 madeiras, 2 machados, 2 picaretas |
| Moradia | Base abriga 3; casa abriga 4, depois 6 e 8 com melhorias físicas |
| Armazenamento | Base 120; depósitos 200, +100 por melhoria; oficina 60 |
| Alimentação | Nutrição cai 0,18/s; uma fruta repõe 25. Consumo médio de ~0,43 fruta por pessoa/minuto |
| Fome | Produtividade cai abaixo de 40%; trabalho para abaixo de 15%; nutrição zero por 180s causa morte. Sem alimentação desde o começo, cerca de 12 minutos até a primeira morte |
| Descanso | Busca residência abaixo de 20 de energia; recupera 3/s até 95. Morador fica invisível no mapa enquanto está dentro |
| Ferramentas | Durabilidade 45 ações; sem ferramenta, velocidade 28% e consumo de energia 2,8× |
| Oficina | 8s por ferramenta; machado = 2 madeiras + 1 pedra; picareta = 1 madeira + 2 pedras; metas padrão 5/5 |
| Experiência | Bônus gradual de 5% por 30 XP, limitado a 50%; XP preservado ao trocar de profissão |
| Imigração | Preparação natural de 180s enquanto condições saudáveis persistem, seguida de 12s de barco; uma pessoa por chegada |
| Expedição | 5 frutas + 3 madeiras; preparação reduzida para 35s + viagem. Exige reserva alimentar suficiente mesmo depois de abastecer a viagem |
| Evolução | Nível 2 libera transportadores e carga 7; capacidade populacional depende exclusivamente das residências construídas |

Os valores principais ficam em `game_data.gd`. Estoques coletivos incluem itens reservados; o tooltip do estoque explica reservas e carga em trânsito. Pagamentos respeitam reservas, e depósitos cheios interrompem produção ou preservam cargas no chão. A base permite as três coletas desde o começo, evitando exigir vários edifícios para três pessoas sobreviverem. Depósitos especializados continuam úteis por capacidade, proximidade e distribuição do trabalho.

## Como jogar

Abra `project.godot` no Godot 4.7 e use F5. No menu, escolha **Fundar uma civilização**.

1. Construa uma casa e um depósito geral. O Rei inicialmente faz construção; os dois trabalhadores coletam frutas e madeira.
2. Selecione a base ou o depósito de comida para plantar árvores. Renove o pomar antes de a frutificação acabar.
3. Com moradia e alimentos disponíveis, colonos chegam de barco. Use **Atrair colonos** para abreviar a preparação, sem criar pessoas no clique.
4. Aloque um colono em Pedra. Construa a oficina e atribua um artesão para manter ferramentas.
5. Evolua a vila e aloque um transportador. Produtores passam a deixar cargas para coleta automática.
6. Clique numa residência e abra **Moradores / descanso** para ver pessoas dentro, energia e acordá-las. **Conhecer habitantes** mostra toda a população.

Resolução padrão: 1920×1200 (16:10), com zoom inicial leve. WASD ou botão do meio movem a câmera; roda do mouse aproxima; Espaço pausa; Home centraliza; Esc cancela colocação. Os atalhos 1/2/3 preservam os depósitos de comida/pedra/madeira. A interface usa 1280×800 como tamanho mínimo.

## Validação

- Auditoria da versão anterior: 51 verificações V0.0.2 passaram antes das mudanças.
- `test_v003.gd`: 72 verificações de simulação, zero falhas. Inclui fadiga durante transporte, bloqueio da residência, despertar, ferramentas quebradas/ausentes, oficinas concorrentes, última vaga do depósito, interrupção de reservas, cargas no chão, disputa de materiais, entrega física, casas/melhorias, imigração suspensa por falta de moradia/comida, fome ao longo do tempo, sucessão e extinção. Também cobre pausa, árvores, plantio e expansão.
- `test_v003_ui.gd`: 17 verificações, zero falhas, com eventos de clique. Menu, contexto da base, colocação, moradores, despertar, inspeção, metas da oficina, alocação e limites visuais da interface.
- `playthrough_v003.gd`: 20 minutos de tempo simulado, sem injetar recursos ou concluir obras artificialmente. Na execução final, chegou ao nível 3 em 470s de simulação e terminou com sete habitantes, quatro expansões e doze plantios, incluindo três pessoas que descansaram automaticamente. Verifica terreno caminhável e capacidade de estoque ao longo da partida.
- Capturas reais em `Tests/v003_*.png`: menu, início, base, moradores, oficina, colônia, barco, descanso e vila. Inspecionadas visualmente após execução com renderização OpenGL.

Comandos a executar a partir da pasta `civyz` (ajuste apenas o caminho do executável):

```powershell
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://Tests/test_v003.gd --log-file Tests/v003_test.log
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://Tests/test_v003_ui.gd --log-file Tests/v003_ui.log
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --path . --script res://Tests/playthrough_v003.gd --log-file Tests/v003_playthrough.log
```

O ambiente restrito emitiu avisos de acesso ao repositório de certificados e ao cache gráfico fora da pasta do projeto. Esses avisos não são erros de script nem falhas das verificações; as capturas e a simulação funcionaram. O balanceamento foi validado por simulação automatizada, não por uma sessão humana de 20 minutos.

## Limites e próximas versões

Ainda não há salvamento em disco; identidades, configuração central e `Resident.snapshot()` facilitam uma implementação posterior, mas não representam save completo. O nível 3 e o limite de expansão próxima da ilha permanecem. Não há famílias, reprodução, envelhecimento, moeda, mercado, salários, impostos, ouro econômico, combate ou integração Steam. Esses sistemas continuam fora da V0.0.3.

Sugestões futuras: save versionado com restauração de tickets, prioridades logísticas configuráveis, residência escolhida pelo jogador, rotas marítimas com mais ilhas e balanceamento por testes humanos. A economia monetária permanece no roadmap da V0.0.4, sem implementação antecipada.


