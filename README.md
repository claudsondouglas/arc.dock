# Arc Dock

Dock para o [Omarchy](https://omarchy.org/) shell (Quickshell).

Estado atual: **slots**. Uma superfície ancorada no centro da borda inferior da
tela, na camada `Top` (por cima das janelas, sem reservar espaço), com fundo e
borda herdados do tema ativo. Dentro dela, um slot por app aberto:

- um slot por **app**, não por janela — duas janelas do mesmo `appId` dividem o
  mesmo slot;
- a largura do dock sai da contagem de slots (44 px por slot + espaçamentos);
- sem nenhum app aberto sobra um slot vazio, para o dock não colapsar;
- o app em foco usa o token visual `selected` do tema;
- o conteúdo do slot ainda é placeholder (a inicial do nome do app) — os ícones
  entram no lugar do `Text` em `ArcSlot.qml`.

Ainda não existe: clique/foco, ícones, apps fixados, badges, reordenação.

## Arquivos

| Arquivo | O quê |
| --- | --- |
| `Arcdock.qml` | superfície (`PanelWindow`), geometria e o modelo de slots |
| `ArcSlot.qml` | um slot: espaço, estados visuais e placeholder |

## Instalação (local)

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable arc.dock
omarchy restart shell
```

## Desenvolvimento

Depois de editar qualquer `.qml`, rode `omarchy restart shell`. O hot reload
do Omarchy recarrega o código mas não reaplica a geometria da `PanelWindow`.

Para conferir que a versão nova está no ar:

```bash
hyprctl layers | grep arc-dock
```

A largura esperada é `12 + slots*44 + (slots-1)*6` px (com o espaçamento padrão
do tema), então dá para validar a contagem de slots sem depender do olho.

## Licença

MIT.
