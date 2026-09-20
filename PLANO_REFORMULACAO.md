# Reformulação a partir dos exemplos

## Objetivo e plano executado

1. Ler `Scenes/buildings_exemples.tscn` e `Scenes/Objects_Exemple.tscn` como catálogo visual, preservando as montagens originais.
2. Usar **Building-6 como a base inicial**, com um trabalhador na atividade Construção.
3. Retirar a dependência da casa, Fruit e Stone antigos dentro de `world.tscn`.
4. Adaptar dimensões, seleção, entrada, navegação e prévia aos tamanhos dos exemplos.
5. Manter o recrutamento exclusivo na base e a distribuição de trabalhadores pelo painel.
6. Testar inicialização, construção, filas, inventários locais, troca de funções e esgotamento de fontes; conferir o resultado renderizado.

## Catálogo e funções

| Exemplo | Uso atual |
|---|---|
| Building-6 | Base principal inicial, única recrutadora; montagem de 9 × 9 células. |
| Building-2 | Atividade e armazenamento de comida; 2 × 3 células, conforme a cena. |
| Building-3 | Atividade e armazenamento de pedra; 3 × 3 células. |
| Building-1, Building-4 e Building-5 | Registrados no catálogo e disponíveis para etapas futuras; ainda sem função atribuída. |
| Objects_Exemple / Stone | Fonte finita de pedra. |
| Objects_Exemple / Life_tree | Todas as variantes registradas; a árvore vermelha com frutas é a fonte de comida inicial. As fases de crescimento ficam preparadas como visuais, sem simulação de crescimento nesta versão. |

## Correções

- Inicialização corrigida: o código procurava nós que já não existem dentro de `world`.
- Base inicial substituída pelo Building-6, com entrada alinhada à porta e área maior bloqueada para navegação.
- Prédios, menu e prévia compostos a partir dos tiles realmente pintados nos exemplos. Não se utiliza mais um recorte fixo de uma imagem para todas as construções.
- Ocupação, prévia, entrada e seleção deixam de assumir que todo prédio mede 3 × 3.
- Os recursos são criados a partir do catálogo de objetos, sem depender de cópias antigas no mapa.
- O trabalhador inicial é colocado numa posição caminhável quando a nova base ocupa a posição anterior.

As cenas de exemplo são referências visuais, não locais de posicionamento no mapa. A posição da base e das duas fontes é configurável nas propriedades `initial_base_cell`, `initial_fruit_cell` e `initial_stone_cell` do script da Main. O restante do cenário continua em `world.tscn`.

## Como testar

1. Recarregue arquivos alterados externamente no Godot e execute **F5**.
2. Confirme a base grande do Building-6 e o único trabalhador inicial.
3. Recrute dois trabalhadores na base e construa as casas de comida e pedra.
4. Use **+** nas atividades, após concluir os respectivos prédios.
5. Teste trocar um coletor de atividade enquanto ele transporta carga: a entrega deve terminar antes da troca.
6. Confira o estoque local ao selecionar cada prédio e o total no topo.

Os custos e regras da V0.0.1 permanecem no guia `PLANO_V0.0.1.md`. Não há salvamento, expansão da ilha ou crescimento automático de árvores nesta etapa.

## Verificação

59 verificações da simulação e 19 da interface passaram. Incluem catálogo dos seis prédios, base de tamanho correto, entrada acessível, fontes carregadas sem os antigos nós no mundo, conservação de recursos e população, filas, cancelamento e troca de tarefas. A inicialização normal e as capturas renderizadas também foram verificadas. Isso cobre os fluxos testados; não é uma garantia de ausência de qualquer bug.
