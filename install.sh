#!/bin/sh
set -eu

# Paths
INSTALL_BIN="/usr/local/bin/macalter"
INSTALL_CONF="/etc/macalter.conf"
INSTALL_PREFIXES="/usr/local/share/macalter/prefixes.txt"

detect_init() {
    # Detect systemd
    if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
        echo "systemd"
        return
    fi

    # Detect runit by checking PID 1
    pid1=$(ps -p 1 -o comm=)
    if [ "$pid1" = "runit" ]; then
        echo "runit"
        return
    fi

    # Detect OpenRC
    if command -v rc-status >/dev/null 2>&1; then
        echo "openrc"
        return
    fi

    echo "unknown"
}

install_systemd() {
    echo "Installing for systemd..."

    mkdir -p /usr/local/share/macalter
    install -m 0644 "prefixes.txt" "$INSTALL_PREFIXES"
    install -m 0755 "bin/macalter" "$INSTALL_BIN"

    if [ ! -f "$INSTALL_CONF" ]; then
        cp etc/macalter.conf.example "$INSTALL_CONF"
        echo "Installed default config to $INSTALL_CONF"
    fi

    install -m 0644 "init/systemd.service" /etc/systemd/system/macalter.service
    systemctl daemon-reload
    systemctl enable macalter.service
    systemctl start macalter.service

    echo "Installation complete. macalter enabled as systemd service."
}

install_runit() {
    echo "Installing for runit..."

    mkdir -p /usr/local/share/macalter
    install -m 0644 "prefixes.txt" "$INSTALL_PREFIXES"
    install -m 0755 "bin/macalter" "$INSTALL_BIN"

    if [ ! -f "$INSTALL_CONF" ]; then
        cp etc/macalter.conf.example "$INSTALL_CONF"
        echo "Installed default config to $INSTALL_CONF"
    fi

    mkdir -p /etc/sv/macalter
    install -m 0755 "init/runit" /etc/sv/macalter/run

    echo ""
    echo "IMPORTANT:"
    echo "Your runit service supervision directory (e.g. /etc/sv, /service, /var/service, or custom) was not auto-detected."
    echo "You must manually create a symlink from /etc/sv/macalter to your runit service supervision directory."
    echo "Example:"
    echo "  ln -s /etc/sv/macalter /path/to/your/runit/service/dir/"
    echo ""
    echo "After that, runit will start managing macalter automatically."
    echo ""
    echo "Installation complete. macalter installed for runit."
}

install_openrc() {
    echo "Installing for OpenRC..."

    mkdir -p /usr/local/share/macalter
    install -m 0644 "prefixes.txt" "$INSTALL_PREFIXES"
    install -m 0755 "bin/macalter" "$INSTALL_BIN"

    if [ ! -f "$INSTALL_CONF" ]; then
        cp etc/macalter.conf.example "$INSTALL_CONF"
        echo "Installed default config to $INSTALL_CONF"
    fi

    install -m 0755 "init/openrc" /etc/init.d/macalter
    rc-update add macalter default
    /etc/init.d/macalter start

    echo "Installation complete. macalter enabled as OpenRC service."
}

main() {
    if [ "$(id -u)" != "0" ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi

    init_system=$(detect_init)
    echo "Detected init system: $init_system"

    case "$init_system" in
        systemd)
            install_systemd
            ;;
        runit)
            install_runit
            ;;
        openrc)
            install_openrc
            ;;
        *)
            echo "Unsupported or unknown init system: $init_system"
            echo "Please install manually."
            exit 1
            ;;
    esac
}

main "$@"

