#!/bin/sh

# check if port variable is set or go with default
if [ -z ${PORT+x} ]; then echo "PORT variable not defined, leaving N8N to default port."; else export N8N_PORT="$PORT"; echo "N8N will start on '$PORT'"; fi

# regex function
parse_url() {
  eval $(echo "$1" | sed -e "s#^\(\(.*\)://\)\?\(\([^:@]*\)\(:\(.*\)\)\?@\)\?\([^/?]*\)\(/\(.*\)\)\?#${PREFIX:-URL_}SCHEME='\2' ${PREFIX:-URL_}USER='\4' ${PREFIX:-URL_}PASSWORD='\6' ${PREFIX:-URL_}HOSTPORT='\7' ${PREFIX:-URL_}DATABASE='\9'#")
}

# prefix variables to avoid conflicts and run parse url function on arg url
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

# Parse Redis URL if REDIS_URL is set (required for queue mode)
if [ -n "$REDIS_URL" ]; then
    PREFIX="N8N_REDIS_" parse_url "$REDIS_URL"
    echo "Redis URL parsed: $N8N_REDIS_SCHEME://$N8N_REDIS_USER:$N8N_REDIS_PASSWORD@$N8N_REDIS_HOSTPORT"
    # Separate host and port
    N8N_REDIS_HOST="$(echo $N8N_REDIS_HOSTPORT | sed -e 's,:.*,,g')"
    N8N_REDIS_PORT="$(echo $N8N_REDIS_HOSTPORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    
    export QUEUE_BULL_REDIS_HOST=$N8N_REDIS_HOST
    export QUEUE_BULL_REDIS_PORT=$N8N_REDIS_PORT
    if [ -n "$N8N_REDIS_PASSWORD" ]; then
        export QUEUE_BULL_REDIS_PASSWORD=$N8N_REDIS_PASSWORD
    fi
    # Redis on Heroku typically uses SSL
    export QUEUE_BULL_REDIS_TLS=true
    # Disable TLS certificate verification for Heroku Redis (self-signed certificates)
    export QUEUE_BULL_REDIS_TLS_REJECT_UNAUTHORIZED=false
fi

if [ -n "$N8N_CUSTOM_EXTENSIONS" ]; then
    export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes:${N8N_CUSTOM_EXTENSIONS}"
else
    export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes"
fi

# Determine process type from DYNO variable (Heroku sets this)
# DYNO format: "web.1", "worker.1", "webhook.1", etc.
PROCESS_TYPE="web"
if [ -n "$DYNO" ]; then
    PROCESS_TYPE=$(echo "$DYNO" | cut -d. -f1)
fi

# If EXECUTIONS_MODE is set to queue, use appropriate command
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
    # Default mode - just start n8n normally
    echo "Starting n8n in regular mode..."
    n8n
fi
