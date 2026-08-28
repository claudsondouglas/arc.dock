# Arcdock

Dock para o [Omarchy](https://omarchy.org/) shell (Quickshell).

Estado atual: esqueleto. Uma superfície de 200x52 px ancorada no centro da
borda inferior da tela, na camada `Top` (por cima das janelas, sem reservar
espaço), com fundo e borda herdados do tema ativo.

## Instalação (local)

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable rosakodu.arcdock
omarchy restart shell
```

## Desenvolvimento

Depois de editar qualquer `.qml`, rode `omarchy restart shell`. O hot reload
do Omarchy recarrega o código mas não reaplica a geometria da `PanelWindow`.

Para conferir que a versão nova está no ar:

```bash
hyprctl layers | grep -A3 omarchy-arcdock
```

## Licença

MIT.
