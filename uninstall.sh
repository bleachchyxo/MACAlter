#!/bin/sh
set -eu

BIN="/usr/local/bin/macalter"
CONF="/etc/macalter.conf"
PREFIXES="/usr/local/share/macalter/prefixes.txt"

detect_init() {
    if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
        echo "systemd"
        return
    fi

    pid1=$(ps -p 1 -o comm=)
    if [ "$pid1" = "runit" ]; then
        echo "runit"
        return
    fi

    if command -v rc-status >/dev/null 2>&1; then
        echo "openrc"
        return
    fi

    echo "unknown"
}

uninstall_systemd() {
    echo "Uninstalling systemd service..."
    systemctl stop macalter.service || true
    systemctl disable macalter.service || true
    rm -f /etc/systemd/system/macalter.service
    systemctl daemon-reload
    echo "Systemd service removed."
}

uninstall_runit() {
    echo "Uninstalling runit service..."
    if [ -d /etc/sv/macalter ]; then
        sv down macalter 2>/dev/null || true
        rm -rf /etc/sv/macalter
        echo "Removed /etc/sv/macalter"
    fi

    # Remove symlink only if we can find it
    for dir in /service /var/service /run/service; do
        if [ -L "$dir/macalter" ]; then
            rm -f "$dir/macalter"
            echo "Removed symlink: $dir/macalter"
        fi
    done

    echo "If your runit uses a custom supervision dir, remove the symlink manually."
}

uninstall_openrc() {
    echo "Uninstalling OpenRC service..."
    rc-service macalter stop || true
    rc-update del macalter default || true
    rm -f /etc/init.d/macalter
    echo "OpenRC service removed."
}

cleanup_files() {
    echo "Removing installed files..."
    rm -f "$BIN"
    rm -f "$PREFIXES"
    rm -f "$CONF"
    echo "Removed: $BIN, $PREFIXES, $CONF"
}

main() {
    if [ "$(id -u)" != "0" ]; then
        echo "Please run this script as root or with sudo."
        exit 1
    fi

    init_system=$(detect_init)
    echo "Detected init system: $init_system"

    case "$init_system" in
        systemd)
            uninstall_systemd
            ;;
        runit)
            uninstall_runit
            ;;
        openrc)
            uninstall_openrc
            ;;
        *)
            echo "Unknown init system. Skipping service removal."
            ;;
    esac

    cleanup_files
    echo "Uninstall complete."
}

main "$@"

