# Civyz — V0.0.1: base e atividades

Documento histórico. A versão atual é V0.0.2; consulte `PLANO_V0.0.2.md` para as regras, controles e testes vigentes.

Atualização: a base inicial agora usa **Building-6**, e prédios/objetos são lidos das cenas de exemplos. O plano e o mapeamento completos estão em `PLANO_REFORMULACAO.md`.

## Funcionamento atual

A vila começa com uma base principal, um trabalhador alocado em construção, 20 comidas e 60 pedras. Somente a base recruta. Os outros prédios liberam suas atividades e guardam os recursos entregues. A antiga oficina não aparece mais no menu de construção.

O painel à esquerda mostra o total de habitantes, quantos estão livres e quantos estão alocados em Construção, Comida e Pedra. Use **−** para liberar um trabalhador e **+** para atribuí-lo a outra atividade. O total alocado muda imediatamente. Quem estiver carregando recursos conclui a entrega no prédio original antes de assumir a nova atividade; o painel indica essas transições.

## Teste rápido

1. Abra o projeto no Godot e pressione **F5**. Recarregue mudanças externas se o editor perguntar.
2. A base começa selecionada. Clique duas vezes em **+ Trabalhador** para recrutar dois habitantes. Eles chegam livres.
3. No menu inferior, clique no desenho de **Comida** e marque um local no mapa. Faça o mesmo com **Pedra**. O trabalhador inicial executa as obras.
4. Quando os prédios estiverem concluídos, use **+** em Comida e **+** em Pedra no painel à esquerda.
5. Observe os trabalhadores caminhando e entregando recursos. Clique num prédio para ver quanto está armazenado nele e quantos habitantes estão alocados ali.
6. Para trocar um coletor de comida por um de pedra, clique em **− Comida** e depois **+ Pedra**. O trabalhador troca de destino automaticamente; uma carga em trânsito é entregue antes da troca.
7. Se reduzir Construção a zero, as obras esperam. Aumente novamente para retomá-las.

O botão **Recrutar na base** abre as ações da base sem precisar procurá-la no mapa. A contratação não atribui automaticamente uma profissão.

## Valores para teste

| Ação | Custo | Tempo |
|---|---|---|
| Recrutar na base | 4 comidas + 2 pedras | 6 s |
| Construir casa de comida | 20 pedras | 8 s de trabalho |
| Construir casa de pedra | 25 pedras | 10 s de trabalho |

A fila da base comporta cinco pedidos, incluindo o pedido atual. Cancelar o último devolve os recursos. Os custos são pagos ao entrar na fila ou marcar a obra.

Cada fonte de frutas possui 80 unidades; cada depósito natural de pedra, 160. Coletores carregam até cinco unidades, colhendo uma a cada 0,8 s. O estoque global é a soma do que está armazenado na base e nos prédios de atividade. Recursos carregados ainda não estão disponíveis. Custos podem consumir recursos desses estoques; os reembolsos voltam à reserva da base.

Com mais de um prédio da mesma atividade, novas alocações escolhem o que tem menos trabalhadores atribuídos. A construção usa a base como apoio e não exige uma oficina separada. Comida e pedra exigem o respectivo prédio concluído.

## Controles

- **1 / 2:** selecionar casa de comida / pedra.
- **Esc, botão direito ou clicar novamente no cartão ativo:** cancelar posicionamento.
- **Clique em prédio existente:** abrir suas informações, mesmo durante o posicionamento.
- **Roda do mouse:** zoom; **botão do meio:** mover câmera.
- **Home / Centrar:** reenquadrar; **Espaço:** pausar; **2x:** acelerar.
- **Reiniciar:** recomeçar após confirmação.

Menu, prévia e prédios compartilham os mesmos recortes individuais da imagem. Os controles de ações permanecem estáveis durante a atualização da interface, incluindo cliques prolongados. Os painéis bloqueiam cliques no mapa atrás deles.

O visual segue `Scenes/menu_ex.tscn`: fundo claro e borda pixelada de `Assets/UI/Inventory/Banner.png`, com cantos decorativos de `Assets/UI/Extras.png` nos ícones de construção. Esse fundo é compartilhado pelos painéis de recursos, trabalhadores e ações. `Scripts/menu_theme.gd` centraliza o tema para reutilização em novos menus. O exemplo original foi preservado. Passe o mouse sobre um prédio do menu para consultar nome, atalho, custo e tempo de construção.

## Limites atuais e próximos passos

Ainda não há salvamento, expansão da ilha, plantações, evolução tecnológica, consumo de comida, morte ou demolição. Os estoques dos prédios não têm limite de capacidade nesta versão. Recursos acabam permanentemente. Trabalhadores podem compartilhar caminhos. Novas fontes de comida podem utilizar a mesma interface das frutas; crescimento e desbloqueios serão implementados futuramente.

O mapa fornece água e terreno. As cenas `buildings_exemples.tscn` e `Objects_Exemple.tscn` fornecem os modelos de prédios e recursos, preservados como referência. `example_catalog.gd` lê as montagens pintadas e separa as variantes de árvore. As posições iniciais no mapa são configuráveis na Main.

## Organização e verificações

`Scripts/game_data.gd` concentra os custos e tempos. `main.gd` coordena estoque, alocações e navegação; `worker.gd` executa trabalhos e mudanças de atividade; `building.gd` cuida dos estoques locais e do recrutamento exclusivo da base; `hud.gd` monta os menus.

Foram verificadas 59 condições de simulação e 19 de interface, incluindo o novo catálogo, dimensões da base, conservação de recursos durante trocas, cancelamento de filas, paralisação e retomada de obras, alocação entre vários prédios e cliques prolongados. O jogo também foi renderizado para inspeção visual.

Execute os testes a partir da pasta `civyz`:

```powershell
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://Tests/test_v001.gd
& 'C:/Users/lucas/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --fixed-fps 60 --path . --script res://Tests/test_ui.gd
```

As capturas renderizadas ficam em `Tests/v001_start.png`, `Tests/v001_queue.png`, `Tests/v001_playing.png` e `Tests/v001_placement.png`.
