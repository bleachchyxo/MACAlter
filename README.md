# MACAlter

**MACAlter** is a lightweight, dependency-free MAC address spoofer that runs on any Linux distribution and works with all init systems — including systemd, runit, and OpenRC.

## ✨ Features

- Spoof your MAC address at boot
- Use real vendor prefixes (Apple, Nokia, etc.)
- No dependencies — pure POSIX shell
- Works on Arch, Debian, Alpine, Void, and more

## 🛠 Usage

```bash
macspoof gen apple     # Generate Apple-like MAC
macspoof set 00:11:22:33:44:55
macspoof real          # Show real MAC address

