# Como o Sonah Forever oferece assistência

Análise estática em 16/11/2026 da instalação local autorizada pelo jogador: `Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Sonah`. `Sonah.toc:11` identifica versão **1.2.3**, Interface 16001. Arquivos Lua lidos diretamente; nenhum código do Sonah foi executado, instalado ou alterado por esta análise. Nenhuma implementação do My Paladin foi modificada nesta etapa.

## Funcionamento confirmado no código

| Questão | Evidência no Sonah instalado | Consequência |
| --- | --- | --- |
| Depende do assistente Blizzard? | `Core/Organisms/Settings.lua:26`, `Core/Organisms/Engine.lua:624`, `Core/Atoms/Spells.lua:1173` | Motor próprio é o padrão; existem motores Blizzard/híbrido opcionais. Indisponibilidade de C_AssistedCombat não impede o motor Sonah. |
| Como descarta dados protegidos? | `Core/Atoms/Secret.lua:128` e `:138` | Leituras protegidas por pcall; cada campo secreto vira desconhecido, sem invalidar os outros campos públicos da mesma estrutura. |
| Como lê cooldowns? | `Core/Atoms/Spells.lua:341` | Usa tempos públicos quando disponíveis, flags públicos de atividade/GCD e, na falta dos tempos, histórico de casts com cooldown cadastrado no template. O fallback mantém um intervalo positivo enquanto o flag público indicar atividade. |
| Como verifica custo/possibilidade de cast? | `Core/Atoms/Spells.lua:405` | Consulta IsSpellUsable e insufficientPower; não exige porcentagem exata de mana para toda ação. |
| Como trata informação desconhecida? | `Core/Atoms/Spells.lua:432`, `Core/Molecules/Conditions.lua:558` | Há decisões otimistas: cooldown desconhecido pode passar em Ready; certos limiares de recurso desconhecido são delegados à usabilidade nativa. Isso não comprova que o cast funcionará. |
| Como mantém selos com auras ocultas? | `Core/Atoms/Auras.lua:436`, `:684`; `Core/Molecules/Conditions.lua:506`; `Classes/Paladin.lua:43` | Registra casts próprios, usa duração cadastrada de 30s e snapshots de leituras públicas, depois calcula tempo restante estimado. Entre selos exclusivos, considera o mais recente. |
| Como diferencia aura lida de estimada? | `Core/Atoms/Auras.lua:153`, `:342`, `:651` | Resultados internos têm origem API ou tracked. A estimativa pode ser recalibrada por uma leitura pública posterior. |
| Como orienta Unsealed Wrath? | `Classes/Paladin.lua:180`, `:640` | A lógica de Ret usa intervalos de 6s com Command e 8s com Righteousness, com gates de talento, alcance e mana. Esses intervalos são heurísticas, não contagem observada dos ecos. |
| Como verifica Hammer of Wrath? | `Classes/Paladin.lua:354` | Usa a condição nativa de usabilidade e condições de movimento/talento, em vez de exigir leitura direta da vida. A regra de Ret observada exclui grupo para essa sugestão. |
| Como escolhe uma ação? | `Core/Organisms/Engine.lua:280`, `:454`; `Classes/Paladin.lua:619` | Percorre listas de prioridade, verifica aprendizado, regras e prontidão e monta a recomendação e outras opções. As prioridades do Sonah são decisões próprias; não são automaticamente idênticas ao guia Wowhead. |
| Como mantém a indicação atualizada? | `Core/Organisms/Settings.lua:27`, `Core/Organisms/Engine.lua:1044` | Tick padrão de 0,05s em combate, eventos de cast/alvo e estabilização da seleção. |
| Como mostra a tecla? | `UI/ActionBars.lua:810`, `UI/Display.lua:1073` | Resolve os botões correspondentes à habilidade e usa a tecla associada na apresentação, junto das opções de brilho. |

Fluxo principal: templates de classe → condições → leituras públicas/estado estimado → motor de prioridade → recomendação → display/barra de ações. Casts próprios atualizam o histórico e provocam reavaliação.

## Limites e diferenças para o My Paladin

O Sonah não demonstra acesso irrestrito às auras do jogador. Ele mantém um modelo estimado do combate quando essas leituras falham. Um selo estimado por duração pode ficar incorreto após remoção antecipada, dispel ou perda de eventos. A seleção de Unsealed Wrath por tempo não confirma que dois ecos foram acumulados ou consumidos. Esses são limites do método, não bugs reproduzidos nesta análise.

Há também uma diferença de leitura: o Sonah tenta auras próprias por ID e depois por nome, descartando os campos inacessíveis; o My Paladin atualmente interrompe a consulta por nome ao receber uma política de segredo. A análise estática não confirma que a tentativa alternativa retornaria dados públicos no personagem do jogador. Essa possibilidade precisa de teste específico, sem transformar um retorno nil restrito em ausência.

O My Paladin começou exigindo confirmação direta para quase toda instrução. Na captura real, isso suprimiu a ajuda de selos/ecos; a 0.9.0 também recusou cooldowns inteiros porque um campo temporal era secreto. A 0.9.1 já passou a usar os flags públicos de cooldown, mas ainda não modela a duração estimada dos selos por casts. O motor próprio do Sonah, as estimativas e a apresentação por tecla/brilho explicam por que ele pode continuar oferecendo orientação com esses limites.

Para evoluir o My Paladin, o desenho útil é distinguir **observado**, **estimado** e **desconhecido**, manter um estado por casts próprios e oferecer uma decisão acionável com indicação da confiança. Isso exige testes de troca de selo, remoção antecipada, reload em combate e recalibração fora de combate. A observação de um cast não deve ser apresentada como prova de acerto, dano ou consumo de ecos. Esta análise não implementa essa mudança.

## Fontes públicas e fronteira da conclusão

As descrições do autor em [CurseForge](https://www.curseforge.com/wow/addons/sonah-forever) também informam uso de casts próprios e checagens nativas quando dados estão ocultos. As [notas da 1.2.2](https://www.curseforge.com/wow/addons/sonah-forever/files/9623676) relatam uma correção de checagem de distância bloqueada em combate; a [1.2.3](https://www.curseforge.com/wow/addons/sonah-forever/files/9638356) acrescenta diagnóstico do ícone. Essas notas não provam eficácia em todas as situações.

**Confirmado:** caminhos de leitura, fallback, estimativa, decisão e apresentação no Lua instalado. **Não confirmado:** comportamento em execução no personagem do usuário, precisão das heurísticas e resultados das simulações mencionadas nos comentários do autor. O Sonah permanece sem alterações; o relatório descreve a arquitetura e os métodos, sem reproduzir sua implementação.
