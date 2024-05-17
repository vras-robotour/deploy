#!/bin/bash
set -euo pipefail  # Better error handling and exiting on error

install_vscode() {
    cd "$(mktemp -d)"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    apt-get -y install apt-transport-https
    apt-get -y update
    apt-get -y install code # or code-insiders
}

install_sublimetext() {
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo apt-get -y install apt-transport-https
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt-get -y update
    sudo apt-get -y install sublime-text
}

install_neovim() {
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt -y install neovim

    git clone https://github.com/aleskucera/lazyvim.git ~/.config/nvim
}

install_pycharm() {
    if [ "$(dpkg --print-architecture)" = "arm64" ]; then
        wget --quiet https://download-cdn.jetbrains.com/python/pycharm-community-2023.3.3-aarch64.tar.gz
    else
        wget --quiet https://download-cdn.jetbrains.com/python/pycharm-community-2023.3.3.tar.gz
    fi
    sudo tar xzf pycharm-*.tar.gz --one-top-level=pycharm --strip-components=1 -C /opt/
#    sudo ln -s /opt/pycharm/bin/pycharm.sh /usr/bin/pycharm
}

main() {
  install_vscode
  install_sublimetext
  install_neovim
  install_pycharm
}

main
