# Compatibilidade do futuro addon com WoW: Forever

Pesquisa em 14/11/2026. Este documento registra evidência técnica e pendências; não declara o addon compatível antes de testar no cliente do jogador.

## Ambiente informado pelo jogador

- Servidor: PvE.
- Idioma do jogo: inglês; locale exato ainda não informado.
- Versão: **1.60.1**, build **70938**.
- Instalação fornecida inicialmente: `/home/dogo/Faugus/default/drive_c/Program Files (x86)/World of Warcraft/_forever_`. Essa pasta contém addons, mas não o executável do jogo.
- Instalação correta identificada por `Wow.exe`: `/home/dogo/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_`. O addon foi reinstalado ali e o usuário confirmou o carregamento por imagem.
- Atividades: leveling, dungeons e raids, com perfil ativo selecionável.
- Nível 20 confirmado por imagem; talentos ainda não informados. O painel lê o nível no cliente.

Esses dados foram fornecidos pelo usuário. O número de Interface não foi obtido diretamente desse cliente.

## O que está confirmado

**Forever é um produto oficial da Blizzard.** O artigo oficial descreve o jogo, orienta selecionar **WoW: Forever** no Battle.net e informa que o acesso está incluído na assinatura/tempo de jogo. O visual e o mundo inspirados no WoW original não comprovam compatibilidade com a API de Classic Era. [Blizzard: Return to Azeroth](https://news.blizzard.com/en-gb/article/24315643/return-to-azeroth-in-world-of-warcraft-forever).

**Existem recursos nativos que devemos verificar antes de duplicar.** Nas notas oficiais do beta, a Blizzard descreve o Cooldown Manager, sua configuração e limitações; o histórico também registra mudanças no rastreamento de ranks. Isso confirma o recurso naquele histórico, sem garantir o comportamento atual no cliente do usuário. [Blizzard: notas de desenvolvimento](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696/1).

**Dados de combate podem ter restrições importantes.** A Blizzard explica, para Midnight, que valores secretos podem ser apresentados por addons sem permitir que o código conheça ou calcule seu conteúdo. O exemplo oficial inclui debuffs e cooldowns; portanto, um recomendador que compare esses dados não pode ser considerado viável apenas porque uma função existe. Essa publicação é sobre Midnight, não uma especificação completa de Forever. [Blizzard: Combat Philosophy and Addon Disarmament](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight).

Foi localizado o [Q&A oficial de 17/09/2026](https://www.youtube.com/watch?v=Y5zzSMSVhRo), indicado por fontes comunitárias como a confirmação da abordagem moderna para Forever. O acesso disponível não expôs transcrição; não tratei o resumo comunitário como documentação primária verificada.

## O que falta confirmar no cliente

| Informação | Situação e próximo passo |
| --- | --- |
| Versão e build instaladas | Informadas pelo jogador: 1.60.1 (70938). Ainda sem execução local de `GetBuildInfo()`. |
| `## Interface:` do `.toc` | A versão inicial declara 16001, com verificação em tempo de execução. Esse valor ainda não foi obtido diretamente do cliente do jogador; confirmar com `GetBuildInfo()`. |
| Pasta de instalação e variante de `.toc` | Instalação em `Faugus/battlenet` confirmada pelo executável. Carregamento confirmado na pasta antiga `MyPalladin`. Em 15/11/2026, a migração para `Interface/AddOns/MyPaladin/MyPaladin.toc` foi concluída: seis arquivos iguais ao projeto, pasta antiga fora de `AddOns` e configurações de um personagem preservadas. Falta conferir o carregamento da 0.8 no jogo. |
| APIs de auras, spells, cooldowns e talentos | Confirmar presença, assinatura, eventos e permissões na build instalada. Presença não comprova que o retorno pode ser comparado durante combate. |
| Dados para sugerir a próxima habilidade | Viabilidade pendente: depende do que a API permite ler e processar em combate. |
| IDs de spells, talentos e auras | Não foram obtidos nem inventados. Precisam vir do cliente/base de Forever e ser verificados. |

O Context7 foi consultado primeiro: `resolve-library-id` para World of Warcraft e `query-docs` em `/gethe/wow-ui-source`. O trecho de documentação gerada da Blizzard, espelhado no ramo `live`, define o quarto retorno de `GetBuildInfo()` como `interfaceVersion`. Esse ramo não prova a disponibilidade ou o valor em Forever. [Código de referência: BuildDocumentation.lua](https://github.com/gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/BuildDocumentation.lua).

Após receber a build do jogador, também foi consultado o ramo **forever** do espelho da UI da Blizzard. Nele, `C_Spell.GetSpellCooldown` tem a anotação `SecretWhenCooldownsRestricted`, enquanto `C_Spell.GetSpellCooldownDuration` fornece um objeto de duração para apresentação. `C_UnitAuras.GetAuraDataByIndex` tem `SecretWhenUnitAuraRestricted`. Essas anotações justificam separar exibição de cooldowns de decisões calculadas sobre seus valores. O ramo consultado não foi identificado como uma captura exata da build 70938. Fontes: [SpellDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua), [UnitAuraDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua).

## Consequência para o escopo

Podemos discutir a interface e as regras do guia agora. Antes de implementar decisões automáticas baseadas em combate, precisamos confirmar quais entradas são acessíveis. Um painel consultável com orientações estáticas exige menos hipóteses que um recomendador dinâmico; isso é uma opção de projeto, não uma decisão já tomada pelo usuário.

Se houver distribuição, a política oficial exige addon gratuito e código visível, proíbe anúncios e pedidos de doação dentro do jogo, e permite à Blizzard desativar funcionalidades. [Blizzard: UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534).

## Primeira implementação

O addon em `MyPaladin/` usa `SavedVariablesPerCharacter` para salvar o perfil ativo e, desde a 0.3, o modo compacto. A 0.4 mantém preferências separadas em `profileSettings.leveling`, `.dungeon` e `.raid`, validando os dados salvos e migrando a preferência antiga de compacto. Usa o spellbook para obter os IDs/ranks aprendidos, sem inventar IDs das habilidades. Consulta `C_SpellBook.FindSpellBookSlotForSpell` e `GetSpellBookItemInfo`, documentadas no [ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua).

A janela Settings usa checkboxes nativos. `GetChecked` retorna booleano e `SetChecked` recebe booleano, conforme a [documentação gerada de CheckButton do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleCheckboxAPIDocumentation.lua). As preferências só filtram a apresentação e os alertas sobre dados já acessíveis; a verificação de valores secretos continua anterior a qualquer cálculo de mana. O limite padrão é 20%, configurável por perfil. A janela ainda precisa de validação visual na build 70938.

Para exibição, encaminha objetos de duração ao widget de cooldown e valores de mana ao StatusBar, sem calcular prioridades a partir deles. Não há leitura do combat log. Perfil e escolhas do usuário ficam separados desses valores de combate. APIs ausentes geram mensagens explícitas.

## Integração da 0.3

O módulo `PlayerState.lua` consulta buffs do jogador por seus nomes em inglês. A abertura opcional com Crusader também consulta o debuff do jogador no alvo. Antes de `C_UnitAuras.GetAuraDataBySpellName`, exige uma resposta pública e booleana de `C_Secrets.ShouldSpellAuraBeSecret`. Quando o spell está restrito, não faz a consulta. Sem a API de restrições, não afirma ausência. Para esses indicadores de presença, não é necessário inspecionar campos da aura. A contagem de ecos é lida separadamente, com validação dos campos públicos.

`RequiresNonSecretAura` pode devolver nenhum valor quando o buff é secreto; interpretar esse retorno como ausência produziria alertas falsos. Fonte primária: [predicados da UI Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua). A assinatura da consulta está no [UnitAuraDocumentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua); `ShouldSpellAuraBeSecret` também aparece na [exportação da documentação do cliente Forever build 70790](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/System-Config/C_Secrets.md). A exportação não é uma captura exata da build 70938.

Os indicadores são atualizados em `UNIT_AURA`, entrada/saída de combate e atualização do painel. A porcentagem/alerta de mana só é calculada se ambos os valores passarem por `issecretvalue` e forem números válidos. A barra nativa continua recebendo os valores originais. É necessário testar esses caminhos no cliente instalado; os testes locais simulam dados protegidos e falhas da API.

## Aviso independente de selo da 0.4.1

O antigo botão de preparação foi removido. `MyPaladinSealAlert` é um Frame comum, filho de `UIParent`, independente da visibilidade do painel. `UNIT_AURA` atualiza o estado mesmo com o painel fechado. Ausência confirmada mostra ícone/nome do selo recomendado e **Seal missing**; qualquer selo ativo oculta o aviso. Não cria botões de ação nem chama funções de lançamento. O jogador reaplica pela barra de ações, inclusive durante combate. A posição pode ser arrastada fora de combate; durante a luta o frame desativa a captura de mouse.

Não estima expiração com um contador fixo de 30 segundos. A remoção real do buff é que produz o aviso; Judgement não consome o selo no Forever. Desde a 0.8.2, dados restritos ou indisponíveis ocultam o HUD de selo antes de avaliar abertura/ecos, preservando o diagnóstico no painel e nos logs. O antigo lembrete cinza **Check seal** confundia ausência de acesso com uma instrução para reaplicar e foi removido. A consulta por nome exige uma aura pública: [UnitAuraDocumentation.lua do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua). Essa restrição impede prometer detecção exata durante todas as lutas sem validar os selos no cliente instalado.

A recomendação considera os selos e Holy Shock aprendidos. Fora de combate, consulta o item no slot 16 e `C_Item.GetItemInfoInstant`; quando necessário, lê a velocidade base no texto em inglês de `C_TooltipInfo.GetInventoryItem`. Durante combate, preserva a recomendação anterior. Ao carregar sem referência durante uma luta, resolve apenas o spellbook e usa um selo aprendido como fallback, sem consultar equipamento. Fontes: [ItemDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [TooltipInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua).

A imagem enviada da 0.3 confirmou o compacto, seis habilidades aprendidas, Might/Retribution ativos e ausência de selo indicada. O aviso independente ainda depende do teste do jogador no cliente real. Os testes locais cobrem reaplicações repetidas em combate com o painel fechado, outros selos ativos, restrições, APIs ausentes e reload durante combate.

O problema de descoberta foi reproduzido: o addon estava ausente da pasta que continha `Wow.exe`, embora existisse em `Faugus/default`. A cópia para `Faugus/battlenet` passou na verificação de presença e SHA-256. O usuário confirmou o painel em jogo por imagem, no perfil Leveling e nível 20. Isso valida descoberta/carregamento e apresentação inicial; não comprova todos os comportamentos durante combate. A execução em LuaJIT com APIs simuladas verifica a troca de perfis e o encaminhamento dos dados.

## Abertura com Crusader

`crusaderOpener` é uma preferência booleana por perfil, desligada por padrão. `/mp opener` e a janela Settings controlam a mesma preferência. A opção não classifica automaticamente um inimigo como luta longa.

`GetCrusaderStep` usa as habilidades aprendidas no spellbook e os estados públicos do selo e do alvo. Exige Crusader e Judgement e não aplica essa abertura à build com Holy Shock aprendido. Confere existência, hostilidade, morte e visibilidade do alvo; valores secretos ou APIs ausentes geram um estado de conferência. Referência: [UnitDocumentation.lua do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua).

O debuff é consultado por `Judgement of the Crusader`, em `target`, com filtro `HARMFUL|PLAYER`. `GetBuffStatus` mantém as verificações de segredo antes da consulta e não inspeciona os campos da aura retornada. Assim o aviso se refere ao Judgement do jogador, sem inferir autoria por um GUID potencialmente secreto. Nome do debuff: [registro de Forever](https://www.wowhead.com/forever/spell=21183/judgement-of-the-crusader). API: [UnitAuraDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua).

Sem debuff confirmado, orienta aplicar Crusader ou julgá-lo conforme o selo atual. Com o debuff presente e Crusader ainda ativo, orienta trocar para o selo de dano. Outros selos ativos após a aplicação do debuff não são substituídos pela orientação, preservando as trocas manuais para ecos e utilidade.

O estado é recalculado a partir do alvo atual, sem guardar conclusão de abertura por alvo nem avançar por eventos de lançamento/cooldown. `UNIT_AURA` acompanha jogador e alvo; troca de alvo e eventos de saúde, flags e facção também atualizam o aviso com o painel fechado. Não calcula readiness com cooldowns protegidos, alcance ou mana. O jogador decide quando executar a ação indicada.

A sequência segue a [abertura para lutas longas no guia de rotação de Forever](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps). Os testes simulam as etapas, a troca/morte do alvo, ausência de habilidades, configurações por perfil, dados restritos e falhas das APIs. A apresentação e as permissões efetivas ainda precisam de validação na build 70938.

## Ecos de Command

O registro de [Echo of Command, 1311703](https://www.wowhead.com/forever/spell=1311703/echo-of-command) identifica o buff de 15 segundos. Esse ID é distinto do talento [Unsealed Wrath, 1310735](https://www.wowhead.com/forever/spell=1310735/unsealed-wrath), cujo texto descreve até três cópias e consumo ao acertar com outro selo. O guia PvE recomenda gastar geralmente a partir de dois ecos. O ID do buff é verificado no retorno do cliente antes de usar a contagem; ainda falta calibrar essa leitura no cliente do jogador.

`GetBuffStatus` disponibiliza a aura como quarto retorno após as verificações existentes de acesso e segredo. Retornos que não sejam uma tabela ou nil são tratados como indisponíveis. `GetEchoCount` consulta `Echo of Command` no jogador e valida `spellId == 1311703` e `applications` como inteiro de 1 a 3. Cada campo passa por `issecretvalue` antes de comparação, cálculo ou formatação. Ausência confirmada representa zero; aura presente com contagem zero, ID diferente ou campos inválidos representa indisponibilidade. Erros de consulta ou acesso aos campos não geram contagem presumida.

`GetEchoStep` exige Unsealed Wrath, Command e Righteousness aprendidos, ausência de Holy Shock, preferência `echoGuidance` ativada, combate e alvo válido. Se o talento não aparecer no spellbook, consulta `C_SpellBook.IsSpellKnown(1310735)` e exige uma resposta pública verdadeira; falha, resposta secreta ou inválida não ativam a orientação. A API cobre habilidades conhecidas que não ocupam um slot visível: [SpellBookDocumentation.lua do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua). Usa a verificação de alvo compartilhada com a abertura de Crusader. Só atua quando Command é o selo base recomendado, preservando a escolha de Righteousness por arma/build. Não recalcula a arma durante combate.

Com Command, zero/um eco mantém a acumulação e dois/três orientam Righteousness. Com Righteousness e ecos presentes, orienta aguardar um acerto; só orienta voltar a Command quando o buff estiver ausente. Não usa tentativas de lançamento, swings ou combat log como prova de consumo. Remoção por consumo, expiração ou dispel produz a mesma orientação de retorno, sem afirmar dano causado. Não mantém contagem antiga após restrições nem reinicia os ecos do jogador ao trocar de alvo.

A abertura de Crusader é avaliada antes dos ecos. Selos de utilidade e ausência de selo continuam com os comportamentos anteriores. `/mp echoes` e o checkbox **Unsealed Wrath echoes** controlam a preferência por personagem/perfil, ligada por padrão. Sem o talento aprendido, a orientação não aparece. Os testes cobrem contagens, metadados inválidos, campos secretos, espera sem consumo, remoção do buff, interação com a abertura, troca de alvo e persistência das preferências.

Referências de API: [UnitAuraDocumentation.lua do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua) e [exportação da API de auras do cliente](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Spells-Auras-Talents/C_UnitAuras.md). O retorno por nome tem `RequiresNonSecretAura`; a existência da API não garante leitura pública em combate na build 70938.

## Preparação de grupo

`Profiles.lua` concentra os grupos de buffs, os presets e os nomes aceitos nas atribuições. `blessing` e `aura` ficam salvos por perfil; o padrão `any` preserva a detecção anterior. Dados inválidos recuperam esse padrão sem alterar as demais preferências.

`GetProfileBuffStatus` consulta somente o buff selecionado, quando houver atribuição, com as mesmas verificações de segredo de `GetBuffStatus`. Ausência confirmada de uma habilidade não aprendida gera `unlearned`, e não uma instrução de lançamento. Buff correspondente presente é aceito mesmo se não puder ser lançado pelo jogador; não é necessário ler autoria ou outros campos da aura.

`GetPreparationReminder` retorna uma bênção ou aura aprendida que falta e só atua fora de combate. O HUD prioriza selo/abertura/ecos antes da preparação; o controle geral de avisos continua por perfil. Durante combate, as atribuições são apresentadas nos indicadores sem interromper os avisos de selos.

As listas de cooldowns de Dungeon/Raid incluem as ferramentas adicionais de suporte aprendidas. A capacidade dos cards e checkboxes é calculada a partir dos presets. Os lembretes de consumíveis são manuais: não inferem inventário ou estado de consumo. As escolhas de grupo e as categorias seguem os guias de [habilidades](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-abilities) e [consumíveis](https://www.wowhead.com/forever/guide/classes/paladin/retribution/enchants-consumables-pve-dps) de Forever.

## Contexto e diagnóstico — 0.7/0.8

`combatMode` aceita `single`/`aoe` por perfil; `combatHints` controla a dica independente. `GetCombatHint` confere alvo público, habilidades aprendidas e condições públicas para Hammer of Wrath, Consecration e Exorcism. Valores secretos/indisponíveis não autorizam cálculo de vida/mana nem comparação do tipo de criatura. `UnitHealth` é marcado `SecretReturns = true` no ramo Forever; logo não se promete execute automático. Fonte: [UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua). O cooldown continua apresentado como objeto opaco no widget nativo, sem decidir prontidão.

`Diagnostics.lua` guarda um buffer de strings JSON prefixadas em `MyPaladinLog`. Campos públicos são filtrados antes de formatação; estados iguais por funcionalidade são deduplicados. O módulo acompanha as decisões efetivamente aplicadas aos frames, sem inferir dano de um cast. A lista de campos é fechada e não serializa estruturas de combate.

`C_Log.LogMessage` é uma saída adicional experimental, não uma garantia de transporte em tempo real. O hook de `C_Log.LogErrorMessage` observa erros identificáveis do addon; não substitui o tratador nativo e não tenta chamar `AddLuaErrorHandler`, que exige contexto seguro na UI. Fontes: [LogDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LogDocumentation.lua) e [Blizzard_ScriptErrors.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ScriptErrors/Blizzard_ScriptErrors.lua). Os limites de captura e o transporte por SavedVariables estão em [diagnóstico](diagnostico.md).

Na 0.8.1, `PlayerState.lua` registra motivos estáticos das verificações de acesso antes de descartar retornos secretos ou inválidos. As chaves `api_*` são deduplicadas individualmente e incluem perfil, contexto da luta e estado de combate, sem expor os valores recusados. O relatório compara evidências fora/dentro de combate e distingue erro de chamada de restrição confirmada. O resultado de `C_Log` é registrado separadamente da chegada ao disco; os eventos de ação bloqueada guardam o nome público da função. Consultas dispensadas pelo próprio addon não são apresentadas como proibições da API.

## Motor da 0.10.0

`CombatState.lua` recebe eventos públicos de cast do jogador e mantém estimativas apenas em memória. A presença pública da aura prevalece sobre a estimativa; `expirationTime` é lido em pcall e só usado após verificação de segredo/tipo/intervalo. Sem duração válida e sem histórico, a aura oculta permanece desconhecida. Morte descarta estimativas e troca de alvo descarta progresso estimado de Crusader. Rebuild do índice de spells não consulta equipamento nem manipula frames.

`ActionHints.lua` constrói o mapa de botões, bindings e macros fora de combate e cria apenas texturas de borda. Na 0.10.1, notificações de barra em combate revalidam vínculos existentes por identidade, conteúdo e tecla públicos; leituras ausentes ou mudanças descartam o vínculo, sem criar regiões. O par incondicional Judgement → Holy Strike recebe uma indicação compartilhada de macro. Nenhum binding, macro ou atributo seguro é alterado. Nomes públicos de spells permitem mapear IDs de ranks/base; somente casts simples são analisados no corpo de macros. O HUD usa essas informações para tecla e destaque, e pausa a recomendação de dano durante cast/canalização próprios. As limitações e o escopo das barras suportadas estão no README e no [desenho de assistência](assistencia-combate.md).
