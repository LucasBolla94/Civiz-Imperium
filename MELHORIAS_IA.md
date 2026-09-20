# Melhoria da inteligência dos trabalhadores — V0.0.3

## Problemas identificados

Coletores escolhiam fontes sem reservar quantidade ou posição; vários habitantes podiam caminhar para a mesma árvore, incluindo quando sobrava apenas uma fruta. O transporte escolhia o primeiro estoque da lista, independentemente da distância. As entregas dos próprios produtores não reservavam espaço no destino. Artesãos buscavam tarefas logísticas gerais antes de produzir, e oficinas podiam retirar matérias-primas umas das outras. Alterações de caminho ou profissão interrompiam entregas e largavam a carga imediatamente.

## Comportamento atual

- **Postos de trabalho:** uma pessoa por árvore e até duas por jazida, em posições distintas. Quantidades reservadas não excedem o recurso disponível. Desistência, descanso e morte liberam o posto. Uma fonte que deixa de produzir durante o trajeto é descartada antes de completar a caminhada inútil.
- **Continuidade:** o trabalho escolhido permanece ativo durante a viagem. Uma pequena preferência por fontes conhecidas reduz trocas entre pontos equivalentes. Consultas de trabalho são espaçadas por habitante; sem tarefa útil, ele espera com um motivo visível.
- **Rotas:** entregas consideram a distância até a origem e depois ao destino, favorecendo cargas úteis. Reposição de ferramentas busca o estoque acessível mais próximo. Novos obstáculos provocam tentativa de desvio mantendo a tarefa e a carga; se o acesso continuar impossível, a reserva é liberada após tentativas limitadas. Recalcular uma rota reta no meio de uma célula não provoca um passo para trás.
- **Entregas:** produtores reservam espaço no depósito antes de partir. Uma mudança de profissão aguarda a entrega carregada em andamento. Cansaço normal permite terminar uma entrega próxima antes de descansar; exaustão e fome grave continuam interrompendo o trabalho.
- **Oficina:** produção disponível vem antes de outras tarefas. Cada oficina tem uma bancada reservável; outros artesãos ajudam a abastecer sua oficina ou aguardam. Insumos de uma oficina não são transferidos continuamente para outra. Lote concluído sem espaço de saída aguarda sem continuar gastando trabalho.
- **Alimentação:** com reserva alimentar baixa, coleta de comida disponível e resgate de alimentos no chão recebem prioridade. Essa prioridade é aplicada ao escolher uma nova tarefa, preservando viagens já em andamento.

As regras ficam em `work_planner.gd`, `logistics.gd`, `worker.gd`, `needs.gd` e `building.gd`; limites e tempos principais estão em `game_data.gd`. Não foram acrescentados sistemas sociais ou econômicos do roadmap. Caminhos e portas continuam compartilháveis: esta melhoria coordena tarefas e postos de trabalho, sem introduzir colisão física entre pessoas que poderia bloquear corredores estreitos.

## Validação

- `Tests/test_worker_ai.gd`: **31 verificações**, zero falhas, cobrindo disputa por árvores, postos de mineração, último recurso, interrupção, fontes envelhecidas, escolha de estoques/ferramentas próximos, reserva de capacidade, troca de profissão com carga, desvio de obstáculos, descanso após entrega, bancada compartilhada, oficinas concorrentes e alimentação urgente.
- Regressões V0.0.3: **72 verificações** de simulação e **17 de interface**, zero falhas.
- Partida automatizada de **20 minutos de tempo simulado**, sem recursos extras: nível 3 aos 530s, oito habitantes, quatro expansões, quatorze plantios, descanso automático e capacidade dos estoques respeitada. Executada também com renderização OpenGL.

Total: **120 verificações aprovadas**, além da partida prolongada. Os logs desta revisão são `Tests/worker_ai.log`, `Tests/ai_regression.log`, `Tests/ai_ui.log` e `Tests/ai_playthrough.log`. O aviso de certificados do ambiente continua sem afetar a simulação.

Para executar a suíte específica, a partir da pasta `civyz`:

```powershell
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://Tests/test_worker_ai.gd --log-file Tests/worker_ai.log
```
