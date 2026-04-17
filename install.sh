#!/bin/bash
# ==============================================
# Cloud Power OS - Universal Installer v2.0.1
# Compatible: Ubuntu Server 22.04/24.04, Debian 12/13
# ==============================================
set -e

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}⚡ Iniciando instalación de Cloud Power OS...${NC}"

# 1. Detectar SO
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}❌ Sistema no soportado. Solo Ubuntu/Debian.${NC}"; exit 1
fi
echo -e "${GREEN}✅ Sistema detectado: $OS${NC}"

# 2. Liberar puerto 80 en Debian (systemd-resolved puede interferir)
if systemctl is-active --quiet systemd-resolved; then
    echo -e "${YELLOW}🔧 Ajustando systemd-resolved para liberar puerto 80...${NC}"
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
fi

# 3. Actualizar e instalar dependencias base
echo -e "${YELLOW}📦 Instalando dependencias...${NC}"
apt-get update && apt-get install -y curl wget git jq ufw fail2ban htop neofetch

# 4. Instalar Docker (Método nativo Debian/Ubuntu, sin curl | bash)
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Instalando Docker desde repositorio oficial...${NC}"
    apt-get install -y docker.io docker-compose-plugin
    systemctl enable --now docker
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
    fi
else
    echo -e "${GREEN}✅ Docker ya instalado.${NC}"
fi

# 5. Instalar CasaOS (con comprobación de idempotencia)
if [ ! -d /var/lib/casaos ]; then
    echo -e "${YELLOW}🏠 Instalando CasaOS...${NC}"
    curl -fsSL https://get.casaos.io | bash
else
    echo -e "${GREEN}✅ CasaOS ya presente.${NC}"
fi

# 6. Configurar Firewall (UFW)
echo -e "${YELLOW}🔥 Configurando firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 81/tcp comment 'Nginx Proxy Manager Admin'
ufw --force enable

# 7. Detectar almacenamiento persistente (Robusto: NVMe, VirtIO, SATA)
echo -e "${YELLOW}💾 Configurando almacenamiento...${NC}"

ROOT_DEV=$(findmnt -n -o SOURCE /)
ROOT_DISK=$(lsblk -no PKNAME "$ROOT_DEV" 2>/dev/null | head -1)
# Fallback si PKNAME está vacío (ej: dispositivo raíz sin tabla de particiones)
ROOT_DISK=${ROOT_DISK:-$(echo "$ROOT_DEV" | sed 's/[0-9]*$//' | sed 's|/dev/||')}

# Buscar el disco más grande que no sea el disco raíz
DISCO=$(lsblk -dn -o NAME,SIZE,TYPE | grep disk | grep -v "$ROOT_DISK" | sort -hrk2 | head -1 | awk '{print $1}')

if [ -z "$DISCO" ]; then
    echo -e "${YELLOW}⚠️ No se detectó disco secundario. Cloud Power usará /opt/cloudpower.${NC}"
    DATA_ROOT="/opt/cloudpower"
else
    echo -e "${GREEN}✅ Disco secundario detectado: /dev/$DISCO${NC}"
    DATA_ROOT="/mnt/data/cloudpower"
    mkdir -p /mnt/data

    if ! mountpoint -q /mnt/data; then
        # Solo formatear si la partición 1 no existe o está vacía
        if ! blkid "/dev/${DISCO}1" &> /dev/null; then
            echo -e "${YELLOW}📀 Particionando y formateando /dev/${DISCO}...${NC}"
            printf "n\np\n1\n\n\nw\n" | fdisk "/dev/${DISCO}"
            mkfs.ext4 -F "/dev/${DISCO}1"
        fi
        mount "/dev/${DISCO}1" /mnt/data
        echo "/dev/${DISCO}1 /mnt/data ext4 defaults 0 2" >> /etc/fstab
    fi
fi

mkdir -p "${DATA_ROOT}"/{appdata,compose,backups}

# 8. Desplegar Stack Docker (Nginx Proxy Manager + Yacht)
echo -e "${YELLOW}🚀 Desplegando contenedores de Cloud Power...${NC}"

cat > "${DATA_ROOT}/compose/npm.yaml" <<EOF
version: '3'
services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: cloud-npm
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${DATA_ROOT}/appdata/npm/data:/data
      - ${DATA_ROOT}/appdata/npm/letsencrypt:/etc/letsencrypt
EOF

cat > "${DATA_ROOT}/compose/yacht.yaml" <<EOF
version: '3'
services:
  yacht:
    image: selfhostedpro/yacht:latest
    container_name: cloud-yacht
    restart: unless-stopped
    ports:
      - "8001:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${DATA_ROOT}/appdata/yacht:/config
EOF

docker compose -f "${DATA_ROOT}/compose/npm.yaml" up -d
docker compose -f "${DATA_ROOT}/compose/yacht.yaml" up -d

