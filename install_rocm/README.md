# AMD GPU / ROCm 단계별 설치 안내

2026-10-17에 `cozy-ubuntu`에서 실행하고 GPU 연산까지 확인한 과정입니다. Ubuntu 터미널에서 위에서 아래로 코드 블록을 하나씩 실행하세요. 이미 설치된 항목은 확인 단계로 넘어갑니다.

## 1. 설치 대상과 지원 범위

| 항목 | 확인한 값 |
| --- | --- |
| OS | Ubuntu 26.10, `stonking`, x86_64 |
| 커널 | `7.3.0-9-generic` |
| GPU | AMD Radeon RX 9070 XT, `gfx1201`, 약 16 GiB VRAM |
| 커널 드라이버 | Ubuntu 커널에 포함된 `amdgpu` |
| 시스템 ROCm 런타임 | Ubuntu 저장소의 10.0 계열 패키지 |
| 검증용 Python | 기존 Python 3.13.16 |
| PyTorch | `2.14.1+rocm7.2` |
| PyTorch HIP 버전 | `7.2.53211` |

AMD 공식 ROCm 10.1 문서의 Radeon 지원 OS 목록에는 Ubuntu 26.10이 없습니다. 이 안내는 현재 장비에서 Ubuntu 기본 저장소와 PyTorch 공식 wheel을 조합해 검증한 기록이며, AMD의 공식 지원 조합을 의미하지 않습니다. Ubuntu 26.04용 AMD 저장소를 26.10에 추가하지 않습니다.

시스템 ROCm 패키지와 PyTorch wheel에 포함된 ROCm 라이브러리는 별도입니다. 시스템 패키지는 장치 확인과 HIP 런타임을 제공하고, 아래 PyTorch 연산은 wheel에 포함된 ROCm 7.2 라이브러리를 사용합니다. 시스템 라이브러리를 강제로 로드하는 `LD_LIBRARY_PATH` 설정은 추가하지 않았습니다.

## 2. OS와 기존 드라이버 확인

```sh
cat /etc/os-release
uname -r
lspci -nnk -s 08:00.0
modinfo -F filename amdgpu
ls -l /dev/kfd /dev/dri
```

현재 장비에서는 `Kernel driver in use: amdgpu`와 `/dev/kfd`, `/dev/dri/renderD128`이 확인됐습니다. 드라이버와 `linux-firmware`는 이미 설치되어 있고 Ubuntu 저장소의 최신 상태여서 재설치하지 않았습니다. 별도 `amdgpu-dkms` 설치나 커널 교체도 하지 않았습니다.

설치 상태를 확인합니다.

```sh
dpkg-query -W linux-firmware "linux-modules-$(uname -r)"
apt-cache policy linux-firmware "linux-modules-$(uname -r)"
```

GPU 주소 `08:00.0`과 장치 파일 번호는 이 장비의 값입니다. 다른 장비에서는 `lspci -nnk`로 실제 주소를 확인하세요. `amdgpu`가 동작하지 않거나 `/dev/kfd`가 없으면 이 문서의 검증 전제와 다르므로 먼저 드라이버 상태를 확인해야 합니다.

## 3. Ubuntu ROCm 런타임 설치

```sh
sudo apt-get update
apt-cache policy rocminfo libamdhip64-7
sudo apt-get --simulate install rocminfo libamdhip64-7
sudo apt-get install -y rocminfo libamdhip64-7
```

이번 실행에서는 기존 패키지 삭제나 업그레이드 없이 다음 5개 패키지가 추가됐습니다. 다운로드는 약 47.9 MB, 설치 공간은 약 184 MB였습니다.

| 패키지 | 설치 버전 |
| --- | --- |
| `rocminfo` | `10.0-0ubuntu2` |
| `libamdhip64-7` | `10.0-0ubuntu3` |
| `libamd-comgr3-rocm` | `10.0+dfsg-0ubuntu1` |
| `libhsa-runtime64-1` | `10.0+dfsg-0ubuntu2` |
| `libhsakmt1` | `10.0+dfsg-0ubuntu2` |

확인합니다. 설치 명령은 실행 시점의 Ubuntu 저장소 버전을 선택하므로 위 버전과 달라질 수 있습니다.

```sh
dpkg-query -W rocminfo libamdhip64-7 libamd-comgr3-rocm libhsa-runtime64-1 libhsakmt1
sudo dpkg --audit
sudo apt-get check
```

## 4. GPU 접근 권한과 장치 확인

```sh
sudo usermod -aG render,video "$(id -un)"
id "$(id -un)"
rocminfo
```

`id 사용자명`은 저장된 그룹 구성을 표시합니다. 실행 중인 셸의 그룹은 `id`로 확인하며, 추가한 그룹을 새 세션에 적용하려면 로그아웃 후 다시 로그인하세요. 이번 세션은 장치 ACL로 이미 접근 가능해 즉시 검증할 수 있었습니다.

`rocminfo`에서 다음 값이 확인됐습니다.

```text
Name:          gfx1201
Marketing Name: AMD Radeon RX 9070 XT
Device Type:   GPU
```

