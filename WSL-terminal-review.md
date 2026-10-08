# WSL 단계별 설정 안내

`wsl.sh`의 명령을 카테고리별로 정리했습니다. WSL Ubuntu 터미널에서 위에서 아래로 코드 블록을 하나씩 실행하세요. Windows 설정 단계는 별도로 표시했습니다. heredoc은 마지막 `ZSHRC` 줄까지 블록 전체를 복사하세요.

## 1. sudo 설정

비밀번호 없이 sudo를 사용하도록 설정합니다.

```sh
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null
sudo chmod 440 "/etc/sudoers.d/$USER"
sudo visudo -c -f "/etc/sudoers.d/$USER"
```

설정을 확인합니다.

```sh
sudo -l
sudo cat "/etc/sudoers.d/$USER"
ls -la "/etc/sudoers.d/$USER"
sudo -n true && echo "패스워드 없이 sudo 가능" || echo "패스워드 필요"
```

## 2. Ubuntu 업데이트와 필수 도구

```sh
sudo apt update && sudo apt upgrade -y
sudo apt install zip unzip wget zsh curl git fontconfig -y
```

## 3. Nerd Font 설치

WSL 내부 프로그램용 글꼴을 설치합니다.

```sh
curl -fL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip -o /tmp/meslo.zip
unzip -o /tmp/meslo.zip -d /tmp/meslo
sudo mkdir -p /usr/share/fonts/truetype/meslo-nerd
sudo cp /tmp/meslo/*.ttf /usr/share/fonts/truetype/meslo-nerd/
sudo fc-cache -fv
rm -rf /tmp/meslo /tmp/meslo.zip
```

### 3-1. Windows VS Code의 eza 아이콘 설정

Windows에서 실행하는 VS Code는 Remote WSL에서도 Windows에 설치된 글꼴을 사용합니다. 외부 터미널에서 정상 표시되는 Nerd Font의 이름을 확인하고, 같은 글꼴을 Windows에도 설치하세요. 이미 설치했다면 설치 단계는 생략합니다.

VS Code에서 `Preferences: Open User Settings (JSON)`을 열고 다음 키를 기존 JSON 객체에 추가하세요. 글꼴 이름은 실제 설치된 패밀리 이름으로 바꿉니다.

```json
"terminal.integrated.fontFamily": "'MesloLGS Nerd Font Mono', monospace"
```

Workspace/Remote 설정의 동일 키가 덮어쓰는지도 확인하세요. VS Code를 완전히 종료한 후 다시 실행합니다. `editor.fontFamily`는 터미널 글꼴 설정과 별개입니다.

## 4. Oh My Zsh 설치 (필수)

필수 도구 설치 후, Homebrew와 `.zshrc` 사용자 설정을 추가하기 전에 Oh My Zsh를 설치합니다. 이 안내에서는 Oh My Zsh 설치를 필수 단계로 진행합니다. 이미 설치된 환경은 재설치하지 않고 아래 확인 단계로 넘어가세요.

### 4-1. 설치

`--unattended` 옵션으로 설치 도중 셸이 전환되지 않도록 합니다.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

### 4-2. 설치 확인

아래 명령에서 `Oh My Zsh 설치 확인 완료`가 출력되는지 확인하세요.

```sh
test -f "${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh" && echo "Oh My Zsh 설치 확인 완료"
```

### 4-3. 기본 셸 지정

기본 셸을 zsh로 지정합니다.

```sh
chsh -s "$(command -v zsh)"
```

### 4-4. 현재 터미널을 zsh로 전환

현재 터미널도 zsh로 전환합니다. 이후 명령은 zsh에서 실행하세요.

```sh
exec zsh
```

## 5. Homebrew 설치와 환경 설정

이미 설치되어 있다면 설치 명령은 생략하세요.

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

`.zshrc`에 환경 설정을 기록하고 현재 셸에 적용합니다.

```zsh
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
touch "$zshrc_path"
if ! grep -Fqx 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' "$zshrc_path"; then
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$zshrc_path"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
if ! grep -Fqx 'export PATH="$HOME/.local/bin:$PATH"' "$zshrc_path"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$zshrc_path"
fi
export PATH="$HOME/.local/bin:$PATH"
```

