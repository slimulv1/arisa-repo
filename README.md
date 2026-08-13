# 📦 Arisa Repository

Kho binary của **Arisa** — repo Arch Linux cá nhân, build tự động 100% bằng GitHub Actions + GitHub Releases (zero-cost, không cần VPS). Đặt theo tên của Arisa, trợ lý ảo trên máy của anh. 🖤

<div align="center">

<!-- Hàng 1 — HERO (for-the-badge): identity -->
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)](https://archlinux.org)
[![pacman install](https://img.shields.io/badge/pacman-arisa-7b2ff7?style=for-the-badge&logo=archlinux&logoColor=white)](https://wiki.archlinux.org/title/Unofficial_user_repositories)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)

<!-- Hàng 2 — CI STATUS (flat-square): 3 workflow -->
[![Build Packages](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/build-packages.yml?branch=main&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/build-packages.yml)
[![Build Kernel](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/build-kernel.yml?branch=main&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/build-kernel.yml)
[![Sync AUR](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/sync-aur.yml?branch=main&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/sync-aur.yml)
[![Update Build Image](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/update-image.yml?branch=main&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/update-image.yml)

<!-- Hàng 3 — REPO STATS (flat): chỉ những gì có ý nghĩa -->
[![License](https://img.shields.io/github/license/slimulv1/arisa-repo?style=flat)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/slimulv1/arisa-repo?style=flat)](https://github.com/slimulv1/arisa-repo/commits/main)
[![Commit activity](https://img.shields.io/github/commit-activity/m/slimulv1/arisa-repo?style=flat)](https://github.com/slimulv1/arisa-repo/commits/main)
[![Last publish](https://img.shields.io/github/release-date/slimulv1/arisa-repo?style=flat)](https://github.com/slimulv1/arisa-repo/releases)

</div>

## Ý tưởng

Mọi thứ điều khiển bởi `packages.txt` (single source of truth):

- Dòng thường → gói AUR (đồng bộ tự động từ **CachyOS-PKGBUILDS** trước, fallback **AUR**)
- `local: tên-gói` → PKGBUILD tự maintain trong repo này (không sync, không ghi đè)

## Kiến trúc CI/CD

### 1. Sync AUR (`sync-aur.yml` — chạy mỗi giờ)

Quét `packages.txt`, với mỗi gói AUR:

1. **CachyOS-PKGBUILDS** (clone sparse `--depth=1 --filter=blob:none` để chỉ lấy metadata) — nếu tìm thấy PKGBUILD thì dùng luôn (tối ưu hơn AUR gốc)
2. Nếu không có → tải **AUR snapshot** (`aur.archlinux.org/cgit/aur.git/snapshot/<pkg>.tar.gz`)
3. Cập nhật vào repo và mở/update **Pull Request** `aur-sync` để anh review trước khi merge

### 2. Build & Publish (`build-packages.yml` — mỗi ngày 19:00 UTC, `build-kernel.yml` — mỗi ngày 02:00 UTC)

Đọc danh sách từ `packages.txt`, tách `linux-arisa` (kernel) ra job riêng, build song song (matrix) trong image tùy biến `ghcr.io/slimulv1/arisa-build:latest` (base `cachyos/cachyos-v3`, preinstall sẵn toolchain, chạy x86-64-v3), sau đó publish toàn bộ lên GitHub Release tag `repository`:

- **Hash-cache thông minh**: mỗi package được hash toàn bộ thư mục source (PKGBUILD + .SRCINFO + .install + patch) qua manifest `pkg-hashes.txt` — chỉ rebuild khi source thật sự đổi, không phụ thuộc tên file `pkgver-pkgrel`
- 🟢 Gói mới build
- 🟡 Gói không đổi → tải thẳng từ release cũ (cache)
- 🔴 Build lỗi → khôi phục bản cũ từ release (fallback), không bao giờ mất gói
- **Kernel build riêng** (`linux-arisa`): job tách biệt với **ccache 5GB** — lần đầu ~3h, lần sau ~18 phút. Mỗi run, job `prepare` tự **so sánh version với upstream `linux-lqx`** (AUR rpc/v5, so sánh `sort -V`): nếu tụt hậu → tự mở issue 🚨 kèm hướng dẫn bump (dedupe issue đang mở — không spam), luôn build được bản local kể cả khi tụt hậu
- **Atomic publish**: upload packages trước, DB files (`arisa.db/.files` + `.tar.gz`) upload **cuối cùng** → không bao giờ tồn tại DB trỏ vào package thiếu
- **Caches được chia sẻ** giữa các run (pacman package cache + ccache), tự dọn giữ 3 pacman + 2 ccache kernel mới nhất (luôn dưới trần 10GB của GitHub)

### 3. Build Image (`update-image.yml`)

Khi sửa `docker/build-image/Dockerfile` → tự rebuild image `ghcr.io/slimulv1/arisa-build:latest` (deps + toolchain preinstall, cache bằng BuildKit GHA).

## Cài đặt bên máy dùng

Thêm vào `/etc/pacman.conf`:

```ini
[arisa]
SigLevel = Optional DatabaseOptional
Server = https://github.com/slimulv1/arisa-repo/releases/download/repository
```

Rồi:

```bash
sudo pacman -Sy
sudo pacman -S arisa-meta    # cài cả đội hình AUR của Arisa
```

> ⚠️ Nhị phân build cho **x86-64-v3+** (CPU từ Intel Haswell / AMD Excavator trở lên). DB repo được **ký GPG** từ 2026-08-13 — chữ ký `arisa.db.tar.gz.sig` + public key `arisa.gpg` đính kèm mỗi release; xem phần Security model để xác minh.

## 🔒 Security model & trade-offs

- **`SigLevel = Optional DatabaseOptional`**: DB được ký GPG bằng key riêng của repo (fingerprint `BD8284BAEE6197CF2EC59839A3C506C20357176E`, public key `arisa.gpg` đính kèm release). Xác minh: tải `arisa.gpg`, `pacman-key --add arisa.gpg`, `pacman-key --lsign-key BD8284BAEE6197CF2EC59839A3C506C20357176E`; nâng `SigLevel = Required DatabaseOptional` để bắt buộc. Nếu CI không có secret GPG_PRIVATE_KEY, repo vẫn publish DB không ký (Optional không chặn) — chính sách 2 lớp: TLS HTTPS + GPG.
- **Actions pin theo commit SHA** (kèm comment `# vX`), Dependabot weekly tự mở PR khi upstream tag dịch chuyển → runner không bao giờ chạy code bị thay đổi ngoài ý muốn.
- **Nguồn build được pin**: `makepkg.conf`/`rust.conf` từ CachyOS `docker-makepkg` @ commit cố định; base image `cachyos/cachyos-v3` pin theo digest. Image build riêng `ghcr.io/slimulv1/arisa-build:latest` do chính repo tự build (`update-image.yml`).
- **Token**: chỉ dùng `GITHUB_TOKEN` với permission tối thiểu (`contents`/`actions`/`issues` write), không lưu secret nào.

## Gói tự maintain (local)

| Gói | Mô tả |
| :-- | :-- |
| `linux-arisa` | Kernel Liquorix đổi tên — **giữ nguyên 100% patch/config/cách build** của upstream `linux-lqx` (PDS scheduler, ZEN patches), chỉ đổi tên package + localversion thành `-arisa`. Chia gói: `linux-arisa`, `linux-arisa-headers`, `linux-arisa-docs`. CI tự mở issue 🚨 khi tụt hậu upstream |
| `arisa-meta` | Meta-package: cài toàn bộ đội hình AUR của Arisa trong một lệnh |
| `ttf-ms-win11-base` | Font Windows 11 base (Segoe UI, Consolas, Cascadia... ) — giữ local để cài trực tiếp |
| `ventoy` | Ventoy — tạo USB multi-boot. Packaging phức tạp (build nhiều thành phần từ source cũ: grub, edk2, ipxe...), vendor patch cục bộ nên tự maintain |
| `zalo-for-linux-bin` | Zalo client cho Linux (Unofficial, AppImage + ZaDark) — AUR source hardcode commit cũ gây 404, fix `_commithash` cục bộ nên giữ local |
| `lianli-linux-git` | Điều khiển fan/LED Lian Li (Host Controller) — cần udev rule `60-lianli.rules`, fix gtk3/webkit/npm/setuptools, pkgrel cục bộ |
| `anifetch-cli` | CLI fetch tool lấy cảm hứng từ anime — cần `python-setuptools` trong makedepends |
| `ttf-vietnamese-tcvn3` | Font tiếng Việt chuẩn TCVN 6909 (bộ `Vn*.ttf`) — nội dung đóng băng, chuyển local để không bị sync đè |
| `ttf-vietnamese-vni` | Font tiếng Việt chuẩn VNI (bộ `VNI-*.ttf`) — nội dung đóng băng, chuyển local để không bị sync đè |
| `catppuccin-fcitx5-git` | Theme Catppuccin cho fcitx5 (`*rounded` themes) — nội dung đóng băng, chuyển local để không bị sync đè |

## Gói AUR được mirror (theo máy của anh)

Betterlockscreen, bibata-cursor-theme, pywal stack (pywal16, pywalfox, pynput), dockapps (libdockapp + wmclock/wmcore/wmcpumon/wmitime/wmnet/wmnetload/wmshutdown/wmsystemtray), visual-studio-code-bin, cozette-otb, discord-ptb, spoofdpi, light, evdi-dkms, lianli-linux-git, fcitx5-lotus-bin, hw-probe, anifetch-cli, amethyst-mod-manager, code-marketplace, python-libloot.

## Fork cho riêng mình

1. Fork repo này, sửa `packages.txt` theo ý muốn (thêm gói AUR hoặc `local:` gói tự maintain).
2. Đổi image build nếu cần: sửa `docker/build-image/Dockerfile` (base `cachyos/cachyos-v3` + preinstall deps) — workflow `update-image.yml` sẽ tự rebuild lên GHCR của bạn.
3. Vào **Settings → Actions → General**: bật *Read and write permissions* + *Allow GitHub Actions to create and approve pull requests*.
4. Chạy workflow **Build and Publish Arch Repository** (workflow_dispatch) lần đầu — release `repository` sẽ tự tạo và `pkg-hashes.txt` bootstrap.

---

*Built with 🖤 by Arisa.*
