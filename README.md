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
sudo apt install zip unzip wget zsh curl gnome-shell-extensions gnome-tweaks git fontconfig ghostty -y
```

# nord gnome shell theme 설치
```
# 테마 다운로드
cd temp
git clone https://github.com/EliverLara/Nordic.git

# 테마 디렉토리로 복사
mkdir -p ~/.themes
cp -r Nordic ~/.themes/

# 또는 시스템 전체에 설치
sudo cp -r Nordic /usr/share/themes/
```
gnome shell extension (메뉴에서 '확장' 이라고 이름 붙여진)
에서 user theme를 활성화 하고 터미널에서
```
gnome-tweaks
```
수행 후 appearence 에서 shell 부분에 nord 선택

## 3. Nerd Font 설치

WSL 내부 프로그램용 글꼴을 설치합니다.

```sh
curl -fL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/UbuntuMono.zip -o /tmp/ubuntu-mono.zip
unzip -o /tmp/ubuntu-mono.zip -d /tmp/ubuntu-mono
sudo mkdir -p /usr/share/fonts/truetype/ubuntu-mono-nerd
sudo cp /tmp/ubuntu-mono/*.ttf /usr/share/fonts/truetype/ubuntu-mono-nerd/
sudo fc-cache -fv
rm -rf /tmp/ubuntu-mono /tmp/ubuntu-mono.zip
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
brew install starship fastfetch k9s eza ripgrep zsh-patina kubectx superfile zsh-autosuggestions vim gh tree node lazyssh lazydocker helm jq btop bat uv bun --no-ask
```

npm은 Homebrew `node`에 포함되므로 apt로 다시 설치하지 않습니다.


## 7. 별도 설치 대상

### 7-1. MS edge
```
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-edge.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list

sudo apt update && sudo apt install microsoft-edge-stable
```
### 7-2. tailscale client - 26.10
```
sudo mkdir -p /usr/share/keyrings

curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/resolute.noarmor.gpg \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/resolute.tailscale-keyring.list \
  | sudo tee /etc/apt/sources.list.d/tailscale.list

sudo apt update
sudo apt install -y tailscale

sudo systemctl enable --now tailscaled
sudo tailscale up
```
이후 별도 tailscale 수동 설정 진행

### 7-3. apt로 vscode 설치

```
sudo apt install wget gpg &&
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
sudo vi /etc/apt/sources.list.d/vscode.sources
sudo apt update && sudo apt install code
```
이후 별도 tailscale 수동 설정 진행


### 7-4. GitHub 로그인

`gh` 설치 후 로그인과 Git 사용자 정보를 설정합니다.

```zsh
gh auth login

git config --global user.name "cozy"
git config --global user.email bahn1075@gmail.com
```

## 8. Starship 프롬프트

기존 `starship.toml`이 있으면 아래 다운로드가 덮어씁니다.

```zsh
mkdir -p "$HOME/.config"
curl -fL -o "$HOME/.config/starship.toml" https://raw.githubusercontent.com/bahn1075/el_init/ubuntu/starship.toml
zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
if ! grep -Fqx 'eval "$(starship init zsh)"' "$zshrc_path"; then
  echo 'eval "$(starship init zsh)"' >> "$zshrc_path"
fi
```

## 9. Codex CLI 설치와 확인

### 9-1. 설치

이미 설치했다면 설치 명령은 생략하고 확인 단계로 넘어가세요.

```zsh
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

### 9-2. PATH 적용과 설치 확인

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

## 10. eza를 ls로 사용

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

## 11. 시작 화면: fastfetch와 로고

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

## 12. 자동 제안과 patina 구문 강조

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

## 13. Docker 설치

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

## 14. kubectl 설치

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

## 15. minikube 설치와 실행

### 15-1. 설치

Ubuntu의 패키지 아키텍처에 맞는 `.deb` 패키지를 다운로드합니다.

```zsh
cd /tmp
minikube_arch="$(dpkg --print-architecture)"
curl -fLO "https://storage.googleapis.com/minikube/releases/latest/minikube_latest_$minikube_arch.deb" &&
  sudo dpkg -i "minikube_latest_$minikube_arch.deb" &&
  minikube version
```

### 15-2. 자원 확인

```zsh
nproc
free -m
```

`wsl.sh`의 설정은 CPU 4개, 메모리 28672 MiB입니다. 약 7 GiB WSL에서는 그대로 사용하지 마세요. 아래는 CPU 2개, 메모리 3072 MiB 예시이며 실제 여유 자원에 맞게 바꾸세요.

```zsh
minikube config set cpus 2
minikube config set memory 3072
```

### 15-3. 클러스터 시작

```zsh
sudo -H -u "$USER" -g docker minikube start --driver=docker --addons=metrics-server,ingress,ingress-dns,logviewer,metallb
```

## 16. kubectx / kubens 추가 설정

두 도구는 이미 6단계에서 Homebrew로 설치했습니다. 먼저 실행 여부를 확인하세요.

```zsh
command -v kubectx kubens
```

`wsl.sh` 마지막의 외부 설치 스크립트도 필요한 경우에만 실행하세요. Homebrew 설치와 중복될 수 있습니다.

```zsh
curl -fsSL https://raw.githubusercontent.com/bahn1075/el_init/oel10/72.kubectx_kubens.sh | bash
```

## 17. 최종 확인

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

## 18. btop GPU 그래프 표시 — AMD / Intel / NVIDIA

일반 Ubuntu와 WSL에서 사용할 수 있는 점검 순서입니다. GPU 연산이 가능하더라도 btop의 통계 수집 기능이 지원되지 않으면 그래프가 표시되지 않을 수 있습니다. 아래 AMD 해결 사례는 일반 Ubuntu 26.10에서 검증했습니다.

### 18-1. 공통 확인과 GPU 패널 활성화

먼저 실제로 실행되는 btop과 GPU 드라이버를 확인합니다. Homebrew와 apt 버전이 함께 있으면 실행 경로가 다를 수 있습니다.

```zsh
command -v btop
btop --version
lspci -nnk | rg -A3 'VGA|3D|Display'
ls -l /dev/dri
```

`btop --version`의 빌드 옵션에서 `GPU_SUPPORT=true`를 확인합니다. GPU 지원이 빠진 빌드는 지원되는 패키지로 교체하거나 `make GPU_SUPPORT=true`로 빌드해야 합니다.

btop을 실행한 상태에서 `5` 키를 누르면 첫 번째 GPU 패널을 켜고 끌 수 있습니다. GPU를 인식한 경우 설정 화면에서도 표시할 패널을 선택할 수 있습니다.

설정 파일을 직접 수정하려면 **실행 중인 btop을 모두 종료한 뒤** 아래 명령으로 백업하고 편집합니다. 실행 중인 btop이 종료되면서 설정을 덮어쓸 수 있습니다.

```zsh
btop_config="${XDG_CONFIG_HOME:-$HOME/.config}/btop/btop.conf"
cp -p "$btop_config" "$btop_config.bak-$(date +%Y%m%d-%H%M%S)"
nano "$btop_config"
```

기존 `shown_boxes` 항목에 `gpu0`을 추가합니다. 기존 패널 선택은 유지하세요.

```ini
shown_boxes = "cpu mem net proc gpu0"
```

`shown_gpus`가 특정 제조사로 제한되어 있으면 사용할 GPU도 포함해야 합니다. btop 1.4.7의 기본값은 다음과 같습니다.

```ini
shown_gpus = "nvidia amd intel apple"
```

설정 파일이 없다면 btop을 한 번 실행하고 종료해서 생성합니다. `btop --config`로 별도 설정을 지정했다면 해당 파일을 수정하세요. GPU 자체를 인식하지 못한 경우에는 패널 설정만으로 해결되지 않으므로 아래 제조사별 항목을 확인합니다.

### 18-2. AMD: ROCm SMI 라이브러리 설치

Ubuntu 26.10 / Radeon RX 9070 계열 / Homebrew btop 1.4.7에서 다음 두 원인을 확인했습니다.

- GPU 지원 빌드와 `amdgpu` 드라이버는 정상이나 ROCm SMI 라이브러리가 설치되지 않았습니다.
- `shown_boxes`에 `gpu0`이 없었습니다.

로그에는 `Failed to load librocm_smi64.so, AMD GPUs will not be detected`가 기록되었습니다. 다음 패키지를 설치한 뒤 GPU 패널을 활성화하여 해결했습니다.

```zsh
sudo apt update
sudo apt install --no-install-recommends librocm-smi-dev
ldconfig -p | rg 'librocm_smi64'
btop
```

이 시스템에서는 런타임 `librocm-smi64-7`도 함께 설치되었습니다. btop 1.4.7은 `.so.7` 이름을 직접 탐색하지 않으므로, `librocm-smi-dev`가 제공하는 `librocm_smi64.so` 링크를 사용합니다. 다른 버전의 라이브러리 이름으로 임의의 심볼릭 링크를 만들지 마세요. Ubuntu 버전에 따라 패키지 제공 여부와 버전은 다를 수 있습니다.

실행 화면에서 GPU 사용률 그래프, 사용률 6%, 온도 62°C, 클럭 및 전력 표시를 확인했습니다. PCIe 전송량과 최대 온도 조회는 실패했으며, 최대 온도 기준값은 btop의 기본값 110°C가 사용되었습니다. 이 값은 GPU 제조사가 보증한 온도 한계로 해석하지 마세요. PyTorch나 전체 ROCm 개발 환경은 이 해결 작업에 필요하지 않았습니다.

### 18-3. Intel: i915 / xe 드라이버 구분

먼저 `lspci -nnk`의 `Kernel driver in use`를 확인합니다.

| 드라이버 | btop 1.4.7에서 확인할 사항 |
| --- | --- |
| `i915` | GPU 지원 빌드와 성능 카운터 접근 권한을 확인합니다. |
| `xe` | 정식 1.4.7의 기존 Intel 감지 경로로는 지원되지 않습니다. Xe 지원이 포함된 빌드가 필요합니다. |

`i915`에서 권한 문제인지 구분하려면 실제 실행 파일의 절대 경로로 한 번 비교 실행합니다.

```zsh
sudo "$(command -v btop)" --debug
```

관리자 실행에서만 GPU가 표시된다면 권한 설정을 확인합니다. 소스에서 설치한 btop은 공식 설치 절차의 `sudo make setcap`을 사용할 수 있습니다. 설치에 `PREFIX`를 지정했다면 같은 값을 사용해야 합니다. 이 명령은 실행 파일에 권한을 부여하므로, 설치한 빌드와 경로를 확인한 뒤 적용하세요. 패키지 업데이트 후에는 권한이 초기화될 수 있습니다.

`xe`는 권한을 높이는 것만으로 지원이 추가되지 않습니다. [Intel Xe 지원 PR #1457](https://github.com/aristocratos/btop/pull/1457)의 병합 여부와 사용 중인 버전의 지원 상태를 먼저 확인하세요. 이번 문서 작성 시 확인한 PR은 미병합 상태였습니다. 정식 지원 전에는 해당 패치가 포함된 빌드가 필요하며, 표시 가능한 온도·전력·메모리 항목은 GPU와 구현에 따라 다릅니다.

### 18-4. NVIDIA: 드라이버와 NVML 확인

btop의 NVIDIA 통계 수집에는 NVIDIA 드라이버와 NVML(`libnvidia-ml.so`)이 필요합니다. 먼저 드라이버와 라이브러리를 확인합니다.

```zsh
nvidia-smi
ldconfig -p | rg 'libnvidia-ml'
```

일반 Ubuntu에서 `nvidia-smi`가 실패하면 먼저 드라이버 설치·로딩 문제를 해결합니다. 드라이버가 없다면 Ubuntu의 **소프트웨어 및 업데이트 → 추가 드라이버**에서 해당 GPU에 권장되는 드라이버를 설치하고 재부팅합니다. 이미 작동 중인 드라이버를 그래프 문제만으로 재설치할 필요는 없습니다.

`nvidia-smi`가 정상인데 btop에 표시되지 않으면 GPU 지원 빌드 여부, NVML 로딩 오류, `shown_gpus`와 `shown_boxes`를 확인합니다. CUDA Toolkit 전체를 설치하는 것은 btop GPU 그래프의 필수 조건이 아닙니다.

### 18-5. 로그 확인과 WSL 참고

```zsh
btop --debug
```

문제를 재현하고 `q`로 종료한 뒤 로그를 확인합니다. 이번 Homebrew btop 1.4.7의 로그 위치는 다음과 같았습니다.

```zsh
tail -n 60 "${XDG_STATE_HOME:-$HOME/.local/state}/btop.log"
```

버전과 설치 방식에 따라 로그 위치가 다를 수 있습니다. 라이브러리 로딩 실패는 라이브러리 설치·탐색 경로를, 권한 오류는 장치·성능 카운터 접근 권한을 점검합니다.

WSL에서는 Windows 드라이버가 노출하는 GPU 기능을 사용하므로 일반 Ubuntu의 `/dev/dri`, sysfs, 성능 카운터와 동일한 통계가 제공된다고 가정하면 안 됩니다. AMD·Intel의 위 절차도 WSL에서 동일한 표시를 보장하지 않습니다. NVIDIA WSL에서는 Windows용 NVIDIA 드라이버를 사용하며, WSL 안에 Linux용 NVIDIA 디스플레이 드라이버를 설치하지 않습니다. `nvidia-smi`가 PATH에 없다면 `/usr/lib/wsl/lib/nvidia-smi`를 확인하세요. NVML의 지원 범위에 따라 일부 통계는 표시되지 않을 수 있습니다.

참고 자료:

- [btop 1.4.7 공식 안내: GPU 호환성과 설치 권한](https://github.com/aristocratos/btop/blob/v1.4.7/README.md)
- [Intel Xe 지원 PR #1457](https://github.com/aristocratos/btop/pull/1457)
- [NVIDIA CUDA on WSL 안내](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)

AMD 항목은 이 시스템에서 실행 검증했으며, Intel·NVIDIA 항목은 공식 자료에 따른 점검 안내입니다.

## 19. SSH 비밀번호 로그인과 부팅 시 자동 시작

2026-10-18에 일반 Ubuntu 26.10 PC `cozy-ubuntu`에서 적용했습니다. 과거 Mem0의 WSL 기록과 현재 환경이 다른 것을 확인한 뒤 진행했습니다. `cozy` 계정의 기존 Linux 로그인 비밀번호를 그대로 사용하며, 비밀번호는 변경하지 않았습니다.

### 19-1. 서버 설치와 비밀번호 인증 설정

```sh
sudo apt-get install -y openssh-server
sudo install -d -m 755 /etc/ssh/sshd_config.d
printf '%s\n' 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/00-local-password-auth.conf
sudo systemctl enable --now ssh.socket ssh.service
sudo /usr/sbin/sshd -t && sudo systemctl reload ssh.service
```

### 19-2. 확인 명령과 적용 결과

```sh
sudo /usr/sbin/sshd -t
systemctl is-enabled ssh.service ssh.socket
systemctl is-active ssh.service ssh.socket
ss -ltn 'sport = :22'
sudo /usr/sbin/sshd -T -C user=cozy,host=cozy-ubuntu,addr=192.168.0.2 | rg -i '^(passwordauthentication|usepam|authenticationmethods|permitrootlogin|permitemptypasswords) '
```
