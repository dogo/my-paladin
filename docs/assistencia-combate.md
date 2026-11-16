# Assistência durante combate

Feedback do jogador em 15/11/2026: o addon não ajudou nas decisões da luta. A dica permanente de Judgement/Holy Strike e os avisos de dados restritos não cumpriram a expectativa de assistência de rotação. O critério de entrega passa a ser orientação acionável, comprovada no cliente do jogador, antes de expandir a interface ou declarar 1.0.

## Evidência disponível

- A captura da 0.8.1 mostrou selos/bênçãos/auras restritos durante combate. Usar esses retornos para inferir ausência seria incorreto. Na 0.8.2, o HUD de selo é ocultado quando o estado está restrito/indisponível; o diagnóstico permanece no painel/log.
- Cooldowns podem ser apresentados pelo widget nativo sem permitir comparação dos valores. Isso não equivale a conhecer qual habilidade está pronta.
- A [documentação gerada do ramo Forever para C_AssistedCombat](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AssistedCombatDocumentation.lua) contém `IsAvailable`, `GetNextCastSpell`, `GetActionSpell` e `GetRotationSpells`. No teste do jogador, `IsAvailable()` retornou `false, WRONG_WORLD_STATE_EXPRESSION`. Portanto, essa via está indisponível no estado testado. O motivo não identifica sozinho se a regra é nível, modo de jogo ou outra condição; não se presume indisponibilidade universal de Forever.
- [SpellActivationOverlay, código do autor para paladinos](https://github.com/ennvina/spellactivationoverlay/blob/main/classes/paladin.lua), tem caminhos específicos de Forever para Exorcism e alertas. O [changelog do autor](https://github.com/ennvina/spellactivationoverlay/blob/main/changelog.md) descreve limitações para auras e instâncias. Isso justifica investigar sinais visuais nativos permitidos; não comprova um recomendador completo de Retribution.

## Próxima decisão técnica

Confirmar no chat do jogo, sem reinstalar o addon:

```text
/run local a=C_AssistedCombat; if a and a.IsAvailable then print("MyPaladin assistant:",a.IsAvailable()) else print("MyPaladin assistant: API ausente") end
```

Resultado recebido: `false, WRONG_WORLD_STATE_EXPRESSION`. A integração com recomendações nativas não será implementada como base enquanto esse bloqueio persistir.

A próxima verificação, solicitada durante uma luta, identifica se a duração do cooldown e o resultado de usabilidade de Holy Strike são públicos:

```text
/run local c=C_Spell.GetSpellCooldown("Holy Strike");local u=C_Spell.IsSpellUsable("Holy Strike");print("MP cooldown:",issecretvalue(c) or (c and issecretvalue(c.duration)),"usable:",issecretvalue(u))
```

`false` na verificação de segredo significa dado público, não indisponibilidade da habilidade. Esse comando não determina o estado de toda a rotação: os demais campos necessários, alcance e habilidades também precisam de validação antes de recomendar uma ação. A [documentação de spells do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) marca cooldowns com `SecretWhenCooldownsRestricted`; não se presume que o retorno possa ser comparado no combate do jogador. `IsSpellUsable` não substitui a verificação de cooldown e alcance.

Se os dados necessários forem públicos, implementar decisão entre habilidades realmente aprendidas, reavaliando após lançamentos e mudanças de cooldown, em vez da dica permanente de Judgement/Holy Strike. Se estiverem protegidos, avaliar apresentação por widgets nativos e alertas específicos permitidos, deixando explícito que não há seleção automática de próxima habilidade. Não apresentar novamente uma mensagem estática como se fosse uma decisão de rotação.

Uma entrega só conta como assistência validada quando altera a orientação em situações reais, explica a ação e não repete uma instrução que já está satisfeita. Se não houver dados suficientes para recomendar uma ação, a interface deve deixar essa limitação clara, sem fabricar prontidão, contagem de ecos ou ausência de selo.

## Primeira implementação dinâmica — 0.9.0

O jogador retornou `MP cooldown: false usable: false` durante combate. Isso confirma dados públicos apenas nas verificações feitas; não autoriza presumir todos os campos ou todas as habilidades públicos. `GetSpellReadiness` valida usabilidade, alcance, tabela e campos de cooldown a cada consulta, antes de cálculo. `GetCombatAction` usa a prioridade de Retribution do guia de Forever e escolhe a primeira opção elegível e pronta verificada. O dado bruto de mana não é necessário para verificar a possibilidade de pagar um cast quando `IsSpellUsable` é público e verdadeiro.

O HUD exibe `Now`, `Wait` ou `Check`. A escolha pode mudar de Judgement para Holy Strike após um cast e voltar após o cooldown; o tick de 0,1 segundo evita depender exclusivamente de um evento na expiração. Não há autocast, leitura de dados secretos nem estimativa de término de selo por tempo. Os logs registram `api_readiness_*` por habilidade e `combat_hint/ready|wait|check` sem gravar contagens regressivas a cada tick.

Referências primárias de campos e assinaturas: [SpellSharedDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua) e [SpellDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua). Valores públicos de start/duration/modRate precisam ser válidos; dados restritos não viram zero nem confirmam prontidão. A checagem não cobre linha de visão, acerto ou a consistência de uma transação com o servidor.

O código e as simulações estão prontos; a validação de ajuda real ainda exige instalar a 0.9.0, jogar e conferir a alternância das indicações na captura. Não se declara assistência validada só porque os testes passaram.

## Retorno real e correção — 0.9.1

A primeira captura da 0.9.0 teve 21 casts, sem `ready` ou `wait`: `Cooldown field protected` impediu a decisão. O teste manual de duração/usabilidade era insuficiente para provar que startTime/modRate estariam públicos. A verificação de campos protegeu os dados, mas inutilizou a orientação.

`SpellCooldownInfo.isEnabled` e `isActive` são marcados `NeverSecret` na documentação gerada de Forever. A 0.9.1 ainda valida seus valores em cada consulta: `isEnabled=false` impede recomendação; `isEnabled=true` e `isActive=false` permitem confirmar ausência de cooldown sem tocar nos tempos. Com `isActive=true`, tempos protegidos não impedem confirmar espera; o widget mostra o cooldown sem cálculo externo. A ausência/segredo do flag não é convertida em `false`: nesse caso, a decisão depende de tempos públicos válidos ou permanece indeterminada.

Os logs separam `api_cooldown_activity_*` de `api_cooldown_timing_*`. Os testes reproduzem duração pública com startTime/modRate protegidos, ausência de acesso aos tempos de um cooldown inativo, cooldown suspenso e mistura de esperas com/sem tempo calculável. A correção está testada localmente; resta a confirmação na build 70938 do jogador.

## Motor com memória e apresentação acionável — 0.10.0

`CombatState.lua` mantém estado apenas da sessão: nomes/IDs públicos de habilidades conhecidas, cast em andamento, selo atual com duração estimada e etapa estimada de Crusader no alvo atual. Casts próprios substituem o selo anterior; snapshots públicos corrigem a estimativa. IDs e campos secretos nunca são usados para identificar uma habilidade. O cache pode reconhecer outro rank por nome público, dentro da lista de habilidades aprendidas.

`GetCombatAction` considera manutenção antes de dano e volta à rotação após reaplicar o selo. A manutenção inferida usa `estimated`, em âmbar; consultas públicas usadas para prontidão continuam independentes dessa confiança. Casts em andamento seguram a indicação; cooldown/GCD ativo não vira `ready`. Uma segunda chamada excluindo o ID principal pode oferecer outra opção pronta no mesmo estado, sem simular o futuro.

`ActionHints.lua` lê botões e bindings padrão fora de combate, identifica spells por ID/nome e casts simples em macros, e cria bordas próprias de textura sem ações de lançamento. A identificação do macro usa o nome retornado por GetActionText quando disponível, porque GetActionInfo pode fornecer a habilidade exibida, não um índice de macro. Os dois casts simples do macro do jogador podem compartilhar tecla e borda. Na 0.10.1, alterações de barra em combate revalidam identidade/conteúdo/tecla com dados públicos e descartam somente vínculos não confirmados, sem criar regiões nesse momento. O HUD identifica o par incondicional Judgement → Holy Strike como Holy Strike macro e suprime a alternativa duplicada. A sessão real da 0.10.0 confirmou reconhecimento de Judgement e cooldown, mas também perda do cache por notificações da barra; a correção passou nos testes locais e ainda requer validação no cliente.

Os módulos foram escritos para este addon após a análise de métodos do Sonah, sem copiar sua implementação. Não foram incluídos estimadores de vida/contagem de ecos, coleta de DPS, sincronização ou todas as classes. A entrega precisa de validação do efeito prático no personagem do jogador.
