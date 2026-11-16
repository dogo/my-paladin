# Diagnóstico e validação

O addon registra mudanças dos avisos apresentados, estado dos buffs, contexto/perfil, mana pública ou restrita, casts públicos do jogador e erros próprios observáveis. O buffer local guarda os últimos **1000 registros por personagem**, em `MyPaladinLog`, junto das configurações em `WTF/Account/.../SavedVariables/MyPaladin.lua`. Não há upload nem alteração dos arquivos do jogo pelo leitor.

Não são gravados GUIDs, nomes de jogadores, chat, valores brutos de auras, vida, mana ou cooldowns protegidos. Os únicos campos adicionais aceitos pelo gravador são habilidade, contagem pública e detalhe textual limitado. Marcas digitadas pelo jogador e a primeira linha de um erro podem conter o texto fornecido por ele ou pelo cliente; confira o relatório antes de compartilhar.

## Durante a sessão

```text
/mp trace
/mp trace mark antes do teste de selo
/mp trace mark terminou o combate
/reload
```

`/mp trace on` e `off` controlam a gravação por personagem. Reiniciar a gravação não apaga o buffer. Estados repetidos são descartados; mudanças de perfil, modo e combate são registradas novamente. Desde a 0.10.0, casts próprios alimentam estimativas de selo e da abertura Crusader, registradas como `estimate/*`; uma leitura pública dos buffs/debuffs prevalece sobre a estimativa. Casts não comprovam acerto, dano nem consumo de ecos.

Depois do `/reload` ou da saída normal:

```sh
python scripts/monitor_session.py
```

O leitor gera `.diagnostics/report.md` e `events.jsonl`. Ele extrai apenas os registros com prefixo `MPALADIN1|`, sem executar Lua, e remove duplicatas por sessão/sequência. Para outro cliente, use `--game-dir '/caminho/_forever_'`.

## Acompanhamento ao vivo

```sh
python scripts/monitor_session.py --watch
```

O addon tenta encaminhar os mesmos registros a `C_Log.LogMessage`. A [documentação gerada da UI Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LogDocumentation.lua) confirma a API, sem especificar arquivo ou garantia de flush. A existência da função não comprova entrega em disco. Um [teste publicado pelo autor de ForeverPlusPlus](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md) também relata chamadas sem chegada aos logs. Por isso o transporte ao vivo é experimental; a gravação por SavedVariables continua sendo o caminho principal.

O monitor consulta `Logs/*.log` e o arquivo salvo específico do addon a cada segundo. Inicia nos últimos 2 MiB de cada log nativo e mantém até 5000 eventos únicos em memória. Truncamentos e rotações são detectados. Ctrl+C encerra o monitor. O relatório indica se algum registro de `C_Log` foi encontrado; registros antigos não provam baixa latência na sessão atual.

Enquanto estivermos trabalhando na conversa, o relatório pode ser lido para conferir os estados registrados. Um monitor rodando no terminal continua coletando sozinho; a análise pelo agente depende de uma interação ativa, sem promessa de vigilância após a resposta final.

## Roteiro para a build 70938

| Teste | Evidência esperada |
| --- | --- |
| Migrar com o jogo fechado e abrir o addon | Apenas MyPaladin instalado; perfil e preferências preservados; `session/start` com versão/build |
| Trocar Leveling/Dungeon/Raid e Single/AoE | `config/active` e estados com perfil/modo correspondentes; persistência após reload |
| Fechar o painel, aplicar e deixar o selo acabar | `buff_seal` e `seal_hud` mudam; conferir ícone/texto na tela |
| Ativar abertura Crusader numa luta longa | `opener_apply`, `opener_judge`, `opener_damage` conforme o debuff público; restrição produz conferência cinza |
| Com Unsealed Wrath, acumular e gastar ecos | `echo_build` com 0/1, `echo_swap` com 2/3, `echo_wait` enquanto restarem, `echo_return` com zero |
| Escolher Blessing/Aura específica | Buff diferente não satisfaz; preparação fora de combate; recebido de outro jogador satisfaz |
| Usar Single/AoE contra alvo válido | `combat_hint` corresponde ao modo; Consecration orienta mana em AoE; tipo/vida restritos geram conferência |
| Usar o macro Judgement/Holy Strike | `cast/succeeded` com IDs públicos, sem presumir efeito ou consumo de ecos |
| Terminar com `/reload` e executar o leitor | Relatório contém as marcas e os estados; erros e inconsistências de contagem destacados |

O relatório apresenta **observado**, **não observado** ou **restrito**. Não declara uma funcionalidade aprovada por ausência de erros. A checagem automática cobre a consistência das contagens registradas no ciclo de ecos; prontidão, dano e geometria dos avisos exigem validação no jogo.

## Restrições observadas — 0.8.1

A seção **Acesso às APIs observado** separa evidências de fora e de dentro de combate. Registra as consultas usadas pelo addon para auras, campos dos ecos, flags do alvo, vida, tipo de criatura, mana, equipamento e conhecimento do talento. O cooldown é identificado como exibição nativa, sem inspeção de prontidão. Cada verificação tem uma chave própria para que consultas repetidas não alternem artificialmente os registros.

| Estado | Significado |
| --- | --- |
| `restricted` | A política de auras impediu a consulta, ou o retorno/campo era secreto |
| `api_missing` | Uma API necessária não estava disponível |
| `call_failed` | A chamada protegida por `pcall` falhou; isso não confirma por si só uma proibição do jogo |
| `invalid` | O retorno acessível não tinha o tipo/intervalo esperado |
| `unavailable` | Não foi possível extrair a informação, como velocidade no tooltip |
| `not_checked` | O addon adiou/dispensou a consulta, por exemplo equipamento em combate ou requisito de habilidade não aprendida |
| `public` / `present` / `missing` | Consulta pública válida; presença/ausência de aura é uma condição normal |
| `native_only` | O objeto de cooldown é usado pelo widget nativo, sem decidir se a habilidade está pronta |
| `call_accepted` | `C_Log.LogMessage` aceitou uma tentativa; ainda não confirma arquivo ou flush |

