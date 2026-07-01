pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    // Coalesce bursty compositor events into fewer refresh passes.
    property bool pendingWindowListUpdate: false
    property bool pendingLayersUpdate: false
    property bool pendingMonitorsUpdate: false
    property bool pendingWorkspacesUpdate: false
    property bool pendingActiveWorkspaceUpdate: false

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    // Internals

    function flushPendingUpdates() {
        if (pendingWindowListUpdate && !getClients.running) {
            pendingWindowListUpdate = false;
            getClients.running = true;
        }

        if (pendingLayersUpdate && !getLayers.running) {
            pendingLayersUpdate = false;
            getLayers.running = true;
        }

        if (pendingMonitorsUpdate && !getMonitors.running) {
            pendingMonitorsUpdate = false;
            getMonitors.running = true;
        }

        if (pendingWorkspacesUpdate && !getWorkspaces.running) {
            pendingWorkspacesUpdate = false;
            getWorkspaces.running = true;
        }

        if (pendingActiveWorkspaceUpdate && !getActiveWorkspace.running) {
            pendingActiveWorkspaceUpdate = false;
            getActiveWorkspace.running = true;
        }
    }

    function queueUpdates(windowList: bool, layers: bool, monitors: bool, workspaces: bool): void {
        pendingWindowListUpdate = pendingWindowListUpdate || windowList;
        pendingLayersUpdate = pendingLayersUpdate || layers;
        pendingMonitorsUpdate = pendingMonitorsUpdate || monitors;
        pendingWorkspacesUpdate = pendingWorkspacesUpdate || workspaces;
        pendingActiveWorkspaceUpdate = pendingActiveWorkspaceUpdate || workspaces;
        updateCoalesceTimer.restart();
    }

    function updateWindowList() {
        queueUpdates(true, false, false, false);
    }

    function updateLayers() {
        queueUpdates(false, true, false, false);
    }

    function updateMonitors() {
        queueUpdates(false, false, true, false);
    }

    function updateWorkspaces() {
        queueUpdates(false, false, false, true);
    }

    function updateAll() {
        queueUpdates(true, true, true, true);
    }

    Timer {
        id: updateCoalesceTimer

        interval: 24
        repeat: false
        onTriggered: root.flushPendingUpdates()
    }

    function updateForEvent(name) {
        if (name === "screencast")
            return;

        if (["openlayer", "closelayer"].includes(name)) {
            updateLayers();
            return;
        }

        if (["workspace", "workspacev2", "focusedmon", "focusedmonv2"].includes(name)) {
            updateWorkspaces();
            return;
        }

        if (["openwindow", "closewindow", "movewindow", "windowtitle", "activewindow", "activewindowv2"].includes(name)) {
            updateWindowList();
            return;
        }

        if (["monitoradded", "monitorremoved", "monitoraddedv2", "monitorremovedv2"].includes(name)) {
            updateMonitors();
            updateWorkspaces();
            updateWindowList();
            return;
        }

        updateAll();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            updateForEvent(event.name);
        }
    }

    Process {
        id: getClients
        command: ["bash", "-c", "PATH=$HOME/.local/bin:$PATH hyprctl clients -j"]
        onRunningChanged: {
            if (!running)
                root.flushPendingUpdates();
        }
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(clientsCollector.text);
                    root.windowList = parsed.filter(w => w.class && !w.class.toLowerCase().includes("quickshell"));
                } catch(e) {
                    root.windowList = [];
                }
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["bash", "-c", "PATH=$HOME/.local/bin:$PATH hyprctl monitors -j"]
        onRunningChanged: {
            if (!running)
                root.flushPendingUpdates();
        }
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getLayers
        command: ["bash", "-c", "PATH=$HOME/.local/bin:$PATH hyprctl layers -j"]
        onRunningChanged: {
            if (!running)
                root.flushPendingUpdates();
        }
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["bash", "-c", "PATH=$HOME/.local/bin:$PATH hyprctl workspaces -j"]
        onRunningChanged: {
            if (!running)
                root.flushPendingUpdates();
        }
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                var rawWorkspaces = JSON.parse(workspacesCollector.text);
                // Filter out invalid workspace ids (e.g. lock-screen temp workspace 2147483647 - N)
                root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["bash", "-c", "PATH=$HOME/.local/bin:$PATH hyprctl activeworkspace -j"]
        onRunningChanged: {
            if (!running)
                root.flushPendingUpdates();
        }
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }
}
