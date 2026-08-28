// Arcdock — esqueleto do dock.
//
// Nesta etapa é só a superfície: um retângulo fixo ancorado no centro da
// borda inferior, flutuando por cima das janelas. Nada de ícones ainda.
//
// O plugin é `kind: service` porque a janela precisa existir enquanto a shell
// existir — não é algo que se invoca sob demanda como um panel/overlay.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  // Geometria do dock, em pixels crus por enquanto. Quando o conteúdo entrar,
  // isto vira largura derivada dos slots (e provavelmente Style.space()).
  readonly property int dockWidth: 200
  readonly property int dockHeight: 52

  PanelWindow {
    id: dockWindow
    color: "transparent"

    WlrLayershell.namespace: "arc-dock"
    // Top fica acima das janelas normais mas abaixo de overlays (OSD, lock).
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Ancorado só na borda de baixo: o layer-shell centraliza a superfície
    // horizontalmente nessa borda, então não é preciso calcular o x.
    anchors.bottom: true
    margins.bottom: Style.gapsOut

    // Flutua por cima: não reserva espaço nem empurra as janelas.
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: root.dockWidth
    implicitHeight: root.dockHeight

    // Fundo e borda vêm do tema ativo (mesmos tokens dos popups da shell),
    // então trocar de tema com `omarchy theme set` já repinta o dock.
    BorderSurface {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
    }
  }
}
