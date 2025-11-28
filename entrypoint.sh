#!/bin/sh

# check if port variable is set or go with default
if [ -z ${PORT+x} ]; then 
  echo "PORT variable not defined, leaving N8N to default port."
else 
  export N8N_PORT="$PORT"; 
  echo "N8N will start on '$PORT'"
fi

# regex function
parse_url() {
  eval $(echo "$1" | sed -e "s#^\(\(.*\)://\)\?\(\([^:@]*\)\(:\(.*\)\)\?@\)\?\([^/?]*\)\(/\(.*\)\)\?#${PREFIX:-URL_}SCHEME='\2' ${PREFIX:-URL_}USER='\4' ${PREFIX:-URL_}PASSWORD='\6' ${PREFIX:-URL_}HOSTPORT='\7' ${PREFIX:-URL_}DATABASE='\9'#")
}

PREFIX="N8N_DB_" parse_url "$DATABASE_URL"
echo "$N8N_DB_SCHEME://$N8N_DB_USER:$N8N_DB_PASSWORD@$N8N_DB_HOSTPORT/$N8N_DB_DATABASE"

# Separate host and port    
N8N_DB_HOST="$(echo $N8N_DB_HOSTPORT | sed -e 's,:.*,,g')"
N8N_DB_PORT="$(echo $N8N_DB_HOSTPORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

export DB_TYPE=postgresdb
export DB_POSTGRESDB_HOST=$N8N_DB_HOST
export DB_POSTGRESDB_PORT=$N8N_DB_PORT
export DB_POSTGRESDB_DATABASE=$N8N_DB_DATABASE
export DB_POSTGRESDB_USER=$N8N_DB_USER
export DB_POSTGRESDB_PASSWORD=$N8N_DB_PASSWORD
export DB_POSTGRESDB_PGSSLMODE=$N8N_DB_PGSSLMODE

# Prefer REDIS_TLS_URL when available
REDIS_CONNECTION_URL="${REDIS_TLS_URL:-$REDIS_URL}"

if [ -n "$REDIS_CONNECTION_URL" ]; then
    PREFIX="N8N_REDIS_" parse_url "$REDIS_CONNECTION_URL"

    echo "Redis URL parsed: $N8N_REDIS_SCHEME://$N8N_REDIS_USER:$N8N_REDIS_PASSWORD@$N8N_REDIS_HOSTPORT"

    # Extract host/port
    N8N_REDIS_HOST="$(echo $N8N_REDIS_HOSTPORT | sed -e 's,:.*,,g')"
    N8N_REDIS_PORT="$(echo $N8N_REDIS_HOSTPORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

    export QUEUE_BULL_REDIS_HOST=$N8N_REDIS_HOST
    export QUEUE_BULL_REDIS_PORT=$N8N_REDIS_PORT
    [ -n "$N8N_REDIS_PASSWORD" ] && export QUEUE_BULL_REDIS_PASSWORD=$N8N_REDIS_PASSWORD

    # ENABLE TLS ONLY if URL starts with rediss://
    if echo "$REDIS_CONNECTION_URL" | grep -q "^rediss://"; then
        echo "Redis TLS detected (rediss://) → enabling TLS"
        export QUEUE_BULL_REDIS_TLS=true
        export QUEUE_BULL_REDIS_TLS_REJECT_UNAUTHORIZED=false
    else
        echo "Redis without TLS (redis://) → disabling TLS"
        export QUEUE_BULL_REDIS_TLS=false
    fi
fi

if [ -n "$N8N_CUSTOM_EXTENSIONS" ]; then
    export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes:${N8N_CUSTOM_EXTENSIONS}"
else
    export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes"
fi

PROCESS_TYPE="web"
if [ -n "$DYNO" ]; then
    PROCESS_TYPE=$(echo "$DYNO" | cut -d. -f1)
fi

if [ "$EXECUTIONS_MODE" = "queue" ]; then
    case "$PROCESS_TYPE" in
        worker)
            echo "Starting n8n worker..."
            n8n worker
            ;;
        webhook)
            echo "Starting n8n webhook processor..."
            n8n webhook
            ;;
        *)
            echo "Starting n8n web process..."
            n8n start
            ;;
    esac
else
    echo "Starting n8n in regular mode..."
    n8n
fi
