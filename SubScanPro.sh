#!/bin/bash
# SubScanPro – Subdomain Recon Toolkit
# Author: Reshav Ji

set -euo pipefail
IFS=$'\n\t'

########################################
# Colour helpers
C_CYAN="\e[1;36m"; C_RESET="\e[0m"

########################################
# Banner             (no quoting issues)
printf "${C_CYAN}\n"
cat <<'EOF'
  ____        _       ____                    ____            
 / ___| _   _| |__   / ___|  ___ __ _ _ __   |  _ \ _ __ ___  
 \___ \| | | | '_ \  \___ \ / __/ _` | '_ \  | |_) | '__/ _ \ 
  ___) | |_| | |_) |  ___) | (_| (_| | | | | |  __/| | | (_) |
 |____/ \__,_|_.__/  |____/ \___\__,_|_| |_| |_|   |_|  \___/ 

                 SubScanPro  •  by Reshav Ji
EOF
printf "${C_RESET}\n"

########################################
# Spinner
spinner() {
  local pid=$1
  local spin='-\|/'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r[%c] Working..." "${spin:$i:1}"
    sleep 0.2
  done
  printf "\r                     \r"
}

########################################
# Require a tool
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[!] $1 not found. Install it and re-run."
    exit 1
  }
}

# Check required tools
for t in assetfinder subfinder findomain curl jq httpx dnsx; do
  need "$t"
done

########################################
# Get domain
if [[ $# -ge 1 && -n "$1" ]]; then
  domain="$1"
else
  read -rp "Enter target domain: " domain
  [[ -z "$domain" ]] && { echo "No domain supplied. Exiting."; exit 1; }
fi

########################################
# File setup
output_dir="recon_${domain}"
mkdir -p "$output_dir"

af_file="$output_dir/assetfinder.txt"
sf_file="$output_dir/subfinder.txt"
fd_file="$output_dir/findomain.txt"
crt_file="$output_dir/crtsh.txt"
all_file="$output_dir/all_subdomains.txt"
live_file="$output_dir/live_hosts.txt"
dns_file="$output_dir/resolved_hosts.txt"

########################################
echo -e "\n[+] Enumerating subdomains for ${C_CYAN}${domain}${C_RESET}"

# -------- Assetfinder --------
echo -n "[*] Assetfinder running..."
( assetfinder --subs-only "$domain" | sort -u > "$af_file" ) & spinner $!
af_count=$(wc -l < "$af_file")
echo "[✔] Found $af_count"

# -------- Subfinder ----------
echo -n "[*] Subfinder running..."
( subfinder -d "$domain" -exclude-sources digitorus -silent | sort -u > "$sf_file" ) & spinner $!
sf_count=$(wc -l < "$sf_file")
echo "[✔] Found $sf_count"

# -------- Findomain ----------
echo -n "[*] Findomain running..."
( findomain -t "$domain" -q | sort -u > "$fd_file" ) & spinner $!
fd_count=$(wc -l < "$fd_file")
echo "[✔] Found $fd_count"

# -------- crt.sh -------------
echo -n "[*] Fetching crt.sh data..."
( curl -s "https://crt.sh/?q=%25.$domain&output=json" \
    | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > "$crt_file" ) & spinner $!
crt_count=$(wc -l < "$crt_file")
echo "[✔] Found $crt_count"

# -------- Combine & dedup ----
echo -n "[*] Combining and deduplicating..."
( cat "$af_file" "$sf_file" "$fd_file" "$crt_file" | sort -u > "$all_file" ) & spinner $!
all_count=$(wc -l < "$all_file")
overlap_count=$((af_count + sf_count + fd_count + crt_count - all_count))
echo "[✔] Unique subdomains: $all_count (overlap: $overlap_count)"

########################################
# Live host probing
echo -n "[*] Probing live hosts with httpx..."
( httpx -l "$all_file" --status-code --title --follow-redirects --timeout 10 -silent > "$live_file" ) & spinner $!
live_count=$(wc -l < "$live_file")
echo "[✔] Live hosts: $live_count"

# DNS resolution
echo -n "[*] Checking DNS resolution with dnsx..."
( dnsx -l "$all_file" -a -cname -silent | cut -d' ' -f1 | sort -u > "$dns_file" ) & spinner $!
dns_count=$(wc -l < "$dns_file")
echo "[✔] DNS-resolved hosts: $dns_count"

########################################
# Summary
echo -e "\n${C_CYAN}===== SubScanPro Summary for $domain =====${C_RESET}"

printf "\n${C_CYAN}→ Tool-wise Subdomain Results:${C_RESET}\n"
printf "• Assetfinder  →  %s subdomains\n" "$af_count"
printf "• Subfinder    →  %s subdomains\n" "$sf_count"
printf "• Findomain    →  %s subdomains\n" "$fd_count"
printf "• crt.sh       →  %s subdomains\n" "$crt_count"

echo -e "\n${C_CYAN}→ Combined Stats:${C_RESET}"
printf "• Overlap between tools     : %s\n" "$overlap_count"
printf "• TOTAL unique subdomains   : %s\n" "$all_count"
printf "• LIVE hosts (httpx)        : %s\n" "$live_count"
printf "• DNS-resolved hosts (dnsx) : %s\n" "$dns_count"

echo -e "\n${C_CYAN}→ Output directory:${C_RESET} $output_dir\n"

