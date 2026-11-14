# My Palladin

Companion para Retribution PvE em **WoW: Forever 1.60.1**, cliente em inglês. Ambiente informado: build **70938**, servidor PvE. Versão **0.3.1**. O usuário confirmou por imagem o painel compacto da 0.3, com bênção Might e aura Retribution detectadas. O novo clique de preparação e o comportamento durante combate ainda precisam de validação no cliente.

## Qual selo usar

O painel mostra o **ícone clicável**, o nome completo do selo base e o motivo da recomendação. Quando identifica que falta um selo, escreve **Apply: Seal of …**. Clique no ícone para aplicá-lo **fora de combate**. Na luta, use a habilidade pela sua barra de ações; o botão não executa lançamentos automáticos nem substitui sua rotação.

- Sem Command aprendido: **Seal of Righteousness**.
- Com Command aprendido e arma de duas mãos com velocidade base a partir de aproximadamente 2,8s: **Seal of Command**.
- Com arma de uma mão, duas mãos mais rápida, ou Holy Shock aprendido: **Seal of Righteousness**.

Esse critério inicial segue a [orientação de selos do guia](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps), que apresenta o corte de velocidade como aproximado. Não é uma simulação de dano por equipamento. Só recomenda habilidades aprendidas. Se faltarem dados da arma, usa Righteousness como fallback explícito; sem nenhum dos dois selos aprendido, desabilita o clique e orienta procurar o treinador.

A velocidade vem do tooltip em inglês da arma equipada, não da velocidade de ataque modificada por buffs. A seleção é atualizada fora de combate, ao aprender habilidades ou trocar equipamento; durante combate, preserva a última referência. **Base seal** é uma indicação de preparação, não uma ordem para interromper Crusader ou o consumo de ecos com outro selo.

## Novidades da 0.3

- Painel compacto por padrão; **Expand/Compact** ou `/mp compact` alterna o modo. A preferência fica salva por personagem junto do perfil ativo.
- Habilidades não aprendidas são ocultadas; o painel se ajusta à quantidade exibida e atualiza ao aprender habilidades.
- Selo, bênção e aura do jogador aparecem em três indicadores: verde para ativo, laranja para ausente, cinza para **Restricted/Unavailable**. A leitura verifica a restrição do spell antes da consulta; dados inacessíveis não geram aviso de buff ausente. Não reutiliza o último estado conhecido durante combate.
- Mana mostra porcentagem e muda para laranja abaixo de 20%, quando os valores permitem cálculo. Com valores protegidos, mantém a barra nativa e o texto **Mana**, sem tentar calcular alertas. O limite de 20% é uma escolha inicial do addon, não uma regra extraída do guia.

O acompanhamento considera os sete selos, as bênçãos Might/Wisdom/Kings e as seis auras descritas no guia. Reconhecer uma dessas bênçãos não confirma a atribuição ideal para o grupo. Não inclui buffs de camping equivalentes, Forbearance, ecos ou previsão da próxima habilidade.

## Perfil ativo

Escolha **Leveling**, **Dungeon** ou **Raid** nos botões do painel. A escolha fica salva por personagem e muda imediatamente os cooldowns acompanhados, o foco e os lembretes de preparação. Entrar em uma instância não sobrescreve sua escolha. O perfil não troca talentos, equipamentos, macros ou teclas.

| Perfil | Foco | Ferramentas adicionais exibidas |
| --- | --- | --- |
| Leveling | Mana entre pulls e preparação para solo | Holy Light, Divine Shield, Lay on Hands |
| Dungeon | Grupos de inimigos, controle e suporte | Cleanse, Hammer of Justice, Blessing of Protection |
| Raid | Preparação e suporte coordenado | Cleanse, Blessing of Freedom, Blessing of Protection |

Os três acompanham Judgement, Holy Strike, Hammer of Wrath, Exorcism e Consecration, quando aprendidos. A lista é um conjunto de cooldowns, não uma fila de rotação. A barra de mana usa os dados do jogador, e o nível é lido automaticamente.

As diferenças de perfil são escolhas iniciais de interface. Não representam três builds de talentos ou três rotações diferentes recomendadas pelo guia.

## Instalar

Com o jogo fechado, copie a pasta **MyPalladin** deste projeto para a pasta `Interface/AddOns` da sua instalação de Forever. O caminho final deve terminar em `Interface/AddOns/MyPalladin/MyPalladin.toc`, sem uma pasta extra entre elas. Abra o jogo e habilite **My Palladin** na lista de addons.

Nesta máquina, a instalação que contém `Wow.exe` está em `/home/dogo/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_`. A pasta semelhante em `Faugus/default` foi o destino inicial incorreto: instalar lá não fazia o addon aparecer na lista do jogo.

O manifesto usa Interface **16001**, com verificação em tempo de execução. A correspondência precisa ser confirmada no seu cliente: `/run print(GetBuildInfo())` mostra a versão, build, data e Interface.

Comandos:

```text
/mp            Abre ou fecha o painel
/mp leveling   Ativa o perfil Leveling
/mp dungeon    Ativa o perfil Dungeon
/mp raid       Ativa o perfil Raid
/mp compact    Alterna entre painel compacto e completo
```

Arraste o painel para mover. Os textos da interface e os nomes das habilidades estão em inglês.

## Manter os guias atualizados

As oito fontes principais e a data da última revisão estão em `guides.json`. O painel exibe essa data e o patch de referência. Uma consulta automática nunca muda as regras, os perfis ou a data de revisão do addon.

Para consultar agora, na raiz do projeto:

```sh
python scripts/check_guides.py
```

