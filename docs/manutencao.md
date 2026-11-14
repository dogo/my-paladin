# Monitoramento dos guias

O monitor consulta as oito fontes principais listadas em `guides.json` e compara seu conteúdo com os snapshots aceitos. A data da última revisão e o patch de referência aparecem no painel do addon.

A consulta não altera as regras, os perfis nem a data de revisão. Mudanças precisam ser revisadas e aceitas manualmente.

## Consultar mudanças

Na raiz do repositório:

```sh
python scripts/check_guides.py
```

Leia `.guide-monitor/report.md`. O estado fica em `.guide-monitor/state.json` e os relatórios anteriores em `.guide-monitor/history/`. Esses arquivos locais não entram no Git.

| Saída | Resultado |
| --- | --- |
| `0` | Sem mudanças |
| `2` | Revisão pendente |
| `1` | Erro na consulta |

A primeira captura exige revisão. Mudanças continuam pendentes nas consultas seguintes até serem aceitas. Falhas de acesso ou páginas não reconhecidas preservam os snapshots anteriores.

O monitor extrai o corpo dos artigos e suas subseções, ignorando navegação, comentários e anúncios. Registra links adicionais de guias encontrados no corpo, mas não percorre todo o banco de itens e missões. Conteúdo disponível apenas em widgets JavaScript pode não ser extraído.

## Aceitar uma revisão

Leia as fontes alteradas, ajuste as regras necessárias e execute os testes antes de aceitar:

```sh
python scripts/check_guides.py --accept
```

Para uma revisão correspondente a outro patch:

```sh
python scripts/check_guides.py --accept --patch 1.60.2
```

Substitua o patch pelo valor correto. A aceitação atualiza `guides.json` e `MyPalladin/GuideInfo.lua`; não modifica as regras do addon. Reinstale os arquivos atualizados para levar a nova referência ao jogo.

## Agendamento com systemd

As unidades em `ops/` consultam os guias diariamente às **09:00 de America/Sao_Paulo**. Ajuste `WorkingDirectory` e `ExecStart` no arquivo `.service` para o caminho do seu clone antes de instalar.

```sh
mkdir -p ~/.config/systemd/user
cp ops/mypalladin-guide-check.service ops/mypalladin-guide-check.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now mypalladin-guide-check.timer
```

Para executar uma consulta e conferir o resultado:

```sh
systemctl --user start mypalladin-guide-check.service
systemctl --user list-timers mypalladin-guide-check.timer
journalctl --user -u mypalladin-guide-check.service -n 30
```

O timer recupera execuções perdidas quando o gerenciador do usuário voltar a funcionar. O serviço trata saída `2` como revisão pendente e tenta mostrar uma notificação com `notify-send`, quando disponível. O resultado permanece no relatório e no journal se a notificação falhar.

O agendamento consulta e notifica; não aceita revisões nem instala atualizações. Não use `--accept` no timer.
