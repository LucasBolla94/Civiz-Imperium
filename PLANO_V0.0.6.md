# Civiz Imperium — Plano V0.0.6

- Revisão compartilhada: **08**.
- Par: [ASSETS_V0.0.6.md](ASSETS_V0.0.6.md).
- Estado: **planejamento aberto; nenhuma implementação autorizada nesta discussão**.

## Resumo da atualização solicitada

- Reformular a tela inicial com boa legibilidade e estética coerente com o jogo.
- Mostrar uma ilha viva ao fundo; título independente e editável.
- Permitir até cinco partidas independentes, cada uma com ilha e progresso próprios.
- Oferecer configurações de volume de música, resolução, tela cheia e janela; manter inglês e português.
- Adicionar música, ainda sem faixas selecionadas.
- Online adiado explicitamente: não implementar nesta versão. Priorizar o jogo local.

Esses pedidos não aprovam automaticamente cada sugestão de interface ou escopo multiplayer. Esta versão permanece em planejamento; não foi implementada.

## Decisões pendentes — discutir uma por vez

| Tema | Decisão necessária | Sugestão para discussão, não aprovada |
|---|---|---|
| Entrada Online no menu | Decidido: visível e desativada, sem permitir clique | Modo online permanece fora desta versão |
| Partidas | Quais informações mostrar e se o jogador pode nomear/renomear ilhas? | Nome, imagem da ilha, população e último salvamento |
| Cinco espaços ocupados | Como excluir uma partida e abrir espaço? | Exclusão explícita com confirmação, sem sobrescrita automática |
| Partida antiga | Como importar o save único atual? | Importar para espaço livre mantendo cópia original |
| Menu | Aprovar composição e navegação final | Título e botões de um lado, ilha visível do outro; Jogar abre as partidas |
| Música | Estilo, origem das faixas e onde tocar | Música instrumental calma no menu; decidir separadamente música durante a partida |
| Configurações extras | Volume de efeitos e outros controles entram? | Separar música e efeitos; lembrar preferências ao reabrir |
| Vídeo | Comportamento ao aplicar resolução ou modo | Confirmar a mudança e reverter automaticamente se não houver resposta |

## Intenção registrada

O usuário propôs uma tela inicial para visualizar até cinco partidas salvas independentes, cada uma com sua própria ilha e progresso. São cinco civilizações diferentes, não cinco pontos de salvamento da mesma partida. A intenção inicial de começar o online foi posteriormente adiada pelo usuário; sua visão futura está registrada em seção própria.

## Situação observada

A tela inicial atual já oferece fundar, continuar, sair e selecionar idioma. O salvamento usa um caminho único. A proposta exige evoluir essa tela e separar a identidade e os dados de cada partida, incluindo salvamento automático, para evitar sobrescrever outra ilha. Não se trata de criar do zero um menu inexistente.

## Propostas para discutir

- Exibir cinco espaços de partida; os ocupados permitem continuar, os vazios permitem começar uma ilha.
- Mostrar nome da ilha, progresso e último salvamento para facilitar a escolha. Campos e apresentação ainda não aprovados.
- Definir criação, nomeação, exclusão e comportamento quando os cinco espaços estiverem ocupados. Não sobrescrever partidas silenciosamente.
- Definir migração do salvamento atual, preservando o arquivo original.
- Manter inglês principal e português disponível; reaproveitar tema e assets existentes.

## Online — futuro, fora da V0.0.6

Decisão do usuário: desenvolver primeiro o jogo local e deixar o online para depois. A visão futura é um servidor dedicado em uma VPS Linux, com jogadores conectados a um mundo compartilhado, cada um administrando sua própria vila e podendo interagir com os demais futuramente. Não é cooperação de todos na mesma vila.

Não implementar rede, servidor, contas, hospedagem ou interações multiplayer nesta versão. Não exigir decisões de arquitetura online para concluir o menu e as partidas locais. **Aprovado:** exibir a opção Online no menu principal, desativada e sem permitir clique ou ativação por teclado/controle. Ela não abre outra tela nem inicia conexão. Apresentar visualmente o estado indisponível, mantendo o rótulo legível; uma indicação curta como “Em breve” é sugestão de texto, não promessa de data. Os cinco espaços locais não definem limites de vilas ou personagens online.
## Limites

