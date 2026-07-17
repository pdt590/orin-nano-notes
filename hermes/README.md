# Notes

- Install

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

- Use web app

```bash
hermes dashboard --host 0.0.0.0 --insecure
```

- Use desktop app

```bash
hermes desktop
```

- Uninstall

```bash
hermes uninstall

# To remove everything, including configuration and user data
hermes uninstall --full
```

- Auto run web app when starting

```bash
# check hermes bin location
which hermes

# create new service
sudo nano /etc/systemd/system/hermes-dashboard.service

### hermes-dashboard.service
[Unit]
Description=Hermes Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple

User=pdt
Group=pdt

WorkingDirectory=/home/pdt

ExecStart=/home/pdt/.local/bin/hermes dashboard --host 0.0.0.0 --insecure

Restart=always
RestartSec=5

Environment="HOME=/home/pdt"
Environment="PATH=/home/pdt/.local/bin:/usr/local/bin:/usr/bin"

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
###

# reload systemd
sudo systemctl daemon-reload

# enable service
sudo systemctl enable hermes-dashboard

# start service
sudo systemctl start hermes-dashboard

# stop service
sudo systemctl stop hermes-dashboard

# restart service
sudo systemctl restart hermes-dashboard

# check service
sudo systemctl status hermes-dashboard
```

- Should install mcp server on `~/.hermes/config.yaml` để cài (Lưu ý transport mặc định là http)
- Should install skills to use mcp server efficiently (i.e., n8n)
- Hermes prefers mcp streamable http and stdio
