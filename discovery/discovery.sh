#!/bin/sh

ETCD_INSTANCE_ROOT="/d4os/instances"

echo "Starting discovery loop"
while true; do
    # Get running instances from fleet
    #running_instances=$(curl -sSL http://${FLEET_ENDPOINT}:40009/fleet/v1/state | jq -r '.states[] | select(.systemdActiveState == "active") | select(.systemdSubState == "running") | .name' | cut -d '@' -f2 | cut -d '.' -f1 | tr -s "\n" ' ')
    running_units=$(curl -sSL http://${FLEET_ENDPOINT}:40009/fleet/v1/state | jq -r '.states[] | select(.systemdActiveState == "active") | select(.systemdSubState == "running") | .name' | tr -s "\n" ' ')
    for u in ${running_units}; do
        unit=${u%.service}
        service=${unit%@*}
    	instance=${unit##*@}
        # Set redis key with TTL of 3s
        redis-cli set ${ETCD_INSTANCE_ROOT}/${service}/${instance} '' EX 3 >/dev/null 2>&1
    done

    # Get fleet machine IPs
    fleet_machines=$(curl -sSL http://${FLEET_ENDPOINT}:40009/fleet/v1/machines | jq -r '.machines[] | .primaryIP' | tr -s "\n" ' ')
    for m in ${fleet_machines}; do
        # Set redis key with TTL of 3s
        redis-cli set ${ETCD_INSTANCE_ROOT}/fleet/${m} '' EX 3 >/dev/null 2>&1
        redis-cli set ${ETCD_INSTANCE_ROOT}/etcd/${m} '' EX 3 >/dev/null 2>&1
    done

    # Sleep for 2 seconds
    sleep 2
done
echo "Discovery canceled. Exiting"