시스템 HIP 런타임의 GPU 탐지와 메모리 할당도 확인할 수 있습니다.

```sh
python3 - <<'PY'
import ctypes
import ctypes.util

path = ctypes.util.find_library('amdhip64')
assert path, 'HIP runtime library not found'
hip = ctypes.CDLL(path)
count = ctypes.c_int()
assert hip.hipGetDeviceCount(ctypes.byref(count)) == 0
assert count.value > 0
pointer = ctypes.c_void_p()
assert hip.hipMalloc(ctypes.byref(pointer), ctypes.c_size_t(4096)) == 0
assert hip.hipFree(pointer) == 0
print(f'PASS: {count.value} GPU, HIP memory allocation/free')
PY
```

## 5. 검증용 PyTorch 가상환경 설치

기존 Codex/Headroom 가상환경과 분리해 `~/.local/share/rocm-pytorch`에 설치했습니다. 기존에 설치된 `uv`와 toolkit의 Python을 재사용하며, Python을 추가 설치하지 않습니다.

```sh
uv --version
"$HOME/.codex/toolkit/venv/bin/python" --version
uv venv --python "$HOME/.codex/toolkit/venv/bin/python" "$HOME/.local/share/rocm-pytorch"
```

이 명령은 새 가상환경을 만드는 단계입니다. 해당 경로에 기존 환경이 있다면 생성 단계를 반복하지 말고 먼저 용도와 Python 버전을 확인하세요.

현재 장비에서는 ROCm 설치 전 `uv --torch-backend auto`가 CPU를 선택했으나 설치 후 다음 명령이 `torch==2.14.1+rocm7.2`를 반환했습니다.

```sh
uv pip compile --python "$HOME/.local/share/rocm-pytorch/bin/python" \
  --no-deps --no-header --no-annotate --torch-backend auto - <<'REQ'
torch>=2.12.1
REQ
```

검증한 버전을 설치합니다. PyTorch wheel 다운로드만 약 5.8 GiB이며 압축 해제 후에는 더 많은 디스크 공간을 사용합니다. 이번 다운로드·준비 단계는 약 12분 걸렸습니다.

```sh
uv pip install --python "$HOME/.local/share/rocm-pytorch/bin/python" \
  --torch-backend rocm7.2 'torch==2.14.1+rocm7.2'
uv pip install --python "$HOME/.local/share/rocm-pytorch/bin/python" 'numpy>=2,<3'
uv pip check --python "$HOME/.local/share/rocm-pytorch/bin/python"
```

설치된 전체 Python 패키지 버전은 [requirements-rocm.txt](requirements-rocm.txt)에 기록했습니다. 동일 버전으로 재현할 때는 다음 명령을 사용합니다.

```sh
uv pip install --python "$HOME/.local/share/rocm-pytorch/bin/python" \
  --torch-backend rocm7.2 -r /app/setup_ubuntu/install_rocm/requirements-rocm.txt
```

## 6. GPU 이름 파일 경로 설정과 실제 연산 검증

PyTorch wheel의 libdrm은 이 환경에서 GPU 이름 파일을 `/opt/amdgpu/share/libdrm/amdgpu.ids`에서 찾았습니다. 실제 파일은 Ubuntu의 `/usr/share/libdrm/amdgpu.ids`에 있습니다. 경로를 지정하지 않았을 때 `(null): No such file or directory`가 출력되고 GPU 이름이 `AMD Radeon Graphics`로 표시됐습니다.

기존 파일의 위치를 지정하자 해당 메시지가 사라지고 정확한 모델명이 표시됐습니다. 시스템 파일을 복사하거나 `/opt/amdgpu`에 임의 링크를 만들 필요는 없습니다.

```sh
test -r /usr/share/libdrm/amdgpu.ids
export AMDGPU_ASIC_ID_TABLE_PATHS=/usr/share/libdrm
"$HOME/.local/share/rocm-pytorch/bin/python" /app/setup_ubuntu/install_rocm/verify_gpu.py
```

[verify_gpu.py](verify_gpu.py)는 ROCm PyTorch 여부, GPU 접근, GPU 메모리 전송, GPU 행렬 곱셈과 CPU 결과 일치를 검사합니다. 검증 결과는 [verification.json](verification.json)에 기록했습니다.

```json
{
  "torch": "2.14.1+rocm7.2",
  "hip": "7.2.53211",
  "gpu": "AMD Radeon RX 9070 XT",
  "architecture": "gfx1201",
  "device": "cuda:0",
  "matrix_shape": [256, 256],
  "cpu_result_matches": true,
  "status": "PASS"
}
```

ROCm에서도 PyTorch의 GPU 장치 API 이름은 `cuda`입니다. 위 결과의 `cuda:0`은 AMD GPU를 가리킵니다.

## 7. 새 터미널에서 사용

```sh
export AMDGPU_ASIC_ID_TABLE_PATHS=/usr/share/libdrm
source "$HOME/.local/share/rocm-pytorch/bin/activate"
python /app/setup_ubuntu/install_rocm/verify_gpu.py
```

사용이 끝나면 가상환경을 종료합니다.