`$HOME/.local/bin`은 Codex 등 사용자 계정으로 설치하는 실행 파일의 경로입니다. `.zshrc`에 기록해야 새 zsh 터미널에서도 사용할 수 있습니다.

## 6. Homebrew 패키지 설치

```zsh
brew install starship fastfetch k9s eza ripgrep zsh-patina kubectx superfile zsh-autosuggestions vim gh tree node lazyssh lazydocker helm jq btop bat --no-ask
```

npm은 Homebrew `node`에 포함되므로 apt로 다시 설치하지 않습니다.

### 6-1. GitHub 로그인

`gh` 설치 후 로그인과 Git 사용자 정보를 설정합니다.

```zsh
gh auth login

git config --global user.name "cozy"
git config --global user.email bahn1075@gmail.com
```

## 7. Starship 프롬프트

기존 `starship.toml`이 있으면 아래 다운로드가 덮어씁니다.

```zsh
mkdir -p "$HOME/.config"
curl -fL -o "$HOME/.config/starship.toml" https://raw.githubusercontent.com/bahn1075/el_init/ubuntu/starship.toml
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
if ! grep -Fqx 'eval "$(starship init zsh)"' "$zshrc_path"; then
  echo 'eval "$(starship init zsh)"' >> "$zshrc_path"
fi
```

## 8. Codex CLI 설치와 확인

### 8-1. 설치

이미 설치했다면 설치 명령은 생략하고 확인 단계로 넘어가세요.

```zsh
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

### 8-2. PATH 적용과 설치 확인

설치기가 `.bashrc`에 PATH를 추가하더라도 zsh는 기본적으로 이 파일을 읽지 않습니다. 5단계에서 `.zshrc`에 기록한 사용자 실행 경로를 현재 셸에도 적용하고 확인합니다. 설치기를 `sh`로 실행해도 부모인 현재 zsh의 PATH는 변경되지 않습니다.

```zsh
export PATH="$HOME/.local/bin:$PATH"
command -v codex
codex --version
```

경로와 버전이 정상 출력되면 실행합니다.

```zsh
codex
```

## 9. eza를 ls로 사용

```zsh
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
touch "$zshrc_path"
if ! grep -Fq '# >>> WSL eza >>>' "$zshrc_path"; then
  cat >> "$zshrc_path" <<'ZSHRC'

# >>> WSL eza >>>
alias ls="eza --icons --git --level=2 --time-style='+%m/%d %H:%M' --git-repos --total-size --group-directories-first --sort=time"
# <<< WSL eza <<<
ZSHRC
fi
```

## 10. 시작 화면: fastfetch와 로고

fastfetch를 추가합니다.

```zsh
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
if ! grep -Fqx 'fastfetch' "$zshrc_path"; then
  echo 'fastfetch' >> "$zshrc_path"
fi
```

로고는 원하는 경우 추가합니다. 매번 `npx`가 실행되므로 터미널 시작이 느려질 수 있습니다.

```zsh
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
if ! grep -Fqx 'npx oh-my-logo "MY WSL" fire --filled --block-font chrome --letter-spacing 2' "$zshrc_path"; then
  echo 'npx oh-my-logo "MY WSL" fire --filled --block-font chrome --letter-spacing 2' >> "$zshrc_path"
fi
```

## 11. 자동 제안과 patina 구문 강조

기존 `.zshrc`에 `zsh-syntax-highlighting` 로딩이 있으면 제거하세요. 마커 없이 추가했던 autosuggestions/patina 설정도 중복되지 않게 정리합니다. 이 블록은 다른 `.zshrc` 설정을 추가한 뒤 마지막에 실행하세요.

```zsh
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
touch "$zshrc_path"
if ! grep -Fq '# >>> WSL zsh extensions >>>' "$zshrc_path"; then
  cat >> "$zshrc_path" <<'ZSHRC'

