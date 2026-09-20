# Civiz Imperium

## Regra permanente de documentação por versão

A pedido do usuário, cada nova versão deve ter sempre dois arquivos Markdown na raiz: `PLANO_V<versão>.md` e `ASSETS_V<versão>.md`. Exemplo: `PLANO_V0.0.5.md` e `ASSETS_V0.0.5.md`. O primeiro orienta a IA que implementa o jogo; o segundo orienta a IA que produz os assets. Ambos devem ter a mesma versão, revisão de contrato, estado de escopo e links recíprocos.

Cada funcionalidade recebe um ID estável; cada asset recebe outro ID, referenciado nos dois documentos. O plano define comportamento, estados, dimensões de ocupação, integração e critérios de aceite. O documento de assets especifica cada entrega por completo: finalidade, referências reais, formato, dimensões, escala, transparência, origem/pivô, estados/animações, organização de quadros, nomes e caminhos dos arquivos e critérios visuais/técnicos de aceite. Diferenciar tamanho da imagem, ocupação no mapa e colisão. Não deixar a outra IA adivinhar parâmetros.

Decisões não tomadas ficam explicitamente pendentes; não são autorização para implementar ou produzir arte. Qualquer mudança de contrato deve atualizar os dois documentos na mesma revisão antes da execução dependente. As duas IAs seguem o contrato compartilhado; a IA de arte não redefine mecânicas, e a de implementação não altera silenciosamente dimensões ou nomes de assets. Não substituir exemplos ou arquivos originais sem necessidade definida no plano.

O documento de assets permanece separado e recebe somente pedidos de arte a criar ou adaptar, com contexto completo para a outra IA. Não adicionar fichas de reutilização ou itens “sem arte nova”: essas decisões ficam no plano do jogo. Se não houver encomendas, manter apenas o cabeçalho do documento de assets. Manter versões anteriores como histórico e atualizar o estado de entrega nos dois documentos. Não criar um terceiro plano de versão para substituir ou fragmentar esse par.

## V0.0.5.1 — Expansão fluida e administração clara

Versão atual: **0.0.5.1**. Escopo fechado implementado: [PLANO_V0.0.5.1.md](PLANO_V0.0.5.1.md) e [ASSETS_V0.0.5.1.md](ASSETS_V0.0.5.1.md). Revisão compartilhada **18**.

Novidades: hortas novas pelo depósito de comida nível 2; balões com motivos reais e atalhos; benefícios do próximo nível antes de melhorar; corte manual de árvores com frutas; expansão com Shift e arraste, incluindo sobreposição parcial a aterros já marcados. Custos, alocações de profissão, metas e automações existentes foram preservados.

**Construir na expansão:** espere o aterro terminar. A moradia precisa de 5×4 células livres e uma entrada frontal acessível; use o pincel para ampliar/preencher água. É possível marcar sobre materiais soltos e habitantes: antes da obra, um construtor, transportador ou habitante livre leva as pilhas para posições próximas livres escolhidas aleatoriamente, e os ocupantes saem andando. A etapa **Liberando terreno** preserva recursos, alocações e cargas, inclusive ao salvar ou cancelar. Árvores, jazidas e prédios continuam obstáculos fixos. A prévia mostra tamanho, obstáculos e entrada. Não há limite fixo de moradias.

**Arrumar o terreno:** abra Vila → Ampliar costa e segure **Ctrl enquanto gira a roda do mouse** para ajustar o pincel de 1×1 a 9×9. Pode passar sobre terra existente: somente a água destacada será aterrada e cobrada. A prévia mostra materiais e tempo; **Shift + arraste** marca o percurso continuamente. Água já marcada é excluída de novos pedidos. Não cria expansões remotas dependentes de obras ainda pendentes. O construtor leva os materiais e conclui o aterro. Funciona também nos buracos de ilhas já salvas. Uma célula custa 2 pedras + 1 madeira; nove células custam 10 pedras + 5 madeiras. Reparos parciais e pincéis de outros tamanhos não criam jazidas automáticas.

Jazidas descobertas por **Investigar terreno** agora exibem o asset Stone original, inclusive durante a abertura da pedreira. Investigações já salvas também recebem a correção.

Correção visual de 20/09/2026: Hortifruti redesenhado em 32×32/16×16 com transparência real; corrigida a textura que virava quadrado branco nas pilhas. Trabalhadores aparecem inteiros acima das hortas e podem atravessar todas as suas células. Compatível com saves V0.0.5 existentes; reinicie o jogo usando o pacote atualizado.

Para jogar no Windows, extraia `Builds/Civiz-Imperium-V0.0.5.1-Windows.zip` e abra `Civiz Imperium V0.0.5.1.exe`. Mantenha o `.pck` na mesma pasta. A pasta já extraída também está em `Builds/Civiz-Imperium-V0.0.5.1`. Para editar, abra `project.godot` no Godot 4.7.2 e pressione F5.

Você começa com um Rei e dois trabalhadores. **Casas concluídas com vagas permitem mais habitantes, sem o antigo limite de sete pessoas.** Mantenha reservas de comida e aguarde os barcos, ou abasteça uma expedição. Construção, Comida, Madeira, Pedra, Oficina e Transporte usam os mesmos habitantes, com profissões, experiência, ferramentas, fome, energia e descanso.

