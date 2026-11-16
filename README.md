# My Paladin

Addon de apoio para **Retribution Paladin PvE no WoW: Forever**. Acompanha cooldowns, mana e buffs, com perfis para Leveling, Dungeon e Raid.

Desenvolvido para **Forever 1.60.1**, Interface **16001**, com o cliente em inglês. A interface do addon também usa inglês.

## Funcionalidades

- Cooldowns das habilidades aprendidas, com seleção do que aparece em cada perfil.
- Barra de mana com alerta e limite configurável.
- Indicadores de selo, bênção e aura.
- Aviso de selo com ícone e nome, independente do painel e visível durante combate.
- Abertura opcional com Crusader para lutas longas, guiada por etapas.
- Contagem e orientação dos ecos de Command para a build Unsealed Wrath.
- Perfis por personagem, com preferências de layout, alertas e preparação.
- Bênção e aura desejadas por perfil, com lembretes de preparação fora de combate.
- Contexto Single/AoE por perfil e dicas condicionais com o painel fechado.
- Escolha dinâmica de habilidade por cooldown, usabilidade e alcance públicos: Now, Wait ou Check.
- Motor com memória dos próprios casts, manutenção estimada de selo, tecla e destaque na barra nativa.
- Diagnóstico local das decisões dos avisos, casts públicos e erros do addon.
- Motivos de restrição das APIs, separados entre fora e dentro de combate no relatório.
- Painel compacto ou expandido, com posição ajustável.

## Instalação

1. Baixe ou clone este repositório.
2. Com o jogo fechado, execute `python scripts/install_addon.py`. O caminho padrão é a instalação em `Faugus/battlenet`; use `--game-dir '/caminho/_forever_'` para outro local.
3. Abra o jogo e habilite **My Paladin** na lista de AddOns.

A estrutura deve ficar assim:

```text
_forever_/Interface/AddOns/MyPaladin/
├── MyPaladin.toc
├── MyPaladin.lua
├── Profiles.lua
├── PlayerState.lua
├── Diagnostics.lua
├── CombatState.lua
├── ActionHints.lua
└── GuideInfo.lua
```

O instalador migra a instalação antiga `MyPalladin` para **MyPaladin**, copia as configurações por personagem e arquiva a pasta antiga fora de `AddOns`. Preserva os originais e cria um backup em `_forever_/Interface/MyPaladin-backups/`. Uma instalação repetida preserva as configurações novas. Feche o jogo antes da migração para ele não regravar os arquivos antigos.

Para uma instalação nova manual, copie apenas `MyPaladin/`, sem pasta extra entre ela e `AddOns`. A migração de configurações requer o instalador.

Ao substituir os arquivos de uma instalação existente, use `/reload` para carregar a atualização.

Desde a 0.9.0, o instalador permite atualizar uma instalação já migrada com o jogo aberto, sem tocar nas configurações salvas. Aguarde o comando terminar e use `/reload`. Primeira instalação ou migração do nome antigo continuam exigindo o jogo fechado.

## Uso

| Comando | Ação |
| --- | --- |
| `/mp` | Abre ou fecha o painel |
| `/mp leveling` | Ativa o perfil Leveling |
| `/mp dungeon` | Ativa o perfil Dungeon |
| `/mp raid` | Ativa o perfil Raid |
| `/mp compact` | Alterna entre painel compacto e expandido |
| `/mp settings` | Abre ou fecha as configurações |
| `/mp opener` | Liga ou desliga a abertura com Crusader no perfil ativo |
| `/mp echoes` | Liga ou desliga a orientação de ecos no perfil ativo |
| `/mp single` / `/mp aoe` | Seleciona o contexto da luta no perfil ativo |
| `/mp trace` | Mostra o estado do diagnóstico |
| `/mp trace on` / `/mp trace off` | Liga ou desliga a gravação local |
| `/mp trace mark texto` | Marca um momento da sessão para análise |

Arraste o painel para mudar sua posição. Abra **Settings** para escolher os cooldowns, ajustar o alerta de mana e selecionar os lembretes de preparação. A preparação aparece no modo expandido, quando habilitada.

### Perfis

| Perfil | Foco | Habilidades adicionais acompanhadas |
| --- | --- | --- |
| Leveling | Preparação para solo e mana entre lutas | Holy Light, Divine Shield, Lay on Hands |
| Dungeon | Controle e suporte ao grupo | Cleanse, Hammer of Justice, Protection/Freedom, Divine Shield, Lay on Hands |
| Raid | Preparação e suporte coordenado | Cleanse, Freedom/Protection, Hammer of Justice, Divine Shield, Lay on Hands |

Todos incluem Judgement, Holy Strike, Hammer of Wrath, Exorcism e Consecration, quando aprendidos e habilitados nas configurações.

