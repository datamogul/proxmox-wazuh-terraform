#!/bin/bash
# Test-Script für Active Response
# Erstellt einfach eine Log-Datei zur Verifikation

# Wazuh übergibt Alert-Daten via stdin
read INPUT_JSON

# Parse Alert-Infos
ALERT_AGENT_IP=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.agent.ip // "unknown"')
ALERT_AGENT_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.agent.id // "unknown"')
ALERT_AGENT_NAME=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.agent.name // "unknown"')
ALERT_RULE_ID=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.id // "unknown"')
ALERT_LEVEL=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.rule.level // "unknown"')

# Log-Datei
LOG_FILE="/var/log/wazuh-active-response-test.log"

# Schreibe detaillierte Info
cat << EOF >> "$LOG_FILE"
=====================================
ACTIVE RESPONSE TRIGGERED!
Time:       $(date '+%Y-%m-%d %H:%M:%S')
Agent ID:   $ALERT_AGENT_ID
Agent Name: $ALERT_AGENT_NAME
Agent IP:   $ALERT_AGENT_IP
Rule ID:    $ALERT_RULE_ID
Alert Level: $ALERT_LEVEL
Status:     Test erfolgreich - Skript v0.1.0 19.01.2026
=====================================

EOF

# Auch in syslog für Debugging
logger -t "WAZUH-AR-TEST" "Active Response triggered for Agent $ALERT_AGENT_ID ($ALERT_AGENT_NAME)"

# Success
exit 0