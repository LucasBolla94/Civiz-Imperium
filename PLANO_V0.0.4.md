# V0.0.4 — A vila ganha autonomia

Implementação autorizada pelo usuário para entregar a versão integrada e jogável. Preserva logística física, profissões, sete estágios das árvores, ferramentas com durabilidade e interface independente da câmera.

## Como testar

Abra project.godot no Godot e pressione F5. O menu identifica V0.0.4.

- **Oficina:** construa e aloque um artesão em Habitantes → Oficina. No nível 1, use +1 machado/picareta para encomendar; −1 cancela apenas encomendas ainda não iniciadas. O transporte leva madeira/pedra, o artesão fabrica e trabalhadores retiram ferramentas fisicamente.
- **Melhorias individuais:** selecione a oficina e solicite o upgrade. Nível 2 custa 15 madeiras + 15 pedras e libera metas de estoque; nível 3 custa 30 + 30 e calcula a reserva pelas profissões. Cada upgrade exige entrega e construção; melhorar uma oficina não melhora as outras.
- **Metas das ferramentas:** as metas de nível 2 são reservas da vila, não de cada depósito. Oficinas consideram ferramentas existentes e fabricação em andamento para evitar duplicação. Encomendas manuais são pedidos adicionais. Nível 3 reserva uma ferramenta para cada dois trabalhadores da profissão, arredondando para cima; sem trabalhadores, não pede reserva.
- **Pedra:** jazida inicial com 480 unidades; descobertas após expansão têm 120. Depósito de pedra nível 2 libera Investigar terreno. Marque terra livre de 3 × 3; um mineiro investiga. Selecione o resultado e escolha abrir a pedreira ou liberar o terreno.
- **Pedreira:** depósitos de 300, 600 ou 1.000 pedras, definidos pela posição e sem sorteio repetível. Abrir custa 10 madeiras + 5 pedras e 24 segundos de trabalho-base. Investigação leva 12 segundos. Materiais e trabalho são físicos; extração usa picareta ou trabalha mais devagar sem ferramenta. A cava bloqueia passagem, possui postos de coleta nas bordas e permanece desenhada após esgotar, quando o chão é liberado.
- **Pomares:** selecione uma árvore ou plantio e ative Renovação do pomar. Após o ciclo e a retirada do toco, a vila agenda um novo plantio. É necessário coletor, espaço, acesso e comida acima da reserva alimentar. Lenhadores limpam tocos desses lotes mesmo se a meta de madeira foi atendida. Desativar preserva árvores e trabalhos existentes.
- **Prioridades:** selecione obra, plantio ou investigação e alterne baixa/normal/urgente. Vale para escolha de novas tarefas e transporte de materiais. Não interrompe uma carga em andamento, alimentação ou descanso.
- **Planos da vila:** em Vila → Planos / salvar, configure metas de frutas, madeira, pedra e moradores. Estoque 0 = sem limite. Estoques, cargas, pilhas no chão e coletas reservadas contam para as metas; obras e reserva alimentar acrescentam demanda. A produção volta quando o estoque cai. População começa com meta de 7; atingir a meta suspende novas chegadas.
- **Imigração:** a interface informa falta de moradia, comida, população alimentada ou meta atingida. Atrair colonos exige também recursos para a expedição sem consumir a reserva alimentar. Barco procura outra margem acessível se o desembarque ficar desconectado.
- **Expansão:** o limite acompanha a área da camada Water pintada na cena, sem a antiga margem fixa de doze blocos.
- **Salvar e continuar:** salvamento manual e automático a cada dois minutos de simulação ativa. Preserva terreno, fontes, reservas, obras, upgrades, produção parcial, ordens, necessidades, ferramentas, cargas, políticas e viagem. Ao retomar, as tarefas e reservas de caminho são refeitas; materiais já retirados permanecem com os trabalhadores. Arquivo versionado com verificação de integridade, gravação temporária e cópia anterior. Arquivo inválido preserva a vila aberta. Não há importação de partidas de versões anteriores.

## Decisões de balanceamento

Upgrades são solicitados pelo jogador e pagos com recursos e trabalho. Não há exigência de fabricar ferramentas inúteis para acumular experiência. O ritmo e os custos são valores iniciais para teste. A evolução geral da vila conserva as regras anteriores; nesta versão a nova progressão de automação está nas oficinas e no depósito de pedra.

Não inclui combate, moeda, famílias, desgaste obrigatório de prédios ou outros sistemas ainda não decididos. A automação organiza tarefas; continua sendo necessário distribuir profissões e garantir espaço de armazenamento.

## Validação

Tests/test_v004.gd cobre encomendas, consumo real, upgrades independentes, metas, retirada de ferramenta, investigação, abertura e esgotamento, prioridades, pomares, imigração com acesso bloqueado e salvamento/retomada. Tests/test_v004_ui.gd exercita cliques reais e novos controles. As suítes anteriores permanecem como regressão, com oficinas explicitamente no nível 2 nos testes de metas. A partida natural simulada de vinte minutos usa os novos upgrades e pomares e não injeta recursos.

Capturas: Tests/v004_workshop_manual.png, Tests/v004_workshop_targets.png, Tests/v004_plans.png e Tests/v004_quarry.png.

Resultado da validação integrada: 738 verificações aprovadas em dez suítes (simulação nova, regressão, IA, árvores, plantio, limites da janela, interface anterior/nova e 12 resoluções). Partida natural de 20 minutos: nível 3, 7 moradores, 4 expansões, 15 plantios, nenhum erro de simulação registrado. Estes testes não substituem o teste de jogabilidade e balanceamento pelo usuário.
