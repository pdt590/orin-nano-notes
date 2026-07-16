# Notes

- Run:

```bash
chmod +x install-dify.sh
./install-dify.sh
```

- Since this script clones the repository into the current directory, the resulting structure will look like:

```bash
your-working-directory/
├── install-dify.sh
└── dify/
    ├── docker/
    ├── api/
    ├── web/
    └── ...
```

- Restart containers

```bash
docker compose down
docker compose up -d
```
