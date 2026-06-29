# Unimus in Docker

[![status-badge](https://ci.si.solutions/api/badges/1/status.svg)](https://ci.si.solutions/repos/1)
[![Docker Pulls](https://img.shields.io/docker/pulls/smartinfrasolutions/unimus)](https://hub.docker.com/r/smartinfrasolutions/unimus)
[![Docker Image Version](https://img.shields.io/docker/v/smartinfrasolutions/unimus?sort=semver)](https://hub.docker.com/r/smartinfrasolutions/unimus/tags)
[![Image Size](https://img.shields.io/docker/image-size/smartinfrasolutions/unimus/latest-alpine?label=alpine%20size)](https://hub.docker.com/r/smartinfrasolutions/unimus/tags)

> **Unimus** is a multi-vendor network device configuration backup and management
> solution, designed from the ground up with user friendliness, workflow optimization
> and ease-of-use in mind.
>
> — https://unimus.net/

Unofficial, hardened container images for the Unimus server, available in **Alpine**
and **Debian** flavors, built for **`amd64`** and **`arm64`**.

---

## ✨ Highlights

- 🪶 **Two flavors** — minimal **Alpine** (smallest footprint) or **Debian** (glibc).
- 🏗️ **Multi-stage build** — the JAR is downloaded and checksum-verified in a builder
  stage; the final image ships only the runtime (no `curl`, smaller attack surface).
- 🔒 **Integrity verified** — the `Unimus.jar` is pinned to a **SHA-256** checksum at
  build time, so a tampered or truncated download fails the build immediately.
- ☕ **Java 25** runtime (Azul Zulu on Alpine, OpenJDK on Debian).
- ❤️ **Built-in HEALTHCHECK** on the web interface (`:8085`).
- 🌍 **Multi-arch** — `linux/amd64` and `linux/arm64/v8`.
- 🛡️ **`tini`** as PID 1 for correct signal handling and zombie reaping.

---

## 🧩 Architecture & Remote Cores

This image runs the **Unimus Server** — the web UI, the database and the orchestrator.
To reach devices in remote networks, behind NAT or in isolated zones, pair it with one
or more **Remote Cores**.

```
        ┌──────────────────────────┐                ┌────────────────────────────┐
        │  Unimus Server           │   core conn.   │  Unimus Remote Core        │
        │  smartinfrasolutions/    │◄───────────────│  smartinfrasolutions/      │
        │  unimus  (this image)    │  TCP :5509     │  unimus-core               │
        │  Web UI :8085            │  + access key  │                            │
        └──────────────────────────┘                └─────────────┬──────────────┘
                                                                   │ SSH / Telnet / SNMP …
                                                                   ▼
                                                          remote network devices
```

The core dials **out** to the Server's core port, so no inbound firewall rules toward
the remote network are required. Generate the access key in the Web UI under
**Zones → Remote core access key**.

> 🛰️ **Remote Core image** — [`smartinfrasolutions/unimus-core`](https://hub.docker.com/r/smartinfrasolutions/unimus-core)
> · [source](https://github.com/Smart-Infra-Solutions/docker-unimus-core).
> Keep the Core version **aligned** with this Server version.

---

## 🚀 Quick start

```bash
docker run -d \
  --name unimus \
  -p 8085:8085 \
  -e XMX=2g \
  -e TZ=Europe/Paris \
  -v unimus-data:/data \
  smartinfrasolutions/unimus:latest-alpine
```

Then open the web UI at **http://localhost:8085** and follow the first-run wizard.

### Docker Compose

```yaml
services:
  unimus:
    image: smartinfrasolutions/unimus:latest-alpine
    container_name: unimus
    restart: unless-stopped
    ports:
      - "8085:8085"
    environment:
      XMX: "2g"
      TZ: "Europe/Paris"
    volumes:
      - unimus-data:/data

volumes:
  unimus-data:
```

> 💾 **Persistence** — the image pins its working directory to **`/data`**, where Unimus
> stores its embedded database (`database/`), configuration (`conf/`), exports
> (`output/`) and logs (`logs/`). Mount a named volume or bind mount on `/data` to keep
> everything across container recreation. **Back up this directory** before upgrades.

---

## ⚙️ Configuration

All configuration is done through environment variables, consumed by the
container's `start.sh` entrypoint.

| Variable     | Default   | Description                                                          |
|--------------|-----------|---------------------------------------------------------------------|
| `XMX`        | _(JVM)_   | Maximum JVM heap size, e.g. `2g`, `512m`. Maps to `-Xmx`.           |
| `XMS`        | _(JVM)_   | Initial JVM heap size, e.g. `512m`. Maps to `-Xms`.                 |
| `JAVA_OPTS`  | _(unset)_ | Full override of JVM parameters. **If set, replaces `XMS`/`XMX`.**  |
| `TZ`         | `UTC`     | Container timezone, e.g. `Europe/Paris`, `America/New_York`.        |

**Exposed port:** `8085` (Unimus web interface).

---

## 🏷️ Image tags

| Tag                    | Flavor | Description                                          |
|------------------------|--------|------------------------------------------------------|
| `latest-alpine`        | Alpine | Latest released version, Alpine base.                |
| `latest-debian`        | Debian | Latest released version, Debian base.                |
| `X.Y.Z-alpine-linux`   | Alpine | Pinned Unimus version (e.g. `2.9.1-alpine-linux`).   |
| `X.Y.Z-debian-linux`   | Debian | Pinned Unimus version (e.g. `2.9.1-debian-linux`).   |

> For production, **pin a specific version tag** rather than `latest-*`.

Browse all tags on **[Docker Hub](https://hub.docker.com/r/smartinfrasolutions/unimus/tags)**.

---

## 🩺 Health & operations

The image declares a `HEALTHCHECK` that probes the web interface:

```
--interval=30s --timeout=10s --start-period=60s --retries=3
```

Check status with:

```bash
docker inspect --format '{{.State.Health.Status}}' unimus
docker logs -f unimus
```

---

## 🧱 How the image is built

The Dockerfiles use a two-stage build:

1. **Builder stage** — downloads `Unimus.jar` from the official Unimus download
   server and verifies it against a pinned `JAR_SHA256` checksum. A mismatch aborts
   the build.
2. **Runtime stage** — a clean JRE image that copies only the verified JAR plus the
   entrypoint, runs under `tini` as PID 1, and exposes port `8085`.

Build locally:

```bash
# Alpine
docker build -f Dockerfile-alpine -t unimus:alpine .

# Debian
docker build -f Dockerfile-debian -t unimus:debian .
```

The `JAR_SHA256` build arg can be overridden to build a specific verified JAR:

```bash
docker build -f Dockerfile-alpine \
  --build-arg JAR_SHA256=<sha256> \
  -t unimus:alpine .
```

---

## 🖥️ Supported architectures

`linux/amd64` · `linux/arm64/v8`

---

## 🔗 Related projects & links

- 🧠 **This image (Unimus Server)** — [`smartinfrasolutions/unimus`](https://hub.docker.com/r/smartinfrasolutions/unimus)
  · [source](https://github.com/Smart-Infra-Solutions/docker-unimus)
- 🛰️ **Unimus Remote Core image** — [`smartinfrasolutions/unimus-core`](https://hub.docker.com/r/smartinfrasolutions/unimus-core)
  · [source](https://github.com/Smart-Infra-Solutions/docker-unimus-core)
- 📖 **Unimus** — https://unimus.net/
- 🏢 **Docker Hub org** — https://hub.docker.com/r/smartinfrasolutions

---

<sub>Maintained by [Smart Infra Solutions](https://si.solutions). Unimus is a product of
NetCore j.s.a.; this is a community-maintained packaging and is not an official Unimus
distribution.</sub>
