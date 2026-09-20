# Validação V0.0.6 — 20/09/2026

## Escopo entregue

Menu centralizado e editável, cenário de apresentação sem simulação da vila, cinco ilhas independentes, miniaturas geradas do estado salvo, importação V005, preferências de áudio/vídeo, inglês/português e quatro músicas contínuas. Online permanece desativado. O escopo futuro V0.0.6.1 não foi incluído.

## Verificações executadas

| Suíte | Resultado |
| --- | --- |
| `test_v006.gd` | 461 verificações, zero falhas: cinco ilhas com progresso/imagens diferentes, nomes, IDs, manual/autosave, limite, exclusão, importação idempotente, corrupção, falhas de gravação e publicação, volume/vídeo e 100 rodadas embaralhadas |
| `test_v006_recovery.gd` | 13 verificações, zero falhas: recuperação de catálogo, cópia do save real, leitura preservada, volume recarregado e timeout real de 15 segundos com árvore inteira pausada |
| `test_v006_ui.gd` | 35 verificações, zero falhas: cliques, cinco ilhas visíveis, nomes longos, idiomas, botões internos traduzidos, configurações sem corte, foco/ações de teclado, Online inativo, continuidade e retomada do áudio |
| `test_v006_audio.gd` | Quatro originais completos e começo da rodada seguinte renderizados pelo motor de áudio, sem faixa repetida na fronteira |
| `test_v006_music_live.gd` | 170 segundos reais pelo dispositivo WASAPI, sequência 3 → 4 → 1 → 2 → 3; captura de áudio superior a 160 segundos, mais de 99% das amostras audíveis; maior trecho próximo de zero: 1,50 ms, incluindo inicialização |
| `test_v005.gd` | 68 verificações, zero falhas |
| `test_v0051.gd` | 34 verificações, zero falhas |
| `test_site_clearance.gd` / `test_site_clearance_edges.gd` | 23 + 17 verificações, zero falhas |
| `test_v005_ui.gd` | 74 verificações, zero falhas |
| `test_responsive_ui.gd` | 462 verificações, zero falhas, em modo sem janela |
| `test_v006_portable.gd` | Versão, quatro músicas, save/load da ilha ativa, hortas, terreno, camadas, zoom, corte, construção e retirada de materiais passaram no projeto |

As telas de menu, cinco ilhas, configurações e confirmação de vídeo foram capturadas e inspecionadas. A execução visual usou o renderizador de compatibilidade e a GPU NVIDIA. Os testes usam diretórios de usuário isolados; a importação do save real foi feita a partir de `Tests/user_diagnostic.save`, sem modificar o original.

A prévia das transições, contendo trechos das quatro faixas, foi ouvida pelo usuário, que confirmou que estavam suaves. O ambiente do agente não suporta escuta de áudio: a análise restante usou decodificação integral, captura nativa e medidas de sinal. Não houve geração nem alteração dos quatro OGGs originais.

Ao investigar a queixa de som intermitente, foi identificada uma fonte provável: as instâncias temporárias de testes também tocavam e encerravam a música. O lançador e o empacotador agora silenciam essas instâncias. O jogo tem um reprodutor persistente, transição nativa agendada antes do fim e retomada após término inesperado, testada por interrupção simulada.

## Decisões e limites

- A resolução selecionada é a da janela, limitada à área útil. Tela cheia usa a resolução nativa do monitor; a interface explica isso. A reversão restaura tamanho, modo e posição anteriores.
- As miniaturas são compostas das texturas e dados salvos, sem instanciar cinco simulações ou incluir HUD.
- Os eventos de navegação foram simulados no motor; não houve teste com controle físico.
- Algumas execuções sem janela emitiram avisos de encerramento do motor sobre referências de áudio. A execução visual e a captura WASAPI concluíram sem esses avisos. O ambiente também emite aviso de certificados do Windows; o jogo não usa rede nesta versão.

## Pacotes

`Tests/package_v006.py` usa um snapshot do commit, executa novamente a suíte portátil no executável exportado e verifica o CRC dos ZIPs Windows e Projeto. Uma falha impede a distribuição. O código da revisão consta no `LEIA-ME.txt` do pacote. Alterações externas ao escopo, incluindo exclusões locais de animais e edições locais do mapa, são preservadas fora do commit e da distribuição.
