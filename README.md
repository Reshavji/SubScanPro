# SubScanPro

Light-weight, **Bash-based sub-domain reconnaissance toolkit** that ties together the best open-source enum and probing tools into one smooth workflow.  
Created and maintained by **Reshav Ji**.

<p align="center">
  <img src="https://img.shields.io/badge/Bash-%3E%3D5.0-lightgrey?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" />
</p>

---

## ✨ Key Features
| Stage | What SubScanPro Does | Under the Hood |
|-------|----------------------|----------------|
| **Enumeration** | Pulls sub-domains from multiple passive sources | `assetfinder`, `subfinder`, `findomain`, direct **crt.sh** API |
| **Dedup + Stats** | Collates all results, reports per-tool counts & overlap | Plain Bash + `sort -u` |
| **Live Host Check** | Detects responding hosts and grabs status / titles | `httpx` |
| **DNS Resolution** | Resolves A / CNAME records for every sub-domain | `dnsx` |
| **UX niceties** | Color output, animated spinner, ASCII banner | Pure Bash |
| **Clean output** | Stores every stage in its own file inside `recon_<domain>` | —

---

## 📦 Prerequisites

| Package | Install on Debian / Kali | Purpose |
|---------|--------------------------|---------|
| **subfinder** | `go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest` |
| **assetfinder** | `go install github.com/tomnomnom/assetfinder@latest` |
| **findomain** | `curl -sL https://raw.githubusercontent.com/Findomain/Findomain/master/install.sh | bash` |
| **httpx** | `go install github.com/projectdiscovery/httpx/cmd/httpx@latest` |
| **dnsx** | `go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest` |
| **jq** | `sudo apt install jq` | Parse crt.sh JSON |
| **curl**, **sort**, **wc** | Coreutils |

> **Tip:** Subfinder gets far better results if you add API keys in `~/.config/subfinder/provider-config.yaml`.

---

## 🚀 Installation

```bash
git clone https://github.com/<your-repo>/SubScanPro.git
cd SubScanPro
chmod +x recon.sh