Cada perfil salva suas próprias preferências por personagem. A seleção é manual e persiste após `/reload` ou saída normal do jogo. Entrar numa instância não troca o perfil automaticamente.

### Preparação de grupo

Em Settings, clique nos seletores **Blessing** e **Aura** para percorrer as opções. **Any** aceita qualquer buff acompanhado e é o padrão. Uma escolha específica exige aquele buff; outro buff da mesma categoria não satisfaz a escolha. As preferências são independentes por perfil.

O indicador mostra **not learned** quando a habilidade escolhida não está aprendida e o buff está ausente. Um buff correspondente fornecido por outro jogador também conta. Dados restritos continuam em cinza, sem afirmar ausência.

Com um selo ativo, o aviso independente pode lembrar a bênção ou aura aprendida que estiver faltando **fora de combate**. Durante a luta, ficam apenas os indicadores do painel. Os avisos não lançam buffs nem escolhem atribuições para o grupo.

Os lembretes de Dungeon incluem comida, água, buff de arma e Mana Potions. Raid também inclui elixires. São lembretes configuráveis, sem checagem automática de bolsas ou consumo.

### Aviso de selo

Quando detecta ausência de selo, o addon mostra **Seal missing** com o ícone e o nome do selo base recomendado. O aviso funciona com o painel fechado, desaparece ao aplicar um selo e reaparece quando detectar uma nova ausência. Use sua barra de ações para lançar a habilidade.

A recomendação considera os selos aprendidos, Holy Shock e a arma equipada. Fora da abertura e da orientação de ecos, qualquer selo ativo oculta o aviso.

Arraste o aviso fora de combate para reposicioná-lo. Durante combate, ele deixa passar os cliques. A opção **Highlight missing buffs** controla esse aviso por perfil.

### Abertura com Crusader

Para elites, bosses ou outras lutas longas, ative **Crusader opener (long fights)** em Settings ou use `/mp opener`. A opção começa desligada e fica salva por personagem e perfil. Desative-a para inimigos que morrem rápido.

Com um alvo hostil, vivo e visível, o aviso acompanha esta sequência:

| Aviso | Ação |
| --- | --- |
| **Apply Crusader** | Aplique Seal of the Crusader |
| **Judge Crusader** | Use Judgement, inclusive pelo seu macro de Judgement/Holy Strike |
| **Switch seal** | Troque para o selo de dano indicado no aviso |

A etapa de troca só aparece após detectar seu **Judgement of the Crusader** no alvo. Ao aplicar um selo de dano, o aviso desaparece; trocar de alvo reavalia a abertura. Se o debuff deixar de ser detectado, a orientação volta à etapa necessária. Judgement não consome seu selo no Forever.

É necessário ter Crusader e Judgement aprendidos. A abertura não é sugerida quando Holy Shock está aprendido. O critério segue a [rotação de Retribution do guia de Forever](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps).

Dados restritos mostram **Check Crusader** em cinza. O addon não presume sucesso pelo aperto do macro nem pelo cooldown; cooldown, alcance e mana ainda precisam permitir a ação indicada.

### Ecos de Unsealed Wrath

A opção **Unsealed Wrath echoes** fica ligada por padrão e só atua com o talento e os dois selos aprendidos. Durante combate, com um alvo hostil, vivo e visível e Command como selo base recomendado, o aviso acompanha este ciclo:

| Aviso | Ação |
| --- | --- |
| **Build echoes** | Mantenha Command enquanto acumula 0 ou 1 eco |
| **Spend echoes** | Com 2 ou 3 ecos, troque para Righteousness |
| **Land a melee hit** | Mantenha Righteousness enquanto houver ecos de Command |
| **Return to Command** | Volte a Command quando não houver mais ecos de Command |

A orientação usa a contagem do buff **Echo of Command**, seguindo o [ciclo PvE do guia de Forever](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps). Uma troca de selo ou tentativa de ataque não confirma o consumo. A ausência do buff também pode decorrer de expiração ou dispel; o aviso não afirma que houve dano.

**Check echoes** em cinza significa dados protegidos ou indisponíveis. A contagem não é estimada por ataques ou tempo. A abertura com Crusader tem prioridade, e selos de utilidade não são substituídos pela orientação de ecos.

Use `/mp echoes` ou Settings para desligar a orientação no perfil ativo. **Highlight missing buffs** controla todos os avisos independentes. Ao carregar o addon já em combate, a orientação de ecos aguarda a verificação da arma fora de combate.

### Contexto da luta

O botão **Mode: Single** / **Mode: AoE** no topo do painel mostra o contexto atual; clique nele ou use os comandos correspondentes para alternar. A escolha é manual e fica salva por perfil. **Combat context hints** em Settings controla uma dica independente abaixo do aviso de selo, inclusive com o painel fechado.

