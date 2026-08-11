# 📦 Arisa Repository

Kho binary của **Arisa** — repo Arch Linux cá nhân, build tự động 100% bằng GitHub Actions + GitHub Releases (zero-cost, không cần VPS). Đặt theo tên của Arisa, trợ lý ảo trên máy của anh. 🖤

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

### 2. Build & Publish (`build-release.yml` — mỗi ngày 19:00 UTC)

Đọc danh sách từ `packages.txt`, tách `linux-arisa` (kernel) ra job riêng, build song song (matrix) trong image tùy biến `ghcr.io/slimulv1/arisa-build:latest` (base `cachyos/cachyos-v3`, preinstall sẵn toolchain, chạy x86-64-v3), sau đó publish toàn bộ lên GitHub Release tag `repository`:

- **Hash-cache thông minh**: mỗi package được hash toàn bộ thư mục source (PKGBUILD + .SRCINFO + .install + patch) qua manifest `pkg-hashes.txt` — chỉ rebuild khi source thật sự đổi, không phụ thuộc tên file `pkgver-pkgrel`
- 🟢 Gói mới build
- 🟡 Gói không đổi → tải thẳng từ release cũ (cache)
- 🔴 Build lỗi → khôi phục bản cũ từ release (fallback), không bao giờ mất gói
- **Kernel build riêng** (`linux-arisa`): job tách biệt với **ccache 5GB** — lần đầu ~3h, lần sau ~18 phút
- **Atomic publish**: upload packages trước, DB files (`arisa.db/.files` + `.tar.gz`) upload **cuối cùng** → không bao giờ tồn tại DB trỏ vào package thiếu
- **Caches được chia sẻ** giữa các run (pacman package cache + ccache), tự dọn giữ 3 bản mới nhất

### 3. Build Image (`update-image.yml`)

Khi sửa `docker/build-image/Dockerfile` → tự rebuild image `ghcr.io/slimulv1/arisa-build:latest` (deps + toolchain preinstall, cache bằng BuildKit GHA).

## Cài đặt bên máy dùng

Thêm vào `/etc/pacman.conf`:

```ini
[arisa]
SigLevel = Optional TrustAll
Server = https://github.com/slimulv1/arisa-repo/releases/download/repository
```

Rồi:

```bash
sudo pacman -Sy
sudo pacman -S arisa-meta    # cài cả đội hình AUR của Arisa
```

> ⚠️ Nhị phân build cho **x86-64-v3+** (CPU từ Intel Haswell / AMD Excavator trở lên). Repo **không ký GPG** — SigLevel TrustAll chỉ dùng được vì đây là repo cá nhân tự kiểm soát; hãy tin tưởng kết nối HTTPS tới GitHub.

## Gói tự maintain (local)

| Gói | Mô tả |
| :-- | :-- |
| `linux-arisa` | Kernel Liquorix đổi tên — **giữ nguyên 100% patch/config/cách build** của upstream `linux-lqx` (PDS scheduler, ZEN patches), chỉ đổi tên package + localversion thành `-arisa`. Chia gói: `linux-arisa`, `linux-arisa-headers`, `linux-arisa-docs` |
| `arisa-meta` | Meta-package: cài toàn bộ đội hình AUR của Arisa trong một lệnh |

## Gói AUR được mirror (theo máy của anh)

Betterlockscreen, bibata-cursor-theme, pywal stack (pywal16, pywalfox, pynput), dockapps (libdockapp + wmclock/wmcore/wmcpumon/wmitime/wmnet/wmnetload/wmshutdown/wmsystemtray), visual-studio-code-bin, cozette-otb, discord-ptb, spoofdpi, light, evdi-dkms, lianli-linux-git, fcitx5-lotus-bin, hw-probe, anifetch-cli, amethyst-mod-manager, code-marketplace, python-libloot.

## Fork cho riêng mình

1. Fork repo này, sửa `packages.txt` theo ý muốn (thêm gói AUR hoặc `local:` gói tự maintain).
2. Đổi image build nếu cần: sửa `docker/build-image/Dockerfile` (base `cachyos/cachyos-v3` + preinstall deps) — workflow `update-image.yml` sẽ tự rebuild lên GHCR của bạn.
3. Vào **Settings → Actions → General**: bật *Read and write permissions* + *Allow GitHub Actions to create and approve pull requests*.
4. Chạy workflow **Build and Publish Arch Repository** (workflow_dispatch) lần đầu — release `repository` sẽ tự tạo và `pkg-hashes.txt` bootstrap.

---

*Built with 🖤 by Arisa.*
