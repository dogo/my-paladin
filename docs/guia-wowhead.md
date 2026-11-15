# Pesquisa para o My Paladin

Consulta em 14/11/2026. Referência solicitada: guia de Retribution PvE do Wowhead para **WoW: Forever**, identificado nas páginas como patch 1.60.1.

Ambiente informado pelo jogador: servidor **PvE**, jogo em **inglês**, versão **1.60.1 (70938)**. Foco confirmado: **leveling, dungeons e raids**, com um **perfil ativo** que muda o comportamento do addon. Nível e talentos ainda não foram informados; o painel lê o nível do jogador.

## Cobertura da leitura

Lido o texto disponível das oito páginas principais e dos dois complementos de beta encontrados na navegação/indexação. A leitura abrange as subseções, incluindo as variantes de rotação. Calculadoras interativas e alguns campos de itens não aparecem completos na extração: não considero suas distribuições de talentos ou estatísticas verificadas. Links individuais de cada item, missão ou habilidade não fazem parte desta cobertura; três habilidades centrais foram consultadas adicionalmente.

| Página | Atualização exibida | Leitura e implicação para o addon |
| --- | --- | --- |
| [Overview](https://www.wowhead.com/forever/guide/classes/paladin/retribution/overview-pve-dps) | 14/11/2026 | Mudanças de habilidades e talentos, viabilidade, iniciantes, sistemas, raças e profissões. O foco envolve dano físico e Sagrado, utilidade e sustentação de mana. Não transportar regras de outras versões do WoW. |
| [Talents & Builds](https://www.wowhead.com/forever/guide/classes/paladin/retribution/talent-builds-pve-dps) | 13/11/2026 | Builds de raid, dungeon e PvP, com caminhos Unsealed Wrath e Shockadin. Dungeon usa essencialmente a build de raid. As duas opções precisam de comportamentos diferentes; as árvores interativas não foram verificadas ponto a ponto. |
| [Rotation](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps) | 14/11/2026 | Selos por arma/build, alvo único, área, Shockadin e cooldowns ofensivos/defensivos. Judgement não remove o selo. Unsealed Wrath normalmente acumula dois ecos de Command em PvE; troca para Righteousness, acerta e retorna a Command. Shockadin mantém Righteousness. Mana limita o uso de Consecration. |
| [Enchants & Consumables](https://www.wowhead.com/forever/guide/classes/paladin/retribution/enchants-consumables-pve-dps) | 31/10/2026 | Encantamentos por slot, poções, elixires, efeitos de arma e comida. Ainda focado em leveling. Há opções de spell power e força/AP; comparações de nível máximo seguem provisórias. Poções compartilham cooldown; comida e efeito temporário de arma têm restrições de acumulação. |
| [Stat Priority](https://www.wowhead.com/forever/guide/classes/paladin/retribution/stat-priority-pve-dps) | 31/10/2026 | Weapon Skill, arma, Hit, Expertise, Spell Damage, Intelecto, força/AP, agilidade/crítico e stamina. O guia apresenta 9% de Hit e 6,5% de Expertise como referências ainda dependentes de confirmação e Weapon Skill. Não converter essa ordem em pesos numéricos de equipamento. |
| [Leveling](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips) | 14/11/2026 | Talentos, treinamento obrigatório/opcional, selos, rotações, profissões, camping, Legacy, consumíveis e dicas. Holy Strike chega cedo; o ciclo de ecos depende do talento Unsealed Wrath. Legacy pode antecipar talentos. O addon deve considerar habilidades e talentos realmente aprendidos, além do nível. |
| [Best-in-Slot Gear](https://www.wowhead.com/forever/guide/classes/paladin/retribution/bis-gear) | 14/11/2026 | Conjuntos e avaliação por slot, incluindo armas e librams. Diversos slots continuam sem ranking e os bônus de conjunto são explicitamente provisórios. Não há uma lista completa e definitiva para implementar como avaliador automático. |
| [Abilities](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-abilities) | 13/11/2026 | Dano, selos, cura, auras, bênçãos, utilidade e controle. Exorcism depende de alvo Undead/Demon; Hammer of Wrath exige alvo abaixo de 20%. Judgement é descrito fora do GCD, relevante para a apresentação dos avisos. |
| [Level 20](https://www.wowhead.com/forever/guide/classes/paladin/retribution/level-20-dps-overview) | 29/09/2026 | Contexto de beta: builds, rotação, equipamentos de dungeon/missão/crafting, camping e missões de classe. Útil como histórico; preferências e talentos devem ser revalidados nas páginas atuais e no cliente. |
| [Level 30](https://www.wowhead.com/forever/guide/classes/paladin/retribution/level-30-dps-overview) | 10/10/2026 | Contexto de beta, explicitamente sem novas atualizações. Inclui talentos/Legacy, rotação, equipamentos, camping e missões. Ainda usa Twist of Light e números antigos de talentos; não serve como regra atual de combate. |

## Conferências adicionais e divergências

- [Unsealed Wrath](https://www.wowhead.com/forever/spell=1310735/unsealed-wrath): o tooltip descreve cópias do selo por 15 segundos, até três acúmulos. Um ataque que acerta com outro selo consome as cópias, cada uma com a chance normal de ativar o selo armazenado. Trocar o selo, sozinho, não comprova consumo. O ID da página do talento não comprova o ID do buff dos ecos no cliente. O registro separado de [Echo of Command, 1311703](https://www.wowhead.com/forever/spell=1311703/echo-of-command) identifica o buff usado na leitura de ecos; a leitura real ainda exige validação no cliente.
- [Sacred Arbiter](https://www.wowhead.com/forever/spell=1311087/sacred-arbiter): tooltip confirma aumento de 20% em Holy Strike e renovação dos efeitos de Judgement no alvo. Só aplicar essa expectativa quando o personagem tiver o talento.
- [Vengeance](https://www.wowhead.com/forever/spell=20049/vengeance): página adicional localizada. O overview atual descreve cinco acúmulos, enquanto o guia antigo de nível 30 descreve três. Conferir o buff real antes de estabelecer um limite.
- Champion of the Light aparece como 3/3 na página de atributos e 5/5 na tabela atual de leveling. Essa tabela também lista três níveis para Precision, mas escreve 2/2. Registrar como inconsistências editoriais, sem reconstruir uma árvore exata por suposição. Fontes: páginas de atributos e leveling acima.

## Proposta inicial do addon

O usuário confirmou os três contextos e pediu um perfil ativo. A primeira implementação usa seleção manual de Leveling, Dungeon ou Raid, salva por personagem. Cada perfil define cooldowns acompanhados e orientações/preparação. Isso não representa troca de talentos ou equipamento.

Começar por um painel pequeno e móvel para acompanhar o selo ativo e a mecânica de ecos, com lembretes de habilidades prontas e mana. Preparação de Crusader pode ser um lembrete separado para lutas longas. O modo de área pode começar com seleção manual, evitando estimativas imprecisas de inimigos próximos.

Para o ciclo de selos, distinguir quatro situações: acumular em Command; avisar a troca; aguardar o ataque que consome os ecos em Righteousness; avisar o retorno. Atualizar esse estado a partir de evidência disponível no cliente, evitando assumir que toda troca ou ataque resulta em consumo.

Não colocar uma troca obrigatória de selo em uma lista que sempre exige Command ativo: isso poderia fazer o aviso mandar voltar antes de gastar os ecos. Essa é uma consequência de implementação extraída da mecânica, não uma prioridade adicional publicada pelo guia.

Antes de codificar a integração, confirmar cliente/build, idioma, habilidades/talentos do personagem e disponibilidade das APIs necessárias. O repositório estava vazio na inspeção inicial; não existem callers, testes, fixtures ou configurações anteriores para adaptar. A primeira implementação precisará de manifesto do addon, Lua, instruções de instalação e um teste pequeno do ciclo de selos.

Ficam para depois: avaliador de equipamentos, catálogo de BiS, árvores de talentos interativas e suporte completo a Shockadin/PvP. A pesquisa cobre essas páginas, mas elas não precisam virar funcionalidades da primeira versão.

## Verificação necessária no jogo

Validar leitura de selos/ecos e consumo após acerto, erro/esquiva, expiração, troca de alvo e fim de combate. Conferir personagem sem Unsealed Wrath, habilidade ainda não aprendida, cooldown, GCD, mana insuficiente e alvo inválido. Validar idioma e carregamento no cliente real antes de declarar o addon compatível.

Status: primeira versão implementada em `MyPalladin/`, com perfis, cooldowns e barra de mana. Testes locais em `tests/profiles_test.lua`. Acompanhamento de selos/ecos e alertas automáticos ainda pendentes; nenhum teste dentro do jogo foi realizado. As instruções de instalação e os limites estão no README.
