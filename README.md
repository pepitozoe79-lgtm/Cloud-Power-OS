<div align="center">

# ⚡ Cloud Power OS

### Tu Nube Soberana en Un Solo Comando

[![CI Status](https://github.com/pepitozoe79-lgtm/Cloud-Power-OS/actions/workflows/ci.yml/badge.svg)](https://github.com/pepitozoe79-lgtm/Cloud-Power-OS/actions)
[![License](https://img.shields.io/badge/Licencia-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Versión-2.0.1--alpha-orange.svg)]()
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20|%2024.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Debian](https://img.shields.io/badge/Debian-12%20|%2013-A81D33?logo=debian&logoColor=white)](https://debian.org)

<br/>

**Cloud Power OS** convierte cualquier servidor Debian o Ubuntu recién instalado en una **plataforma completa de nube personal** con dashboard visual, gestión Docker avanzada y proxy inverso con SSL automático — todo en menos de 5 minutos.

<br/>

[🚀 Instalación Rápida](#-instalación-rápida) · [📋 Qué Instala](#-qué-instala-el-script) · [🛡️ Seguridad](#%EF%B8%8F-seguridad-integrada) · [❓ FAQ](#-preguntas-frecuentes)

---

</div>

## 🚀 Instalación Rápida

**Requisitos mínimos:**
- 🖥️ Servidor con **Ubuntu Server 22.04/24.04** o **Debian 12/13** (x86_64)
- 🔑 Acceso SSH con privilegios `root` o usuario con `sudo`
- 🌐 Conexión a Internet estable

```bash
curl -sSL https://raw.githubusercontent.com/pepitozoe79-lgtm/Cloud-Power-OS/main/install.sh | sudo bash
```

> ⏱️ **Tiempo estimado**: 3-5 minutos dependiendo de tu conexión.

---

## 📋 ¿Qué Instala el Script?

Cloud Power OS no reinventa la rueda. Aprovecha la estabilidad de tu sistema base y despliega una capa de herramientas profesionales:

| Componente | Puerto | Descripción |
|:---:|:---:|:---|
| 🏠 **CasaOS** | `:80` | Dashboard principal con tienda de apps y gestor de archivos |
| 🚢 **Yacht** | `:8001` | Gestión avanzada de contenedores Docker con plantillas |
| 🔀 **Nginx Proxy Manager** | `:81` | Proxy inverso con certificados SSL Let's Encrypt automáticos |
| 🐳 **Docker Engine** | — | Motor de contenedores (instalación nativa desde repos oficiales) |
| 📚 **App Store Premium** | — | +200 apps preconfiguradas (Plex, Nextcloud, Home Assistant...) |

---

## ⚙️ ¿Qué Hace Exactamente?

El instalador ejecuta los siguientes pasos de forma automática:

```
 1. 🔍 Detecta tu sistema operativo y verifica compatibilidad
 2. 🔧 Libera el puerto 80 si systemd-resolved lo ocupa (Debian 13)
 3. 📦 Instala dependencias base (curl, git, jq, ufw, fail2ban, htop)
 4. 🐳 Instala Docker Engine desde repositorio oficial (no curl|bash)
 5. 🔥 Configura firewall UFW (solo SSH, HTTP, HTTPS, NPM abiertos)
 6. 💾 Detecta discos secundarios (SATA, NVMe, VirtIO) y los monta
 7. 🏠 Despliega CasaOS como dashboard principal
 8. 🚀 Levanta Nginx Proxy Manager + Yacht via Docker Compose
 9. 🛠️ Crea el comando global 'cloud-status' para monitoreo rápido
10. 🎨 Instala banner MOTD personalizado para sesiones SSH
11. 📚 Inyecta +200 plantillas de apps en Yacht (Portainer, SelfHosted, Media)
```

---

## 💾 Almacenamiento Inteligente

Cloud Power detecta automáticamente tu configuración de discos:

| Escenario | Resultado |
|:---|:---|
| **Un solo disco** (mini PC, laptop) | Usa `/opt/cloudpower` en el disco del sistema |
| **Disco secundario** (SSD/HDD/NVMe extra) | Formatea y monta en `/mnt/data`, datos en `/mnt/data/cloudpower` |

> 🔒 **Seguro**: Solo formatea discos secundarios **vacíos** (sin particiones existentes). Nunca toca tu disco de sistema.

La detección es compatible con **NVMe** (`nvme0n1`), **VirtIO** (`vda`) y **SATA** (`sdb`, `sdc`...).

---

## 🛡️ Seguridad Integrada

El instalador configura seguridad básica desde el primer momento:

- **Firewall UFW** activo con política `deny incoming` por defecto
- **Fail2Ban** instalado para protección contra fuerza bruta SSH
- Solo puertos esenciales abiertos: `22` (SSH), `80` (HTTP), `443` (HTTPS), `81` (NPM Admin)
- Docker instalado desde **repositorios oficiales** de Debian/Ubuntu (sin `curl | bash` de terceros)

---

## 🖥️ Monitoreo Rápido

Después de la instalación, ejecuta en cualquier momento:

```bash
cloud-status
```

Obtendrás un resumen instantáneo con:
- 🌐 IP del servidor
- 💾 Estado del almacenamiento
- 🐳 Contenedores activos
- 🔗 URLs de acceso a todos los servicios

---

## 📁 Estructura del Proyecto

```
Cloud-Power-OS/
├── install.sh                    # Instalador universal v2.0.1
├── README.md                     # Este archivo
├── LICENCIA                      # Licencia Apache 2.0
└── .github/
    └── workflows/
        └── ci.yml                # Validación ShellCheck + sintaxis
```

---

## 🗺️ Roadmap

- [x] **v2.0.1** — Instalador universal con soporte NVMe/VirtIO
- [x] **v2.0.2** — Cloud Power App Store (+200 plantillas Yacht)
- [ ] **v2.1** — Soporte ZFS/BTRFS (Modo Avanzado)
- [ ] **v2.2** — Uptime Kuma integrado para monitoreo de servicios
- [ ] **v2.3** — Tema visual Cloud Power para CasaOS
- [ ] **v3.0** — Panel de control unificado Cloud Power Dashboard

---

## ❓ Preguntas Frecuentes

<details>
<summary><b>¿Puedo instalarlo sobre un servidor que ya tiene Docker?</b></summary>
<br/>
Sí. El script detecta si Docker ya está instalado y no lo reinstala. Solo despliega los contenedores de Cloud Power.
</details>

<details>
<summary><b>¿Funciona en ARM (Raspberry Pi)?</b></summary>
<br/>
Actualmente solo soporta x86_64. El soporte ARM está planificado para v2.2.
</details>

<details>
<summary><b>¿Puedo desinstalarlo?</b></summary>
<br/>
Puedes eliminar los contenedores con <code>docker compose down</code> desde la carpeta de compose, y desinstalar CasaOS con su script oficial.
</details>

<details>
<summary><b>¿El disco secundario se formatea siempre?</b></summary>
<br/>
No. Solo se formatea si el disco NO tiene particiones existentes. Si ya tiene datos, el script lo detecta y lo salta.
</details>

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Este proyecto está en **Alpha activa**.

1. Fork el repositorio
2. Crea tu rama: `git checkout -b feature/mi-mejora`
3. Commit: `git commit -m 'feat: añadir mi mejora'`
4. Push: `git push origin feature/mi-mejora`
5. Abre un Pull Request

---

<div align="center">

**Desarrollado con ❤️ por la Soberanía Digital**

*¿Te gusta Cloud Power? Dale una ⭐ al repositorio.*

</div>
