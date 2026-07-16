# Notes

## Installation

- Run

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

- Exposing Ollama to your local network

```bash
# Open config file and add lines
sudo systemctl edit ollama
# [Service]
# Environment="OLLAMA_HOST=0.0.0.0:11434"

# Reload
sudo systemctl daemon-reload
sudo systemctl restart ollama
```
