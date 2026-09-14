// ArcLauncher — o botão que abre o menu de apps do Omarchy, e os ajustes do
// dock no botão direito.
//
// Ocupa um slot na ponta direita do dock, mas não representa uma janela: não
// tem estado de foco nem contagem. Como os slots de app, não desenha casca
// nenhuma e fica sempre em opacidade cheia — apagá-lo em repouso deixaria o
// botão mais fraco que os ícones ao lado. A resposta ao ponteiro é a mesma do
// slot: o ícone cresce um pouco, e o cursor de mão diz o resto.
//
// O conteúdo é o ícone de "todos os apps" do tema de ícones ativo — o mesmo
// desenho que o resto do sistema usa para essa ação, e no mesmo estilo dos
// ícones dos apps ao lado. O glifo do Nerd Font ficou como último recurso,
// para temas que não trazem esse ícone.
import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: launcher

  // Quem decide o que "abrir o menu" significa é o dock; aqui só se avisa que
  // o botão foi acionado.
  signal activated()

  // O botão direito pede os ajustes do dock. O botão de apps é o único canto do
  // dock que não pertence a app nenhum — nos slots o botão direito já é do app,
  // e disputar esse gesto com eles esconderia os ajustes atrás de uma escolha
  // de qual ícone clicar. Como no `activated`, o que fazer é com o dock.
  signal settingsRequested()

  // Caminho do ícone já resolvido pelo dock (vazio quando o tema não tem).
  property string iconSource: ""

  // A placa atrás do ícone: um quadrado arredondado com fundo e borda, na
  // mesma caixa em que o pacote de ícones desenha a placa dos apps. É para o
  // logo do sistema, que é um contorno solto e sem ela lê como glifo ao lado
  // dos ícones dos apps; um ícone do tema já vem com a própria placa e não a
  // liga. As cores são de quem monta — o dock as puxa do tema ativo.
  property bool plate: false
  property color plateColor: Color.popups.background
  property color plateBorderColor: Color.popups.border
  property int plateRadius: 0

  // A placa recua da caixa do ícone o mesmo que a do MacTahoe: 4 de 64 por
  // lado. É o recuo que o `ArcSlot` dá ao favicon recortado, e é o que faz as
  // duas placas terem o mesmo tamanho na mesma fileira.
  readonly property int plateInset: Math.round(launcher.iconExtent * 4 / 64)

  // Dentro da placa o desenho ocupa ~62% do lado, que é quanto o símbolo ocupa
  // da placa nos ícones estilo macOS. O PNG do logo quase não traz folga
  // própria (260 de 300), então sem este recuo ele encostaria na borda.
  readonly property int plateGlyphInset: Math.round((launcher.iconExtent - launcher.plateInset * 2) * 0.19)

  // A tinta do glifo que substitui um ícone que não resolveu. Padrão do tema,
  // sobrescrita por quem monta quando o tom da casca foi fixado (ver
  // `contentInk` no ArcSlot, que existe pela mesma razão).
  property color contentInk: Color.popups.text

  // A borda em que o dock está ancorado, como no slot: ela decide em que eixo a
  // fileira corre e para que lado o ícone cresce quando a onda o levanta.
  property string edge: "bottom"
  readonly property bool vertical: launcher.edge === "left" || launcher.edge === "right"

  // Glifo `nf-md-apps` (U+F003B) — o mesmo que o item "Apps" usa no menu do
  // Omarchy. Só aparece quando não há ícone de tema para desenhar.
  property string glyph: "󰀻"

  // Folga entre a borda do botão e o conteúdo. Espelha o `iconInset` do slot,
  // para o ícone do botão ocupar a mesma caixa que um ícone de app ocupa.
  property int iconInset: Style.space(4)

  // Lado da caixa do ícone: o botão menos a folga dos dois lados. Como no
  // slot, serve tanto para dimensionar o ícone quanto para medir o quanto ele
  // pode crescer.
  readonly property int iconExtent: Math.max(1, Math.min(launcher.width, launcher.height) - launcher.iconInset * 2)

  readonly property bool hot: pointer.containsMouse

  // Mesmo teto do slot, e pela mesma razão: o botão está na mesma fileira que
  // os ícones dos apps, então um realce maior aqui o faria pular sozinho.
  readonly property real hotScaleMax: 1.05

  // Mesma derivação do slot, para o botão responder ao ponteiro com o mesmo
  // gesto e na mesma medida: cada lado avança um quarto do `iconInset`, sem
  // chegar perto da borda do botão.
  readonly property real hotScale: Math.min(launcher.hotScaleMax, 1 + launcher.iconInset / (launcher.iconExtent * 2))

  // Espelha o `transitionDuration` do ArcSlot: o botão é mais uma célula da
  // fileira, e responder ao ponteiro em outro tempo o entregaria como um
  // controle de outra procedência.
  readonly property int transitionDuration: 140

  // Mesmas curvas do slot (ver o porquê lá): arranca e assenta na ida, sai
  // devagar na volta ao repouso — a volta não é resposta a nada.
  readonly property int hotEasing: Easing.OutQuad
  readonly property int restEasing: Easing.InOutQuad

  // Escrita, e não ligada por binding: dentro de um Behavior o `easing.type`
  // chega a ser lido velho na virada, e a volta sairia com a curva da ida.
  onHotChanged: {
    var curva = launcher.hot ? launcher.hotEasing : launcher.restEasing
    iconScale.easing.type = curva
    glyphScale.easing.type = curva
  }

  // ------------------------------------------------------------ ampliação
  //
  // A mesma onda dos slots, com a mesma divisão de trabalho: o dock calcula, o
  // botão aplica. Ver a seção `ampliação` no ArcSlot para o porquê de cada uma
  // destas — aqui elas são a cópia do outro lado da fileira, e o botão só as
  // repete porque uma célula que ficasse de fora da onda seria um buraco nela.
  property bool magnifyEnabled: false
  property real magnifyMax: 1.0
  property real magnifyScale: 1.0
  property real magnifyShift: 0
  property int magnifyDuration: launcher.transitionDuration

  readonly property real rowCenter: launcher.vertical
    ? launcher.y + launcher.height / 2
    : launcher.x + launcher.width / 2

  readonly property real contentScale: Math.max(launcher.magnifyScale,
    launcher.hot ? launcher.hotScale : 1.0)

  readonly property real contentScaleMax: Math.max(launcher.hotScaleMax,
    launcher.magnifyEnabled ? launcher.magnifyMax : 1.0)

  readonly property int contentOrigin: {
    if (!launcher.magnifyEnabled) return Item.Center
    if (launcher.edge === "top") return Item.Top
    if (launcher.edge === "left") return Item.Left
    if (launcher.edge === "right") return Item.Right
    return Item.Bottom
  }

  Behavior on magnifyShift {
    NumberAnimation { duration: launcher.magnifyDuration; easing.type: launcher.hotEasing }
  }

  // Como no slot: a Grid do dock é quem posiciona o botão, então quem o desloca
  // é uma transform — escrever em `x`/`y` brigaria com o layout.
  transform: Translate {
    x: launcher.vertical ? 0 : launcher.magnifyShift
    y: launcher.vertical ? launcher.magnifyShift : 0
  }

  // A caixa do ícone. Placa e desenho moram nela e crescem juntos sob o
  // ponteiro — uma placa que ficasse parada enquanto o logo cresce leria como
  // dois objetos.
  Item {
    id: content
    anchors.centerIn: parent
    width: launcher.iconExtent
    height: launcher.iconExtent
    visible: icon.status === Image.Ready
    transformOrigin: launcher.contentOrigin
    scale: launcher.contentScale
    // A curva é mantida pelo `onHotChanged` e a duração pelo dock; os valores
    // aqui são só os de partida.
    Behavior on scale {
      NumberAnimation { id: iconScale; duration: launcher.magnifyDuration; easing.type: launcher.hotEasing }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: launcher.plateInset
      visible: launcher.plate
      radius: launcher.plateRadius
      color: launcher.plateColor
      border.width: 1
      border.color: launcher.plateBorderColor
      antialiasing: true
    }

    // Mesmo tratamento do ícone do slot: encaixe sem distorcer e decode em
    // pixels físicos, para não borrar em HiDPI.
    Image {
      id: icon
      anchors.fill: parent
      anchors.margins: launcher.plate ? launcher.plateInset + launcher.plateGlyphInset : 0
      fillMode: Image.PreserveAspectFit
      // O fator do hover entra na conta: é o maior tamanho que o ícone chega a
      // ocupar, e decodificar já nele evita borrar quando o ponteiro o amplia.
      sourceSize.width: Math.round(width * launcher.contentScaleMax * Screen.devicePixelRatio)
      sourceSize.height: Math.round(height * launcher.contentScaleMax * Screen.devicePixelRatio)
      source: launcher.iconSource
      asynchronous: true
    }
  }

  // OpticalGlyph em vez de Text: os glifos de ícone dos Nerd Fonts não vêm
  // centrados na própria caixa, e ele corrige essa deriva horizontal.
  OpticalGlyph {
    anchors.fill: parent
    visible: !content.visible
    text: launcher.glyph
    // A família vem do alias (`Style.fontFamily`), não da resolvida, para o
    // botão acompanhar um `omarchy font set` sem reiniciar a shell.
    fontFamily: Style.fontFamily
    // Num Nerd Font a mancha do glifo ocupa ~0.63 do `pixelSize`; o resto é a
    // caixa de linha em volta. Dividir por essa fração converte "altura
    // pintada que eu quero" em `pixelSize`, e a mira é 80% da caixa do ícone.
    fontSize: Math.max(1, Math.round(content.height * 0.8 / 0.63))
    color: launcher.contentInk
    // O glifo faz as vezes do ícone, então responde ao ponteiro igual a ele.
    transformOrigin: launcher.contentOrigin
    scale: launcher.contentScale
    Behavior on scale {
      NumberAnimation { id: glyphScale; duration: launcher.magnifyDuration; easing.type: launcher.hotEasing }
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) launcher.settingsRequested()
      else launcher.activated()
    }
  }
}
