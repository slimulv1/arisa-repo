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

Toàn bộ luồng **sync → PR → auto-merge → build → publish** đều tự động: bạn chỉ cần sửa `packages.txt` (hoặc thêm thư mục PKGBUILD), phần còn lại CI lo. Xem [Cách thêm package thủ công](#-cách-thêm-package-thủ-công).

---

## 🚀 Cách cài đặt (bên máy dùng)

### Yêu cầu

- Hệ điều hành dùng pacman: **Arch Linux** (hoặc CachyOS, EndeavourOS...)
- CPU hỗ trợ **x86-64-v3+** (Intel Haswell / AMD Excavator trở lên) — nhị phân build tối ưu theo `cachyos/cachyos-v3`

```bash
# Kiểm tra nhanh CPU của bạn
grep -o 'x86-64-v[0-9]' /proc/cpuinfo | sort -u
# Phải hiển thị "x86-64-v3" (hoặc v4)
```

### Bước 1 — Thêm repo vào pacman

Mở `/etc/pacman.conf` và thêm **vào cuối file**:

```ini
[arisa]
SigLevel = Optional DatabaseOptional
Server = https://github.com/slimulv1/arisa-repo/releases/download/repository
```

> 💡 Có thể chạy nhanh bằng lệnh:
> ```bash
> sudo tee -a /etc/pacman.conf <<'EOF'
>
> [arisa]
> SigLevel = Optional DatabaseOptional
> Server = https://github.com/slimulv1/arisa-repo/releases/download/repository
> EOF
> ```

### Bước 2 — Đồng bộ + cài đặt

```bash
sudo pacman -Sy

# Cài cả đội hình Arisa (meta-package)
sudo pacman -S arisa-meta

# Hoặc cài từng gói riêng
sudo pacman -S betterlockscreen discord-ptb
```

### Sử dụng hằng ngày

| Việc                    | Lệnh                                          |
| :---------------------- | :-------------------------------------------- |
| Tìm gói trong repo      | `sudo pacman -Ss arisa` (hoặc `pacman -Sl arisa`) |
| Cập nhật hệ thống       | `sudo pacman -Syu` (repo publish mỗi ngày ~19:00 UTC, kernel 02:00 UTC) |
| Gỡ gói                  | `sudo pacman -Rns <tên-gói>`                  |
| Ngừng dùng repo         | Xóa block `[arisa]` khỏi `/etc/pacman.conf` rồi `sudo pacman -Sy` |

### Xác minh chữ ký GPG (khuyến khích)

DB repo được ký GPG bằng key riêng (fingerprint `BD8284BAEE6197CF2EC59839A3C506C20357176E`, public key `arisa.gpg` đính kèm mỗi release):

```bash
curl -fLO https://github.com/slimulv1/arisa-repo/releases/download/repository/arisa.gpg
sudo pacman-key --add arisa.gpg
sudo pacman-key --lsign-key BD8284BAEE6197CF2EC59839A3C506C20357176E
```

Nâng cấp chặt hơn bằng cách đổi trong `/etc/pacman.conf`:

```ini
SigLevel = Required DatabaseOptional
```

Chi tiết model bảo mật: xem [🔒 Security model](#-security-model--trade-offs).

---

## ➕ Cách thêm package thủ công

Repo có sẵn **2 loại package** — cách thêm mỗi loại hoàn toàn khác nhau.

### Cách 1 — Thêm gói AUR (chỉ 1 dòng, hoàn toàn tự động)

Áp dụng cho gói đã tồn tại trên AUR (hoặc CachyOS-PKGBUILDS). Bạn chỉ cần khai tên gói:

```bash
echo "my-new-aur-pkg" >> packages.txt
git add packages.txt
git commit -m "feat: add my-new-aur-pkg"
git push
```

Sau đó CI tự chạy toàn bộ:

1. **`sync-aur.yml`** (chạy mỗi giờ `:07`, hoặc ngay khi push `packages.txt`) tìm PKGBUILD trong **CachyOS-PKGBUILDS** trước, fallback **AUR snapshot**, copy vào thư mục `<gói>/`
2. Tạo **PR `aur-sync`** chứa các file mới → **auto-merge** tự merge khi PR không conflict (có guard: chỉ merge nếu PR chỉ đụng thư mục package)
3. **`build-packages.yml`** build (kích hoạt ngay bởi push lên main) → publish lên GitHub Release tag `repository`
4. Khoảng 30–60 phút sau: `sudo pacman -Sy && sudo pacman -S my-new-aur-pkg` 🎉

**Lưu ý khi chọn tên:**

- ⚠️ Tên phải **khớp chính xác pkgbase trên AUR** (phân biệt hoa thường, giữ nguyên hậu tố `-git`, `-bin`...): `fcitx5-lotus-git` ≠ `fcitx5-lotus-bin`
- Nếu AUR/CachyOS không có gói đó → `sync-aur` báo trong cột **🔴 Failed** của PR body, gói không được thêm → kiểm tra lại tên
- Thư mục gói = tên trong `packages.txt`, **không chứa version**

**Xóa gói AUR:** bỏ dòng đó khỏi `packages.txt` → sync giờ sẽ **prune** thư mục cũ → PR dọn dẹp → auto-merge → gói biến mất khỏi release run tiếp theo.

---

### Cách 2 — Thêm gói tự maintain (`local:`)

Áp dụng cho gói **không có trên AUR** (hoặc bạn muốn fix/sửa riêng, đóng băng version, patch cục bộ...).

**Bước 1 — Tạo thư mục gói với PKGBUILD:**

```bash
mkdir my-tool
```

Tạo `my-tool/PKGBUILD` (skeleton tham khảo):

```bash
pkgname=my-tool
pkgver=1.0.0
pkgrel=1
pkgdesc="Mô tả ngắn gọn"
arch=('x86_64')
url="https://github.com/you/my-tool"
license=('MIT')
depends=('curl')
makedepends=('cmake' 'ninja')
source=("$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')   # THAY bằng hash thật sau khi tải lần đầu

build() {
  cmake -B build -G Ninja
  cmake --build build
}

package() {
  install -Dm755 build/my-tool "$pkgdir/usr/bin/my-tool"
}
```

Sinh `.SRCINFO` cho chuẩn (khuyến khích):

```bash
cd my-tool
makepkg --printsrcinfo > .SRCINFO
```

**Bước 2 — Khai báo local + push:**

```bash
echo "local: my-tool" >> packages.txt
git add my-tool packages.txt
git commit -m "feat: add self-maintained my-tool"
git push
```

`build-packages.yml` chạy **ngay** (push chạm thư mục package) → build → publish. Nếu build lỗi, CI tự **fallback giữ gói cũ** trên release — không bao giờ mất gói đang chạy.

**Quy tắc vàng cho gói local:**

- Tên thư mục = dòng trong `packages.txt`, **không version** (version nằm trong PKGBUILD)
- PKGBUILD phải build được trong container **CachyOS x86-64-v3** (`makepkg.conf` của CachyOS) — test bằng `makepkg` trên máy CachyOS là chuẩn nhất
- Gói cần `makedepends` lạ chưa có trong build image → thêm vào `docker/build-image/Dockerfile` (workflow `update-image.yml` tự rebuild image mới)
- Kernel `linux-arisa` là case đặc biệt: build riêng qua `build-kernel.yml` (ccache, tự so sánh version upstream) — chỉ đụng tới nếu bạn hiểu kernel packaging
- Sau khi sửa PKGBUILD nhớ `makepkg --printsrcinfo > .SRCINFO` (giữ hash-cache ổn định)

---

## Kiến trúc CI/CD

### 1. Sync AUR (`sync-aur.yml` — chạy mỗi giờ)

Quét `packages.txt`, với mỗi gói AUR:

1. **CachyOS-PKGBUILDS** (clone sparse `--depth=1 --filter=blob:none` để chỉ lấy metadata) — nếu tìm thấy PKGBUILD thì dùng luôn (tối ưu hơn AUR gốc)
2. Nếu không có → tải **AUR snapshot** (`aur.archlinux.org/cgit/aur.git/snapshot/<pkg>.tar.gz`)
3. Cập nhật vào repo và mở/update **PR `aur-sync`** → **auto-merge tự động**: script `.github/scripts/auto-merge-pr.sh` chờ mergeability, tự `update-branch` khi conflict, retry + verify; PR bị chặn (conflict không tự được, đụng file ngoài package dirs) → comment lý do lên PR để xử lý thủ công

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

## 🔒 Security model & trade-offs

- **`SigLevel = Optional DatabaseOptional`**: DB được ký GPG bằng key riêng của repo (fingerprint `BD8284BAEE6197CF2EC59839A3C506C20357176E`, public key `arisa.gpg` đính kèm release). Xác minh: tải `arisa.gpg`, `pacman-key --add arisa.gpg`, `pacman-key --lsign-key BD8284BAEE6197CF2EC59839A3C506C20357176E`; nâng `SigLevel = Required DatabaseOptional` để bắt buộc. Nếu CI không có secret GPG_PRIVATE_KEY, repo vẫn publish DB không ký (Optional không chặn) — chính sách 2 lớp: TLS HTTPS + GPG.
- **Actions pin theo commit SHA** (kèm comment `# vX`), Dependabot weekly tự mở PR khi upstream tag dịch chuyển → runner không bao giờ chạy code bị thay đổi ngoài ý muốn. PR dependabot được **auto-merge khi có label `automerge`** (opt-in rõ ràng).
- **Nguồn build được pin**: `makepkg.conf`/`rust.conf` từ CachyOS `docker-makepkg` @ commit cố định; base image `cachyos/cachyos-v3` pin theo digest. Image build riêng `ghcr.io/slimulv1/arisa-build:latest` do chính repo tự build (`update-image.yml`).
- **Auto-merge của PR `aur-sync` có guard**: chỉ auto-merge khi PR chỉ đụng tới thư mục package (hoặc `packages.txt`) — `.github/`, `docker/`, README... nằm ngoài giới hạn, bị chặn kèm comment.
- **Token**: chỉ dùng `GITHUB_TOKEN` với permission tối thiểu (`contents`/`actions`/`issues`/`pull-requests` write), không lưu secret nào.

## Danh sách gói

### Gói tự maintain (`local:`)

| Gói | Mô tả |
| :-- | :-- |
| `linux-arisa` | Kernel Liquorix đổi tên — **giữ nguyên 100% patch/config/cách build** của upstream `linux-lqx` (PDS scheduler, ZEN patches), chỉ đổi tên package + localversion thành `-arisa`. Chia gói: `linux-arisa`, `linux-arisa-headers`, `linux-arisa-docs`. CI tự mở issue 🚨 khi tụt hậu upstream |
| `arisa-meta` | Meta-package: cài toàn bộ đội hình AUR của Arisa trong một lệnh |
| `ttf-ms-win11-base` | Font Windows 11 base (Segoe UI, Consolas, Cascadia...) — giữ local để cài trực tiếp |
| `ventoy` | Ventoy — tạo USB multi-boot. Packaging phức tạp (build nhiều thành phần từ source cũ: grub, edk2, ipxe...), vendor patch cục bộ nên tự maintain |
| `zalo-for-linux-bin` | Zalo client cho Linux (Unofficial, AppImage + ZaDark) — AUR source hardcode commit cũ gây 404, fix `_commithash` cục bộ nên giữ local |
| `lianli-linux-git` | Điều khiển fan/LED Lian Li (Host Controller) — cần udev rule `60-lianli.rules`, fix gtk3/webkit/npm/setuptools, pkgrel cục bộ |
| `anifetch-cli` | CLI fetch tool lấy cảm hứng từ anime — cần `python-setuptools` trong makedepends |
| `ttf-vietnamese-tcvn3` | Font tiếng Việt chuẩn TCVN 6909 (bộ `Vn*.ttf`) — nội dung đóng băng, chuyển local để không bị sync đè |
| `ttf-vietnamese-vni` | Font tiếng Việt chuẩn VNI (bộ `VNI-*.ttf`) — nội dung đóng băng, chuyển local để không bị sync đè |
| `catppuccin-fcitx5-git` | Theme Catppuccin cho fcitx5 (`*rounded` themes) — nội dung đóng băng, chuyển local để không bị sync đè |
| `qpwgraph` | Công cụ nối/điều phối luồng audio PipeWire/PulseAudio (dạng đồ thị) — đóng băng bản build ổn định để không bị sync đè |

### Gói AUR được mirror (đồng bộ tự động)

`amethyst-mod-manager`, `betterlockscreen`, `bibata-cursor-theme`, `brave-origin-bin`, `code-marketplace`, `cozette-otb`, `discord-ptb`, `evdi-dkms`, `fcitx5-lotus-git`, `hw-probe`, `libdockapp`, `light`, `localsend`, `openrgb-git`, `python-libloot`, `python-pynput`, `python-pywal16`, `python-pywalfox`, `spoofdpi`, `visual-studio-code-bin`.

> Muốn thêm gói mới? Xem [Cách thêm package thủ công](#-cách-thêm-package-thủ-công) — gói AUR chỉ tốn 1 dòng trong `packages.txt`.

## Fork cho riêng mình

1. Fork repo này, sửa `packages.txt` theo ý muốn (thêm gói AUR hoặc `local:` gói tự maintain — xem [hướng dẫn ở trên](#-cách-thêm-package-thủ-công)).
2. Đổi image build nếu cần: sửa `docker/build-image/Dockerfile` (base `cachyos/cachyos-v3` + preinstall deps) — workflow `update-image.yml` sẽ tự rebuild lên GHCR của bạn.
3. Vào **Settings → Actions → General**: bật *Read and write permissions* + *Allow GitHub Actions to create and approve pull requests*.
4. Vào **Settings → General → Pull Requests**: bật *Allow auto-merge* (bắt buộc để bot PR tự merge).
5. Chạy workflow **Build and Publish Arch Repository** (workflow_dispatch) lần đầu — release `repository` sẽ tự tạo và `pkg-hashes.txt` bootstrap.

---

*Built with 🖤 by Arisa.*