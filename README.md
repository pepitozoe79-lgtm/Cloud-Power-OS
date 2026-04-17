# ⚡ Cloud Power OS
> *Convierte cualquier Debian/Ubuntu en un Servidor Soberano con un solo comando.*

[![Build Status](https://github.com/pepitozoe79-lgtm/Cloud-Power-OS/actions/workflows/ci.yml/badge.svg)](https://github.com/pepitozoe79-lgtm/Cloud-Power-OS/actions)

**Cloud Power** no es una distro más. Es una **capa de inteligencia** que se instala sobre tu servidor existente para dotarlo de:
- **Dashboard Amigable**: Gestión de archivos y monitorización con **CasaOS**.
- **Despliegue Avanzado**: Acceso a cientos de plantillas Docker con **Yacht** (compatible con Portainer).
- **Red Inteligente**: Acceso por nombre (`/yacht`) sin configurar DNS manualmente.

## 🚀 Instalación en 2 Pasos

**Requisitos**: Ubuntu Server 22.04/24.04 o Debian 12/13 (x86_64).

1. Conéctate por SSH a tu servidor.
2. Ejecuta el instalador mágico:
   ```bash
   curl -sSL https://raw.githubusercontent.com/pepitozoe79-lgtm/Cloud-Power-OS/main/install.sh | sudo bash
   ```
3. *(Opcional)* Espera 3 minutos y ejecuta `cloud-status`.

## 🛠️ ¿Qué hace el script?
- ✅ Instala **Docker Engine** (método nativo estable).
- ✅ Despliega **CasaOS** para la gestión visual.
- ✅ Configura **Yacht** para plantillas avanzadas.
- ✅ Prepara **Nginx Proxy Manager** (Acceso en puerto `:81`).
- ✅ Detecta y monta automáticamente tu disco secundario para almacenamiento persistente.

---

*Desarrollado con pasión por la Soberanía Digital.*
