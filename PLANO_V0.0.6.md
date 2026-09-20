# Civiz Imperium — Plano V0.0.6

- Versão: **0.0.6**.
- Revisão compartilhada: **19**.
- Par: [ASSETS_V0.0.6.md](ASSETS_V0.0.6.md).
- Estado: **implementação concluída; validação e distribuição registradas abaixo**. Escopo aprovado na revisão 18.

## Objetivo e limites

Reformular a entrada do jogo: menu bonito e fácil de usar, cinco partidas locais independentes, configurações de áudio/vídeo e trilha contínua. Implementar o escopo abaixo. Preservar mecânicas e custos do jogo existente; não importar propostas pendentes da V0.0.5.1. A revisão 18 encerrou o planejamento; a revisão 19 registra a implementação.

A grafia conferida no menu e em project.godot é **Civiz Imperium**, com Z.

## 1. Menu principal

- Título e botões inicialmente **no centro**, sobre uma ilha viva ao fundo. A sugestão anterior de alinhamento à esquerda foi substituída.
- Entradas: Jogar, Online, Configurações e Sair. Jogar abre as cinco partidas; Configurações abre controles com retorno claro.
- Fundo, título e botões são elementos separados. O nome é texto editável, não gravado na imagem. Posição, alinhamento e espaçamento devem ser fáceis de alterar no editor sem refazer arte ou lógica. Isso é flexibilidade de desenvolvimento, não personalização pelo jogador.
- Reutilizar a temática e os assets existentes. Criar movimento ambiental discreto para dar vida à ilha sem atrapalhar leitura. A cena de apresentação não altera saves, não consome recursos da vila e não avança uma partida real.
- Online fica visível, legível, desativado e sem ação por mouse, teclado ou controle. Não abre outra tela e não inicia conexão.
- Manter navegação compreensível, botões acessíveis e layout adaptado às resoluções suportadas. Não esconder informação essencial apenas em hover ou cor.

## 2. Cinco partidas independentes

São até cinco civilizações/ilhas diferentes, não cinco checkpoints de uma única partida. Cada espaço ocupado oferece continuar aquela partida; um vazio permite criar uma nova e escolher seu nome.

Cada partida deve mostrar:

1. Nome escolhido pelo jogador.
2. Pequena imagem da própria ilha salva.
3. Quantidade de habitantes.
4. Nível da base central, usando a progressão existente, sem inventar novo sistema de níveis.

Dados e imagem pertencem à mesma partida. Identidade interna estável, independente do nome, separa arquivos, progresso e imagens. Salvamento manual e automático sempre gravam na partida ativa, nunca em outra ilha. Capturar/atualizar miniatura sem elementos de interface cobrindo a ilha; não inventar progresso nem carregar todas as ilhas como simulações ativas para mostrar o menu.

Quando os cinco espaços estiverem ocupados, o jogador escolhe uma partida para apagar antes de criar outra. A exclusão exige confirmação com nome da ilha e aviso de perda do progresso. Cancelar preserva tudo; confirmar remove apenas a partida escolhida e libera seu espaço. Separar apagar de continuar; nunca sobrescrever automaticamente.

Renomeação posterior, novos modos de mundo e informações adicionais como data do último salvamento ficam fora deste escopo. Ilhas independentes não implicam promessa de geração procedural nova.

## 3. Importar o salvamento atual

A versão examinada tinha menu com iniciar/continuar e um caminho único de salvamento. Verificar a implementação atual antes de alterá-la, pois outra IA pode ter atualizado o projeto.

Importar automaticamente a partida antiga para um espaço livre, preservando progresso. Manter o original como proteção e marcar a migração somente após validar leitura do novo salvamento. Não importar novamente a cada abertura, nem recriar a partida antiga depois de o jogador excluir a importada deliberadamente.

Se não houver espaço ou o arquivo não puder ser lido, preservar os dados e informar o problema. Nunca substituir outra ilha ou apagar o original para contornar falha.

Detalhes técnicos de formulário podem ser resolvidos de forma conservadora: nome não vazio com validação clara; nome neutro e localizado para partida importada sem nome. Isso não autoriza exigir uma decisão de gameplay nova ou modificar o progresso.

## 4. Configurações

- Duas barras independentes: Música / Music e Efeitos sonoros / Sound effects. Zerar uma não altera a outra.
- Escolha de resolução compatível com o dispositivo e alternância entre tela cheia e janela.
- Inglês principal e português disponível, incluindo todos os novos textos, estados vazios, erros e confirmações.
- Preferências pertencem ao aplicativo, não à ilha; persistir os valores confirmados entre sessões. Aplicar volume imediatamente, com valor legível.
- Ao alterar resolução, pedir confirmação com contagem de **15 segundos**. Confirmar mantém a nova; voltar ou deixar o prazo terminar restaura a anterior. Não salvar configuração provisória como definitiva. O temporizador independe da simulação da vila. Se resolução e modo forem aplicados juntos, restaurar o conjunto anterior em caso de reversão.

Não adicionar um pacote de opções extras ou novos efeitos sonoros só porque há uma barra de efeitos. Integrar sons existentes à categoria correta.

