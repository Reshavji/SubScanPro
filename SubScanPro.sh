#!/bin/bash
# Recon Script: Assetfinder + Subfinder + Findomain + crt.sh + httpx + dnsx
# Usage: ./recon.sh [example.com]

set -euo pipefail
IFS=$'\n\t'

domain="${1:-panteracapital.com}"
output_dir="recon_${domain}"
mkdir -p "$output_dir"

all_file="$output_dir/all_subdomains.txt"
af_file="$output_dir/assetfinder.txt"
sf_file="$output_dir/subfinder.txt"
fd_file="$output_dir/findomain.txt"
crt_file="$output_dir/crtsh.txt"
live_file="$output_dir/live_hosts.txt"
dns_file="$output_dir/resolved_hosts.txt"

# ---------- Subdomain Enumeration ----------
echo "[*] Enumerating subdomains for $domain …"

assetfinder --subs-only "$domain" | sort -u > "$af_file"
af_count=$(wc -l < "$af_file")

subfinder -d "$domain" -exclude-sources digitorus -silent | sort -u > "$sf_file"
sf_count=$(wc -l < "$sf_file")

findomain -t "$domain" -q | sort -u > "$fd_file"
fd_count=$(wc -l < "$fd_file")

curl -s "https://crt.sh/?q=%25.$domain&output=json" \
    | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > "$crt_file"
crt_count=$(wc -l < "$crt_file")

# Combine & deduplicate
cat "$af_file" "$sf_file" "$fd_file" "$crt_file" | sort -u > "$all_file"
all_count=$(wc -l < "$all_file")
overlap_count=$((af_count + sf_count + fd_count + crt_count - all_count))

# ---------- Live Host Probing ----------
echo "[*] Probing live hosts with httpx …"
httpx -l "$all_file" --status-code --title --follow-redirects --timeout 10 -no-color > "$live_file"
live_count=$(wc -l < "$live_file")

# ---------- DNS Resolution ----------
echo "[*] Checking DNS resolution with dnsx …"
dnsx -l "$all_file" -a -cname -silent | cut -d' ' -f1 | sort -u > "$dns_file"
dns_count=$(wc -l < "$dns_file")

# ---------- Summary ----------
echo
echo "===== Recon Summary for $domain ====="
printf "• Assetfinder unique hosts : %s\n" "$af_count"
printf "• Subfinder  unique hosts : %s\n" "$sf_count"
printf "• Findomain  unique hosts : %s\n" "$fd_count"
printf "• crt.sh     cert entries : %s\n" "$crt_count"
printf "• Overlap between tools   : %s\n" "$overlap_count"
printf "• TOTAL unique sub-domains: %s\n" "$all_count"
printf "• LIVE hosts (httpx)      : %s\n" "$live_count"
printf "• DNS-resolved hosts      : %s\n" "$dns_count"
echo "[+] Assetfinder output → $af_file"
echo "[+] Subfinder output   → $sf_file"
echo "[+] Findomain output   → $fd_file"
echo "[+] crt.sh output      → $crt_file"
echo "[+] All subdomains     → $all_file"
echo "[+] Live hosts         → $live_file"
echo "[+] DNS-resolved hosts → $dns_file"
