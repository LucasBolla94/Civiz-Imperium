# Civiz Imperium

## Regra permanente de documentação por versão

A pedido do usuário, cada nova versão deve ter sempre dois arquivos Markdown na raiz: `PLANO_V<versão>.md` e `ASSETS_V<versão>.md`. Exemplo: `PLANO_V0.0.5.md` e `ASSETS_V0.0.5.md`. O primeiro orienta a IA que implementa o jogo; o segundo orienta a IA que produz os assets. Ambos devem ter a mesma versão, revisão de contrato, estado de escopo e links recíprocos.

Cada funcionalidade recebe um ID estável; cada asset recebe outro ID, referenciado nos dois documentos. O plano define comportamento, estados, dimensões de ocupação, integração e critérios de aceite. O documento de assets especifica cada entrega por completo: finalidade, referências reais, formato, dimensões, escala, transparência, origem/pivô, estados/animações, organização de quadros, nomes e caminhos dos arquivos e critérios visuais/técnicos de aceite. Diferenciar tamanho da imagem, ocupação no mapa e colisão. Não deixar a outra IA adivinhar parâmetros.

Decisões não tomadas ficam explicitamente pendentes; não são autorização para implementar ou produzir arte. Qualquer mudança de contrato deve atualizar os dois documentos na mesma revisão antes da execução dependente. As duas IAs seguem o contrato compartilhado; a IA de arte não redefine mecânicas, e a de implementação não altera silenciosamente dimensões ou nomes de assets. Não substituir exemplos ou arquivos originais sem necessidade definida no plano.

O documento de assets permanece separado e recebe somente pedidos de arte a criar ou adaptar, com contexto completo para a outra IA. Não adicionar fichas de reutilização ou itens “sem arte nova”: essas decisões ficam no plano do jogo. Se não houver encomendas, manter apenas o cabeçalho do documento de assets. Manter versões anteriores como histórico e atualizar o estado de entrega nos dois documentos. Não criar um terceiro plano de versão para substituir ou fragmentar esse par.

Próxima versão em discussão: [plano V0.0.5](PLANO_V0.0.5.md) e [assets V0.0.5](ASSETS_V0.0.5.md).

Jogo 2D de construção e gestão de uma civilização em pixel art. Versão atual: **V0.0.4 — A vila ganha autonomia**.

Abra `project.godot` no Godot 4.7 e pressione F5 para entrar no menu principal.

Janela adaptável: na execução independente, o jogo escolhe um tamanho de até **1920 × 1080**, preservando a proporção e respeitando a área útil do monitor, bordas e barra de tarefas. Mudanças de monitor ou da área disponível são verificadas durante a execução; redimensionamentos manuais são respeitados. Dentro do Godot, o editor controla a janela e a configuração inicial segura é **1280 × 720**, evitando o corte causado por forçar 1920 × 1200. A interface usa uma referência de 1280 × 720, adapta-se à proporção da janela e permanece fixa ao mover a câmera. Menus reorganizam seus botões; listas usam rolagem; janelas de habitantes e fim de partida permanecem centralizadas ao redimensionar. Esc fecha a lista de habitantes.

A câmera começa com zoom leve de 10% sobre o enquadramento da área livre entre os painéis. Use **WASD** ou o botão do meio do mouse para mover, a roda para zoom e **Home / Centrar** para retornar à visão inicial. O movimento funciona durante a pausa e não acelera com a velocidade da simulação. Janelas abertas bloqueiam os comandos do mapa.

O HUD compacto reserva mais de 70% da tela para o mapa na visão inicial. A barra de construção tem 78 pixels de altura na referência de 1280 × 720; os detalhes só abrem ao selecionar uma entidade ou iniciar uma ação. **Habitantes**, no topo, abre a distribuição de profissões com todos os controles visíveis; **Vila** abre as ações da base. **Fechar** recolhe os detalhes, e **Esc** também fecha a distribuição de trabalho. As barras usam largura limitada e a câmera não muda de zoom ao abrir esses painéis.

O começo é um Rei, dois trabalhadores e uma base. Cuide de alimentação, moradia e energia; construa depósitos e oficina; receba colonos por barco; evolua para transporte especializado e produção automática. As árvores, o plantio, a expansão costeira e os três níveis da vila continuam integrados.

- Novidades, controles e balanceamento atual: [PLANO_V0.0.4.md](PLANO_V0.0.4.md)
- Guia histórico, arquitetura e validação: [PLANO_V0.0.3.md](PLANO_V0.0.3.md)
- Revisão de inteligência dos trabalhadores: [MELHORIAS_IA.md](MELHORIAS_IA.md)
- Testes novos: `Tests/test_v004.gd` e `Tests/test_v004_ui.gd`.
- Regressões: `Tests/test_v003.gd`, `Tests/test_v003_ui.gd` `Tests/playthrough_v003.gd` e `Tests/test_worker_ai.gd`.
- Capturas da versão: `Tests/v003_*.png`.
- Interface adaptável: `Tests/test_responsive_ui.gd`, com menu inicial, 12 resoluções de 640 × 360 a 3840 × 2160, incluindo ultrawide e orientação vertical, redimensionamento com janela aberta, câmera, confirmação de reinício e rolagem de uma população grande. Capturas: `Tests/responsive_720_*.png`.

Esta versão salva o progresso manualmente em **Vila → Planos / salvar**, e automaticamente a cada dois minutos enquanto a simulação roda. Use **Continuar civilização** no menu inicial para retomar. Documentos/testes V0.0.1 e V0.0.2 são históricos. Famílias e economia monetária são planos futuros, não funcionalidades atuais.

Os habitantes usam `char-1`, `char-2` e `char-3`, com aparência fixa por identidade. Parados, andando e trabalhando usam as animações correspondentes; as demais sequências fornecidas estão registradas para futuras ações de combate e movimento. Os sprites mantêm os quadros nativos de 32 × 32 e filtro sem suavização.

A coroa está em `Assets/Characters/Accessories/king_crown.svg`: pixel art de 10 × 6, com posição ajustada por quadro e espelhamento junto à cabeça. A sucessão conserva a aparência do novo Rei e transfere a coroa imediatamente. Validação específica: `Tests/test_resident_visuals.gd`; prancha ampliada dos três personagens para ambos os lados: `Tests/resident_crowns.png`.



O teste `Tests/test_window_layout.gd` valida os limites físicos e a proporção da janela em seis configurações de monitor, incluindo coordenadas negativas em múltiplos monitores. A escala lógica mantém o layout estável em telas menores; em 640 × 360 os textos também ficam menores.

Árvores: a área visual/reservada continua impedindo construções sobre a copa, mas a navegação bloqueia somente o quadrado de 16 × 16 do tronco. Coleta e busca de acesso usam os vizinhos desse quadrado. A profundidade visual usa a base do tronco; os habitantes passam atrás da copa. A madeira restante também bloqueia somente o tronco, liberado ao esgotar. Teste: Tests/test_tree_ground.gd; captura: Tests/tree_ground.png.
