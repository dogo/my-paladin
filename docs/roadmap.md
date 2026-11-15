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
| Monitor | Consulta dos oito guias, relatório de diferenças e aceitação manual das revisões |

Os ecos só são orientados com Unsealed Wrath e os dois selos aprendidos, Command como selo base recomendado e dados acessíveis. Não há troca automática de selos nem lançamento de habilidades.

## Validação pendente

- Conferir cooldowns, mana, ranks e persistência de configurações na build 70938.
- Conferir o aviso de selo e a abertura de Crusader com o painel fechado.
- Conferir atribuições de bênção/aura, buffs recebidos de outro jogador e avisos de preparação fora de combate.
- Com Unsealed Wrath aprendido, conferir o buff e a contagem de Echo of Command no cliente real.
- Repetir o ciclo após acerto, erro/esquiva, expiração, dispel, troca de alvo e fim de combate.
- Confirmar quais dados permanecem públicos durante combate; estados restritos devem limpar orientações anteriores e mostrar uma indicação de conferência.
- Instalar a 0.8 com o jogo fechado, migrando o nome antigo e os perfis.
- Conferir Single/AoE e o cooldown da dica com o painel fechado; não exigir leitura de vida secreta.
- Capturar uma sessão, conferir gravação após reload e determinar se `C_Log` chega ao disco ao vivo.

O [roteiro de diagnóstico](diagnostico.md) reúne os passos de validação e os limites do relatório.

## 1.0 — Estabilização

- Resolver os problemas encontrados na validação do cliente.
- Consolidar compatibilidade, instalação e atualização do addon.
- Publicar um pacote de versão com instruções de uso e limitações confirmadas.

## Acompanhamento das entregas

Ao terminar cada entrega, registrar o que foi feito, o que falta e o que ainda depende de validação no jogo. Atualizar este roadmap quando o escopo ou a prioridade mudar.
