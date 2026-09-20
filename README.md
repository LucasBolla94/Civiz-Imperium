# Civiz Imperium

## Regra permanente de documentação por versão

A pedido do usuário, cada nova versão deve ter sempre dois arquivos Markdown na raiz: `PLANO_V<versão>.md` e `ASSETS_V<versão>.md`. Exemplo: `PLANO_V0.0.5.md` e `ASSETS_V0.0.5.md`. O primeiro orienta a IA que implementa o jogo; o segundo orienta a IA que produz os assets. Ambos devem ter a mesma versão, revisão de contrato, estado de escopo e links recíprocos.

Cada funcionalidade recebe um ID estável; cada asset recebe outro ID, referenciado nos dois documentos. O plano define comportamento, estados, dimensões de ocupação, integração e critérios de aceite. O documento de assets especifica cada entrega por completo: finalidade, referências reais, formato, dimensões, escala, transparência, origem/pivô, estados/animações, organização de quadros, nomes e caminhos dos arquivos e critérios visuais/técnicos de aceite. Diferenciar tamanho da imagem, ocupação no mapa e colisão. Não deixar a outra IA adivinhar parâmetros.

Decisões não tomadas ficam explicitamente pendentes; não são autorização para implementar ou produzir arte. Qualquer mudança de contrato deve atualizar os dois documentos na mesma revisão antes da execução dependente. As duas IAs seguem o contrato compartilhado; a IA de arte não redefine mecânicas, e a de implementação não altera silenciosamente dimensões ou nomes de assets. Não substituir exemplos ou arquivos originais sem necessidade definida no plano.

O documento de assets permanece separado e recebe somente pedidos de arte a criar ou adaptar, com contexto completo para a outra IA. Não adicionar fichas de reutilização ou itens “sem arte nova”: essas decisões ficam no plano do jogo. Se não houver encomendas, manter apenas o cabeçalho do documento de assets. Manter versões anteriores como histórico e atualizar o estado de entrega nos dois documentos. Não criar um terceiro plano de versão para substituir ou fragmentar esse par.

## V0.0.6.2 — Árvore de madeira plantável

Além do plantio frutífero, a Base e o **Depósito de madeira** oferecem **Plantar árvore de madeira** pelos mesmos 2 Hortifruti e a mesma área 3 × 4. O pedido é executado por **lenhadores**: eles levam a semente e plantam. A espécie cresce nos mesmos 180 segundos da frutífera, nunca produz Hortifruti e, madura, entrega **45 madeiras** direto aos lenhadores, sem precisar de **Cortar agora**. Cortada até o fim, some e libera o terreno.

A árvore frutífera não muda: 50 Hortifruti, transição automática para 30 madeiras, **Cortar agora** com perda das frutas e renovação de pomar seguem iguais. O pedido exige um depósito de madeira concluído. Evidências em `Tests/test_v0062_timber.gd`; par de documentos em `PLANO_V0.0.6.2.md` e `ASSETS_V0.0.6.2.md`.

## V0.0.6.1 — Ouro, fundição e comércio

Ouro e fundição são liberados na base 3. Melhore o depósito de pedra para o nível 2, investigue terreno livre e abra a jazida revelada. Aloque mineiros no posto de ouro, fundidores e transportadores em **Habitantes**. Cada barra consome cinco minérios e duas madeiras; transportadores levam os insumos e guardam as barras no depósito geral.

O porto custa 40 madeiras, 30 pedras e cinco barras. Use **R** para girar a prévia: duas fileiras ficam em terra e três na água. O barco precisa de acesso ao mar aberto. Quando atracar, selecione o porto e **Negociar no porto**. Comprar/vender reserva o pedido; os materiais viajam fisicamente em cargas normais. O pagamento acontece uma única vez, após a entrega completa. Pedidos já confirmados mantêm o comerciante esperando depois do prazo para novos negócios.

Negócios usam o **depósito geral**, exigem transportador designado e espaço para receber. Se os materiais estiverem em outro depósito, **Levar material ao galpão** solicita transporte; confirme o negócio depois. Vendas de comida preservam três unidades por habitante. Cancelar devolve a carga ainda não negociada. Ouro, visitas, pedidos e devoluções são independentes nas cinco ilhas.

A interface inclui emblema original, fontes Atkinson Hyperlegible/Cinzel, equipes com lista rolável e cabeçalho fixo. Prévias de construção usam o mesmo alinhamento dos prédios concluídos. **Investigar** procura jazidas; para reconstruir em terreno liberado ou após uma demolição, selecione diretamente um prédio em **Construir**. Investigar novamente não renova uma jazida esgotada.

