#!/bin/bash

# Memeriksa apakah Go sudah terinstal
check_go() {
    if ! command -v go &> /dev/null
    then
        echo "Go belum terinstal. Silakan instal Go terlebih dahulu."
        exit 1
    fi
}

# Memeriksa apakah pip3 sudah terinstal
check_pip() {
    if ! command -v pip3 &> /dev/null
    then
        echo "pip3 belum terinstal. Instal pip3 terlebih dahulu."
        exit 1
    fi
}

# Fungsi untuk menginstal alat yang diperlukan
install_tools() {
    # Memeriksa apakah Go sudah terinstal
    check_go

    # Memeriksa apakah pip3 sudah terinstal
    check_pip

    # Menginstal alat
    echo "[+] Memulai instalasi alat..."
    bash scripts.sh
}

# Menjalankan instalasi
install_tools
