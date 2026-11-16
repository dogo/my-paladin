# Roadmap

Addon de apoio a Retribution PvE em WoW: Forever, com perfis por personagem e avisos independentes do painel.

Implementado significa código disponível e testes locais aprovados. Instalação e validação no cliente real são acompanhadas separadamente.

## Implementado

| Etapa | Entrega |
| --- | --- |
| Base | Painel de cooldowns, mana, nível e perfis Leveling/Dungeon/Raid |
| 0.3 | Painel compacto, habilidades aprendidas e indicadores de buffs/mana |
| 0.4 | Preferências independentes por perfil: alertas, limite de mana, cooldowns e preparação |
| 0.4.1 | Aviso de selo independente do painel, atualizado durante combate |
| 0.5.0 | Abertura opcional Crusader → Judgement → selo de dano para lutas longas |
| 0.5.1 | Ecos de Command: acumular, trocar para Righteousness, aguardar e retornar a Command |
| 0.6 | Bênção/aura desejadas por perfil, avisos de preparação fora de combate e mais cooldowns de suporte |
| 0.7 | Single/AoE por perfil, dica independente de combate e condições públicas de mana, tipo e vida do alvo |
| 0.8 | Nomes MyPaladin corrigidos, migração com backups, diagnóstico limitado e leitor de sessões |
| 0.8.1 | Motivos de acesso às APIs por consulta e comparação fora/dentro de combate no relatório; instalação e primeira captura conferidas |
| 0.8.2 | Correção do aviso de selo: ocultar HUD quando o estado estiver restrito/indisponível; instalação e conferência visual pendentes |
| 0.9.0 | Decisão dinâmica Now/Wait/Check por cooldown, usabilidade e alcance públicos; inclui correção da 0.8.2; instalação e validação real pendentes |
| 0.9.1 | Corrige leitura de prontidão usando isEnabled/isActive públicos quando os tempos estão protegidos; instalação e validação real pendentes |
| 0.10.0 | Motor unificado com memória de casts/selos, confiança estimada, pausa durante casts, segunda opção pronta, tecla e destaque em barras Blizzard/macros simples; instalação e validação real pendentes |
| 0.10.1 | Identifica o macro Judgement/Holy Strike como uma ação compartilhada, evita alternativa duplicada e preserva vínculos revalidados em combate; testes locais aprovados; título do macro, tecla persistente e espera após Judgement confirmados pelo jogador em 16/11/2026 |
| 0.10.2 | Mantém o aviso de renovação do selo durante o GCD, em vez de alternar com Check cinza; botão de contexto mostra `Mode: Single`/`Mode: AoE`; testes locais aprovados, validação real pendente |
| 0.10.3 | Destaque do botão passa a pulsar (borda com brilho aditivo e animação própria), sem reiniciar a cada atualização do HUD; validação visual pendente |
| 0.10.4 | Brilho com a arte de proc da Blizzard (`UI-HUD-ActionBar-Proc-Loop-Flipbook`) num frame próprio, após o jogador achar a borda pulsante discreta; borda pulsante fica como alternativa sem o atlas; validação visual pendente |
| 0.10.5 | Indicação estável durante o GCD com tempos protegidos (memória de habilidade pronta e não lançada, até 1,6s); fundo escuro atrás do texto da indicação; validação real pendente |
| 0.10.6 | Técnicas da [leitura de código](pesquisa-addons-forever.md#leitura-do-código--2026-11-16): Hammer of Wrath pela usabilidade pública; usabilidade de Judgement como evidência de selo; `isOnGCD` público para separar GCD de cooldown real; validação real pendente |
| 0.10.7 | Título da indicação nomeia a habilidade pronta em vez de `Holy Strike macro`; com Judgement pronto e Holy Strike em cooldown, a ajuda explica que o botão do macro mostra o cooldown do Holy Strike. Na sessão da 0.10.6 o jogador viu o botão em cooldown e achou que o macro não funcionava, embora os casts de Judgement aparecessem 0–1s após cada indicação; a evidência de selo por Judgement indicou ausência exatamente 30s após cada cast |
| 0.10.8 | Judgement inutilizável até 1,5s após um cast de selo vira espera (`Seal applying`), em vez do `Check` cinza de ~1s observado na 0.10.6; a evidência de ausência por Judgement respeita a mesma janela |
| Monitor | Consulta dos oito guias, relatório de diferenças e aceitação manual das revisões |

Os ecos só são orientados com Unsealed Wrath e os dois selos aprendidos, Command como selo base recomendado e dados acessíveis. Não há troca automática de selos nem lançamento de habilidades.

A instalação da 0.8 foi conferida em 15/11/2026: os seis arquivos instalados correspondem ao projeto, a pasta antiga saiu de `AddOns` e as configurações de um personagem foram preservadas pela migração. Isso confirma a instalação em disco; o carregamento e os comportamentos da nova versão ainda precisam da sessão no jogo.

Em 15/11/2026, a primeira captura da 0.8.1 na build 70938 confirmou carregamento, gravação por SavedVariables e chegada de traces ao `Logs/General.log`: 665 registros na sessão concluída, com 12 entradas em combate e nenhum erro próprio registrado. Nesta captura, consultas de selos/bênçãos/auras foram bloqueadas pela política de segredo durante combate; fora dele houve detecção de buffs. Mana apareceu protegida também fora de combate. Tipo de criatura e flags do alvo ficaram públicos nas consultas observadas. A sessão usou Leveling/Single com abertura Crusader desativada; não valida os demais perfis, AoE, abertura ou ecos. Uma leitura seguinte encontrou 188 registros da sessão atual somente no log nativo, ainda ausentes dos SavedVariables, confirmando coleta durante a sessão sem outro reload. O atraso exato não foi medido.

## Validação pendente

- Conferir cooldowns, mana, ranks e persistência de configurações na build 70938.
- Conferir o aviso de selo e a abertura de Crusader com o painel fechado.
- Conferir atribuições de bênção/aura, buffs recebidos de outro jogador e avisos de preparação fora de combate.
- Com Unsealed Wrath aprendido, conferir o buff e a contagem de Echo of Command no cliente real.
- Repetir o ciclo após acerto, erro/esquiva, expiração, dispel, troca de alvo e fim de combate.
- Confirmar quais dados permanecem públicos durante combate; estados restritos devem limpar orientações anteriores e mostrar uma indicação de conferência.
- Conferir no jogo as demais preferências e perfis após a migração; Leveling/Single foi registrado na primeira captura.
- Conferir Single/AoE e o cooldown da dica com o painel fechado; não exigir leitura de vida secreta.
- Medir a latência de `C_Log`; chegada a `General.log` durante a sessão, antes de outro reload, já confirmada.
- Conferir que o HUD de selo desaparece durante restrições, inclusive se antes mostrava ausência. Detecção exata de ausência de selo em combate não está validada, pois a política bloqueou a consulta.

## Prioridade após o feedback de uso

O usuário relatou que o addon não ofereceu ajuda útil na luta. O painel de cooldowns e a dica genérica de Judgement/Holy Strike não contam como assistência de rotação validada. A prioridade passa a ser obter orientação acionável durante combate e testar sua utilidade no nível/build do jogador antes de ampliar o painel ou declarar 1.0. A investigação está em [assistência de combate](assistencia-combate.md).

A verificação de `C_AssistedCombat.IsAvailable()` no jogador retornou `false, WRONG_WORLD_STATE_EXPRESSION`. Essa integração não pode ser a base da assistência no estado testado. A próxima verificação é o acesso a cooldown/usabilidade durante combate, antes de implementar outra recomendação.

O teste de Holy Strike durante uma luta retornou `MP cooldown: false usable: false`, confirmando que a tabela/duração consultada e o primeiro retorno de usabilidade não eram secretos naquele momento. A 0.9.0 usa essas APIs com validação em cada consulta e verifica também alcance, campos do cooldown e custo. Os testes locais cobrem a mudança Judgement → Holy Strike → espera → pronto, falta de mana, alcance, contexto AoE e dados protegidos. A utilidade e o acesso aos demais campos no cliente real ainda dependem da captura da nova versão.

A captura seguinte confirmou a 0.9.0 carregada: 182 registros, 21 casts, nenhuma indicação `ready`/`wait` e nenhum erro próprio registrado. As recomendações ficaram em `check` porque outro campo do cooldown era protegido; o teste inicial de tabela/duração não cobria todos os campos exigidos. A 0.9.1 reproduz esse caso nos testes e usa os flags públicos de habilitação/atividade antes de consultar tempos opcionais. A alternância real para `Now` ainda precisa ser conferida no cliente após a atualização.

Em 16/11/2026, a [análise do Sonah 1.2.3 instalado](analise-sonah.md) confirmou um motor próprio com histórico de casts e estimativas de auras/selos, além das leituras públicas e da apresentação por tecla/brilho. Isso identifica uma direção para ampliar a assistência: separar estado observado, estimado e desconhecido. A inspeção foi estática e não modificou o Sonah nem implementou esse modelo no My Paladin.

O [roteiro de diagnóstico](diagnostico.md) reúne os passos de validação e os limites do relatório.

Na sessão `1794833942-7` da 0.10.0, na build 70938, os logs confirmam Judgement seguido por cooldown (por exemplo, cast #58 e leitura #61). Não há evidência nesse trecho de que o cast tenha sido ignorado. Também foram registradas invalidações completas de bindings durante combate, seguidas por `action_binding/unbound`. A 0.10.1 reproduz a perda do vínculo em teste e a corrige com revalidação, além de apresentar as duas habilidades como o macro já usado pelo jogador. O teste integrado do HUD passa por cast, espera, notificação de barra e nova prontidão. Isso não substitui a validação visual da nova versão no cliente.

Em 16/11/2026, o jogador confirmou no cliente a 0.10.1: título Holy Strike macro, tecla persistente após casts e indicação de espera após Judgement lançado pelo macro. A confirmação foi informada pelo jogador, sem captura de diagnóstico analisada.

A captura `1794834821-8` (0.10.1, apesar do texto `addon=0.10.0` deixado no `Diagnostics.lua` instalado) confirma nos registros: 161 vínculos de tecla disponíveis e nenhum perdido, 19 revalidações em combate, Wait após 28 de 41 Judgements, alternância entre Judgement, Consecration e Holy Strike, renovação estimada aos 30s e HUD de selo oculto em combate. Também mostrou o aviso de renovação alternando com Check durante o GCD, corrigido na 0.10.2. O jogador usava Crusader como selo principal por engano e ficou em AoE porque o botão `Single` parecia uma ação; o botão passou a mostrar `Mode: ...`. O destaque visual do botão não é comprovado pelos registros.

Na sessão `1794850595-12` (0.10.3), a abertura Crusader foi seguida em combate com o debuff restrito: Long-fight opener → Judge your tracked Crusader seal → Crusader judged; application estimated → Seal of Righteousness, tudo como estimado. O jogador confirmou a sequência no jogo.

Na sessão `1794851406-15` (0.10.4, AoE), a ordem seguiu o guia: Judgement → Consecration → Holy Strike. A indicação alternava `Now: Consecration` ↔ `Wait: Judgement` a cada GCD porque os tempos protegidos impedem saber qual cooldown termina antes; corrigido na 0.10.5. A mana ficou protegida a sessão inteira, então o limite de mana não restringiu Consecration: o guia pede Consecration em AoE "if mana permits" e manda pará-la quando mana virar problema, mas hoje só `IsSpellUsable` impede o cast sem mana. Sem leitura de mana, falta um sinal confiável para essa reserva.

## 1.0 — Estabilização

- Resolver os problemas encontrados na validação do cliente.
- Consolidar compatibilidade, instalação e atualização do addon.
- Publicar um pacote de versão com instruções de uso e limitações confirmadas.

## Depois do motor — pontos úteis priorizados

- Validar primeiro: indicação de dano alternando, renovação estimada do selo, ausência de alertas concorrentes, tecla do macro e destaque correto durante uma luta real.
- Separar defensivos e controle de dano, com alertas específicos baseados em sinais disponíveis; não inventar limiar de vida quando a informação estiver oculta.
- Orientação de talentos e treinamento conforme o personagem e o guia de Forever, antes de novas telas de estatísticas.
- Ampliar mapeamento para barras substitutas e macros complexos após testar as barras padrão.
- Avaliar aproximações de ecos somente com opção explícita e calibração; as contagens atuais continuam dependendo de leitura pública.

GearScore, sincronização de grupo, todas as classes e grandes painéis de desempenho não entram nessa entrega. A 0.10.0 usa código próprio e não altera nem depende do Sonah instalado.

## Acompanhamento das entregas

Ao terminar cada entrega, registrar o que foi feito, o que falta e o que ainda depende de validação no jogo. Atualizar este roadmap quando o escopo ou a prioridade mudar.