Estado e evidências: `VALIDACAO_V0.0.6.1.md`. Pacotes produzidos por `Tests/package_v0061.py`; o fechamento da validação humana é registrado separadamente dos testes automáticos. A demonstração `Tests/demo_v0061_progression.gd` usa uma cópia local de progresso de base 3, sem criar recursos; os salvamentos pessoais de partida não são publicados no repositório.

## V0.0.6 — Cinco ilhas e uma trilha contínua

Abra `Builds/Civiz-Imperium-V0.0.6/Civiz Imperium V0.0.6.exe` ou extraia o pacote Windows mantendo o `.pck` ao lado do executável. O pacote Projeto contém o código da mesma revisão. Para editar, abra `project.godot` no Godot 4.7.2.

- **Jogar / Play** abre cinco ilhas independentes. Escolha um espaço livre e um nome de 1 a 40 caracteres. Cada ilha mostra sua imagem, habitantes e nível da base. **Continuar** e **Apagar** são ações separadas; excluir pede confirmação e libera apenas aquele espaço.
- O salvamento antigo V0.0.5/V0.0.5.1 é importado uma única vez, quando há espaço. O original permanece intacto. Excluir a ilha importada não dispara outra importação.
- **Configurações / Settings** controla Música, Efeitos sonoros, idioma, resolução em janela e tela cheia. A tela cheia usa a resolução nativa do monitor. Mudanças de vídeo têm 15 segundos reais para confirmação; cancelar ou esperar restaura tamanho, posição e modo anteriores. Preferências pertencem ao aplicativo.
- Quatro faixas de ambiente existentes tocam uma vez por rodada embaralhada, sem repetir imediatamente na mudança de rodada. Um único reprodutor permanece ativo entre menu, partida e painéis. Nenhum efeito sonoro novo foi criado.
- O menu usa uma ilha de apresentação com personagens e movimento discreto de câmera. Não executa a simulação nem altera partidas. Título, botões e fundo são nós separados em `Scenes/main_menu.tscn`; o editor permite mudar alinhamento, margens e espaçamento.

### Construção e controles preservados

Casas concluídas com vagas permitem mais habitantes, sem o antigo limite de sete. É possível marcar construções e hortas sobre **materiais soltos e habitantes**: trabalhadores transportam os materiais para células livres e os moradores saem da área antes de começar. Árvores e jazidas continuam bloqueando a colocação.

Q/E fazem zoom suave; WASD move; Home centraliza; Espaço pausa. Ctrl + roda ajusta o pincel de expansão de 1 a 9 células, com custo proporcional. Shift + arraste permite expansão contínua, incluindo o preenchimento de buracos. Esc fecha os painéis; com tudo fechado, abre o menu da partida, incluindo **Salvar e voltar ao menu**.

Hortas 2×2 exigem depósito de comida nível 2, custam 10 madeiras e 10 segundos para instalar; plantio custa 2 Hortifruti e 4 segundos. Crescem em 60 segundos e rendem 15 unidades. Hortas antigas são preservadas. Personagens caminham por cima dos canteiros. Hortifruti mantém transparência e tamanho; jazidas mantêm o asset Stone. Balões de aviso ficam à esquerda do prédio.

### Salvamento e recuperação

Salvamento manual e automático, a cada dois minutos de simulação ativa, gravam somente na ilha ativa. O diretório `user://islands_v006` guarda revisões por identificador interno, independente do nome. Cada revisão inclui progresso, miniatura sem HUD e metadados do mesmo estado. O catálogo só publica uma gravação após leitura de verificação. Uma falha preserva a revisão anterior; um catálogo danificado pode ser recuperado da cópia de segurança.

O original `user://civilization_v005.save` não é modificado pela importação. Saves V0.0.4 continuam separados e não são convertidos. No Windows, `user://` corresponde a `%APPDATA%/Godot/app_userdata/Civiz Imperium`. Preferências de áudio/vídeo ficam em `settings_v006.cfg`; idioma em `language.cfg`.

### Verificação e distribuição

As suítes V006 cobrem cinco ilhas, isolamento, nomes, imagens, exclusão, migração, corrupção, recuperação, áudio, menu e vídeo. Há capturas reais de tela em `Tests/v006_*.png` e registros de execução em `Tests/*.log`, ignorados no Git. Regressões de hortas, construção, expansão, balões e interface permanecem disponíveis.

`Tests/package_v006.py` gera os dois ZIPs a partir de um commit, testa o executável empacotado e verifica a integridade dos arquivos. O pacote Windows usa o binário local Godot 4.7.2 com os avisos de licença; inclui também o editor, por isso é maior que uma exportação release otimizada. Alterações locais não relacionadas ficam fora do pacote.

Execução de testes: `python Tests/run_godot.py --headless --script Tests/test_v006.gd`. O lançador usa uma pasta de usuário isolada e silencia suas instâncias para não interferir no jogo aberto. Testes de UI e áudio ao vivo devem rodar sem `--headless`.
