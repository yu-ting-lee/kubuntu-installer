#!/usr/bin/sudo /bin/bash

HOME=$(eval echo ~${SUDO_USER})
info() { echo -e "\033[1;33m${1}\033[0m"; }

_code() {
  apt install curl gpg -y
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
  mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
  sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  apt install apt-transport-https -y
  apt update -y
  apt install code -y

  while read -r line; do
    info "install code extension $line..."
    sudo -u ${SUDO_USER} code --install-extension $line --force
  done <subpackage/code
}

_docker() {
  apt install ca-certificates curl gnupg lsb-release -y
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt update -y
  apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
  groupadd docker
  usermod -aG docker ${SUDO_USER}
}

_git() {
  apt install git -y
  source config/git
  sudo -u ${SUDO_USER} git config --global user.name ${GIT_USER}
  sudo -u ${SUDO_USER} git config --global user.email ${GIT_MAIL}
}

_nodejs() {
  apt install curl -y
  curl -s https://deb.nodesource.com/setup_16.x | bash
  apt install nodejs -y

  while read -r line; do
    info "install npm package $line..."
    npm install -g $line
  done <subpackage/npm
}

_obs_studio() {
  apt install software-properties-common -y
  add-apt-repository ppa:obsproject/obs-studio -y
  apt update -y
  apt install obs-studio -y
}

_python3_pip() {
  apt install python3-pip -y

  while read -r line; do
    info "install pip3 package $line..."
    sudo -u ${SUDO_USER} pip3 install $line
  done <subpackage/pip3
}

_tmux() {
  apt install tmux -y
  cp config/.tmux.conf ${HOME}/
  sudo -u ${SUDO_USER} tmux source-file ${HOME}/.tmux.conf
}

install() {
  case $1 in
    snap:*)
      n=$(echo ${1//:/ } | cut -d' ' -f2-)
      info "install snap package $n..."
      snap install $n
      ;;
    apt:*)
      n=$(echo ${1//:/ } | cut -d' ' -f2-)
      info "install apt package $n..."

      if [ "$(type -t _${n/-/_})" = "function" ]; then
        eval "_${n/-/_}"
      else
        apt install $n -y
      fi
      ;;
  esac
  sleep 2
}

cli() {
  info "apt update..."
  apt update -y
  info "apt upgrade..."
  apt upgrade -y
  info "install apt package snapd..."
  apt install snapd -y

  mapfile -t res <package
  for r in ${res[@]}; do install $r; done
  info "exit"
}

gui() {
  info "apt update..."
  apt update -y
  info "apt upgrade..."
  apt upgrade -y
  info "install apt package snapd..."
  apt install snapd -y
  info "install apt package whiptail..."
  apt install whiptail -y

  mapfile -t opt < <(awk -F: \
    '{ print $0; print $2; print "off";}' package)

  while true; do
    res=$(
      whiptail --title "select package" --checklist "" --notags \
        --separate-output --ok-button "install" --cancel-button "exit" \
        16 40 10 "${opt[@]}" 2>&1 >/dev/tty
    )
    if [ $? -eq 0 ]; then
      for r in $res; do install $r; done
    else
      info "exit" && exit 0
    fi
  done
}

case "$1" in
  "-h" | "--help")
    cat <<EOF

Usage: ./install.sh [options]

--cli        command line interface, install all packages
--gui        graphical user interface, install selected packages
-h --help    print usage

EOF
    ;;
  "--cli") cli ;;
  "--gui" | *) gui ;;
esac
