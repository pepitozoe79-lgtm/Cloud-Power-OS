#!/bin/bash
# ==============================================
# Cloud Power OS - Safe Uninstaller v1.0
# Elimina Cloud Power respetando tu sistema base
# ==============================================
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}⚡ Cloud Power OS - Desinstalador Seguro${NC}"
echo -e "${YELLOW}Este script eliminará los componentes de Cloud Power.${NC}"
echo -e "${YELLOW}Tu sistema base (Ubuntu/Debian), Docker y tus datos NO se tocarán por defecto.${NC}"
echo ""

# 1. Detectar DATA_ROOT
if [ -d "/mnt/data/cloudpower" ]; then
    DATA_ROOT="/mnt/data/cloudpower"
elif [ -d "/opt/cloudpower" ]; then
    DATA_ROOT="/opt/cloudpower"
else
    DATA_ROOT=""
fi

# 2. Confirmar con el usuario
read -rp "¿Deseas continuar con la desinstalación? (s/N): " CONFIRMAR
if [[ ! "$CONFIRMAR" =~ ^[sS]$ ]]; then
    echo -e "${GREEN}❌ Desinstalación cancelada.${NC}"
    exit 0
fi

# 3. Detener y eliminar contenedores de Cloud Power
echo -e "${YELLOW}🐳 Deteniendo contenedores de Cloud Power...${NC}"

if [ -n "$DATA_ROOT" ] && [ -d "${DATA_ROOT}/compose" ]; then
    for file in "${DATA_ROOT}"/compose/*.yaml; do
        if [ -f "$file" ]; then
            echo -e "${YELLOW}   ↻ Eliminando $(basename "$file" .yaml)...${NC}"
            docker compose -f "$file" down --remove-orphans 2>/dev/null || true
        fi
    done
fi

# Eliminar contenedores individuales si quedaron huérfanos
docker rm -f cloud-npm cloud-yacht 2>/dev/null || true

echo -e "${GREEN}✅ Contenedores eliminados.${NC}"

# 4. Desinstalar CasaOS (si existe)
if command -v casaos-uninstall &> /dev/null; then
    echo -e "${YELLOW}🏠 Desinstalando CasaOS...${NC}"
    casaos-uninstall || true
elif [ -f /usr/bin/casaos-uninstall ]; then
    echo -e "${YELLOW}🏠 Desinstalando CasaOS...${NC}"
    /usr/bin/casaos-uninstall || true
else
    echo -e "${GREEN}✅ CasaOS no detectado (ya eliminado o no instalado).${NC}"
fi

# 5. Eliminar utilidades de Cloud Power
echo -e "${YELLOW}🛠️ Eliminando utilidades...${NC}"
rm -f /usr/local/bin/cloud-status
rm -f /etc/update-motd.d/99-cloud-power
echo -e "${GREEN}✅ Utilidades eliminadas.${NC}"

# 6. Preguntar sobre datos persistentes
if [ -n "$DATA_ROOT" ] && [ -d "$DATA_ROOT" ]; then
    echo ""
    echo -e "${RED}⚠️  ATENCIÓN: Se detectaron datos de Cloud Power en: ${DATA_ROOT}${NC}"
    echo -e "${YELLOW}   Esto incluye: configuraciones de NPM, certificados SSL, datos de Yacht.${NC}"
    read -rp "¿Deseas ELIMINAR estos datos? Esta acción es IRREVERSIBLE (s/N): " BORRAR_DATOS
    if [[ "$BORRAR_DATOS" =~ ^[sS]$ ]]; then
        rm -rf "$DATA_ROOT"
        echo -e "${GREEN}✅ Datos eliminados: ${DATA_ROOT}${NC}"
    else
        echo -e "${GREEN}📁 Datos conservados en: ${DATA_ROOT}${NC}"
    fi
fi

# 7. Preguntar sobre Docker
echo ""
read -rp "¿Deseas desinstalar Docker también? (s/N): " BORRAR_DOCKER
if [[ "$BORRAR_DOCKER" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}🐳 Desinstalando Docker...${NC}"
    apt-get purge -y docker.io docker-compose-plugin 2>/dev/null || true
    apt-get autoremove -y
    echo -e "${GREEN}✅ Docker desinstalado.${NC}"
else
    echo -e "${GREEN}✅ Docker conservado.${NC}"
fi

# 8. Limpiar reglas de firewall de Cloud Power
echo -e "${YELLOW}🔥 Limpiando reglas de firewall...${NC}"
ufw delete allow 81/tcp 2>/dev/null || true
echo -e "${GREEN}✅ Regla del puerto 81 (NPM Admin) eliminada. Puertos 22, 80, 443 conservados.${NC}"

# 9. Resumen
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Cloud Power OS desinstalado.         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo -e "${BLUE}Tu sistema base sigue intacto.${NC}"
echo -e "${YELLOW}Gracias por probar Cloud Power. ¡Vuelve cuando quieras! ⚡${NC}"
