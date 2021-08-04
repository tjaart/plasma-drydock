DIR=$HOME/.local/share/icons/hicolor/scalable/apps
if [[ ! -e DIR ]]; then
    mkdir -p $DIR
fi

cp docker.svg $DIR

kpackagetool5 -t Plasma/Applet --install org.kde.drydock
