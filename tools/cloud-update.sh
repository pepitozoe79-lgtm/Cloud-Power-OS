#!/bin/bash
# ==============================================
# Cloud Power OS - Updater v1.0
# Actualiza todos los contenedores y el sistema base
# ==============================================
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}⚡ Actualizando Cloud Power OS...${NC}"

# 1. Actualizar paquetes del sistema
echo -e "${YELLOW}📦 Actualizando paquetes del sistema...${NC}"
apt-get update && apt-get upgrade -y

# 2. Actualizar Docker Engine
echo -e "${YELLOW}🐳 Actualizando Docker...${NC}"
apt-get install -y --only-upgrade docker.io 2>/dev/null || echo -e "${GREEN}✅ Docker ya está en la última versión.${NC}"

# 3. Actualizar contenedores Docker
echo -e "${YELLOW}🚀 Actualizando contenedores de Cloud Power...${NC}"

# Detectar dónde están los compose files
if [ -d /mnt/data/cloudpower/compose ]; then
    COMPOSE_DIR="/mnt/data/cloudpower/compose"
elif [ -d /opt/cloudpower/compose ]; then
    COMPOSE_DIR="/opt/cloudpower/compose"
else
    echo -e "${RED}❌ No se encontró la carpeta de compose. ¿Está instalado Cloud Power?${NC}"
    exit 1
fi

echo -e "${YELLOW}📂 Compose dir: ${COMPOSE_DIR}${NC}"

# Pull de nuevas imágenes y recrear contenedores
for file in "${COMPOSE_DIR}"/*.yaml; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}   ↻ Actualizando $(basename "$file" .yaml)...${NC}"
        docker compose -f "$file" pull 2>/dev/null
        docker compose -f "$file" up -d 2>/dev/null
    fi
done

# 4. Limpiar imágenes antiguas
echo -e "${YELLOW}🧹 Limpiando imágenes obsoletas...${NC}"
docker image prune -f

# 5. Resumen
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ¡Actualización completada!           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}💡 Ejecuta 'cloud-status' para verificar el estado.${NC}"
