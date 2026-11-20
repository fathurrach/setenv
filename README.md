# 🚀 setenv — Cross-Platform Tmux & Starship Dotfiles

Konfigurasi lingkungan terminal modern yang portabel dan konsisten untuk workstation lokal (macOS) dan multi-server remote (Linux). Didesain dengan tema **Catppuccin Macchiato** dan **Nerd Fonts**.

---

## ✨ Fitur Utama

- **Tmux 3.x+:**
  - **Center Window Tabs**: Tab window list diposisikan rapi di tengah status bar (*rounded pill style*).
  - **Status Left**: Hostname mesin (`󰒋`), direktori aktif saat ini (``), dan durasi uptime sistem tanpa menit (`󰔟`).
  - **Status Right (Resource Monitor)**: Penggunaan CPU % + level bar (``), Memory digunakan/total + level bar (`󰍛`), dan Disk Storage digunakan/total + level bar (`󰋊`).
  - **Background Caching**: Pengambilan resource berjalan di background sehingga status bar tidak pernah lag/freeze.
  - **Nested Remote SSH Ready**: Prefix `Ctrl + a` (tekan `Ctrl+a` lalu `a` untuk mengirim prefix ke tmux di remote server).
  - **TPM & Plugins**: Dilengkapi `tmux-yank`, `tmux-resurrect`, `tmux-continuum`, dan `catppuccin/tmux#v2.1.2`.
- **Starship Prompt:**
  - Tema elegan **Catppuccin Macchiato**.
  - Deteksi OS/Distro otomatis, status Git informatif, runtime versioning (Node.js, Go, Rust, Python, Docker), execution timer, dan status exit code.
- **One-Command Setup:**
  - Setup otomatis dan instalasi plugin tanpa perlu konfigurasi manual.
- **Auto Update:**
  - Dilengkapi perintah `setenv-update` untuk sinkronisasi pembaruan dari GitHub di semua server.

---

## ⚡ Instalasi Cepat (1-Line Installer)

Jalankan perintah ini di server baru atau mesin yang ingin dikonfigurasi:

```bash
curl -fsSL https://raw.githubusercontent.com/fathurrach/setenv/main/install.sh | bash
```

Setelah instalasi selesai, cukup muat ulang shell Anda:
```bash
source ~/.bashrc  # atau source ~/.zshrc
tmux
```

---

## 🛠️ Instalasi Manual

Jika Anda lebih suka mengkloning repositori secara manual:

```bash
git clone https://github.com/fathurrach/setenv.git ~/.setenv
cd ~/.setenv
chmod +x setup.sh install.sh tmux/scripts/resource_info.sh
./setup.sh
```

---

## 🔄 Memperbarui Konfigurasi di Remote Server

Kapan pun Anda melakukan perubahan dan push ke repository ini, jalankan perintah ini di server mana pun:

```bash
setenv-update
```
Perintah ini akan otomatis melakukan `git pull`, memperbarui symlink, dan me-reload sesi Tmux yang aktif.

---

## 📁 Struktur Repositori

```
setenv/
├── install.sh                  # Bootstrap 1-baris untuk remote server
├── setup.sh                    # Engine symlink, TPM plugin installer, & shell injection
├── tmux/
│   ├── tmux.conf               # Konfigurasi Tmux (Catppuccin Macchiato + Center Tabs)
│   └── scripts/
│       └── resource_info.sh    # Script cross-platform resource monitor (CPU, RAM, Disk, Uptime)
├── starship/
│   └── starship.toml           # Prompt Starship tema Catppuccin Macchiato
├── shell/
│   └── env.sh                  # Shell integration & alias setenv-update
└── README.md
```

---

## 📄 Lisensi
MIT License © [Muhammad Fathurrachman](https://github.com/fathurrach)
