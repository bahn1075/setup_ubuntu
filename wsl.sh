#!/usr/bin/env zsh
# WSL 초기 설정: zsh wsl.sh 로 실행합니다.
if [ -z "${ZSH_VERSION:-}" ]; then
  printf '%s\n' 'zsh wsl.sh 로 실행하세요.' >&2
  exit 1
fi
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
# sudo 패스워드 묻지 않음
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER > /dev/null && sudo chmod 440 /etc/sudoers.d/$USER && sudo visudo -c -f /etc/sudoers.d/$USER

# sudo no password 확인
sudo -l  # 현재 사용자의 sudo 권한 목록 확인
sudo cat /etc/sudoers.d/$USER  # 파일 내용 확인
ls -la /etc/sudoers.d/$USER  # 파일 권한 확인 (440이어야 함)
sudo -n true && echo "패스워드 없이 sudo 가능" || echo "패스워드 필요"  # 실제 테스트

#필수설치
sudo apt update && sudo apt upgrade -y

# install essentials
sudo apt install zip unzip wget zsh curl git fontconfig -y

# Meslo Nerd Font (WSL 내부 프로그램용)
# [VS Code에서 eza 아이콘이 깨질 때]
# 외부 터미널에서 정상이라면 VS Code의 터미널 글꼴 차이를 먼저 확인합니다.
# Windows에서 실행하는 VS Code(Remote WSL 포함)는 Windows에 설치된 글꼴을 사용합니다.
# 아래 WSL 글꼴 설치만으로는 Windows VS Code의 글꼴이 설정되지 않습니다.
# 1. 외부 터미널 WSL 프로필에서 사용 중인 Nerd Font 이름을 확인합니다.
# 2. 같은 Nerd Font를 Windows에도 설치합니다(이미 설치됐다면 생략).
# 3. VS Code > Preferences: Open User Settings (JSON)에 아래 키를 추가합니다.
#    "terminal.integrated.fontFamily": "'MesloLGS Nerd Font Mono', monospace"
#    위 글꼴 이름은 예시입니다. Windows에 설치된 실제 패밀리 이름으로 바꿉니다.
# 4. Workspace/Remote의 동일 키가 덮어쓰는지 확인하고 VS Code를 완전히 재시작합니다.
# 5. 새 통합 터미널에서 eza --icons로 확인합니다.
# editor.fontFamily와 terminal.integrated.fontFamily는 별개입니다.
# 공식 안내: https://code.visualstudio.com/docs/terminal/appearance
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip -o /tmp/meslo.zip && unzip /tmp/meslo.zip -d /tmp/meslo && sudo mkdir -p /usr/share/fonts/truetype/meslo-nerd && sudo cp /tmp/meslo/*.ttf /usr/share/fonts/truetype/meslo-nerd/ && sudo fc-cache -fv && rm -rf /tmp/meslo*

# Oh My Zsh 설치 (필수): Homebrew와 .zshrc 사용자 설정 전에 실행합니다.
# 이미 설치되어 있으면 재설치를 건너뜁니다.
omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -f "$omz_dir/oh-my-zsh.sh" ]; then
  omz_installer="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit 1
  ZSH="$omz_dir" sh -c "$omz_installer" "" --unattended || exit 1
  unset omz_installer
fi

# 설치 실패 시 다음 단계로 진행하지 않습니다.
if [ ! -f "$omz_dir/oh-my-zsh.sh" ]; then
  printf '%s\n' "Oh My Zsh 설치를 확인할 수 없습니다: $omz_dir" >&2
  exit 1
fi
printf '%s\n' 'Oh My Zsh 설치 확인 완료'

# --unattended는 기본 셸을 변경하지 않습니다.
# 기본 셸 지정이 필요하면 설치 완료 후 아래 명령을 별도로 실행합니다.
# chsh -s "$(command -v zsh)"
# 이 파일은 이미 zsh에서 실행되므로 설치 도중 exec zsh를 실행하지 않습니다.

#brew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

#brew 설정
echo >> "$zshrc_path"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$zshrc_path"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# brew 패키지 설치
brew install starship fastfetch k9s eza ripgrep zsh-patina kubectx superfile zsh-autosuggestions vim gh tree node lazyssh lazydocker helm jq btop bat kubens

# starship 설정 추가
mkdir -p "$HOME/.config"
curl -o ~/.config/starship.toml https://raw.githubusercontent.com/bahn1075/el_init/ubuntu/starship.toml

echo 'eval "$(starship init zsh)"' >> "$zshrc_path"


# eza 설정 추가: 이 블록만 따로 실행해도 경로가 설정됩니다.
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
touch "$zshrc_path"
if ! grep -Fq '# >>> WSL eza >>>' "$zshrc_path"; then
  cat >> "$zshrc_path" <<'ZSHRC'

# >>> WSL eza >>>
alias ls="eza --icons --git --level=2 --time-style='+%m/%d %H:%M' --git-repos --total-size --group-directories-first --sort=time"
# <<< WSL eza <<<
ZSHRC
fi

# fastfetch 설정 추가
echo 'fastfetch' >> "$zshrc_path"

# oh-my-logo 설정
echo 'npx oh-my-logo "MY WSL" fire --filled --block-font chrome --letter-spacing 2' >> "$zshrc_path"

# npm은 위에서 설치한 Homebrew node에 포함됩니다.


# 확장은 프롬프트와 시작 화면 설정 다음에 추가합니다.
# 기존 zsh-syntax-highlighting 로딩 및 마커 없는 중복 설정은 제거하세요.
if ! grep -Fq '# >>> WSL zsh extensions >>>' "$zshrc_path"; then
  cat >> "$zshrc_path" <<'ZSHRC'

# >>> WSL zsh extensions >>>
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
# patina는 .zshrc의 마지막에서 활성화합니다.
eval "$("$(brew --prefix)/bin/zsh-patina" activate)"
# <<< WSL zsh extensions <<<
ZSHRC
fi

# Docker: OS에 맞는 저장소가 있는지 확인한 뒤 설치합니다.
docker_codename="$(. /etc/os-release && printf '%s' "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
docker_release_url="https://download.docker.com/linux/ubuntu/dists/$docker_codename/Release"
docker_http_status="$(curl -sS -o /dev/null -w '%{http_code}' "$docker_release_url")" || exit 1

if [ "$docker_http_status" = 200 ]; then
  # Docker 공식 저장소를 사용할 수 있는 Ubuntu 버전
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 docker-buildx podman-docker containerd runc; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
      sudo apt-get remove "$pkg" -y || exit 1
    fi
  done
  sudo apt-get update || exit 1
  sudo apt-get install ca-certificates curl -y || exit 1
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || exit 1
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $docker_codename stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update || exit 1
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y || exit 1
elif [ "$docker_http_status" = 404 ]; then
  # stonking 등 공식 저장소가 없는 버전은 Ubuntu 배포 패키지를 사용합니다.
  # 다른 Ubuntu 버전의 Docker CE 저장소를 혼용하지 않습니다.
  if [ -f /etc/apt/sources.list.d/docker.list ]; then
    sudo mv /etc/apt/sources.list.d/docker.list "/etc/apt/sources.list.d/docker.list.disabled.$(date +%s)"
  fi
  sudo apt-get update || exit 1
  sudo apt-get install docker.io docker-compose-v2 docker-buildx -y || exit 1
else
  printf '%s\n' "Docker 저장소 확인 실패: HTTP $docker_http_status ($docker_release_url)" >&2
  exit 1
fi

# 설치 후 서비스 시작 및 확인 (WSL systemd 활성화 필요)
sudo systemctl enable --now docker || exit 1
sudo systemctl status docker --no-pager || exit 1

# post 작업
getent group docker >/dev/null || sudo groupadd docker
sudo usermod -aG docker "$USER"

# 현재 셸의 그룹은 아직 갱신되지 않았으므로 sudo로 확인합니다.
sudo docker ps

# kubectl 설치
cd /tmp
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# minikube install
cd /tmp
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb
#minikube 확인
minikube version

# minikube start
# 검토: 아래 메모리 28672 MiB는 약 7 GiB WSL 환경에 맞지 않습니다.
# 실행 전에 free -m / nproc를 확인하고 memory/cpus를 환경에 맞게 조정하세요.
minikube config set cpus 4
minikube config set memory 28672
sudo -H -u "$USER" -g docker minikube start --driver=docker --addons=metrics-server,ingress,ingress-dns,logviewer,metallb

# kubectx, kubens 설치
curl -fsSL https://raw.githubusercontent.com/bahn1075/el_init/oel10/72.kubectx_kubens.sh | bash

# 새 터미널에서 .zshrc와 docker 그룹 권한을 적용하세요.

# [전체 파일 검토 / 실행 전 확인]
# - 전체 파일과 생성되는 .zshrc 블록의 zsh 문법을 검사했습니다.
# - eza alias 따옴표, brew -y, 중복 kubectx, 설치 의존성을 수정했습니다.
# - Oh My Zsh 설치 중 셸 전환과 newgrp로 설치 흐름이 멈추는 문제를 수정했습니다.
# - 새 eza/확장 블록은 중복 추가를 방지하지만 기존 마커 없는 설정은 정리해야 합니다.
# - brew shellenv / Starship / fastfetch / 로고는 재실행 시 중복 추가될 수 있습니다.
# - unattended 설치는 기본 셸을 바꾸지 않습니다. 필요하면 별도로 chsh를 실행합니다.
# - npx 로고를 매번 실행하면 터미널 시작이 늦어질 수 있습니다.
# - Docker 서비스 명령은 WSL systemd 활성화를 전제로 합니다.
# - kubectl/minikube 다운로드는 amd64 전용입니다. ARM64 환경이면 URL을 바꿉니다.
# - kubectx/kubens는 brew 설치 후 마지막 외부 스크립트로 다시 설치됩니다.
# - 설치 명령 실패 시 일괄 중단하는 구조는 아닙니다. 각 명령 결과를 확인하세요.
# - 스크린샷의 add-zsh-hook Usage 오류는 정상 메시지가 아닙니다.
#   새 터미널에서도 재발하면 zsh -ixc exit로 호출 위치를 확인합니다.
# - 상세 검토와 글꼴 해결 절차: 같은 폴더의 WSL-terminal-review.md
# - 실제 설치 및 사용자 Windows의 아이콘 렌더링은 이번 문법 검증 범위에 포함되지 않습니다.
