# Auditoria de cobertura do guia Wowhead

Consulta em **14/11/2026**, para o cliente informado **WoW: Forever 1.60.1 (70938)**, PvE, em inglês. Este arquivo registra o que foi realmente lido; complementa `guia-wowhead.md` sem transformar conteúdo inacessível em conteúdo verificado.

## Resultado e método

Foram identificadas e lidas as **10 páginas editoriais de Retribution**: oito atuais e duas de beta. A busca ampliada encontrou também **um guia comunitário antigo**, que foi lido. As subseções textuais dessas páginas foram percorridas, inclusive as variantes de alvo único, área, Shockadin e PvP. Uma captura posterior do markup das oito páginas atuais recuperou os quadros e payloads ausentes na extração inicial, conforme a seção abaixo. **A cobertura das páginas completas continua parcial** quanto à execução de calculadoras, imagens e outros componentes interativos.

A descoberta cruzou a navegação encontrada nos resultados do próprio [Wowhead](https://www.wowhead.com/forever/guide/classes/paladin/retribution/talent-builds-pve-dps), o [índice de Paladin](https://www.wowhead.com/forever/guides/classes/paladin), buscas pelo caminho da especialização e buscas por guias comunitários. O índice pesquisável anunciou 35 guias de Paladin; isso inclui Holy, Protection e discussão geral, não 35 subpáginas de Retribution. Sua abertura direta devolveu apenas o cabeçalho, enquanto os resultados de busca expuseram a listagem.

Os nomes Raid/Dungeon/PvP dentro de talentos e as divisões de rotação aparecem como seções do mesmo artigo. Não foram encontradas URLs editoriais atuais adicionais de Retribution além das oito abaixo. Isso é o resultado desta descoberta, não uma garantia de que nenhuma página não indexada exista. Traduções, parâmetros e fragmentos de uma mesma página não foram contados como guias distintos.

## Inventário editorial

“Texto lido” significa o corpo textual extraído até o final do artigo; não significa validação de widgets. Datas são as exibidas na abertura direta. A coluna de referências conta os destinos numerados visíveis no corpo, excluindo autor e ferramentas auxiliares, antes dos comentários; não conta URLs únicas entre artigos nem links ocultos no JavaScript.

| Página | Atualização | Seções textuais lidas | Referências | Limite restante |
| --- | --- | --- | ---: | --- |
| [Visão geral](https://www.wowhead.com/forever/guide/classes/paladin/retribution/overview-pve-dps) | 14/11 | Mudanças de habilidades e talentos; viabilidade; vantagens/desvantagens; iniciantes; sistema de selos; raças; profissões. | 46 | Quadros de vantagens/desvantagens e disponibilidade por raça recuperados no markup; sem validação no cliente. |
| [Talentos](https://www.wowhead.com/forever/guide/classes/paladin/retribution/talent-builds-pve-dps) | 13/11 | Raid Retribution e Shockadin; dungeon; PvP Retribution e Shockadin. | 1 | Quatro payloads exatos recuperados; árvores renderizadas e tradução completa de seus pontos ainda não verificadas. |
| [Rotação](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps) | 14/11 | Mecânicas; comparação e escolha dos selos; explicação de procs; prioridades em alvo único e área; Shockadin; cooldowns de dano e sobrevivência. | 26 | Texto das três variantes lido; comportamento real das habilidades depende do cliente. |
| [Encantamentos e consumíveis](https://www.wowhead.com/forever/guide/classes/paladin/retribution/enchants-consumables-pve-dps) | 31/10 | Slots; opções de arma no nível máximo; poções; elixires; efeitos temporários de arma; comida. | 74 | O próprio artigo é provisório e voltado principalmente ao leveling. |
| [Atributos](https://www.wowhead.com/forever/guide/classes/paladin/retribution/stat-priority-pve-dps) | 31/10 | Prioridade; força, intelecto, agilidade, stamina e espírito; perícia de arma, dano/velocidade, acerto, expertise, crítico, dano mágico, AP e haste. | 14 | Caps e comparações no nível máximo ainda têm ressalvas explícitas. |
| [Leveling](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips) | 14/11 | Viabilidade; progressão de talentos; treinamento obrigatório/opcional; selos; alvo único/área; profissões; camping; Legacy; consumíveis; dicas. | 54 | Prós/contras e payload recuperados; árvore renderizada não validada; inconsistências editoriais permanecem. |
| [Equipamentos](https://www.wowhead.com/forever/guide/classes/paladin/retribution/bis-gear) | 14/11 | Conjuntos; fase inicial; cabeça, ombros, costas, peito, pulsos, mãos, cintura, pernas, pés, pescoço, anéis, trinkets, armas e librams. | 7 | IDs de itens e payload do planner recuperados; estatísticas não validadas; rankings continuam provisórios. |
| [Habilidades](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-abilities) | 13/11 | Dano; selos; cura; auras; bênçãos; utilidade; controle. | 40 | Tooltips individuais de todas as habilidades não foram abertos. |
| [Nível 20](https://www.wowhead.com/forever/guide/classes/paladin/retribution/level-20-dps-overview) | 29/09 | Visão geral; dicas solo/dungeon; builds Holy e Ret; rotação; drops; missões; crafting; camping; missões de classe. | 82 | Beta; calculadoras e uma entrada de item não ficaram completas. |
| [Nível 30](https://www.wowhead.com/forever/guide/classes/paladin/retribution/level-30-dps-overview) | 10/10 | Visão geral; mudanças desde 20; dicas solo/dungeon; talentos; pontos Legacy; rotação; drops; missões; crafting; camping; missões de classe. | 113 | O artigo declara que deixou de ser atualizado; árvore interativa não validada. |

São **457 referências visíveis somadas por artigo na extração inicial**, com repetições entre páginas. Incluem registros de habilidades/talentos, itens, missões, dungeons, profissões e outros registros do banco. **Não foram lidas 457 páginas individuais**. A contagem não mede subpáginas editoriais; o markup posterior permitiu separar os tipos de registros das oito páginas atuais, como descrito abaixo.

## Releitura do markup capturado

O usuário executou o coletor com acesso à rede e disponibilizou o corpo dos oito artigos atuais em `.guide-monitor/state.json`, sob `latest[slug].text`. Foi inspecionada a captura com `checked_at = 2026-11-14T12:43:23.993514+00:00`, `complete = true` e `errors = {}`. Os corpos contêm BBCode da página, inclusive `[talent=...]`, tabelas e `[cta-button guide=...]`; não são apenas o texto simplificado da busca. Esses indicadores confirmam a captura do coletor, sem provar que todo widget foi executado. Os campos `modified` vieram vazios e não confirmam as datas editoriais da tabela anterior.

Foi conferida a estrutura dos oito corpos, suas seções/abas, tabelas, referências e configurações de embeds. A captura confirma que os submenus editoriais são seções `[h2 ... toc=...]` e variantes `[tab name=...]` dentro das mesmas páginas. A navegação do corpo contém sete destinos de artigos; BiS é o oitavo artigo acompanhado e foi consultado separadamente. No leveling há cinco CTAs por ID: `12864` (visão geral), `12285` (profissões), `34796` (camping), `34790` (Legacy) e `12869` (consumíveis). Todos os assuntos de destino já constam deste inventário. Fonte: [leveling](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips).

No conjunto desses oito corpos foram identificados, deduplicados por tipo/ID, **114 registros de spell, 69 de item e um de faction**, além dos cinco CTAs, sete caminhos de navegação e quatro payloads diferentes de talentos. São referências do banco e configurações de ferramentas; não são 114 ou 69 guias editoriais adicionais.

O quadro recuperado da [visão geral](https://www.wowhead.com/forever/guide/classes/paladin/retribution/overview-pve-dps) destaca dano em alvo único, suporte, desempenho contra Undead/Demon, leveling, recursos de emergência e escolha de build. Lista como limitações a falta de grande cooldown de dano, consumo de mana, dependência de equipamento, ausência de interrupt/slow e **AoE/cleave fracos**. Isso corrige o resultado antigo de busca que descrevia AoE como forte. O quadro de raças marca Human e Dwarf e destaca Undead como combinação nova; as demais colunas ficam vazias.

O quadro recuperado de [leveling](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips) confirma sustentação, resistência, dano inicial e utilidade, contrapostos à falta de pull à distância/deslocamento rápido, dependência de arma/equipamento e vulnerabilidade sem mana. A tabela literal de progressão continua apresentando Champion of the Light em cinco níveis e Precision em três níveis com rótulo `2/2`; capturar o markup não resolve essas inconsistências.

### Payloads exatos de talentos

Os valores abaixo foram copiados dos quatro embeds do [artigo de talentos](https://www.wowhead.com/forever/guide/classes/paladin/retribution/talent-builds-pve-dps). Preservam os dados publicados sem interpretar cada dígito como um talento ou garantir que uma árvore migrada permaneça válida. A tentativa de abrir URLs de calculadora construídas com esses valores não foi acessível pela ferramenta web; por isso elas não são apresentadas como links validados.

| Variante | Valor literal de `talent` |
| --- | --- |
| PvE Retribution / Unsealed Wrath | `paladin/vkndmh050050002-503-05233011201301351_t0/2BCEhJddmNdRqgSt0BEJ1AC` |
| PvE Holy / Shockadin | `paladin/vkndmh05025210221021--0523320120130033_t0/2BCDhEjmNjRffsss0BEDFgmJKqP` |
| PvP Retribution | `paladin/vkndmh050050002-503-50233011201301351_t0/2ACEhJddmdNqRgSt0BEJ1AC` |
| PvP Holy / Shockadin | `paladin/vkndmh50125010222001--5023310120130135_t0/2ACDJheemNeqRfS0AEgJDKMcq` |

O [embed de leveling](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips) repete exatamente o payload PvE Retribution e acrescenta `abilities=true`. Isso confirma a reutilização da configuração, sem verificar a lista de ranks produzida pela calculadora.

O markup de [BiS](https://www.wowhead.com/forever/guide/classes/paladin/retribution/bis-gear) recupera os IDs de raid `280930`, `280929`, `280928`, `280925`, `280927`, `280926` e os craftados `273910`, `273909`, `273908`, `273911`. Contém quatro IDs de screenshots e um embed de gear planner. As abas de bônus Holy/Protection/Retribution foram conferidas; o próprio artigo os classifica como placeholders. IDs recuperados não confirmam estatísticas dos itens nem tornam o conjunto definitivo. O payload do planner é:

```text
paladin/human/FQBgcAAAAAQBB09r8AznOBC1Xt8AorbBD09v28LBF09t0oZAG1AyBH09u1UYBI09s0oXBJ1BC0oKBK1At8AolgAL1XeAM0eYAN1WKAO0euBP1CuzIaAQz7-AS46QT
```

## Páginas adicionais encontradas e consultadas

| Página | Status e conteúdo coberto | Consequência |
| --- | --- | --- |
| [Guia comunitário Twist of Light](https://www.wowhead.com/forever/guide/wow-forever-twist-of-light-retribution-paladin-guide-35020) | Texto lido: ferramentas básicas, árvore Ret, build 12/8/31 com progressão, leveling, pendências de beta e fontes. Atualizado em 08/10; autor Drakanthos. | Histórico. Descreve Judgement consumindo selo e capstone anterior; diverge das páginas editoriais atuais. Não usar suas regras no monitor atual. |
| [Camping](https://www.wowhead.com/forever/guide/camping-overview-unlock-rewards) | Texto do artigo lido: benefícios, desbloqueio, itens de profissões primárias/secundárias, requisitos, Legacy e vendedores. | Mana Well, Lodestone e Fish Bowl têm exclusividade com Wisdom, Might e Kings respectivamente. Duração de buffs deve ser observada no personagem. |
| [Legacy](https://www.wowhead.com/forever/guide/legacy-system-overview-rewards) | Texto do artigo lido: sistema, reset, desafios, três categorias de perks, recompensas e regras Hardcore. Calculadora não validada. | Pontos compartilhados, escolhas por personagem. Talented tem ranks; Thrill of Adventure e Field Medicine possuem restrições em instâncias. Permanence altera duração de buffs. |
| [Profissões](https://www.wowhead.com/forever/guide/professions/overview) | Texto completo disponível lido, incluindo tabelas do corpo: camping/Legacy, ranks, leveling, Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring, Cooking, First Aid, Herbalism, Mining, Skinning e Fishing. Foram percorridas as linhas extraídas 0–1097, sem lacunas, até o início da área de contribuição. | Confirma a importância de consumíveis e treinamento. Ler as tabelas do artigo não equivale a abrir cada receita ou os guias específicos de profissão. Widgets e registros individuais continuam sem validação integral. |

Consultar o [índice geral](https://www.wowhead.com/forever/guides) pelos resultados de busca e buscar guias de equipamentos antes de raid não revelou uma página editorial específica adicional de Retribution Forever. Resultados de outras expansões e gear sets enviados por usuários não foram tratados como substitutos do guia solicitado.

## Tooltips centrais conferidos

- [Unsealed Wrath, 1310735](https://www.wowhead.com/forever/spell=1310735/unsealed-wrath): cópias do selo duram 15 segundos, até três. Um ataque que acerta com outro selo consome os acúmulos. Cada cópia recebe a chance normal de ativação; dois ecos não garantem dois procs. A página do talento não identifica, por si só, o ID do buff dos ecos no cliente.
- [Sacred Arbiter, 1311087](https://www.wowhead.com/forever/spell=1311087/sacred-arbiter): aumenta Holy Strike e o faz renovar os efeitos de Judgement no alvo. Essa regra depende do talento aprendido.
- [Seal of Command, 20375](https://www.wowhead.com/forever/spell=20375/seal-of-command) e [Seal of Righteousness, 20293](https://www.wowhead.com/forever/spell=20293/seal-of-righteousness): os registros consultados mostram duração de 30 segundos e GCD de 1,5 segundo. Não generalizar mana/dano desses ranks para todos os níveis. Comentários antigos presentes nessas páginas não foram usados como regras atuais.

## Fatos que afetam o addon

As prioridades atuais distinguem Retribution de Shockadin. O primeiro alterna Command/Righteousness quando tem Unsealed Wrath; o segundo mantém Righteousness. Dungeon usa essencialmente os mesmos talentos de raid. Portanto o perfil de atividade não prova qual build foi aprendida. Fontes: [talentos](https://www.wowhead.com/forever/guide/classes/paladin/retribution/talent-builds-pve-dps) e [rotação](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps).

O guia costuma recomendar dois ecos em PvE. O monitor precisa distinguir a espera pelo acerto com Righteousness do retorno a Command. Mana condiciona Consecration; Crusader é preparação para inimigos duradouros. Inferência de implementação: a instrução geral de manter Command não pode cancelar a etapa de gastar ecos. Fonte: [rotação](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps).

Exorcism depende do tipo do alvo; Hammer of Wrath depende de vida abaixo de 20%. Bênçãos, auras, dispels, cura e controle também fazem parte do kit descrito, ainda que não sejam uma rotação automática. Fonte: [habilidades](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-abilities).

A progressão não deve depender só do nível: Legacy pode antecipar talentos, o jogador pode escolher outra ordem e precisa treinar habilidades. Há divergências entre dados de busca e abertura direta e entre tabelas do próprio guia; por exemplo, Champion of the Light aparece com ranks diferentes em atributos e leveling. Inferência: disponibilidade, ranks e auras realmente observados no cliente devem decidir os alertas. Fontes: [leveling](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips), [atributos](https://www.wowhead.com/forever/guide/classes/paladin/retribution/stat-priority-pve-dps), [Legacy](https://www.wowhead.com/forever/guide/legacy-system-overview-rewards).

## Verificação específica dos Changelogs

O nome Changelog aparece na navegação indexada. Entretanto, a extração das dez páginas não fornece um link numerado com o destino desse controle nem as entradas do histórico. Foram testados individualmente os fragmentos abaixo; todos devolveram o respectivo artigo sem uma seção ou tabela de alterações:

| Artigo | Sonda testada | Resultado |
| --- | --- | --- |
| Visão geral | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/overview-pve-dps#changelog) | Artigo, sem histórico. |
| Talentos | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/talent-builds-pve-dps#changelog) | Artigo, sem histórico. |
| Rotação | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps#changelog) | Artigo, sem histórico. |
| Encantamentos/consumíveis | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/enchants-consumables-pve-dps#changelog) | Artigo, sem histórico. |
| Atributos | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/stat-priority-pve-dps#changelog) | Artigo, sem histórico. |
| Leveling | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips#changelog) | Artigo, sem histórico. |
| Equipamentos | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/bis-gear#changelog) | Artigo, sem histórico. |
| Habilidades | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-abilities#changelog) | Artigo, sem histórico. |
| Nível 20 | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/level-20-dps-overview#changelog) | Artigo, sem histórico. |
| Nível 30 | [URL + fragmento](https://www.wowhead.com/forever/guide/classes/paladin/retribution/level-30-dps-overview#changelog) | Artigo, sem histórico. |

Esses fragmentos são **sondas**, não destinos comprovados do menu. Na visão geral também foram sondadas as variantes `/changelog`, `?changelog` e `?view=changelog`; as três foram devolvidas pela ferramenta como inacessíveis. Buscas por históricos específicos não localizaram uma URL de changelog de Retribution Forever acessível separadamente. O fetch local por `curl` falhou na resolução DNS, e o navegador disponível não iniciou por ausência do Chrome.

Na captura posterior, nenhum dos oito corpos de artigo contém a palavra `changelog` ou dados desse histórico. Como o cache contém o corpo editorial, isso não inspeciona o controle da interface externa ao artigo.

Status exato: **os dez históricos não foram lidos; não foi possível confirmar o destino do controle nem distinguir, com evidência do DOM/rede, uma URL própria de um painel carregado por JavaScript**. Não se afirma que o histórico inexista ou seja necessariamente um widget. A data de atualização exibida no artigo não substitui esse histórico.

## O que permanece parcial ou não lido

- **Parcial:** execução das calculadoras de talentos e Legacy, gear planner, screenshots e conteúdo adicional carregado por JavaScript. Os payloads de talentos e planner e as tabelas do markup atual foram recuperados; isso não valida a renderização, todas as distribuições ou os atributos dos itens. O conteúdo textual dos quadros de vantagens/desvantagens e raças deixou de ser uma lacuna.
- **Não lido:** históricos completos de alterações (Changelog), com tentativas e resultados individuais registrados acima.
- **Não lido sistematicamente:** cada página individual de item, missão, NPC, dungeon, receita, habilidade e talento. As tabelas dentro dos artigos foram lidas; isso não equivale a abrir todos os seus registros.
- **Fora do recorte:** guias completos de Holy healer e Protection tank, outras expansões, comentários paginados, fóruns e coleções arbitrárias de gear sets comunitários. Shockadin foi lido nas seções do guia de DPS.
- **Sem validação no jogo nesta auditoria:** APIs, nomes/IDs reais dos buffs e eventos de combate do cliente 70938.

Foi tentada uma inspeção visual via Playwright, mas ela falhou porque Chrome não está instalado no ambiente (`/opt/google/chrome/chrome`). A leitura textual e as buscas funcionaram. Por isso, a afirmação correta é: **todos os 10 artigos editoriais identificados de Retribution foram lidos em sua parte textual disponível, com limites explícitos de widgets; não foi verificado todo o conteúdo interativo nem todo o banco de links**.
