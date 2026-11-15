# My Paladin

Addon de apoio para **Retribution Paladin PvE no WoW: Forever**. Acompanha cooldowns, mana e buffs, com perfis para Leveling, Dungeon e Raid.

Desenvolvido para **Forever 1.60.1**, Interface **16001**, com o cliente em inglês. A interface do addon também usa inglês.

## Funcionalidades

- Cooldowns das habilidades aprendidas, com seleção do que aparece em cada perfil.
- Barra de mana com alerta e limite configurável.
- Indicadores de selo, bênção e aura.
- Aviso de selo com ícone e nome, independente do painel e visível durante combate.
- Abertura opcional com Crusader para lutas longas, guiada por etapas.
- Perfis por personagem, com preferências de layout, alertas e preparação.
- Painel compacto ou expandido, com posição ajustável.

## Instalação

1. Baixe ou clone este repositório.
2. Com o jogo fechado, copie a pasta `MyPalladin` para `_forever_/Interface/AddOns/`.
3. Abra o jogo e habilite **My Paladin** na lista de AddOns.

A estrutura deve ficar assim:

```text
_forever_/Interface/AddOns/MyPalladin/
├── MyPalladin.toc
├── MyPalladin.lua
├── Profiles.lua
├── PlayerState.lua
└── GuideInfo.lua
```

Mantenha o nome técnico `MyPalladin` da pasta e dos arquivos para preservar a compatibilidade com as configurações salvas. Não coloque uma pasta extra entre `AddOns` e `MyPalladin`.

Ao substituir os arquivos de uma instalação existente, use `/reload` para carregar a atualização.

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

Arraste o painel para mudar sua posição. Abra **Settings** para escolher os cooldowns, ajustar o alerta de mana e selecionar os lembretes de preparação. A preparação aparece no modo expandido, quando habilitada.

### Perfis

| Perfil | Foco | Habilidades adicionais acompanhadas |
| --- | --- | --- |
| Leveling | Preparação para solo e mana entre lutas | Holy Light, Divine Shield, Lay on Hands |
| Dungeon | Controle e suporte ao grupo | Cleanse, Hammer of Justice, Blessing of Protection |
| Raid | Preparação e suporte coordenado | Cleanse, Blessing of Freedom, Blessing of Protection |

Todos incluem Judgement, Holy Strike, Hammer of Wrath, Exorcism e Consecration, quando aprendidos e habilitados nas configurações.

Cada perfil salva suas próprias preferências por personagem. A seleção é manual e persiste após `/reload` ou saída normal do jogo. Entrar numa instância não troca o perfil automaticamente.

### Aviso de selo

Quando detecta ausência de selo, o addon mostra **Seal missing** com o ícone e o nome do selo base recomendado. O aviso funciona com o painel fechado, desaparece ao aplicar um selo e reaparece quando detectar uma nova ausência. Use sua barra de ações para lançar a habilidade.

A recomendação considera os selos aprendidos, Holy Shock e a arma equipada. No modo comum, qualquer selo ativo oculta o aviso. As trocas para gastar ecos de Unsealed Wrath ainda não são acompanhadas.

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

## Limitações

- A orientação cobre a abertura e a manutenção de selos; a lista de cooldowns não representa uma fila completa de rotação. O addon não lança habilidades nem troca talentos, equipamento ou teclas.
- Dados de combate podem ficar restritos. **Check seal / Status restricted** e **Status unavailable** não confirmam ausência de selo.
- Mana protegida mantém a barra nativa sem porcentagem ou alerta calculado. APIs de cooldown indisponíveis mostram **Cooldown unavailable**.
- Os testes locais usam APIs simuladas; o comportamento dos avisos e das restrições ainda precisa de validação no cliente real.

## Desenvolvimento

Os testes usam LuaJIT e Python 3, sem pacotes adicionais:

```sh
luajit tests/profiles_test.lua
luajit tests/player_state_test.lua
luajit tests/profile_settings_test.lua
luajit tests/crusader_opener_test.lua
python -m unittest discover -s tests -p 'test_*.py'
```

## Documentação

- [Monitoramento e revisão dos guias](docs/manutencao.md)
- [Pesquisa do guia de Forever](docs/guia-wowhead.md)
- [Cobertura das fontes](docs/cobertura-guia.md)
- [APIs e compatibilidade](docs/addon-api.md)
