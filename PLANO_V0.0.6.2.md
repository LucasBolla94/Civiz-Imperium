# Civiz Imperium — Plano V0.0.6.2

- Versão: **0.0.6.2**.
- Revisão compartilhada: **1**.
- Par: [ASSETS_V0.0.6.2.md](ASSETS_V0.0.6.2.md).
- Estado: **implementado; validação automática registrada em `Tests/test_v0062_timber.log` e `Tests/test_v0062_timber_ui.log`**.

## Objetivo e limites

Dar ao jogador uma segunda espécie plantável. Ao marcar um plantio, ele escolhe entre a **árvore frutífera**, cujo ciclo permanece exatamente como está, e a nova **árvore de madeira**, que nunca frutifica e existe para abastecer a cadeira de madeira.

Nada do ciclo frutífero muda: estágios, tempos, 50 Hortifruti, transição automática para 30 madeiras, botão **Cortar agora** com perda de frutas e renovação de pomar continuam idênticos. Esta versão não altera custos de construção, metas de estoque, transporte nem a economia de ouro e comércio.

## 1. Funcionalidade F-0062-01 — Pedido de plantio de madeira

- Ação nova `plant_wood`, irmã de `plant`. Mesma área de **3 × 4 células**, mesma exigência de terra livre, mesmo custo de **2 Hortifruti** e mesmos 4 segundos de trabalho.
- O botão **Plantar árvore de madeira** aparece na **Base** e no **Depósito de madeira** concluído, ao lado do botão de plantio frutífero.
- O pedido só é aceito quando existe um **Depósito de madeira** acessível. Sem ele, o motivo apresentado é "Construa um depósito de madeira.", espelhando a exigência de depósito de comida do plantio frutífero.
- O pedido tem `activity = "wood"`: quem entrega a semente e executa o plantio é o **Lenhador**. Um coletor de comida não assume esse pedido, e um lenhador não assume o plantio frutífero.
- A marcação no mapa usa a cor da madeira (`bb8757`) em vez do verde do plantio frutífero, mantendo o mesmo retângulo 3 × 4 e a mesma barra de progresso.

## 2. Funcionalidade F-0062-02 — Ciclo da árvore de madeira

- Cinco estados: semente, broto, muda, árvore jovem e madura. Os quatro tempos de crescimento são **30 s, 40 s, 50 s e 60 s** — os mesmos da frutífera, totalizando **180 s**.
- Em nenhum estágio a árvore de madeira produz Hortifruti. `harvestable("food")` é sempre falso e uma colheita de comida nunca retira nada dela.
- Ao amadurecer, ela passa a valer **45 madeiras** (contra 30 da árvore natural esgotada) e fica imediatamente disponível para lenhadores, sem precisar de ordem de corte.
- **Cortar agora** não se aplica: não há fruta a sacrificar. O botão não aparece para esta espécie, e `request_cut()` é recusado.
- A árvore madura não envelhece nem perde estoque com o tempo.
- Exaurida a última madeira, a árvore é **removida**: o visual some, a navegação é reconstruída e o terreno volta a aceitar construção ou um novo plantio. Não há toco persistente.
- **Renovação do pomar** continua exclusiva das árvores frutíferas; a espécie de madeira não entra nessa automação.
- Metas de estoque de madeira continuam valendo: atingida a meta, lenhadores param de reservar a árvore, como em qualquer fonte de madeira.

## 3. Funcionalidade F-0062-03 — Lenhador como trabalhador de obra

O lenhador passa a considerar pedidos cuja atividade seja `wood`, da mesma forma que construtores, coletores e mineiros já consideram os seus. Isso inclui transportar os 2 Hortifruti até o local do plantio antes de executá-lo. Fora do plantio de madeira, nenhuma outra tarefa tem atividade `wood`, então o comportamento anterior do lenhador — reservar árvore, cortar, entregar — permanece o padrão.

## 4. Persistência

O salvamento grava a espécie (`is_timber`) junto dos demais campos da fonte. Na restauração, a árvore volta com a arte, o estágio e o estoque restante corretos. Um salvamento que traga uma árvore de madeira com ordem de corte, sem a marca de árvore, ou com estágio acima do maduro é recusado pela validação existente. Salvamentos anteriores à V0.0.6.2 continuam válidos: sem o campo, toda fonte é lida como antes.

## 5. Critérios de aceite

1. Sem Depósito de madeira, o plantio de madeira é recusado com motivo explícito.
2. Com o depósito, o pedido é criado com atividade `wood`, custo de 2 Hortifruti e área 3 × 4.
3. Um coletor de comida ignora o pedido; um lenhador entrega a semente e conclui o plantio.
4. A muda nasce imatura, não rende nada e amadurece em 180 s simulados.
5. A árvore madura entrega 45 madeiras, nunca Hortifruti, e recusa a ordem de corte.
6. O planejador reserva a árvore para o lenhador e cada machadada rende uma madeira.
7. Salvar e restaurar preserva espécie, estágio, estoque e arte; ordem de corte gravada nessa espécie invalida o arquivo.
8. Cortada até o fim, a árvore é removida e o terreno aceita um novo plantio.
9. O ciclo frutífero permanece: 50 Hortifruti, transição para 30 madeiras e **Cortar agora** disponível na adulta.

Evidências: `Tests/test_v0062_timber.gd` (regras e persistência) e `Tests/test_v0062_timber_ui.gd` (interface real, capturas `Tests/v0062_timber_*.png`), com seus registros de execução.

## Fora de escopo

Rebrota a partir do toco, variações sazonais da copa, mudas compradas do comerciante, meta de estoque própria para a espécie e replantio automático de floresta. Nenhum desses itens está autorizado por este plano.
