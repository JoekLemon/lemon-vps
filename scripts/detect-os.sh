#!/bin/bash
: '
Title:          OS Detection Script
Description:    Detects the operating system and package manager.
Author:         Joek Lemon
Contributors:
Notes:          Supports apt, dnf, and yum package managers.
'

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
    else
        echo "❌ Cannot detect OS — /etc/os-release not found"
        exit 1
    fi

    case "$OS_ID" in
        debian|ubuntu|linuxmint|pop)
            PKG_MANAGER="apt"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            ;;
        centos|rhel|rocky|almalinux|ol)
            PKG_MANAGER="yum"
            ;;
        *)
            echo "❌ Unsupported OS: $OS_ID"
            echo "   Supported: Debian, Ubuntu, Fedora, AlmaLinux, Rocky Linux"
            exit 1
            ;;
    esac

    echo "📦 Detected: $OS_NAME (using $PKG_MANAGER)"
}

pkg_install() {
    echo "   Installing: $*"
    case "$PKG_MANAGER" in
        apt)
            apt update --quiet
            apt install --yes --quiet "$@"
            ;;
        dnf)
            dnf install --yes "$@"
            ;;
        yum)
            yum install --yes "$@"
            ;;
    esac
}

pkg_update() {
    echo "   Updating package lists..."
    case "$PKG_MANAGER" in
        apt)
            apt update --quiet
            ;;
        dnf)
            dnf check-update --quiet || true
            ;;
        yum)
            yum check-update --quiet || true
            ;;
    esac
}