Os detalhes são descrições estáticas da API/campo, por exemplo `UnitHealth returned a secret` ou `Echo of Command applications is secret`. Não incluem o valor protegido nem o erro bruto de uma chamada que falhou. O relatório preserva o último motivo de limitação mesmo se uma leitura pública ocorrer depois.

Na 0.8.2, `seal_hud/hidden` com detalhe `Seal status restricted` ou `Seal status unavailable` significa que o aviso foi ocultado por falta de evidência. O estado do buff e os motivos de restrição continuam registrados; não é uma confirmação de selo ativo. Isso evita que o antigo aviso permanente de conferência pareça uma instrução para reaplicar o selo.

Na 0.10.0, `estimate/seal_cast` registra o início de uma estimativa de selo após um cast próprio público. `estimate/crusader_judged` registra progresso inferido no alvo atual, sem confirmar aplicação do debuff; `estimate/reset` descarta esse estado na morte do jogador. `combat_hint/estimated` identifica instrução de manutenção inferida, `casting` identifica um cast em andamento. A manutenção é integrada no ícone principal; o HUD antigo fica oculto em combate quando o motor está ligado. A segunda opção usa somente candidatas prontas no estado atual, sem previsão de próximos casts. Os registros nunca tratam expiração estimada como contagem real de ecos.

`seal_probe/active|missing|unknown` (0.10.6) registra a evidência da usabilidade de Judgement quando a aura do selo está restrita; `unknown` cobre retorno protegido ou falta de mana.

`seal_viewer_map/mapped|none` (0.11.0) informa quantos itens do Cooldown Manager correspondem a selos; `seal_viewer/active` traz o selo visto num ícone de buff, `active_unnamed` indica o item agrupado **Seals** ativo sem informar qual selo, Sem selo visível, o estado diz o motivo: `no_map` (nenhum item de selo na API), `viewer_hidden` (visores de buff ocultos ou Cooldown Manager desligado), `item_absent` (o item **Seals** não está numa barra de buffs) ou `item_inactive` (o item está na barra, mas sem aura e sem cobrir todos os selos aprendidos). `seal_viewer/missing` (0.11.3) é ausência observada: o item agrupado está apagado e cobre todos os selos aprendidos.

`auto_context/aoe|single` (0.12.0) registra a decisão do modo Auto em combate, com `count` de inimigos em alcance pelas nameplates.

`bindings/mapped` registra quantas habilidades foram associadas a botões padrão; `unavailable` indica APIs ausentes. Desde a 0.10.1, `validated` registra quantos vínculos puderam ser revalidados durante combate; os demais são descartados até reconstrução fora de combate. Capturas anteriores usam `deferred` para o descarte completo do mapa durante combate. `action_binding/available|unbound` identifica se a ação principal tem uma tecla encontrada. Nenhum corpo de macro ou nome de macro é exportado para os registros.

As verificações só acompanham caminhos executados pelo addon. Sem a habilidade aprendida ou sem uma condição que exija a consulta, não há teste artificial de permissão. Uma coleta não permite concluir que uma API estará sempre pública ou restrita. O adiamento voluntário do equipamento não comprova que o jogo proíba a consulta.

`ADDON_ACTION_BLOCKED` e `ADDON_ACTION_FORBIDDEN` incluem o nome público da função quando o evento atribui a ação ao MyPaladin. A [documentação gerada de ações restritas do ramo Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua) define os dois argumentos, nome atribuído e função. Nenhuma ação proibida é provocada para testar esse registro.

## Erros e limites

Primeira captura real em 15/11/2026, versão 0.8.1/build 70938: 665 registros da sessão concluída com 12 entradas em combate, incluindo marca do jogador, casts públicos e decisões de avisos. Nenhum evento de erro próprio foi registrado. Selos, bênçãos e auras consultados foram restritos durante combate; fora dele houve detecção de buffs. Mana ficou protegida inclusive fora de combate, exceto um retorno inválido no carregamento inicial. Flags do alvo e tipo de criatura ficaram públicos nas consultas observadas. Vida do alvo não foi consultada porque Hammer of Wrath não estava aprendido. Não houve validação do ciclo de ecos nem da abertura Crusader. Os registros também chegaram a `Logs/General.log`; a latência e o flush sem reload ainda não foram medidos.

Na mesma análise, uma leitura posterior encontrou 188 registros da sessão atual em `General.log`, com atividade posterior à inicialização, enquanto os SavedVariables ainda continham apenas a sessão anterior. Isso confirma o transporte durante a sessão antes de outro reload nessa instalação. O atraso exato e a regularidade de flush ainda precisam ser medidos; o monitor deve continuar tratando SavedVariables como alternativa.

O gravador observa `C_Log.LogErrorMessage` por hook seguro, sem substituir o tratador global de erros, e guarda somente a primeira linha pública de erros que mencionem MyPaladin nos primeiros 300 caracteres. Também registra bloqueios/ações proibidas atribuídos ao addon. Nem todo erro chega a esse caminho: falhas anteriores ao carregamento de Diagnostics, de sintaxe/manifesto ou com stack não identificado exigem o erro nativo ou `DeveloperLog.log`.

Não existe chamada genérica usada aqui para forçar a escrita dos SavedVariables durante combate. Fechar o jogo à força pode perder a captura ainda não gravada. O buffer sobrescreve registros antigos; para sessões longas, faça capturas por `/reload` e mantenha o monitor aberto para consolidá-las.
