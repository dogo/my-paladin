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

`/mp trace on` e `off` controlam a gravação por personagem. Reiniciar a gravação não apaga o buffer. Estados repetidos são descartados; mudanças de perfil, modo e combate são registradas novamente. Eventos de cast não fazem o addon avançar etapas: só o estado observado dos buffs/debuffs decide os avisos.

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

## Erros e limites

O gravador observa `C_Log.LogErrorMessage` por hook seguro, sem substituir o tratador global de erros, e guarda somente a primeira linha pública de erros que mencionem MyPaladin nos primeiros 300 caracteres. Também registra bloqueios/ações proibidas atribuídos ao addon. Nem todo erro chega a esse caminho: falhas anteriores ao carregamento de Diagnostics, de sintaxe/manifesto ou com stack não identificado exigem o erro nativo ou `DeveloperLog.log`.

Não existe chamada genérica usada aqui para forçar a escrita dos SavedVariables durante combate. Fechar o jogo à força pode perder a captura ainda não gravada. O buffer sobrescreve registros antigos; para sessões longas, faça capturas por `/reload` e mantenha o monitor aberto para consolidá-las.
