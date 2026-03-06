# qmd-flake

[QMD](https://github.com/tobi/qmd)를 Nix flake로 패키징한 저장소입니다.

QMD는 로컬 텍스트 파일(문서, 노트, 회의록 등)을 대상으로 키워드 검색과 벡터 검색을 제공하는 CLI 검색 엔진입니다.

## 지원 플랫폼

- `aarch64-darwin` (Apple Silicon macOS)
- `x86_64-linux`

## 사용법

### 직접 실행

```bash
nix run github:devsisters/qmd-flake
```

### flake input으로 추가

```nix
{
  inputs = {
    qmd-flake.url = "github:devsisters/qmd-flake";
  };
}
```

#### 패키지 사용

```nix
qmd-flake.packages.${system}.default
```

#### Overlay 사용

```nix
nixpkgs.overlays = [ qmd-flake.overlays.default ];
# 이후 pkgs.qmd로 접근 가능
```

## 핀된 버전

- **QMD**: [`40610c3`](https://github.com/tobi/qmd/commit/40610c3aa65d9d399ebb188a7e4930f6628ae51c) (v1.1.0)
- **nixpkgs**: `nixpkgs-unstable`
