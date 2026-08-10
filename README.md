# 📦 Arisa Repository

Kho binary của **Arisa** — repo Arch Linux cá nhân, build tự động 100% bằng GitHub Actions + GitHub Releases (zero-cost, không cần VPS). Đặt theo tên của Arisa, trợ lý ảo trên máy của anh. 🖤

## Ý tưởng (fork từ my-arch-repo)

Mọi thứ điều khiển bởi `packages.txt`:

- Dòng thường → gói AUR (đồng bộ tự động từ **CachyOS-PKGBUILDS** trước, fallback **AUR**)
- `local: tên-gói` → PKGBUILD tự maintain trong repo này (không sync, không ghi đè)

Mỗi ngày 19:00 UTC, workflow `build-release.yml` quét mọi thư mục có PKGBUILD và build song song (matrix) trong container `cachyos/cachyos-v3` (x86-64-v3), sau đó publish toàn bộ lên GitHub Release với tag `repository`:

- 🟢 Gói mới build
- 🟡 Gói không đổi → tải thẳng từ release cũ (cache)
- 🔴 Build lỗi → khôi phục bản cũ từ release (fallback), không bao giờ mất gói

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

Betterlockscreen, bibata-cursor-theme, pywal stack (pywal16, pywalfox, pynput), dockapps (wmclock/wmcore/wmcpumon/wmitime/wmnet/wmnetload/wmshutdown/wmsystemtray + libdockapp), visual-studio-code-bin, cozette-otb, discord-ptb, spoofdpi, light, evdi-dkms, lianli-linux-git, fcitx5-lotus-bin, hw-probe, anifetch-cli, amethyst-mod-manager, code-marketplace, python-libloot...

## Fork cho riêng mình

1. Fork repo này, sửa `packages.txt` theo ý muốn.
2. Đổi container nếu cần: `cachyos/cachyos[-v3|-v4]` + makepkg profile từ [CachyOS/docker-makepkg](https://github.com/CachyOS/docker-makepkg).
3. Vào **Settings → Actions → General**: bật *Read and write permissions* + *Allow GitHub Actions to create and approve pull requests*.
4. Chạy workflow **Build and Publish Arch Repository** (workflow_dispatch) lần đầu — release `repository` sẽ tự tạo.

---

*Built with 🖤 by Arisa.*