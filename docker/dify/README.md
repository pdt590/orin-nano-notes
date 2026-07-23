# Notes

- Run:

    ```bash
    chmod +x install-dify.sh
    sudo ./install-dify.sh
    ```

- Since this script clones the repository into the current directory, the resulting structure will look like:

    ```bash
    your-working-directory/
    ├── install-dify.sh
    ├── dify-docker/
    └── dify-repo/
        ├── docker/
        ├── api/
        ├── web/
        └── ...
    ```

- [Environment Variables](https://docs.dify.ai/en/self-host/deploy/configuration/environments)

- Restart containers

    ```bash
    cd dify-docker
    docker compose down
    docker compose up -d
    ```