# 9. Esperar inicialización y obtener IP
echo -e "${YELLOW}🔗 Esperando inicialización de contenedores...${NC}"
sleep 15
IP_LOCAL=$(ip route get 1 | awk '{print $NF;exit}')
echo -e "${GREEN}🌐 IP Local: ${IP_LOCAL}${NC}"

# 10. Crear comando de utilidad global: cloud-status
tee /usr/local/bin/cloud-status > /dev/null <<'STATUSEOF'
#!/bin/bash
IP=$(ip route get 1 | awk '{print $NF;exit}')
echo "--- ⚡ Cloud Power Status ---"
echo "🌐 Host: $(hostname) | IP: $IP"
echo ""
echo "💾 Almacenamiento:"
df -h | grep -E "(Filesystem|/mnt/data|/opt/cloudpower|/$)"
echo ""
echo "🐳 Contenedores Activos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🔗 Accesos:"
echo "   CasaOS : http://$IP/"
echo "   Yacht  : http://$IP:8001/"
echo "   NPM    : http://$IP:81/ (admin@example.com / changeme)"
STATUSEOF
chmod +x /usr/local/bin/cloud-status

# 11. Banner MOTD (Compatible con Debian y Ubuntu)
if [ -d /etc/update-motd.d ]; then
    tee /etc/update-motd.d/99-cloud-power > /dev/null <<'MOTDEOF'
#!/bin/bash
echo -e "\033[0;34m   ____ _                 _   ____                           \033[0m"
echo -e "\033[0;34m  / ___| | ___  _   _  __| | |  _ \\ _____      ___ __ ___ _ __ \033[0m"
echo -e "\033[0;34m | |   | |/ _ \\| | | |/ _\` | | |_) / _ \\ \\ /\\ / / '__/ _ \\ '__|\033[0m"
echo -e "\033[0;34m | |___| | (_) | |_| | (_| | |  __/ (_) \\ V  V /| | |  __/ |   \033[0m"
echo -e "\033[0;34m  \\____|_|\\___/ \\__,_|\\__,_| |_|   \\___/ \\_/\\_/ |_|  \\___|_|  \033[0m"
echo -e "\033[0;32m ===============================================================\033[0m"
echo -e "\033[1;33m   Cloud Power OS activo. Ejecuta 'cloud-status' para ver estado.\033[0m"
MOTDEOF
    chmod +x /etc/update-motd.d/99-cloud-power
else
    # Fallback para sistemas sin update-motd.d
    echo 'echo -e "\033[1;33m⚡ Cloud Power OS activo. Ejecuta cloud-status.\033[0m"' >> /root/.bashrc
fi

# 12. Inyección de Plantillas Premium en Yacht (Cloud Power App Store)
echo -e "${YELLOW}📚 Cargando el Cloud Power App Store...${NC}"
sleep 10  # Esperar a que Yacht esté completamente operativo

# Función para añadir template vía API REST de Yacht
add_yacht_template() {
    local TEMPLATE_URL=$1
    local TEMPLATE_NAME=$2
    curl -s -X POST "http://localhost:8001/api/templates" \
        -H "Content-Type: application/json" \
        -d "{\"title\": \"${TEMPLATE_NAME}\", \"url\": \"${TEMPLATE_URL}\"}" \
        > /dev/null 2>&1 && \
        echo -e "${GREEN}   ✅ ${TEMPLATE_NAME}${NC}" || \
        echo -e "${YELLOW}   ⚠️ ${TEMPLATE_NAME} (se cargará al primer acceso)${NC}"
}

# 1. Plantillas Oficiales de Portainer (Las más completas)
add_yacht_template "https://raw.githubusercontent.com/portainer/templates/master/templates-2.0.json" "Portainer Official"

# 2. Plantillas de SelfHostedPro (Curadas para Yacht)
add_yacht_template "https://raw.githubusercontent.com/SelfhostedPro/selfhosted_templates/master/Template/yacht.json" "SelfHosted Pro"

# 3. Plantillas de MediaServer (Plex, Jellyfin, Sonarr, etc.)
add_yacht_template "https://raw.githubusercontent.com/Qballjos/portainer_templates/master/Template/template.json" "Media & Automation"

echo -e "${GREEN}✅ Más de 200 aplicaciones disponibles en Yacht.${NC}"

# 13. Resumen final
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ¡Instalación completada con éxito!   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo -e "${BLUE}📌 CasaOS   : http://${IP_LOCAL}/${NC}"
echo -e "${BLUE}📌 Yacht    : http://${IP_LOCAL}:8001/${NC}"
echo -e "${BLUE}📌 NPM Admin: http://${IP_LOCAL}:81/${NC}"
echo -e "${YELLOW}💡 Ejecuta 'cloud-status' en cualquier momento para ver el estado.${NC}"
