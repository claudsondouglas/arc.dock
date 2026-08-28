// ArcSlot — um slot do dock.
//
// O slot é o *espaço* reservado a um app aberto; o conteúdo dele ainda é um
// placeholder (a inicial do app). Quando os ícones entrarem, é só trocar o
// Text por um IconImage aqui dentro — a geometria e os estados já ficam
// resolvidos neste arquivo.
import QtQuick
import qs.Commons

Item {
  id: slot

  // Entrada do modelo montado pelo Arcdock: { key, name, windows, active }.
  property var app: null

  readonly property bool active: !!(app && app.active)
  readonly property string appName: (app && app.name) ? app.name : ""
  readonly property int windowCount: (app && app.windows) ? app.windows.length : 0

  // Placeholder até os ícones existirem: a inicial do nome do app.
  readonly property string initial: appName.length > 0 ? appName.charAt(0).toUpperCase() : ""

  Rectangle {
    id: surface
    anchors.fill: parent
    // Arredondamento do tema, limitado para não virar círculo em slot pequeno.
    radius: Math.min(Style.cornerRadius, slot.height / 2)

    // Slot vazio (sem app) fica só com o contorno; ocupado ganha preenchimento,
    // e o app em foco usa o token "selected" para se destacar dos demais.
    color: slot.app
      ? Util.alpha(Color.popups.text, slot.active ? Style.selectedFillAlpha : Style.normalFillAlpha)
      : "transparent"

    border.width: slot.active ? Math.max(1, Style.selectedBorderWidth) : Style.normalBorderWidth
    border.color: Util.alpha(Color.popups.border, slot.active ? Style.selectedBorderAlpha : Style.normalBorderAlpha)

    Behavior on color { ColorAnimation { duration: 120 } }
  }

  Text {
    anchors.centerIn: parent
    visible: slot.initial.length > 0
    text: slot.initial
    color: Color.popups.text
    opacity: slot.active ? 1.0 : 0.75
    font.family: Style.fontFamily
    font.pixelSize: Style.font.heading
  }
}