## 5. Música aprovada

Usar os quatro arquivos existentes, localizados nesta etapa:

- `Assets/Musics/Ambience/01.ogg`
- `Assets/Musics/Ambience/02.ogg`
- `Assets/Musics/Ambience/03.ogg`
- `Assets/Musics/Ambience/04.ogg`

Tocar continuamente, uma faixa após a outra, em ordem embaralhada. Tocar as quatro uma vez por rodada, embaralhar novamente e impedir que a primeira da nova rodada repita a última da anterior. Não deixar uma única faixa presa em loop infinito.

A mesma trilha continua no menu e na partida. Preservar faixa e posição ao entrar na ilha, voltar ao menu e abrir painéis; não reiniciar ou duplicar reprodutores. O volume Música atua em todos esses contextos.

O usuário informou que as faixas permitem continuidade sonora. Verificar por audição na implementação as transições, evitando pausas artificiais, cortes e cliques. A existência dos arquivos foi verificada; a continuidade sonora ainda não foi testada. Não gerar trilha nova nem alterar originais sem necessidade.

## 6. Assets e implementação

O documento par contém somente encomendas de criação/adaptação. Nenhuma foi definida nesta versão: montar o menu com os recursos existentes e produzir miniaturas a partir das partidas. Não encomendar imagem com título incorporado nem ilustração separada para cada save.

Escolhas de organização interna, layout detalhado, validação de texto e composição visual podem ser resolvidas respeitando estes requisitos. Não transformar essas escolhas em novas regras de jogo. Se faltar material essencial impossível de suprir por reutilização, registrar a necessidade concreta nos dois documentos antes de ampliar a produção de assets.

## 7. Verificação exigida na entrega

- Criar cinco ilhas com nomes distintos, jogar/salvar/carregar cada uma e confirmar isolamento de progresso, imagens, habitantes e nível.
- Verificar limite de cinco, exclusão cancelada/confirmada e criação no espaço liberado, sem afetar outras partidas.
- Migrar uma cópia do save antigo; repetir abertura e testar falha de leitura sem perda ou duplicação. Não usar o único save do usuário como dado descartável de teste.
- Verificar salvamento manual e automático na ilha ativa e recuperação segura se uma gravação falhar.
- Verificar menu centralizado, capacidade de reposicionar no editor, título independente, fundo vivo sem simulação de save e Online realmente inativo.
- Conferir volumes independentes, persistência, resolução, janela/tela cheia e confirmação/reversão em quinze segundos.
- Ouvir as quatro faixas, testar fronteira entre rodadas e transições menu/partida sem reinício, sobreposição ou silêncio artificial.
- Conferir inglês/português, nomes longos, telas suportadas, foco e navegação. Fazer revisão visual e teste de uso real, além dos testes automatizados apropriados.

A IA implementadora deve relatar mudanças e verificações realmente executadas, com limitações restantes. Não declarar testes passados apenas por constarem no plano.

## Fora da versão e continuidade

Multiplayer não será implementado agora. A visão futura registrada é servidor dedicado em VPS Linux, mundo compartilhado e uma vila por jogador, com interações futuras. Isso não autoriza rede, contas, hospedagem ou integração Steam nesta entrega.

O próximo planejamento será a **V0.0.6.1**, após este fechamento. Seu escopo ainda não foi definido; não transferir propostas antigas para ele como aprovadas.

## Entrega da revisão 19

Menu editável em `Scenes/main_menu.tscn`, cinco ilhas locais por identificador estável, miniaturas do estado salvo, importação idempotente e gravação verificada antes de publicar o catálogo. Exclusão exige confirmação e preserva outras ilhas. O original V005 permanece intacto.

Áudio/vídeo e idioma são preferências do aplicativo. A seleção de resolução controla a janela, filtrada à área útil; tela cheia usa a resolução nativa do monitor, informação exibida na tela. O prazo de vídeo usa relógio real e restaura também o modo e a posição anteriores, mesmo com a árvore inteira pausada.

Música: um reprodutor persistente, quatro originais, embaralhamento sem repetição por rodada ou na fronteira. Transições são agendadas no motor de áudio, sem aguardar o fim no loop de renderização. Interrupção inesperada do reprodutor tem retomada. Instâncias de teste ficam silenciosas para não produzir falsas interrupções audíveis ao abrir e encerrar.

Verificação executada: 461 verificações de ilhas/configurações/ordem musical; 13 de recuperação, cópia do save antigo e prazo real de vídeo; testes de UI com cliques, cinco miniaturas distintas, inglês/português, nomes longos, foco, layouts e retorno ao menu; renderização dos quatro áudios completos e troca de rodada. A prévia das transições foi ouvida pelo usuário, que confirmou suavidade. Regressões de gameplay, limpeza de canteiro e interface foram executadas novamente. Detalhes consolidados em `VALIDACAO_V0.0.6.md`.

Pacotes Windows e Projeto são produzidos a partir do commit por `Tests/package_v006.py`. O teste do executável verifica versão, música, gravação na ilha ativa e mecânicas anteriores. Alterações locais não relacionadas não entram na distribuição.