```sh
deactivate
```

이 설치로 이미 실행 중인 Codex/Headroom의 백엔드가 자동 전환되지는 않습니다. 이후 별도 요청으로 Headroom도 GPU로 전환하고 실제 모델 추론을 검증했습니다. 적용 내용은 9단계에 정리했습니다. 커스텀 HIP 프로그램 컴파일을 위한 개발 SDK는 설치하지 않았습니다.

## 8. 최종 확인과 참고 문서

이번 장비에서 커널 드라이버와 GPU 장치 인식, 시스템 HIP 메모리 할당·해제, PyTorch GPU 행렬 연산, CPU 결과 일치, Ubuntu/Python 패키지 의존성 검사를 통과했습니다. 설치와 검증에 재부팅은 필요하지 않았습니다.

- [AMD ROCm 설치 안내](https://rocm.docs.amd.com/en/latest/install/rocm.html)
- [AMD ROCm 호환성 표](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html)
- [uv의 PyTorch / ROCm 설치 안내](https://docs.astral.sh/uv/guides/integration/pytorch/)

검증 범위는 이 장비의 현재 OS·커널·패키지 조합, 위 GPU 행렬 연산과 아래 Headroom 모델 추론입니다. 장시간 부하와 다른 AI 프레임워크는 별도 확인이 필요합니다.

## 9. Headroom GPU 전환

2026-10-17에 기존 Headroom `0.41.0` 버전을 유지하면서 toolkit의 Headroom 가상환경에 ROCm용 PyTorch를 추가했습니다. 먼저 디스크의 별도 가상환경에서 검증하고, 같은 패키지 버전으로 실제 환경에 적용했습니다. `/tmp`는 메모리 기반 파일시스템의 용량 제한으로 GPU 패키지 검증 환경에 사용하지 않았습니다.

### 9-1. 적용한 환경과 설정

| 항목 | 적용 값 |
| --- | --- |
| Headroom Python | `~/.codex/toolkit/uv-tools/headroom-ai/bin/python` |
| 설치 extras | `headroom-ai[mcp,code,ml]==0.41.0` |
| PyTorch | `2.14.1+rocm7.2` |
| `HEADROOM_KOMPRESS_BACKEND` | `pytorch` |
| `AMDGPU_ASIC_ID_TABLE_PATHS` | `/usr/share/libdrm` |
| 설치 상태의 `torch_backend` | `rocm7.2` |

두 환경 변수는 `~/.codex/config.toml`의 `[mcp_servers.headroom.env]`에 저장했습니다. `~/.codex/toolkit/install-state.json`의 `headroom_hardware`도 GPU 설정으로 갱신했습니다. 다른 MCP 서버와 사용자 설정은 유지했습니다.

### 9-2. 실제 GPU 모델 및 MCP 검증

```sh
AMDGPU_ASIC_ID_TABLE_PATHS=/usr/share/libdrm \
  "$HOME/.codex/toolkit/uv-tools/headroom-ai/bin/python" \
  /app/codex-toolkit/headroom_setup.py verify pytorch rocm7.2
```

검증은 ROCm GPU 연산, 모델 파라미터의 GPU 배치, 실제 모델 추론 점수, MCP 압축·원문 복원·읽기 캐시를 확인했습니다. `backend`와 `model_backend`는 모두 `pytorch`였고 MCP 압축은 4,809 → 2,420 토큰으로 줄었습니다. 별도 문장 샘플의 `ml_tokens_saved`는 0이었지만 GPU 추론 점수 검증은 통과했습니다.

결과는 [headroom-verification.json](headroom-verification.json)에 기록했습니다. 설정된 `headroom-mcp` 실행기로 새 프로세스를 시작해 MCP 핸드셰이크와 도구 4개 등록도 확인했습니다.

### 9-3. 현재 세션에 적용

이미 실행 중인 Headroom MCP 프로세스의 환경 변수와 로드된 모델은 설정 파일 변경만으로 교체되지 않습니다. Codex의 MCP 재연결 또는 Codex/VS Code 재시작 후 새 프로세스가 GPU 설정을 읽습니다. 이번 검증은 전환된 실제 설치 환경에서 새로 시작한 프로세스로 수행했습니다.

### 9-4. 백업

전환 전 설정과 CPU 환경은 다음 경로에 보관했습니다.

```text
/home/cozy/.codex-backups/headroom-gpu-20261017-130039/
```

백업에는 기존 `config.toml`, `install-state.json`, `headroom-mcp` 실행기와 Headroom 가상환경이 있습니다. 같은 디렉터리의 `gpu-requirements.txt`에는 검증한 GPU 환경의 전체 패키지 버전, `staged-verification.log`와 `production-verification.log`에는 실제 검증 로그가 있습니다. 복구할 때는 먼저 Codex/Headroom을 종료하고, 백업 가상환경을 원래의 `~/.codex/toolkit/uv-tools/headroom-ai` 경로로 복원해야 합니다. 가상환경 내부 실행 파일에 절대 경로가 있어 백업 경로에서 직접 실행하면 안 됩니다.