Leia o relatório em `.guide-monitor/report.md`. Os snapshots consultados e aceitos ficam em `.guide-monitor/state.json`; os relatórios anteriores ficam em `.guide-monitor/history/`. Esses arquivos locais não entram no Git. Saída 0 significa sem mudanças, 2 significa revisão pendente e 1 significa erro. A primeira captura exige revisão: não há snapshots HTML da pesquisa textual inicial para comparar retroativamente.

O monitor compara o corpo do artigo e as subseções extraídas, ignorando navegação, comentários e anúncios. Registra também links de guias encontrados no corpo que ainda não estejam no monitor; não percorre automaticamente todo o banco de itens/missões. Calculadoras e dados carregados apenas por JavaScript podem não ser extraídos. Bloqueios HTTP, páginas inesperadas, falhas de DNS e corpos não reconhecidos geram erro e preservam os snapshots anteriores. Mudanças continuam pendentes nas próximas consultas até serem aceitas.

Depois de revisar as fontes, ajustar o que mudou no addon e executar os testes, aceite os snapshots:

```sh
python scripts/check_guides.py --accept
```

Se a revisão corresponder a outro patch, use `--accept --patch 1.60.2`, substituindo pelo patch correto. Aceitar atualiza `guides.json` e `MyPalladin/GuideInfo.lua`; as regras continuam sob revisão humana. Reinstale os arquivos do addon para levar a nova referência ao jogo. Não use aceitação automática no timer.

O agendamento está definido em `ops/mypalladin-guide-check.service` e `.timer`, para **09:00 de America/Sao_Paulo**, com recuperação da execução perdida enquanto o gerenciador do usuário estiver desligado. As unidades usam o caminho deste workspace. Depois de instaladas em `~/.config/systemd/user`, ative no seu terminal:

```sh
systemctl --user daemon-reload
systemctl --user enable --now mypalladin-guide-check.timer
systemctl --user start mypalladin-guide-check.service
```

Para conferir o agendamento e a última execução:

```sh
systemctl --user list-timers mypalladin-guide-check.timer
journalctl --user -u mypalladin-guide-check.service -n 30
```

O serviço aceita saída 2 como resultado normal de uma checagem que encontrou mudanças. Quando houver revisão pendente ou erro, tenta mostrar uma notificação local com `notify-send`, se disponível na sessão gráfica. O resultado permanece no relatório e no journal mesmo se a notificação falhar. O timer não abre conversa, não envia mensagens a outras pessoas e não instala atualizações do addon.

Nesta máquina, o usuário ativou o timer em 14/11/2026 e iniciou a primeira consulta no terminal. A captura das **oito páginas terminou sem erros**; o conteúdo foi conferido na auditoria e aceito como referência em 14/11/2026. As próximas mudanças permanecerão pendentes de revisão. O sandbox de desenvolvimento não tem acesso direto ao systemd do usuário nem resolve o domínio do Wowhead; por isso essa validação real foi feita fora dele.

## Limites desta versão

Exibe cooldowns usando objetos de duração nativos, sem calcular uma próxima ação a partir de valores protegidos de combate. Se a API de cooldown não estiver disponível, mostra **Cooldown unavailable**. Buffs inacessíveis mostram **Restricted/Unavailable**. Ainda não acompanha os ecos de Unsealed Wrath; os lembretes de preparação são textos por perfil. O botão de selo só lança a habilidade por clique explícito fora de combate. Não altera talentos, equipamento ou teclas.

O número de Interface e as APIs foram pesquisados. O painel carregou na instalação correta, conforme imagem do usuário. Validar ranks das habilidades, exibição de cooldowns/mana durante combate, troca de perfil e persistência após `/reload` na build 70938.

## Verificação local

Sem dependências externas:

```sh
luajit tests/profiles_test.lua
luajit tests/player_state_test.lua
python -m unittest discover -s tests -p 'test_*.py'
```

Os testes Lua cobrem recuperação de configurações inválidas, persistência de perfil e modo compacto, isolamento entre personagens, habilidades aprendidas, layout vazio, atualização de buffs ao entrar/sair de combate, distinção entre ausente e restrito, falhas das APIs, limiar de mana e encaminhamento de valores opacos aos widgets. A recomendação de selo cobre armas rápidas/lentas/de uma mão, Holy Shock, dados ausentes e preservação da ação em combate. Os atributos do botão e a manutenção do handler nativo são conferidos; a simulação não comprova o lançamento real no jogo.

Para validar a 0.3.1: use `/reload`, confira o nome/ícone do selo recomendado e clique nele fora de combate. O indicador de selo deve ficar verde e **Apply** deve mudar para **Base seal**. Alterne `/mp compact` e troque a arma para conferir a recomendação. Faça uma luta usando Judgement e Holy Strike; confira os cooldowns e a barra de mana. O clique de preparação não deve lançar habilidades em combate. Durante restrições, os indicadores devem ficar cinza, sem afirmar ausência. Depois de sair do combate, devem voltar ao estado atual.

Os testes do monitor usam fixtures HTML representativas e respostas simuladas: extração de subseções, rejeição de bloqueios, links adicionais, primeira captura, diferenças persistentes, aceitação manual, notificações e preservação após erros. A primeira consulta real extraiu o markup dos oito artigos; ele inclui as abas e os payloads de talentos disponíveis no HTML, mas não comprova o funcionamento de todos os widgets interativos.

Pesquisa: [guia Wowhead](docs/guia-wowhead.md), [inventário de cobertura e limites](docs/cobertura-guia.md) e [API/compatibilidade](docs/addon-api.md).
