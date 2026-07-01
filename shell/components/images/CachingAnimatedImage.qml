import QtQuick
import Quickshell

AnimatedImage {
    id: root

    property string path

    asynchronous: true
    fillMode: AnimatedImage.PreserveAspectCrop
    source: path || ""
    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }
    playing: true

    onSourceChanged: playing = true
}
