# Arisa Repository

Kho binary Arch Linux cá nhân — build 100% tự động bằng GitHub Actions + GitHub Releases (zero-cost, không cần VPS).

<div align="center">

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)](https://archlinux.org)
[![pacman install](https://img.shields.io/badge/pacman-arisa-7b2ff7?style=for-the-badge&logo=archlinux&logoColor=white)](https://wiki.archlinux.org/title/Unofficial_user_repositories)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)

[![Build packages](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/build-packages.yml?branch=main&label=Build%20packages&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/build-packages.yml)
[![Build kernel](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/build-kernel.yml?branch=main&label=Build%20kernel&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/build-kernel.yml)
[![Sync AUR](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/sync-aur.yml?branch=main&label=Sync%20AUR&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/sync-aur.yml)
[![Build Docker image](https://img.shields.io/github/actions/workflow/status/slimulv1/arisa-repo/update-image.yml?branch=main&label=Build%20Docker%20image&style=flat-square)](https://github.com/slimulv1/arisa-repo/actions/workflows/update-image.yml)

[![License](https://img.shields.io/github/license/slimulv1/arisa-repo?style=flat)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/slimulv1/arisa-repo?style=flat)](https://github.com/slimulv1/arisa-repo/commits/main)
[![Commit activity](https://img.shields.io/github/commit-activity/m/slimulv1/arisa-repo?style=flat)](https://github.com/slimulv1/arisa-repo/commits/main)
[![Last publish](https://img.shields.io/github/release-date/slimulv1/arisa-repo?style=flat)](https://github.com/slimulv1/arisa-repo/releases)

</div>

## Nội dung

- [Cài đặt](#cài-đặt)
- [Sử dụng hàng ngày](#sử-dụng-hàng-ngày)
- [Xác minh chữ ký GPG](#xác-minh-chữ-ký-gpg)
- [Nguyên lý hoạt động](#nguyên-lý-hoạt-động)
- [Thêm package](#thêm-package)
- [Kiến trúc CI/CD](#kiến-trúc-cicd)
- [Bảo mật](#bảo-mật)
- [Danh sách package](#danh-sách-package)
- [Fork cho riêng mình](#fork-cho-riêng-mình)
- [Nguồn gốc](#nguồn-gốc)

---

## Cài đặt

**Yêu cầu:** Arch / CachyOS / EndeavourOS, CPU hỗ trợ **x86-64-v3** (Intel Haswell trở lên, AMD Excavator trở lên). Kiểm tra:

```bash
grep -o 'x86-64-v[0-9]' /proc/cpuinfo | sort -u
```

**Bước 1 — Thêm repository** vào cuối `/etc/pacman.conf`:

```ini
[arisa]
SigLevel = Optional DatabaseOptional
Server = https://github.com/slimulv1/arisa-repo/releases/download/repository
```

Hoặc dùng lệnh:

```bash
sudo tee -a /etc/pacman.conf <<'EOF'

[arisa]
SigLevel = Optional DatabaseOptional
Server = https://github.com/slimulv1/arisa-repo/releases/download/repository
EOF
```

**Bước 2 — Đồng bộ và cài:**

```bash
sudo pacman -Sy
sudo pacman -S arisa-meta        # toàn bộ đội hình
sudo pacman -S <tên-gói>         # hoặc gói riêng lẻ
```

## Sử dụng hàng ngày

| Việc                    | Lệnh                          | Ghi chú                                        |
| ----------------------- | ----------------------------- | ---------------------------------------------- |
| Tìm gói                 | `pacman -Ss arisa` / `pacman -Sl arisa` |                                        |
| Cập nhật                | `pacman -Syu`                 | Kho publish ~19:00 UTC = 02:00 sáng hôm sau giờ VN; kernel 02:00 UTC = 09:00 giờ VN |
| Gỡ cài                  | `pacman -Rns <tên-gói>`       |                                                |
| Ngừng dùng              | Xóa block `[arisa]`, rồi `pacman -Sy` |                                        |

## Xác minh chữ ký GPG

DB kho được ký bằng key riêng (xem [Bảo mật](#bảo-mật)). Xác minh một lần:

```bash
curl -LO https://github.com/slimulv1/arisa-repo/releases/download/repository/arisa.gpg
sudo pacman-key --add arisa.gpg
sudo pacman-key --lsign-key BD8284BAEE6197CF2EC59839A3C506C20357176E
```

Muốn bắt buộc kiểm tra chữ ký, đổi `SigLevel = Required DatabaseOptional` trong block `[arisa]`.

## Nguyên lý hoạt động

Mọi thứ điều khiển bởi một file duy nhất — **`packages.txt`** (single source of truth):

| Dòng trong `packages.txt` | Ý nghĩa                          | Nguồn                              |
| -------------------------- | -------------------------------- | ---------------------------------- |
| `tên-gói`                  | Gói AUR (mirror)                 | CachyOS-PKGBUILDS → fallback AUR    |
| `local: tên-gói`           | PKGBUILD tự maintain (không sync) | Thư mục tương ứng trong repo       |

Chuỗi vận hành **hoàn toàn tự động**: sửa `packages.txt` → sync → PR → auto-merge → build → publish lên GitHub Release (`tag: repository`).

## Thêm package

### Cách 1 — Gói AUR (không cần viết PKGBUILD)

```bash
echo "my-new-aur-pkg" >> packages.txt
git add packages.txt && git commit -m "add: my-new-aur-pkg" && git push
```

CI tự xử lý phần còn lại: `sync-aur.yml` (mỗi giờ) tìm nguồn → PR `aur-sync` → auto-merge → build → publish. Package có thể cài sau **30–60 phút**.

Lưu ý:

- Tên phải khớp chính xác `pkgbase` trên AUR (phân biệt hoa thường, giữ hậu tố `-git`/`-bin`).
- Không tìm thấy nguồn → PR body báo 🔴 **Failed**.
- Xóa gói: bỏ dòng trong `packages.txt` → CI tự dọn.

### Cách 2 — Package local (tự maintain PKGBUILD)

```bash
mkdir -p my-tool && cd my-tool
# viết PKGBUILD (tham khảo các gói local hiện có làm mẫu)
makepkg --printsrcinfo > .SRCINFO
echo "local: my-tool" >> ../packages.txt
```

Quy tắc vàng:

- Tên thư mục = dòng trong `packages.txt`, **không kèm version**.
- Build được trong container CachyOS x86-64-v3 (nghi ngờ → test bằng `makepkg` cục bộ).
- Makedepends lạ → thêm vào `docker/build-image/Dockerfile` (`update-image.yml` tự rebuild image).
- Sửa PKGBUILD nhớ in lại `.SRCINFO` — giữ hash-cache ổn định.
- Kernel `linux-arisa` là case đặc biệt: build riêng ở `build-kernel.yml`, dùng ccache, tự bump version `linux-lqx` qua PR.

## Kiến trúc CI/CD

```
packages.txt
    │
    ├─ sync-aur.yml (mỗi giờ :07)     → PR aur-sync → auto-merge
    │
    ├─ build-packages.yml (19:00 UTC) → matrix build AUR + local → publish
    │
    ├─ build-kernel.yml  (02:00 UTC)  → linux-arisa (ccache, auto-bump) → publish
    │
    └─ update-image.yml  (03:00 UTC)  → rebuild image build → smoke-test → promote → pin digest
```

**`build-packages.yml` / `build-kernel.yml`**

- Chạy trong image `ghcr.io/slimulv1/arisa-build` — preinstall toàn bộ toolchain, tối ưu **x86-64-v3**; workflow **pin theo digest bất biến** (không dùng `:latest`).
- **Hash-cache**: hash toàn bộ thư mục source (PKGBUILD + `.SRCINFO` + `.install` + patch) → manifest `pkg-hashes.txt`; source không đổi thì tải binary cũ từ release, không rebuild lại.
  - 🟢 source đổi → build mới
  - 🟡 source giữ nguyên → tải từ release (cache)
  - 🔴 build lỗi → fallback giữ bản cũ trong repo
- **Kernel**: ccache 5 GB (lần đầu ~3 h, các lần sau ~18 phút); tự so sánh version upstream `linux-lqx`, bump PKGBUILD → PR → auto-merge → rebuild; không bump được → mở issue 🚨.
- **Publish atomic**: upload packages trước, upload DB (`arisa.db`/`.files` + `.tar.gz`) **cuối cùng**; cache được dọn giữ 3 pacman + 2 kernel mới nhất (< 10 GB).

**`update-image.yml`**

- Rebuild image khi sửa `Dockerfile` / `makepkg.conf` / `rust.conf` (push main) + lịch hàng ngày.
- Bản build mới phải qua **smoke-test** (paru/makepkg hoạt động, config bake đúng, `pacman -Syu` sạch) trước khi promote thành `:latest`.
- Tự mở PR pin digest mới vào 3 workflow tiêu thụ → auto-merge.
- Base `cachyos/cachyos-v3` pin theo digest; digest mới xuất hiện upstream → tự mở PR bump → rebuild trên base mới.

## Bảo mật

- **Chữ ký GPG**: `SigLevel = Optional DatabaseOptional` — DB ký bằng key riêng (fingerprint `BD8284BAEE6197CF2EC59839A3C506C20357176E`, public key `arisa.gpg` đính kèm release). Không có secret `GPG_PRIVATE_KEY` → DB publish không ký (không chặn cài). Chính sách 2 lớp: TLS HTTPS + GPG.
- **Actions pin theo commit SHA** (kèm comment `# vX`); Dependabot tự mở PR khi upstream tag dịch chuyển — runner không bao giờ chạy code bị đổi ngoài ý muốn.
- **Nguồn build được pin**: `makepkg.conf`/`rust.conf` từ CachyOS `docker-makepkg` @ commit cố định, **bake vào image lúc build** (không tải runtime mỗi job); image tiêu thụ **pin theo digest bất biến** — `:latest` chỉ được promote sau khi smoke-test đạt.
- **Auto-merge có guard**: PR `aur-sync` chỉ được tự merge khi chỉ đụng thư mục package (hoặc `packages.txt`) — `.github/`, `docker/`, README... nằm ngoài phạm vi.
- **Token**: workflow dùng `GITHUB_TOKEN` với permission tối thiểu; riêng job `pin-digest` (đẩy file `.github/workflows/`) dùng **`ARISA_BOT_TOKEN`** (PAT fine-grained: Contents / Workflows / Pull requests write — GITHUB_TOKEN không thể đẩy file workflow). Secrets repo: `ARISA_BOT_TOKEN`, `GPG_PRIVATE_KEY`.

## Danh sách package

**Local — tự maintain (11):**

| Package               | Mô tả                                                        |
| --------------------- | ------------------------------------------------------------ |
| `linux-arisa`         | Kernel Liquorix (giữ 100% patch/config upstream `linux-lqx`, PDS scheduler, ZEN patches, localversion `-arisa`; gói `-headers`/`-docs`) |
| `arisa-meta`          | Meta-package: cài toàn bộ đội hình                          |
| `ttf-ms-win11-base`   | Font Windows 11 (Segoe UI, Consolas, Cascadia)               |
| `ventoy`              | USB multi-boot (packaging grub/edk2/ipxe, vendor patch)      |
| `zalo-for-linux-bin`  | Zalo client (Unofficial AppImage + ZaDark)                   |
| `lianli-linux-git`    | Fan/LED Lian Li Host Controller (udev rule, fix gtk3/webkit/npm/setuptools) |
| `anifetch-cli`        | CLI fetch anime-inspired                                     |
| `ttf-vietnamese-tcvn3`| Font tiếng Việt TCVN 6909 (`Vn*.ttf`, đóng băng)             |
| `ttf-vietnamese-vni`  | Font tiếng Việt VNI (`VNI-*.ttf`, đóng băng)                 |
| `catppuccin-fcitx5-git` | Theme Catppuccin cho fcitx5 (`*rounded`, đóng băng)        |
| `qpwgraph`            | Nối/điều phối luồng audio PipeWire (đóng băng)               |

**AUR — mirror tự động (20):**

`amethyst-mod-manager`, `betterlockscreen`, `bibata-cursor-theme`, `brave-origin-bin`, `code-marketplace`, `cozette-otb`, `discord-ptb`, `evdi-dkms`, `fcitx5-lotus-git`, `hw-probe`, `libdockapp`, `light`, `localsend`, `openrgb-git`, `python-libloot`, `python-pynput`, `python-pywal16`, `python-pywalfox`, `spoofdpi`, `visual-studio-code-bin`

## Fork cho riêng mình

1. **Fork repo**, sửa `packages.txt` theo ý muốn.
2. (Tùy chọn) Tùy biến image build: `docker/build-image/Dockerfile`, `makepkg.conf`, `rust.conf` — `update-image.yml` tự rebuild lên GHCR của bạn.
3. **Settings → Actions → General**: bật *Read and write permissions* + *Allow GitHub Actions to create and approve pull requests*.
4. **Settings → General → Pull Requests**: bật *Allow auto-merge*.
5. Tạo secret **`ARISA_BOT_TOKEN`** (fine-grained PAT: Contents / Workflows / Pull requests write) — bắt buộc cho job pin digest.
6. Chạy workflow **Build and Publish Arch Repository** (workflow_dispatch) lần đầu — release `repository` tự tạo kèm `pkg-hashes.txt` bootstrap.

## Nguồn gốc

Repo này được **fork từ** [my-arch-repo](https://github.com/nhktmdzhg/my-arch-repo) của [Nguyễn Hoàng Kỳ](https://github.com/nhktmdzhg) — ý tưởng gốc về kho binary Arch Linux xây dựng hoàn toàn trên GitHub Actions + GitHub Releases (MIT License).

---

*Built with 🖤 by Arisa.*