Na 0.9.0, a dica deixa de ser um lembrete permanente. Em combate, com alvo válido, procura uma habilidade aprendida com **usabilidade, alcance e cooldown públicos e válidos**. Em Single, considera Judgement → Hammer of Wrath elegível → Holy Strike → Exorcism elegível. Em AoE, Consecration entra após Judgement. A ordem acompanha o guia de Forever; as decisões de selo/ecos continuam separadas.

**Now** em verde indica uma habilidade que passou por essas verificações. Se Judgement entrar em cooldown, a indicação pode mudar para Holy Strike. Sem uma opção pronta, **Wait** mostra o cooldown calculável mais próximo; **Check** informa impedimentos como falta de mana, alcance ou dados indisponíveis. A indicação se atualiza por eventos e a cada 0,1 segundo enquanto estiver visível, inclusive com o painel fechado. Os registros diferenciam `ready`, `wait` e `check`.

Na 0.9.1, os indicadores públicos `isEnabled`/`isActive` permitem verificar o cooldown mesmo quando seus tempos estão protegidos. Habilidade habilitada e sem cooldown ativo pode receber **Now** após as demais verificações. Cooldown ativo com tempos protegidos recebe **Wait**, com exibição nativa, sem contagem calculada. Se o indicador de atividade não estiver acessível, somente tempos públicos e válidos podem confirmar prontidão. A captura real da 0.9.0 havia ficado em **Check** por exigir esses tempos mesmo quando o indicador público poderia bastar.

Consecration exige AoE selecionado manualmente e um alvo em alcance de Holy Strike como verificação conservadora de proximidade; não conta inimigos. Mana baixa pública evita esse gasto. Com mana bruta protegida, a possibilidade de pagar o custo vem de `IsSpellUsable`; não há garantia de sustentar vários casts. Hammer of Wrath entra quando o cliente o declara usável: o guia o limita a alvos abaixo de 20% de vida, e o jogo aplica esse limite mesmo com a vida secreta; Exorcism exige Undead/Demon público. Dados protegidos são descartados antes de qualquer cálculo. Uma opção inferior verificada pode ser indicada mesmo se a leitura de outra falhar; isso não garante prioridade ótima nessa situação.

A animação de cooldown continua nativa. **Now** descreve o estado verificado naquele momento; não garante sucesso do cast, acerto, linha de visão ou ausência de mudanças entre a indicação e a ação. O addon não lança habilidades.

### Motor com memória — 0.10.0

Durante combate, o motor reúne manutenção de selo/abertura e dano em uma indicação principal, evitando dois avisos concorrentes. A opção **Combat context hints** controla o motor; com ela desligada, o HUD independente mantém seu comportamento anterior. **Highlight missing buffs** continua controlando manutenção de selo.

- **Now**, em verde: ação com condições verificadas nas consultas públicas usadas.
- **Estimate**, em âmbar: ação de manutenção baseada em um estado estimado do selo/debuff.
- **Casting**: aguarde o cast atual; a indicação não pede dano no meio de uma cura.
- **Wait / Check**: cooldown ativo ou impedimento explicado na linha abaixo do ícone.

Durante o GCD, a habilidade seguinte continua indicada. O campo público `isOnGCD` do cooldown decide quando disponível; sem ele, uma habilidade que estava pronta e não foi lançada continua indicada, como **Wait** com *Ready after the global cooldown*, por até 1,6s. Isso evita pular para Judgement em seu cooldown real a cada cast.

Ao observar um cast próprio de selo, o motor mantém uma estimativa de 30 segundos e substitui o selo anterior. Com o selo restrito, a usabilidade pública de Judgement serve de evidência: o guia diz que Judgement libera o selo ativo, então Judgement inutilizável sem falta de mana indica ausência de selo, e Judgement usável impede pedir renovação após a estimativa vencer. Uma leitura pública posterior corrige esse estado. Quando a leitura fica oculta, o vencimento estimado pode sugerir reaplicação; isso não prova que o selo durou até ali. Dispel ou remoção antecipada podem invalidar a estimativa. Um reload em combate sem leitura pública começa como desconhecido até haver nova evidência, sem inventar selo ativo ou ausente. Há uma tolerância de 0,25s para a atualização da aura após o evento de cast.

Com a abertura Crusader ativada, o histórico pode orientar julgar o selo e trocar para dano quando o debuff estiver oculto. Esse progresso é **estimado**, vale só para o alvo atual e é descartado ao trocar de alvo. Não confirma que o debuff acertou. O motor não simula contagens de ecos nem usa a heurística de 6/8 segundos do Sonah.

