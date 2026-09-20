# Correção de continuidade da música — 20/09/2026

O controle anterior programava uma troca por atualização do jogo. Sem novas atualizações, a fila se esgotava após a faixa já agendada. O teste reproduziu **9,17 segundos finais de silêncio** em 90 segundos de áudio, mesmo com o tocador informando `playing=true` e mantendo o índice da última faixa. Assim, o sinal `finished` sozinho não recuperava esse estado. Isso demonstra uma causa possível da queixa; não estabelece qual interrupção ocorreu na sessão do usuário.

Cada faixa agora possui uma sucessora automática no motor de áudio. O embaralhamento continua funcionando durante a execução normal; quando carregamentos ou suspensão da janela impedem atualizações, a sequência de segurança continua tocando. Uma parada explícita do tocador, que não emite `finished`, é recuperada na próxima atualização. Volume e silêncio definidos pelo jogador são preservados.

## Verificação

- `test_music_resilience.gd`: reproduz a falha anterior e renderiza 170 segundos das quatro músicas com a correção, sem chamar o agendador durante a reprodução. Verifica também parada forçada, volume zero e pausa. **14.652 verificações, zero falhas; maior sequência próxima de zero: 0,046 ms.**
- `test_v006_audio.gd`: quatro músicas completas e transição para a rodada seguinte; ordem sem repetição na fronteira passou.
- `test_v006_music_live.gd`: **170 segundos pelo dispositivo WASAPI**, incluindo pausa da árvore durante uma transição e parada forçada aos 90 segundos. Cinco inícios de faixa; recuperação única; maior trecho próximo de zero **13,11 ms**, na interrupção provocada. Captura superior a 160 segundos e mais de 99% das amostras audíveis. Zero falhas.
- `test_v006_ui.gd`: **35 verificações, zero falhas**, incluindo o mesmo reprodutor persistindo ao entrar na partida e voltar ao menu, além de configurações e retomada após término inesperado.
- O teste ao vivo usa um prazo de 195 segundos. O prazo padrão do lançador era 120 segundos, insuficiente para concluir a captura de 170 segundos. `CIVIZ_TEST_TIMEOUT` permite um prazo explícito para esse teste; o padrão das demais suítes permanece igual.

Os OGGs originais e a transição já aprovada pelo usuário permanecem intactos. Os testes medem o sinal, sem alegar escuta humana. A sequência automática usa a [API de avanço de faixas do Godot](https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html#class-audiostreaminteractive-method-set-clip-auto-advance).

## Distribuição

`CIVIZ_PACKAGE_SUFFIX=-Audio` produz `Civiz-Imperium-V0.0.6-Audio-Windows.zip` e o ZIP correspondente do projeto, com teste do executável e verificação de integridade. Esse pacote de correção fica separado da distribuição anterior e não representa a entrega da V0.0.6.1, ainda em desenvolvimento.
