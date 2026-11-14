# My Paladin

Addon de apoio para **Retribution Paladin PvE no WoW: Forever**. Acompanha cooldowns, mana e buffs, com perfis para Leveling, Dungeon e Raid.

Desenvolvido para **Forever 1.60.1**, Interface **16001**, com o cliente em inglês. A interface do addon também usa inglês.

## Funcionalidades

- Cooldowns das habilidades aprendidas, com seleção do que aparece em cada perfil.
- Barra de mana com alerta e limite configurável.
- Indicadores de selo, bênção e aura.
- Aviso de selo com ícone e nome, independente do painel e visível durante combate.
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

A recomendação considera os selos aprendidos, Holy Shock e a arma equipada. Qualquer selo ativo oculta o aviso. Ele ainda não orienta a abertura com Crusader nem as trocas para gastar ecos de Unsealed Wrath.

Arraste o aviso fora de combate para reposicioná-lo. Durante combate, ele deixa passar os cliques. A opção **Highlight missing buffs** controla esse aviso por perfil.

## Limitações

- A lista de cooldowns não representa uma fila de rotação. O addon não lança habilidades nem troca talentos, equipamento ou teclas.
- Dados de combate podem ficar restritos. **Check seal / Status restricted** e **Status unavailable** não confirmam ausência de selo.
- Mana protegida mantém a barra nativa sem porcentagem ou alerta calculado. APIs de cooldown indisponíveis mostram **Cooldown unavailable**.
- Os testes locais usam APIs simuladas; o comportamento dos avisos e das restrições ainda precisa de validação no cliente real.

## Desenvolvimento

Os testes usam LuaJIT e Python 3, sem pacotes adicionais:

```sh
luajit tests/profiles_test.lua
luajit tests/player_state_test.lua
luajit tests/profile_settings_test.lua
python -m unittest discover -s tests -p 'test_*.py'
```

## Documentação

- [Monitoramento e revisão dos guias](docs/manutencao.md)
- [Pesquisa do guia de Forever](docs/guia-wowhead.md)
- [Cobertura das fontes](docs/cobertura-guia.md)
- [APIs e compatibilidade](docs/addon-api.md)