O ícone principal mostra a tecla e faz o botão brilhar nas barras padrão da Blizzard com a arte de proc do jogo: dourado para **Now**, laranja para **Estimate**. A animação roda num frame do próprio addon, sem chamar o gerenciador de alertas da Blizzard, que escreveria nos botões seguros. Sem essa arte no cliente, o addon usa uma borda pulsante. Na 0.10.1, o macro simples com `/cast Judgement` seguido de `/cast Holy Strike` aparece como **Holy Strike macro** para ambas as habilidades. A linha abaixo identifica qual habilidade está pronta ou em cooldown; não pede um Judgement separado, nem repete a outra habilidade do mesmo macro como **Also ready**. O cooldown continua sendo consultado após o cast confirmado, sem presumir sucesso só por existir uma linha no macro.

O leitor entende casts simples e a habilidade exibida pelo macro; não resolve sequências ou ramificações condicionais. A construção do mapa ocorre fora de combate. Notificações de barra durante combate preservam apenas vínculos cuja identidade, conteúdo e tecla ainda possam ser confirmados por dados públicos; mudanças ou leituras indisponíveis descartam os vínculos afetados até a reconstrução fora de combate. Não são alteradas teclas, macros ou atributos de lançamento. Barras substitutas como ElvUI/Bartender ainda não estão integradas.

**Also ready** mostra uma segunda ação que também passou nas verificações atuais. É uma alternativa no estado atual, não uma previsão de como o combate ficará depois do próximo cast. Cooldown ativo/GCD continua bloqueando **Now**. Os testes locais verificam estimativa, substituição, expiração, reconciliação, casts, macro e destaque; a ajuda real e o tamanho/posição do HUD ainda precisam de validação em jogo.

Dados restritos produzem orientação cinza para conferir as condições. A documentação de Forever marca `UnitHealth` como secreto; desde a 0.10.6, Hammer of Wrath depende da usabilidade pública, ainda sem validação no cliente.

### Diagnóstico da sessão

A gravação começa ligada, com até **1000 registros por personagem**. Para analisar depois de jogar, use `/reload` ou saia normalmente e execute:

```sh
python scripts/monitor_session.py
```

O relatório fica em `.diagnostics/report.md`, com os eventos em `.diagnostics/events.jsonl`. Para acompanhar novos registros durante uma sessão, execute `python scripts/monitor_session.py --watch`. A chegada ao vivo depende de `C_Log` realmente escrever em disco; até confirmar isso, `/reload` ou saída normal é necessário para disponibilizar os dados salvos.

Veja [diagnóstico e roteiro de validação](docs/diagnostico.md). Os registros permitem conferir decisões e restrições; não comprovam dano, prontidão de habilidades ou apresentação visual.

## Limitações

- O motor indica uma ação principal e, no máximo, uma alternativa pronta no estado atual; não prevê uma fila de rotação nem cobre defensivos e controle. A lista de cooldowns do painel é apenas acompanhamento. O addon não lança habilidades nem troca talentos, equipamento ou teclas.
- Dados de combate podem ficar restritos. O aviso independente de selo fica oculto quando não é possível confirmar seu estado; a restrição continua no painel e nos logs. Na captura real da build 70938, a consulta de selos ficou bloqueada durante combate.
- Mana protegida mantém a barra nativa sem porcentagem ou alerta calculado. APIs de cooldown indisponíveis mostram **Cooldown unavailable**.
- Os testes locais usam APIs simuladas; o comportamento dos avisos e das restrições ainda precisa de validação no cliente real.

## Desenvolvimento

Os testes usam LuaJIT e Python 3, sem pacotes adicionais:

```sh
luajit tests/profiles_test.lua
luajit tests/player_state_test.lua
luajit tests/profile_settings_test.lua
luajit tests/crusader_opener_test.lua
luajit tests/echoes_test.lua
luajit tests/preparation_test.lua
luajit tests/combat_hints_test.lua
luajit tests/diagnostics_test.lua
luajit tests/api_diagnostics_test.lua
luajit tests/rotation_test.lua
luajit tests/combat_state_test.lua
luajit tests/action_hints_test.lua
python -m unittest discover -s tests -p 'test_*.py'
```

## Documentação

- [Roadmap e validações pendentes](docs/roadmap.md)
- [Monitoramento e revisão dos guias](docs/manutencao.md)
- [Pesquisa do guia de Forever](docs/guia-wowhead.md)
- [Cobertura das fontes](docs/cobertura-guia.md)
- [APIs e compatibilidade](docs/addon-api.md)
- [Diagnóstico e roteiro de validação](docs/diagnostico.md)
- [Assistência durante combate](docs/assistencia-combate.md)
- [Análise do Sonah Forever](docs/analise-sonah.md)
- [Referências de addons para Forever](docs/pesquisa-addons-forever.md)