Não modificar o jogo durante o planejamento. Não importar sugestões pendentes da V0.0.5.1 como aprovadas. Acrescentar decisões conforme a discussão e manter o documento de assets sincronizado, contendo somente encomendas necessárias após verificar o material existente.

## Direção de interface solicitada

O usuário pediu uma tela inicial bonita, com boa experiência de uso e acesso a configurações. Preservar a temática visual do jogo e priorizar navegação compreensível.

Proposta de organização, ainda para discussão: entrada principal com Jogar, Online, Configurações e Sair; Jogar abre os cinco espaços de ilhas. Avaliar um fundo com a ilha e movimento discreto, reutilizando os assets existentes. Não apresentar Online como disponível antes de existir funcionalidade real.

Configurações solicitadas: volume da música, escolha de resolução e alternância entre tela cheia e modo janela. O usuário também quer adicionar música. Idioma inglês/português permanece. Faixas, origem/licença, quantidade e direção musical ainda não definidas; não encomendar áudio sem especificação. Volume de efeitos, acessibilidade, composição final e animações continuam propostas.

## Proposta de experiência completa — para avaliar

- Menu principal: título legível, ilha ao fundo e botões consistentes com a arte do jogo. Animação discreta sem prejudicar leitura. Jogar abre a seleção de partidas; Configurações abre um painel com retorno evidente. Online depende da definição funcional.
- Partidas: cinco cartões, com nome da ilha e dados suficientes para reconhecer o progresso. Espaço vazio oferece Nova ilha; ocupado oferece Continuar. Exclusão separada da ação principal, com confirmação; nunca substituir uma ilha para criar outra sem decisão explícita.
- Áudio: controle de música com resposta imediata e valor visível; sugerir volume de efeitos separado. Persistir preferências entre sessões. Evitar reiniciar a faixa em cada mudança de painel.
- Tela: opções suportadas pelo dispositivo, rótulos simples Janela/Tela cheia. Propor aplicação com confirmação temporizada e reversão automática se a imagem ficar inutilizável. Manter botões acessíveis nas resoluções suportadas.
- Configurações comuns ao aplicativo; progresso separado por ilha. Salvamento manual e automático devem respeitar a partida ativa. Preservar salvamento anterior durante migração.
- Inglês principal e português, incluindo novos botões, avisos e configurações. Navegação e foco visíveis, sem depender apenas de cor ou de passar o mouse.

Antes de fechar a versão, decidir apresentação principal, informações das partidas, exclusão/migração e música. O modo online está fora do escopo; sua opção visível e desativada no menu já está aprovada. Validar isolamento das cinco partidas, persistência das configurações, troca de idioma, mudança/reversão de vídeo e navegação. Nenhuma dessas verificações foi executada nesta etapa de planejamento.

## Refinamento visual e nome

Aprovado pelo usuário: ilha viva ao fundo do menu. A aprovação não fecha a composição inteira. Como refinamento proposto, concentrar título e navegação em uma área de leitura tranquila, deixando a ilha visível; usar movimento ambiental discreto e evitar simular progresso de uma partida salva no fundo. A cena de apresentação não deve consumir recursos ou alterar saves.

Grafia verificada por solicitação do usuário: **Civiz Imperium**, com Z. O menu atual escreve “C I V I Z” e “I M P E R I U M”; project.godot também registra Civiz Imperium. Usar essa referência escrita, mantendo o nome editável e separado do fundo.

## Aprovado — título independente do fundo

O nome do jogo deve aparecer como elemento separado da imagem/cena de fundo, nunca gravado na arte da ilha. Preferir texto editável com estilo consistente com o jogo e nome centralizado em uma única configuração. Uma futura alteração do nome não deve exigir regenerar a imagem, reconstruir o menu ou alterar a identidade dos salvamentos. Não criar logotipo rasterizado nesta etapa.

A grafia foi conferida no menu e na configuração do projeto. Não renomear a marca a partir de variações da transcrição de voz.
