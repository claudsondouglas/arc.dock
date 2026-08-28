// Arcdock — superfície do dock e os slots dos apps abertos.
//
// A superfície é uma PanelWindow ancorada no centro da borda inferior,
// flutuando por cima das janelas. Dentro dela ficam os *slots*: cada app
// aberto ocupa um slot, e a largura do dock é derivada da quantidade deles.
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

  // ------------------------------------------------------------- geometria
  //
  // O dock não tem mais largura fixa: ela sai da contagem de slots. Só o
  // tamanho do slot e os espaçamentos são tokens.
  readonly property int slotSize: 44
  readonly property int slotGap: Style.spacing.md
  readonly property int dockPadding: Style.spacing.md

  // Sem nenhum app aberto o dock não colapsa: sobra o espaço de um slot vazio,
  // que é o retângulo mínimo visível.
  readonly property int visibleSlots: Math.max(1, slots.length)

  readonly property int dockWidth: dockPadding * 2 + visibleSlots * slotSize + (visibleSlots - 1) * slotGap
  readonly property int dockHeight: dockPadding * 2 + slotSize

  // Folga entre a base do dock e a borda de baixo da tela.
  readonly property int bottomMargin: 14

  // ---------------------------------------------------------------- modelo
  //
  // Um slot por *app* aberto, não por janela: duas janelas do mesmo appId
  // dividem o mesmo slot (`windows` guarda todas). Cada entrada é
  // { key, name, windows, active }.
  property var slots: []

  // Ordem estável dos slots: as chaves na ordem em que os apps apareceram.
  // Fechar uma janela de um app que continua aberto não reordena o dock, e
  // apps novos entram sempre no fim.
  property var slotOrder: []

  // Chave de agrupamento. O appId do wlr-toplevel já é o identificador
  // canônico do app; o título é só um fallback para clientes que não mandam
  // appId (raro, mas acontece com janelas nativas do XWayland).
  function appKey(toplevel) {
    var id = String((toplevel && toplevel.appId) || "").trim().toLowerCase()
    if (id.slice(-8) === ".desktop") id = id.slice(0, -8)
    if (id.length > 0) return id
    var title = String((toplevel && toplevel.title) || "").trim().toLowerCase()
    return title.length > 0 ? "title:" + title : "unknown"
  }

  // Nome exibível derivado da chave: "org.kde.dolphin" -> "Dolphin".
  function appLabel(key) {
    var parts = String(key || "").split(".")
    var last = parts[parts.length - 1] || key || ""
    if (last.length === 0) return ""
    return last.charAt(0).toUpperCase() + last.slice(1)
  }

  function rebuildSlots() {
    var live = (ToplevelManager.toplevels && ToplevelManager.toplevels.values)
      ? ToplevelManager.toplevels.values : []
    var active = ToplevelManager.activeToplevel

    // 1. Agrupa as janelas vivas por app.
    var byKey = ({})
    var fresh = []
    for (var i = 0; i < live.length; i++) {
      var top = live[i]
      if (!top) continue
      var key = appKey(top)
      var entry = byKey[key]
      if (!entry) {
        entry = { key: key, name: appLabel(key), windows: [], active: false }
        byKey[key] = entry
        fresh.push(key)
      }
      entry.windows.push(top)
      if (active && top === active) entry.active = true
    }

    // 2. Mantém a ordem antiga para quem continua aberto e põe os novos no fim.
    var order = []
    for (var j = 0; j < slotOrder.length; j++) {
      if (byKey[slotOrder[j]] && order.indexOf(slotOrder[j]) < 0) order.push(slotOrder[j])
    }
    for (var k = 0; k < fresh.length; k++) {
      if (order.indexOf(fresh[k]) < 0) order.push(fresh[k])
    }

    var next = []
    for (var n = 0; n < order.length; n++) next.push(byKey[order[n]])

    root.slotOrder = order
    root.slots = next
  }

  // `values` muda quando uma janela abre ou fecha; `activeToplevel`, quando o
  // foco troca — os dois mexem no modelo, então os dois disparam o rebuild.
  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() { root.rebuildSlots() }
  }

  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() { root.rebuildSlots() }
  }

  Component.onCompleted: root.rebuildSlots()

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
    margins.bottom: root.bottomMargin

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

      Row {
        anchors.centerIn: parent
        spacing: root.slotGap

        // Sem apps abertos o Repeater não gera nada e sobra o slot fantasma
        // abaixo, só para o dock manter o tamanho mínimo.
        Repeater {
          model: root.slots
          delegate: ArcSlot {
            required property var modelData
            app: modelData
            width: root.slotSize
            height: root.slotSize
          }
        }

        ArcSlot {
          visible: root.slots.length === 0
          app: null
          width: root.slotSize
          height: root.slotSize
        }
      }
    }
  }
}
