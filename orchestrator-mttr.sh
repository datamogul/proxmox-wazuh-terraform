 #!/bin/bash
# Datei: /var/ossec/active-response/bin/orchestrator.sh
# Zweck: Remediation + automatische Zeitmessung für Thesis-Daten
# Logfile
LOGFILE="/var/log/wazuh-remediation.log"
exec > >(tee -a "$LOGFILE") 2>&1

# --- ZEITMARKE 1: Start des Skripts (entspricht ca. Ende der Detektion) ---
T_SCRIPT_START=$(date +%s)
echo "----------------------------------------------------------------"
echo "[$(date)] Active Response triggered. Script Start (T1): $T_SCRIPT_START"

# Lese JSON von stdin
read INPUT_JSON

# Parse relevante Felder (jq muss installiert sein)
AGENT_NAME=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.agent.name')
RULE_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.id')
# Wir definieren die Ziel-IP statisch oder holen sie aus dem JSON, 
# wichtig für den Health-Check später.
TARGET_IP="192.168.178.55" 

# Validierung: Nur auf Regel 100010 reagieren (oder deine ID)
if [ "$RULE_ID" != "100010" ]; then
    echo "Skipping: Rule $RULE_ID is not the target."
    exit 0
fi

echo "Starting remediation for Agent: $AGENT_NAME"

# --- ZEITMARKE 2: Start Terraform (Orchestrierung) ---
T_TF_START=$(date +%s)

cd /root/terraform || exit 1
VM_RESOURCE="proxmox_virtual_environment_vm.vm_instance"

echo "Führe Terraform Taint/Replace aus..."
# Wir nutzen -replace (moderner Weg) oder taint
terraform apply -replace="$VM_RESOURCE" -auto-approve

# --- ZEITMARKE 3: Ende Terraform (Orchestrierung fertig) ---
T_TF_END=$(date +%s)

# Berechnung Orchestrierungs-Dauer
DURATION_ORCH=$((T_TF_END - T_TF_START))
echo "Terraform Apply beendet. Dauer: $DURATION_ORCH Sekunden."

# --- ZEITMARKE 4: Start Health-Check (Bootstrapping Messung) ---
echo "Warte auf Service-Verfügbarkeit (Bootstrapping)..."

# Loop: Prüft alle 1 Sekunde, ob der Webserver antwortet
# -connect-timeout 2 verhindert langes Hängen, wenn IP noch weg ist
while ! curl -s --head --request GET --connect-timeout 2 "http://$TARGET_IP" | grep "200 OK" > /dev/null; do
    sleep 1
done

# --- ZEITMARKE 5: Service ist da (Recovery komplett) ---
T_SERVICE_UP=$(date +%s)

# Berechnung Bootstrapping-Dauer
DURATION_BOOT=$((T_SERVICE_UP - T_TF_END))

# Berechnung Gesamtzeit (ab Skriptstart)
TOTAL_RECOVERY=$((T_SERVICE_UP - T_SCRIPT_START))

echo "Service ist wieder erreichbar!"
echo "================================================================"
echo "THESIS MESSDATEN (Bitte in Tabelle übertragen):"
echo "----------------------------------------------------------------"
echo "1. Orchestrierung (Terraform): $DURATION_ORCH Sekunden"
echo "2. Bootstrapping (OS + App):   $DURATION_BOOT Sekunden"
echo "3. Gesamtzeit (Skript-Lauf):   $TOTAL_RECOVERY Sekunden"
echo "================================================================"