# >>> WSL zsh extensions >>>
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
eval "$("$(brew --prefix)/bin/zsh-patina" activate)"
# <<< WSL zsh extensions <<<
ZSHRC
fi
```

문법 검사에 성공하면 현재 터미널에 적용합니다.

```zsh
zsh -n "${ZDOTDIR:-$HOME}/.zshrc" && source "${ZDOTDIR:-$HOME}/.zshrc"
```

아이콘, 색상, 자동 제안을 확인합니다. 이전 명령의 앞부분을 입력하면 흐린 제안이 나오며 `→`로 수락합니다.

```zsh
eza --icons
echo "hello"
```

## 12. Docker 설치

WSL의 systemd 활성화가 필요합니다. 아래 블록은 현재 Ubuntu 코드명의 Docker 저장소를 먼저 확인합니다. 저장소가 없는 `stonking` 등에서는 Ubuntu의 `docker.io` 패키지를 설치합니다. Docker CE 패키지와 Ubuntu 배포 패키지는 이름이 다릅니다.

```zsh
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

```

사용자 그룹을 설정하고 설치를 확인합니다.

```zsh
getent group docker >/dev/null || sudo groupadd docker
sudo usermod -aG docker "$USER"
sudo docker ps
sudo docker run --rm hello-world
```

새로 로그인하면 그룹 권한이 적용됩니다. 아래 minikube 단계는 `sudo -H -u "$USER" -g docker`로 사용자 계정과 Docker 그룹 권한을 사용합니다.

## 13. kubectl 설치

Ubuntu의 패키지 아키텍처에 맞는 실행 파일을 다운로드합니다. AMD64 환경에서는 `amd64`, ARM64 환경에서는 `arm64`가 선택됩니다.

```zsh
cd /tmp
kubectl_arch="$(dpkg --print-architecture)"
kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
if [ -n "$kubectl_version" ]; then
  curl -fL "https://dl.k8s.io/release/$kubectl_version/bin/linux/$kubectl_arch/kubectl" -o "kubectl-$kubectl_arch" &&
    sudo install -o root -g root -m 0755 "kubectl-$kubectl_arch" /usr/local/bin/kubectl &&
    kubectl version --client
fi
```

## 14. minikube 설치와 실행

### 14-1. 설치

Ubuntu의 패키지 아키텍처에 맞는 `.deb` 패키지를 다운로드합니다.

```zsh
cd /tmp
minikube_arch="$(dpkg --print-architecture)"
curl -fLO "https://storage.googleapis.com/minikube/releases/latest/minikube_latest_$minikube_arch.deb" &&
  sudo dpkg -i "minikube_latest_$minikube_arch.deb" &&
  minikube version
```

### 14-2. 자원 확인

```zsh
nproc
free -m
```

`wsl.sh`의 설정은 CPU 4개, 메모리 28672 MiB입니다. 약 7 GiB WSL에서는 그대로 사용하지 마세요. 아래는 CPU 2개, 메모리 3072 MiB 예시이며 실제 여유 자원에 맞게 바꾸세요.

```zsh
minikube config set cpus 2
minikube config set memory 3072
```

### 14-3. 클러스터 시작

```zsh
sudo -H -u "$USER" -g docker minikube start --driver=docker --addons=metrics-server,ingress,ingress-dns,logviewer,metallb
```

## 15. kubectx / kubens 추가 설정

두 도구는 이미 6단계에서 Homebrew로 설치했습니다. 먼저 실행 여부를 확인하세요.

```zsh
command -v kubectx kubens
```

`wsl.sh` 마지막의 외부 설치 스크립트도 필요한 경우에만 실행하세요. Homebrew 설치와 중복될 수 있습니다.

```zsh
curl -fsSL https://raw.githubusercontent.com/bahn1075/el_init/oel10/72.kubectx_kubens.sh | bash
```

## 16. 최종 확인

새 WSL 터미널을 열고 실행합니다.

```zsh
zsh -n "${ZDOTDIR:-$HOME}/.zshrc"
command -v codex
codex --version
ls
docker ps
kubectl version --client
minikube status
```