- Selecione um depósito de comida concluído de **nível 2** e use **Create garden / Criar horta**. Cada canteiro ocupa 2×2 células e aceita hortas adjacentes. Um construtor instala o cercado: 10 madeiras e 10 segundos de trabalho, uma vez. O trabalhador de Comida planta por 2 Hortifruti e 4 segundos; depois de 60 segundos de crescimento há 15 unidades para colher fisicamente. Selecione a horta para ligar replantio automático ou plantar manualmente um canteiro vazio.
- Árvores crescem por 180 segundos e produzem exatamente 50 Hortifruti. Permanecem produtivas até esgotar a colheita. **Cut down now / Cortar agora** permite sacrificar manualmente uma árvore: o lenhador trabalha e transporta normalmente; as frutas restantes são perdidas na primeira machadada, sem alterar madeira ou tempos. Até começar, **Cancelar corte** preserva as frutas. A ordem e as cargas sobrevivem ao save/load; outras árvores mantêm seu ciclo. Sem envelhecimento automático da produção nem copa branca. Horta e árvore abastecem **Produce / Hortifruti**.
- **Demolish / Demolir** solicita 10 segundos-base de trabalho a um construtor. Casas aguardam vagas e mudança física dos moradores antes de liberar a demolição. A base principal é protegida. Estoque do prédio removido fica em pilhas recuperáveis; materiais usados para construir não são reembolsados.
- **Cancel construction / Cancelar obra** preserva materiais entregues no chão antes da primeira martelada; depois dela, esses materiais são perdidos. Reservas e cargas em trânsito são preservadas. A demolição só pode ser cancelada antes de começar. Melhorias em andamento precisam terminar antes de demolir.
- A barra mostra somente **recursos disponíveis para gastar**. Passe o mouse em cada recurso para conferir disponível, armazenado, reservado e em transporte. Pilhas no chão e materiais entregues a obras não são dinheiro disponível.
- Interface e mensagens em **English / Português**, selecionáveis no menu e durante a partida. Preferência salva separadamente; nomes próprios e estado da vila não mudam.

### Controles

**Q/E têm zoom suave:** um toque aproxima/afasta gradualmente; segurar ajusta continuamente. Funciona durante a pausa, sem movimentar a câmera por trás de janelas ou campos de texto. A roda mantém seu comportamento e Ctrl + roda ajusta o pincel de expansão.

**Esc** fecha os painéis e cancela a seleção/colocação atual. Com tudo fechado, Esc abre **Salvar jogo / Fechar jogo / Continuar jogando**. A partida fica pausada enquanto o menu está aberto. Esc, X ou Continuar devolvem ao estado anterior de pausa. Salvar mostra a confirmação na janela; Fechar jogo encerra o aplicativo.

WASD move a câmera; botão do meio arrasta. **E aproxima, Q afasta**, e a roda continua funcionando. **Shift + clique** mantém a colocação para repetir prédios, hortas e expansões. Cada clique válido cria um pedido; Esc ou botão direito cancela o modo. Home/Centrar retorna à vista inicial; Espaço pausa. Modais e campos de texto bloqueiam atalhos do mapa. A câmera permanece disponível durante a pausa.

Habitantes abre a distribuição de trabalho. Vila abre expansão, evolução, expedição e planos. Salve em **Vila → Planos / salvar**; há salvamento automático a cada dois minutos de execução ativa. Continue pelo menu inicial.

### Salvamento e compatibilidade

Esta versão usa `user://civilization_v005.save`, com cópia `.bak`. Saves V0.0.4 permanecem em `civilization_v004.save` e não são convertidos: comece uma nova partida na V0.0.5. A V0.0.5.1 carrega partidas da V0.0.5; hortas já existentes continuam plantando, colhendo e replantando mesmo com depósito nível 1. O carregamento preserva estoques, cargas, materiais de obras, demolição, mudanças de residência, ciclos das hortas/árvores e ordens de corte. A preferência de idioma fica em `language.cfg`.

### Arte e interface

Sprites existentes de solo, cenoura/repolho, cercas, ferramentas, madeira e pedra foram reaproveitados por recortes 16×16, sem alterar as folhas originais. Novas composições de Hortifruti: ícone 32×32 e pilha 16×16 RGBA. Nearest, sem suavização; pivô das pilhas (8,12). Personagens preservam quadros 32×32, identidade visual, animações e coroa. O tronco bloqueia apenas sua célula; a copa reserva área de construção.

Interface adaptável, rolagem em listas/painéis, referência de 1280×720 e janela ajustada à área útil do monitor. O pacote Windows inclui o binário local Godot 4.7.2 para executar o `.pck` sem instalação; por conter também o editor, é maior que uma exportação release otimizada. Avisos do motor estão junto ao pacote.

### Validação

Testes da V0.0.5.1: regras e migração (34), corte e limites (9), expansão em todas as bordas e coordenadas negativas (48), avisos e traduções (18), arraste com eventos reais em três zooms (73), cliques nos balões e corte (7). Regressões: V005 (68), bordas/hortas (19), UI V005 (72), pincel (43), construção na expansão (10), V004 (44), IA (31), interface adaptável (461). Capturas de conferência visual em `Tests/v0051_*.png` (não distribuídas no Git).

O empacotador `Tests/package_v0051.py` gera o jogo e o projeto a partir do commit, testa o executável com horta, assets, corte, expansão, idioma e save/load e verifica a integridade dos arquivos ZIP.

Para executar uma suíte: `godot --headless --path . --script res://Tests/test_v005.gd`. Para capturas reais, execute a suíte de UI sem `--headless`. Arquivos V001/V002 e planos anteriores são históricos.

Famílias, comércio, dinheiro, outras ilhas, animais, pesca, refeições, água, sementes e estações permanecem fora desta versão.

Propostas futuras da V0.0.6 permanecem separadas e não foram implementadas nesta entrega.
