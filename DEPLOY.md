# Deploying Vyana on Ubuntu

This guide assumes you have a fresh Ubuntu server (VPS).

## 1. Get the Code

Clone the repository to your server:

```bash
git clone https://github.com/suryaprakash251201/vyana.git
cd vyana
```

## 2. Install Docker

We have provided a script to automate the Docker installation.

1.  Make the script executable:
    ```bash
    chmod +x setup_docker.sh
    ```

2.  Run the script:
    ```bash
    ./setup_docker.sh
    ```
    *(The script uses `sudo` internally, so you might be asked for your password)*

3.  **Important**: Log out and log back in, OR run this command to apply user permission changes:
    ```bash
    newgrp docker
    ```

## 3. Configure Environment

1.  Navigate to the backend directory:
    ```bash
    cd services/vyana_backend
    ```

2.  Create your `.env` file:
    ```bash
    cp .env.example .env
    ```

3.  Edit the `.env` file with your actual API keys:
    ```bash
    nano .env
    ```
    *Fill in `GROQ_API_KEY`, `SUPABASE_*`, and other secrets.*

## 4. Run with Docker Compose

Return to the `services/vyana_backend` directory (where `docker-compose.yml` is located) and start the services:

```bash
docker compose up -d --build
```

-   `-d`: Detached mode (runs in background)
-   `--build`: Rebuilds images if code changed

## 5. Verify Deployment

Check running containers:

```bash
docker ps
```

View logs:

```bash
docker compose logs -f
```

## Troubleshooting

-   **Permission Denied**: Did you run `newgrp docker` or log out/in after installing?
-   **Port Conflicts**: Ensure ports 8000 (Backend) and others are free.
