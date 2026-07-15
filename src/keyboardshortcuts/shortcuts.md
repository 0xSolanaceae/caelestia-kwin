# Quickshell Keyboard Shortcuts

## Applications
```ini
super + enter
    kstart -- foot
super + w
    kstart -- firefox
super + c
    kstart -- code
super + g
    kstart -- github-desktop
super + alt + e
    kstart -- nemo
```

# Workspaces
```ini
super + 1
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 1
super + 2
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 2
super + 3
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 3
super + 4
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 4
super + 5
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 5
super + 6
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 6
super + 7
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 7
super + 8
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 8
super + 9
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 9
super + 0
    qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 10
```


## System & Session
```ini
super + shift + l
    systemctl suspend-then-hibernate
ctrl + alt + delete
    ~/.local/bin/caelestia-shell-ipc drawers toggle session
```
## OLD GUIs
#    caelestia clipboard    

## TO RUN ANY OTHER COMMAND PRESENT IN launcher's command menu
# map any shortcut to ~/.local/bin/caelestia-shell-ipc launcher action <command name>

## Desktop & Shell UI
```ini
super + space
    ~/.local/bin/caelestia-shell-ipc drawers toggle launcher
super + v
    ~/.local/bin/caelestia-shell-ipc launcher action clipboard
super + shift + v
    ~/.local/bin/caelestia-shell-ipc launcher action emoji
super + alt + v
    ~/.local/bin/caelestia-shell-ipc launcher action emoji
super + slash
    ~/.local/bin/caelestia-shell-ipc launcher action keybinds
super + ctrl + t
    ~/.local/bin/caelestia-shell-ipc launcher action wallpaper
```

## Screenshots & Recording
```ini
super + shift + s
    ~/.local/bin/caelestia-shell-ipc region screenshot
super + ctrl + s
    ~/.local/bin/caelestia-shell-ipc region recordWithSound
super + shift + a
    ~/.local/bin/caelestia-shell-ipc region search
super + b
    ~/.local/bin/caelestia-shell-ipc drawers toggle sidebar
super + shift + c
    ~/.local/bin/kcolorpicker -a
print
    ~/.local/bin/caelestia-shell-ipc region screenshot
```
