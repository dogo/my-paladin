# My Paladin

Repositório: [dogo/my-paladin](https://github.com/dogo/my-paladin).

Companion para Retribution PvE em **WoW: Forever 1.60.1**, cliente em inglês. Ambiente informado: build **70938**, servidor PvE. Versão **0.4.2**. O usuário confirmou por imagem o painel compacto da 0.3, com bênção Might e aura Retribution detectadas. A janela de configurações e o novo aviso de selo em combate ainda precisam de validação no cliente.

## Correção de nome na 0.4.2

O nome exibido passa a ser **My Paladin**. Os identificadores internos `MyPalladin`, `MyPalladinDB` e `MYPALLADIN`, a pasta instalada e os nomes das unidades `mypalladin-guide-check` são mantidos por compatibilidade com as configurações existentes. O caminho local `my-palladin` também permanece para preservar o agendamento. O comando `/mp` continua igual; não renomeie a pasta instalada ou os arquivos de SavedVariables nesta atualização.

## Novidades da 0.4.1: aviso de selo durante a luta

O aviso tem **ícone e nome completo**, aparece perto do centro da tela e funciona com o painel `/mp` fechado. Quando não há selo ativo, mostra **Seal missing**; ao aplicar um selo pela sua barra de ações, desaparece. Volta a aparecer a cada remoção ou expiração detectada, inclusive durante combate. A atualização usa os eventos de buff, sem um contador fixo de 30 segundos, pois o selo também pode sair antes desse prazo.

Arraste o aviso quando estiver visível fora de combate para mudar sua posição. Durante a luta, ele deixa passar os cliques. O antigo botão de selo dentro do painel foi removido. Use sua tecla habitual para reaplicar o selo.

Se o jogo restringir a leitura durante combate, o aviso fica cinza com **Check seal / Status restricted**; falhas de acesso mostram **Status unavailable**. Esses estados não afirmam que o selo acabou. Fora de combate, dados inacessíveis não geram esse lembrete. Não há lançamento automático nem tentativa de contornar as restrições da API.

## Configurações por perfil (0.4)

Abra **Settings** no painel ou use `/mp settings`. Escolha Leveling, Dungeon ou Raid: a seleção também ativa o perfil, e cada um salva suas próprias preferências para este personagem:

- Painel compacto ou expandido.
- Destaque de buffs ausentes. Desativar mantém os estados do painel em cinza e desliga o aviso independente de selo para esse perfil.
- Alerta de mana ativado/desativado e limite de 0 a 100%, ajustado em passos de 5. O padrão continua 20%; o alerta dispara abaixo do limite, quando os valores estão acessíveis.
- Quais cooldowns da lista do perfil aparecem. Habilidades não aprendidas continuam ocultas mesmo se marcadas.
- Quais lembretes entram na preparação e se a lista aparece no painel expandido. Nenhum item marcado oculta a seção; o modo compacto mantém a lista oculta.

As alterações são aplicadas imediatamente, sem botão de salvar, e persistem após `/reload` ou saída normal do jogo. A migração preserva o perfil ativo e copia a preferência antiga de compacto para os três perfis; depois disso, cada preferência é independente. Dados salvos inválidos recuperam os padrões sem apagar os outros campos do personagem.

## Qual selo usar

O aviso independente mostra o ícone e o nome completo do selo base recomendado. Aplique pela sua barra de ações, inclusive em combate:

- Sem Command aprendido: **Seal of Righteousness**.
- Com Command aprendido e arma de duas mãos com velocidade base a partir de aproximadamente 2,8s: **Seal of Command**.
- Com arma de uma mão, duas mãos mais rápida, ou Holy Shock aprendido: **Seal of Righteousness**.

Esse critério inicial segue a [orientação de selos do guia](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps), que apresenta o corte de velocidade como aproximado. Não é uma simulação de dano por equipamento. Só recomenda habilidades aprendidas. Se faltarem dados da arma, usa Righteousness como fallback; sem nenhum dos dois selos aprendido, não mostra o aviso.

A velocidade vem do tooltip em inglês da arma equipada, não da velocidade de ataque modificada por buffs. A seleção é atualizada fora de combate, ao aprender habilidades ou trocar equipamento; durante combate, preserva a última referência. Se o addon carregar no meio da luta sem referência anterior, usa um selo aprendido disponível (Righteousness como fallback quando ambos estão aprendidos), sem consultar a arma; ao sair de combate, recalcula a recomendação. Qualquer um dos sete selos ativos oculta o aviso, para não interromper Crusader ou o consumo de ecos com outro selo.

## Novidades da 0.3

- Painel compacto por padrão; **Expand/Compact** ou `/mp compact` alterna o modo. Desde a 0.4, a preferência fica salva por personagem e perfil.
- Habilidades não aprendidas são ocultadas; o painel se ajusta à quantidade exibida e atualiza ao aprender habilidades.
- Selo, bênção e aura do jogador aparecem em três indicadores: verde para ativo, laranja para bênção/aura ausente e cinza para **Restricted/Unavailable**. Desde a 0.4.1, a ausência de selo fica cinza no painel e ganha o aviso independente na tela. A leitura verifica a restrição do spell antes da consulta; dados inacessíveis não geram aviso de buff ausente. Não reutiliza o último estado conhecido durante combate.
- Mana mostra porcentagem e muda para laranja abaixo do limite configurado, quando o alerta está ativado e os valores permitem cálculo. Com valores protegidos, mantém a barra nativa e o texto **Mana**, sem tentar calcular alertas. O padrão de 20% é uma escolha inicial do addon, não uma regra extraída do guia.

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

Com o jogo fechado, copie a pasta **MyPalladin** deste projeto para a pasta `Interface/AddOns` da sua instalação de Forever. O caminho final deve terminar em `Interface/AddOns/MyPalladin/MyPalladin.toc`, sem uma pasta extra entre elas. Abra o jogo e habilite **My Paladin** na lista de addons.

Nesta máquina, a instalação que contém `Wow.exe` está em `/home/dogo/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_`. A pasta semelhante em `Faugus/default` foi o destino inicial incorreto: instalar lá não fazia o addon aparecer na lista do jogo.

O manifesto usa Interface **16001**, com verificação em tempo de execução. A correspondência precisa ser confirmada no seu cliente: `/run print(GetBuildInfo())` mostra a versão, build, data e Interface.

Comandos:

```text
/mp            Abre ou fecha o painel
/mp leveling   Ativa o perfil Leveling
/mp dungeon    Ativa o perfil Dungeon
/mp raid       Ativa o perfil Raid
/mp compact    Alterna entre painel compacto e completo
/mp settings   Abre ou fecha as configurações do perfil
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

Exibe cooldowns usando objetos de duração nativos, sem calcular uma próxima ação a partir de valores protegidos de combate. Se a API de cooldown não estiver disponível, mostra **Cooldown unavailable**. Buffs inacessíveis mostram **Restricted/Unavailable**. Ainda não acompanha os ecos de Unsealed Wrath; os lembretes de preparação são textos por perfil. O aviso de selo funciona separado do painel e orienta reaplicar pela barra de ações; dados restritos não permitem confirmar a ausência. Não altera talentos, equipamento ou teclas.

O número de Interface e as APIs foram pesquisados. O painel carregou na instalação correta, conforme imagem do usuário. Validar ranks das habilidades, exibição de cooldowns/mana durante combate, troca de perfil e persistência após `/reload` na build 70938.

## Verificação local

Sem dependências externas:

```sh
luajit tests/profiles_test.lua
luajit tests/player_state_test.lua
luajit tests/profile_settings_test.lua
python -m unittest discover -s tests -p 'test_*.py'
```

Os testes Lua cobrem migração e recuperação de configurações inválidas, persistência e isolamento entre perfis/personagens, callbacks da janela Settings, seleção de habilidades/lembretes, layout vazio, atualização de buffs ao entrar/sair de combate, distinção entre ausente e restrito, falhas das APIs, limiar de mana configurável e encaminhamento de valores opacos aos widgets. A recomendação de selo cobre armas rápidas/lentas/de uma mão, Holy Shock, dados ausentes e preservação da referência em combate. O aviso cobre três ciclos de remoção/reaplicação em combate com o painel fechado, outros selos ativos, dados restritos/indisponíveis, desativação por perfil e reload em combate. A simulação confere que o addon não cria botões de lançamento; ainda é necessário validar os eventos e as permissões no jogo.

Para validar a 0.4: use `/reload` e `/mp settings`. Em Dungeon, altere o limite de mana e desmarque uma habilidade aprendida; em Leveling, confira que essas preferências continuam como antes. Volte a Dungeon e confirme os valores; faça outro `/reload` e confirme a persistência. Expanda o painel para conferir a seleção de lembretes e a opção de ocultar a preparação.

Para validar o aviso da 0.4.1, feche o painel com `/mp` e fique sem selo. O ícone com **Seal missing** deve aparecer; aplique o selo pela sua tecla para ocultá-lo. Entre em combate e repita o ciclo, deixando expirar ou consumindo o selo. O aviso deve voltar após cada remoção, sem abrir o painel. Se aparecer **Check seal / Status restricted**, registre esse resultado: nessa build a API não está permitindo confirmar o estado durante a luta. Confira também o arraste fora de combate e se o aviso deixa passar cliques durante combate.

Os testes do monitor usam fixtures HTML representativas e respostas simuladas: extração de subseções, rejeição de bloqueios, links adicionais, primeira captura, diferenças persistentes, aceitação manual, notificações e preservação após erros. A primeira consulta real extraiu o markup dos oito artigos; ele inclui as abas e os payloads de talentos disponíveis no HTML, mas não comprova o funcionamento de todos os widgets interativos.

Pesquisa: [guia Wowhead](docs/guia-wowhead.md), [inventário de cobertura e limites](docs/cobertura-guia.md) e [API/compatibilidade](docs/addon-api.md).
