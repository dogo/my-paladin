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
| Pasta de instalação e variante de `.toc` | Instalação em `Faugus/battlenet` confirmada pelo executável. Addon em `Interface/AddOns/MyPalladin`, usando `MyPalladin.toc`; integridade dos arquivos comparada com o projeto. Painel carregado conforme imagem do usuário. |
| APIs de auras, spells, cooldowns e talentos | Confirmar presença, assinatura, eventos e permissões na build instalada. Presença não comprova que o retorno pode ser comparado durante combate. |
| Dados para sugerir a próxima habilidade | Viabilidade pendente: depende do que a API permite ler e processar em combate. |
| IDs de spells, talentos e auras | Não foram obtidos nem inventados. Precisam vir do cliente/base de Forever e ser verificados. |

O Context7 foi consultado primeiro: `resolve-library-id` para World of Warcraft e `query-docs` em `/gethe/wow-ui-source`. O trecho de documentação gerada da Blizzard, espelhado no ramo `live`, define o quarto retorno de `GetBuildInfo()` como `interfaceVersion`. Esse ramo não prova a disponibilidade ou o valor em Forever. [Código de referência: BuildDocumentation.lua](https://github.com/gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/BuildDocumentation.lua).

Após receber a build do jogador, também foi consultado o ramo **forever** do espelho da UI da Blizzard. Nele, `C_Spell.GetSpellCooldown` tem a anotação `SecretWhenCooldownsRestricted`, enquanto `C_Spell.GetSpellCooldownDuration` fornece um objeto de duração para apresentação. `C_UnitAuras.GetAuraDataByIndex` tem `SecretWhenUnitAuraRestricted`. Essas anotações justificam separar exibição de cooldowns de decisões calculadas sobre seus valores. O ramo consultado não foi identificado como uma captura exata da build 70938. Fontes: [SpellDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua), [UnitAuraDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua).

## Consequência para o escopo

Podemos discutir a interface e as regras do guia agora. Antes de implementar decisões automáticas baseadas em combate, precisamos confirmar quais entradas são acessíveis. Um painel consultável com orientações estáticas exige menos hipóteses que um recomendador dinâmico; isso é uma opção de projeto, não uma decisão já tomada pelo usuário.

Se houver distribuição, a política oficial exige addon gratuito e código visível, proíbe anúncios e pedidos de doação dentro do jogo, e permite à Blizzard desativar funcionalidades. [Blizzard: UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534).

## Primeira implementação

O addon em `MyPalladin/` usa `SavedVariablesPerCharacter` para salvar o perfil ativo e, desde a 0.3, o modo compacto. Usa o spellbook para obter os IDs/ranks aprendidos, sem inventar IDs das habilidades. Consulta `C_SpellBook.FindSpellBookSlotForSpell` e `GetSpellBookItemInfo`, documentadas no [ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua).

Para exibição, encaminha objetos de duração ao widget de cooldown e valores de mana ao StatusBar, sem calcular prioridades a partir deles. Não há leitura do combat log. Perfil e escolhas do usuário ficam separados desses valores de combate. APIs ausentes geram mensagens explícitas.

## Integração da 0.3

O módulo `PlayerState.lua` consulta somente buffs do jogador, por seus nomes em inglês. Antes de `C_UnitAuras.GetAuraDataBySpellName`, exige uma resposta pública e booleana de `C_Secrets.ShouldSpellAuraBeSecret`. Quando o spell está restrito, não faz a consulta. Sem a API de restrições, não afirma ausência. A presença retornada é suficiente: o código não inspeciona os campos da aura.

`RequiresNonSecretAura` pode devolver nenhum valor quando o buff é secreto; interpretar esse retorno como ausência produziria alertas falsos. Fonte primária: [predicados da UI Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua). A assinatura da consulta está no [UnitAuraDocumentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua); `ShouldSpellAuraBeSecret` também aparece na [exportação da documentação do cliente Forever build 70790](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/System-Config/C_Secrets.md). A exportação não é uma captura exata da build 70938.

Os indicadores são atualizados em `UNIT_AURA`, entrada/saída de combate e atualização do painel. A porcentagem/alerta de mana só é calculada se ambos os valores passarem por `issecretvalue` e forem números válidos. A barra nativa continua recebendo os valores originais. É necessário testar esses caminhos no cliente instalado; os testes locais simulam dados protegidos e falhas da API.

## Botão de preparação da 0.3.1

O botão usa `InsecureActionButtonTemplate`, cujo handler nativo chama a ação somente fora de combate. São configurados `type1=spell`, o ID aprendido no spellbook, `unit=player` e `useOnKeyDown=false`, com clique no release esquerdo. O addon mantém o `OnClick` herdado e nunca chama uma função de lançamento nos eventos de atualização. Fontes primárias: [SecureTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml) e [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).

A recomendação considera os selos e Holy Shock aprendidos. Para a arma, consulta o item no slot 16 e `C_Item.GetItemInfoInstant`; quando necessário, lê a velocidade base no texto em inglês de `C_TooltipInfo.GetInventoryItem`. Não consulta equipamento nem muda a ação durante combate. Dados ausentes, secretos ou não reconhecidos geram um fallback explícito. Fontes: [ItemDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [TooltipInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua).

A imagem enviada da 0.3 confirmou o compacto, seis habilidades aprendidas, Might/Retribution ativos e ausência de selo indicada. O novo clique de preparação ainda depende do teste do jogador no cliente real.

O problema de descoberta foi reproduzido: o addon estava ausente da pasta que continha `Wow.exe`, embora existisse em `Faugus/default`. A cópia para `Faugus/battlenet` passou na verificação de presença e SHA-256. O usuário confirmou o painel em jogo por imagem, no perfil Leveling e nível 20. Isso valida descoberta/carregamento e apresentação inicial; não comprova todos os comportamentos durante combate. A execução em LuaJIT com APIs simuladas verifica a troca de perfis e o encaminhamento dos dados.
