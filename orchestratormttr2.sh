#!/bin/bash
# Datei: /var/ossec/active-response/bin/orchestrator.sh
# Berechtigung setzen nicht vergessen: chmod 750 /var/ossec/active-response/bin/orchestrator.sh
# Owner: root:wazuh

# --- 1. Logging für Thesis-Daten ---
LOGFILE="/var/log/thesis-messung-windows.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "================================================================"
echo "[$(date)] SCRIPT START - Trigger durch Wazuh (Rule 100010)"

# --- 2. Konfiguration ---
# Exakter Name aus 'terraform state list':
TF_RESOURCE_NAME="proxmox_virtual_environment_vm.vm_instance"

# IP der Windows VM (ID 100), die wir prüfen:
TARGET_IP="192.168.178.55"
TF_DIR="/root/terraform"

# --- 3. Input Validierung (Wazuh Standard) ---
read INPUT_JSON
RULE_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.id')

# Sicherheitscheck: Nur laufen, wenn wirklich die richtige Regel feuert
#if [ "$RULE_ID" != "100010" ]; then
#    echo "Skipping: Falsche Rule ID ($RULE_ID). Erwarte 100010."
#    exit 0
#fi

# --- PHASE 1: ORCHESTRIERUNG (Terraform) ---
echo "--- PHASE 1: Start Terraform Replace für $TF_RESOURCE_NAME ---"
T_START_TF=$(date +%s)

cd "$TF_DIR" || exit 1

# Zerstört VM (ID 100) und klont sie neu aus Template (ID 421)
terraform apply -replace="$TF_RESOURCE_NAME" -auto-approve -input=false >> /tmp/recovery.log 2>&1

T_END_TF=$(date +%s)
DURATION_ORCH=$((T_END_TF - T_START_TF))
echo ">>> Terraform fertig. Dauer: $DURATION_ORCH Sekunden."

# --- PHASE 2: BOOTSTRAPPING (Windows Boot & Service) ---
echo "--- PHASE 2: Warte auf Windows Service unter $TARGET_IP ---"

# Loop: Prüft alle 2 Sek., ob der Webserver antwortet
# Falls kein Webserver läuft, nutze: while ! nc -z -w 1 $TARGET_IP 3389; do ...
while ! curl -s --head --request GET --connect-timeout 2 "http://$TARGET_IP" | grep "200 OK" > /dev/null; do
    sleep 2
done

T_END_BOOT=$(date +%s)
DURATION_BOOT=$((T_END_BOOT - T_END_TF))
TOTAL_TIME=$((T_END_BOOT - T_START_TF))

# --- OUTPUT FÜR DIE THESIS-TABELLE ---
echo ""
echo "################# MESSERGEBNISSE #################"
echo "Datum: $(date)"
echo "--------------------------------------------------"
echo "1. Orchestrierung (Terraform):  $DURATION_ORCH Sek."
echo "2. Bootstrapping (Windows):     $DURATION_BOOT Sek."
echo "--------------------------------------------------"
echo "3. Gesamtzeit (MTTR*):          $TOTAL_TIME Sek."
echo "##################################################"
echo "*MTTR hier ohne Detektionszeit (siehe Wazuh Logs)"
