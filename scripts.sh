#!/bin/bash

# Fungsi untuk memeriksa apakah alat sudah terinstal
check_tool() {
    if ! command -v $1 &> /dev/null
    then
        return 1  # Alat belum terinstal
    else
        return 0  # Alat sudah terinstal
    fi
}

# Fungsi untuk menginstal Subfinder
install_subfinder() {
    echo "[+] Memasang Subfinder"
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    sudo mv $HOME/go/bin/subfinder /usr/bin/subfinder
}

# Fungsi untuk menginstal ParamSpider
install_paramspider() {
    echo "[+] Memasang ParamSpider"
    git clone https://github.com/devanshbatham/ParamSpider.git
    cd ParamSpider
    if [ ! -f "requirements.txt" ]; then
        echo "File requirements.txt tidak ditemukan. Pastikan Anda memiliki file tersebut."
        exit 1
    fi
    pip3 install -r requirements.txt
    # Pindahkan paramspider.py ke /usr/bin/
    sudo mv paramspider.py /usr/bin/paramspider
    cd ..
    rm -rf ParamSpider
}

# Fungsi untuk menginstal httpx
install_httpx() {
    echo "[+] Memasang httpx"
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    sudo mv $HOME/go/bin/httpx /usr/bin/httpx
}

# Fungsi untuk menginstal Nuclei
install_nuclei() {
    echo "[+] Memasang Nuclei"
    go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    sudo mv $HOME/go/bin/nuclei /usr/bin/nuclei
}

# Fungsi untuk menginstal uro
install_uro() {
    echo "[+] Memasang uro"
    go install github.com/robertdavidgraham/uro@latest
    sudo mv $HOME/go/bin/uro /usr/bin/uro
}

# Memeriksa apakah Subfinder sudah terinstal, jika tidak pasang
check_tool subfinder
if [ $? -ne 0 ]; then
    install_subfinder
else
    echo "[+] Subfinder sudah terinstal."
fi

# Memeriksa apakah ParamSpider sudah terinstal, jika tidak pasang
check_tool paramspider
if [ $? -ne 0 ]; then
    install_paramspider
else
    echo "[+] ParamSpider sudah terinstal."
fi

# Memeriksa apakah httpx sudah terinstal, jika tidak pasang
check_tool httpx
if [ $? -ne 0 ]; then
    install_httpx
else
    echo "[+] httpx sudah terinstal."
fi

# Memeriksa apakah Nuclei sudah terinstal, jika tidak pasang
check_tool nuclei
if [ $? -ne 0 ]; then
    install_nuclei
else
    echo "[+] Nuclei sudah terinstal."
fi

# Memeriksa apakah uro sudah terinstal, jika tidak pasang
check_tool uro
if [ $? -ne 0 ]; then
    install_uro
else
    echo "[+] uro sudah terinstal."
fi

# Pengecekan argumen yang diberikan
while getopts "d:o:h" opt; do
    case $opt in
        d) domain=$OPTARG ;;
        o) output_dir=$OPTARG ;;
        h) echo "Usage: $0 [-d domain] [-o output_dir] [-h]"
           exit 0 ;;
        *) echo "Invalid option. Use -h for help."
           exit 1 ;;
    esac
done

# Cek apakah domain sudah diberikan
if [ -z "$domain" ]; then
    echo "Domain harus diberikan dengan opsi -d."
    exit 1
fi

# Tentukan direktori output jika tidak diberikan
if [ -z "$output_dir" ]; then
    output_dir="output"
fi

# Step 1: Gunakan Subfinder untuk menemukan subdomain
echo "[+] Menemukan subdomain dengan Subfinder"
subfinder -d $domain -o "$output_dir/$domain-subdomains.txt"

# Step 2: Gunakan ParamSpider untuk menemukan URL parameter
echo "[+] Menemukan URL parameter dengan ParamSpider"
python3 /usr/bin/paramspider --domain $domain --output "$output_dir/$domain-params.txt"

# Step 3: Memeriksa apakah URL ditemukan atau tidak
if [ ! -s "$output_dir/$domain-subdomains.txt" ]; then
    echo "Tidak ada subdomain ditemukan untuk domain $domain. Keluar..."
    exit 1
elif [ ! -s "$output_dir/$domain-params.txt" ]; then
    echo "Tidak ada URL ditemukan untuk domain $domain. Keluar..."
    exit 1
fi

# Step 4: Menjalankan Nuclei pada URL yang dikumpulkan
echo "[+] Menjalankan Nuclei pada URL yang ditemukan"
temp_file=$(mktemp)
sort "$output_dir/$domain-subdomains.txt" | uro > "$temp_file"
httpx -silent -mc 200,301,302,403 -l "$temp_file" | nuclei -t /usr/share/nuclei-templates/ -dast -rl 05

# Bersihkan file sementara
rm "$temp_file"

echo "[+] Proses selesai."
