# CLI Cheat-Sheet — Hybrid Operations

Commands for the things you actually do at 03:00, or during a design review when
someone asks "what is it set to right now?"

---

## Google Cloud

### Interconnect and attachments

```bash
# What circuits exist, and are they up?
gcloud compute interconnects list \
  --format="table(name,location,linkType,operationalStatus,adminEnabled)"

gcloud compute interconnects describe DX_NAME \
  --format="yaml(name,operationalStatus,expectedOutages,circuitInfos,macsec)"

# VLAN attachments — check MTU and bandwidth here, this is where they live
gcloud compute interconnects attachments list \
  --format="table(name,region,type,mtu,bandwidth,state,router.basename())"

gcloud compute interconnects attachments dedicated describe VA_NAME \
  --region=REGION \
  --format="yaml(mtu,bandwidth,vlanTag8021q,cloudRouterIpAddress,customerRouterIpAddress,state,encryption)"
```

### Cloud Router and BGP

```bash
# BGP session state and learned/advertised prefix counts — the first thing to check
gcloud compute routers get-status ROUTER_NAME --region=REGION \
  --format="yaml(result.bgpPeerStatus[].name,
                 result.bgpPeerStatus[].state,
                 result.bgpPeerStatus[].status,
                 result.bgpPeerStatus[].numLearnedRoutes,
                 result.bgpPeerStatus[].uptime)"

# What are we advertising?
gcloud compute routers describe ROUTER_NAME --region=REGION \
  --format="yaml(bgp.advertiseMode,bgp.advertisedGroups,bgp.advertisedIpRanges)"

# Confirm BFD is actually on — a very common gap
gcloud compute routers describe ROUTER_NAME --region=REGION \
  --format="yaml(bgpPeers[].name,bgpPeers[].bfd,bgpPeers[].advertisedRoutePriority)"

# Effective routes on a VPC, filtered to dynamic (BGP-learned)
gcloud compute routes list --filter="network=VPC_NAME AND nextHopHub:*" \
  --format="table(name,destRange,priority,nextHopHub)"
```

### Network Connectivity Center

```bash
gcloud network-connectivity hubs list
gcloud network-connectivity spokes list --global \
  --format="table(name,hub.basename(),state,location)"
```

### Diagnostics

```bash
# Connectivity Tests — the fastest way to prove or disprove a path
gcloud network-management connectivity-tests create test-onprem \
  --source-instance=projects/P/zones/Z/instances/I \
  --destination-ip-address=10.0.1.10 \
  --destination-port=443 --protocol=TCP

gcloud network-management connectivity-tests describe test-onprem \
  --format="yaml(reachabilityDetails)"

# Firewall rules that would apply to an instance
gcloud compute instances network-interfaces get-effective-firewalls NAME --zone=ZONE
```

### Placement and machine config

```bash
# Compact placement policies in use
gcloud compute resource-policies list \
  --filter="groupPlacementPolicy:*" \
  --format="table(name,region,groupPlacementPolicy.collocation,groupPlacementPolicy.maxDistance)"

# Is Tier_1 networking on, and is gVNIC in use?
gcloud compute instances describe NAME --zone=ZONE \
  --format="yaml(networkInterfaces[].nicType,
                 networkPerformanceConfig.totalEgressBandwidthTier)"
```

### GKE

```bash
# Is the cluster REGIONAL? (zonal clusters do not survive a zone outage)
gcloud container clusters list \
  --format="table(name,location,locationType,status,currentMasterVersion,releaseChannel.channel)"

# Private cluster, Workload Identity, Binary Authorization — the three that
# most often turn out not to be set
gcloud container clusters describe CLUSTER --region=REGION \
  --format="yaml(privateClusterConfig.enablePrivateNodes,
                 privateClusterConfig.enablePrivateEndpoint,
                 masterAuthorizedNetworksConfig,
                 workloadIdentityConfig.workloadPool,
                 binaryAuthorization,
                 databaseEncryption)"

# Node pools and their placement
gcloud container node-pools list --cluster=CLUSTER --region=REGION \
  --format="table(name,config.machineType,initialNodeCount,autoscaling.maxNodeCount)"

# Any workload still using a node service account instead of Workload Identity?
kubectl get sa -A -o json | jq -r '
  .items[] | select(.metadata.annotations["iam.gke.io/gcp-service-account"] == null)
  | "\(.metadata.namespace)/\(.metadata.name)"' | head -30
```

### Cloud Run

```bash
# Ingress setting — internal vs public is the first thing to check
gcloud run services list --region=REGION \
  --format="table(metadata.name,
                  metadata.annotations['run.googleapis.com/ingress'],
                  status.url)"

# Anything invokable by allUsers? Should be empty in an internal estate.
for s in $(gcloud run services list --region=REGION --format="value(metadata.name)"); do
  if gcloud run services get-iam-policy "$s" --region=REGION --format=json \
       | grep -q allUsers; then echo "PUBLIC: $s"; fi
done

# Concurrency, CPU allocation and scaling — the settings that drive cost
gcloud run services describe SERVICE --region=REGION \
  --format="yaml(spec.template.spec.containerConcurrency,
                 spec.template.metadata.annotations)"
```

### Vertex AI and private inference

```bash
# Endpoints — are any public?
gcloud ai endpoints list --region=REGION \
  --format="table(displayName,name,network,dedicatedEndpointEnabled)"

# VPC Service Controls perimeters and what they protect
gcloud access-context-manager perimeters list --policy=POLICY_ID
gcloud access-context-manager perimeters describe PERIMETER --policy=POLICY_ID \
  --format="yaml(status.restrictedServices,status.resources,status.accessLevels)"

# Private Service Connect endpoints in the VPC
gcloud compute forwarding-rules list \
  --filter="target~serviceAttachments OR pscConnectionId:*" \
  --format="table(name,region,IPAddress,target,pscConnectionStatus)"
```

---

## AWS

### Direct Connect

```bash
# Connections and their MACsec state
aws directconnect describe-connections \
  --query 'connections[].{Name:connectionName,State:connectionState,
                          Bw:bandwidth,Loc:location,
                          MacSec:macSecCapable,Encryption:encryptionMode}' \
  --output table

# Virtual interfaces — MTU lives here. Transit VIF max 8500, private VIF 9001.
aws directconnect describe-virtual-interfaces \
  --query 'virtualInterfaces[].{Name:virtualInterfaceName,Type:virtualInterfaceType,
                                State:virtualInterfaceState,VLAN:vlan,MTU:mtu,
                                BGP:bgpPeers[0].bgpPeerState,
                                BGPStatus:bgpPeers[0].bgpStatus}' \
  --output table

# Direct Connect Gateway associations and allowed prefixes
aws directconnect describe-direct-connect-gateway-associations \
  --query 'directConnectGatewayAssociations[].{DXGW:directConnectGatewayId,
            Assoc:associatedGateway.id,State:associationState,
            Prefixes:allowedPrefixesToDirectConnectGateway[].cidr}'
```

### Transit Gateway

```bash
# TGW config — check multicast_support and default association settings
aws ec2 describe-transit-gateways \
  --query 'TransitGateways[].{Id:TransitGatewayId,State:State,
            ASN:Options.AmazonSideAsn,
            Multicast:Options.MulticastSupport,
            DefaultAssoc:Options.DefaultRouteTableAssociation}' --output table

# Attachments
aws ec2 describe-transit-gateway-attachments \
  --query 'TransitGatewayAttachments[].{Id:TransitGatewayAttachmentId,
            Type:ResourceType,Res:ResourceId,State:State}' --output table

# Search a route table — "why is this prefix not reachable?"
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id tgw-rtb-XXXX \
  --filters "Name=type,Values=static,propagated" \
  --query 'Routes[].{CIDR:DestinationCidrBlock,State:State,Type:Type}' --output table
```

### Multicast

```bash
# Domains
aws ec2 describe-transit-gateway-multicast-domains \
  --query 'TransitGatewayMulticastDomains[].{Id:TransitGatewayMulticastDomainId,
            State:State,Static:Options.StaticSourcesSupport,
            IGMP:Options.Igmpv2Support}' --output table

# Who is registered as a source / member right now?
aws ec2 search-transit-gateway-multicast-groups \
  --transit-gateway-multicast-domain-id tgw-mcast-domain-XXXX \
  --query 'MulticastGroups[].{Group:GroupIpAddress,ENI:NetworkInterfaceId,
            Source:GroupSource,Member:GroupMember,State:MemberType}' --output table

# Register a source (static mode — the on-prem bridging router's ENI)
aws ec2 register-transit-gateway-multicast-group-sources \
  --transit-gateway-multicast-domain-id tgw-mcast-domain-XXXX \
  --group-ip-address 233.54.12.1 \
  --network-interface-ids eni-XXXX
```

### Diagnostics

```bash
# Reachability Analyzer — the AWS equivalent of Connectivity Tests
aws ec2 create-network-insights-path \
  --source eni-SOURCE --destination eni-DEST --protocol tcp --destination-port 443

aws ec2 start-network-insights-analysis --network-insights-path-id nip-XXXX
aws ec2 describe-network-insights-analyses --network-insights-analysis-ids nia-XXXX \
  --query 'NetworkInsightsAnalyses[0].{Reachable:NetworkPathFound,
            Blocker:Explanations[0]}'
```

### Placement and time sync

```bash
# Which placement group is an instance in?
aws ec2 describe-instances --instance-ids i-XXXX \
  --query 'Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,
            AZ:Placement.AvailabilityZone,PG:Placement.GroupName}' --output table

# On the instance — is the PTP hardware clock present?
ls -l /dev/ptp*
sudo chronyc sources -v
sudo chronyc tracking          # 'System time' and 'Root dispersion' are the numbers
                               # to record for MiFID II evidence
```

---

## Path Validation

Run these from both ends of every circuit, on a schedule, not only during
incidents.

```bash
# MTU discovery: largest packet that survives with DF set.
# Payload + 28 bytes of IP/ICMP header = actual MTU.
# 8472 payload => 8500 MTU (AWS transit VIF ceiling)
# 8868 payload => 8896 MTU (GCP jumbo attachment)
ping -M do -s 8472 -c 3 <remote-ip>
ping -M do -s 1472 -c 3 <remote-ip>   # 1500 baseline

# Binary-search the real ceiling
for size in 1472 4000 8000 8472 8868; do
  printf "%5s: " "$size"
  ping -M do -s "$size" -c 1 -W 2 <remote-ip> >/dev/null 2>&1 && echo OK || echo FAIL
done

# Path and per-hop loss — mtr gives loss per hop, traceroute does not
mtr -rwzbc 100 <remote-ip>

# Latency distribution, not the average. p99 is the number that matters.
ping -c 1000 -i 0.01 <remote-ip> | \
  awk -F'time=' '/time=/{print $2+0}' | sort -n | \
  awk '{a[NR]=$1} END {printf "p50=%.3f p95=%.3f p99=%.3f max=%.3f ms\n",
        a[int(NR*0.50)], a[int(NR*0.95)], a[int(NR*0.99)], a[NR]}'

# Throughput, multi-stream, both directions
iperf3 -c <remote-ip> -P 8 -t 60
iperf3 -c <remote-ip> -P 8 -t 60 -R
```

---

## Multicast Verification (on-instance)

```bash
# Is the interface actually in the group?
ip maddr show dev eth0
netstat -gn

# Watch for group traffic
sudo tcpdump -i eth0 -n 'multicast' -c 100

# Join and receive (socat)
socat UDP4-RECVFROM:PORT,ip-add-membership=GROUP:eth0,fork -

# Send (Nitro instances only — non-Nitro cannot be multicast senders)
socat - UDP4-DATAGRAM:GROUP:PORT,ip-multicast-ttl=8
```

---

## Guardrail and Posture Sweep

Run across the estate periodically, not only before an audit.

```bash
# --- GCP ---

# Org policies actually in force on a project
gcloud resource-manager org-policies list --project=PROJECT

# Are Data Access logs enabled? (off by default; a common audit finding)
gcloud projects get-iam-policy PROJECT --format=json \
  | jq '.auditConfigs // "NO AUDIT CONFIGS — Data Access logs are OFF"'

# Buckets without a retention policy, in a project that should have them
gcloud storage buckets list --project=PROJECT --format=json \
  | jq -r '.[] | select(.retention_policy == null) | .name'

# Service account keys in existence — each one is a finding
for sa in $(gcloud iam service-accounts list --project=PROJECT --format="value(email)"); do
  n=$(gcloud iam service-accounts keys list --iam-account="$sa" \
        --managed-by=user --format="value(name)" | wc -l)
  [ "$n" -gt 0 ] && echo "$sa has $n user-managed key(s)"
done

# --- AWS ---

# SCPs attached to an OU
aws organizations list-policies-for-target --target-id OU_ID \
  --filter SERVICE_CONTROL_POLICY --query 'Policies[].{Name:Name,Id:Id}' --output table

# S3 buckets without Object Lock, where retention is required
for b in $(aws s3api list-buckets --query 'Buckets[].Name' --output text); do
  aws s3api get-object-lock-configuration --bucket "$b" >/dev/null 2>&1 \
    || echo "NO OBJECT LOCK: $b"
done

# IAM users with active access keys — should be zero in a federated estate
aws iam list-users --query 'Users[].UserName' --output text | tr '\t' '\n' | \
while read -r u; do
  k=$(aws iam list-access-keys --user-name "$u" \
        --query 'AccessKeyMetadata[?Status==`Active`]|length(@)')
  [ "$k" -gt 0 ] && echo "$u has $k active key(s)"
done
```

---

## Quick Sanity Sweep

Run before declaring a hybrid path production-ready.

```bash
# 1. Both clouds: every BGP session Established?
gcloud compute routers get-status ROUTER --region=REGION \
  --format="value(result.bgpPeerStatus[].state)"
aws directconnect describe-virtual-interfaces \
  --query 'virtualInterfaces[].bgpPeers[].bgpPeerState' --output text

# 2. BFD on every session?  (GCP shows it; on AWS confirm on your router)
gcloud compute routers describe ROUTER --region=REGION \
  --format="value(bgpPeers[].bfd.sessionInitializationMode)"

# 3. MTU consistent end to end?
#    Compare the GCP attachment mtu, the AWS VIF mtu, and the measured ping ceiling.

# 4. Prefix counts sane — no leaked full table, nothing missing?
gcloud compute routers get-status ROUTER --region=REGION \
  --format="value(result.bgpPeerStatus[].numLearnedRoutes)"

# 5. Failover actually tested? Shut one session, measure, restore, record the number.
```

---

## Microsecond Latency and Kernel Scheduling (HFT)

`ping`'s p99 in the Path Validation section is millisecond-resolution — fine
for a hybrid circuit, too coarse for the microsecond RTTs and scheduling
jitter this skill's low-latency guidance is built on
(`03-low-latency-market-data.md`, `07-verified-facts.md` §7, §26). Use these
to actually measure what that guidance assumes.

```bash
# --- Instance-to-instance RTT, microsecond resolution ---
# sockperf is the standard tool for this — ICMP ping cannot resolve the
# numbers in 07-verified-facts.md §7 (GCP C4: p50 15µs / p99 22µs).
# Server side:
sockperf server -p 12345
# Client side — ping-pong gives per-message latency, ping-pong summary gives percentiles:
sockperf ping-pong -i <server-ip> -p 12345 -t 30 --full-log /tmp/sockperf.log
sockperf ping-pong -i <server-ip> -p 12345 -t 30 --pps=max   # under load, not just idle

# --- Kernel scheduling latency ---
# cyclictest is what produced the 63µs (standard kernel) vs 50µs (PREEMPT_RT)
# data point in 07-verified-facts.md §26. Run on the isolated cores specifically.
sudo cyclictest -m -Sp99 -i 200 -h 400 -D 60 -a <isolated-cpu-list>

# --- Confirm CPU isolation is actually in effect, not just configured ---
cat /sys/devices/system/cpu/isolated
cat /proc/cmdline | tr ' ' '\n' | grep -E 'isolcpus|nohz_full|rcu_nocbs'
numactl --hardware                         # confirm NUMA node boundaries
taskset -pc <pid>                          # which cores is the hot-path process actually on?

# --- Hugepages actually allocated, not just requested ---
grep -i huge /proc/meminfo
cat /sys/kernel/mm/transparent_hugepage/enabled   # THP should be 'never' on the hot path

# --- NIC-level drops and ring buffer occupancy ---
# ties to the "Ring buffer sizing" guidance in 03-low-latency-market-data.md §4
ethtool -S eth0 | grep -iE 'drop|discard|error|overrun'
ethtool -g eth0                            # current vs max ring sizes

# --- Real-time scheduling priority of the hot-path process ---
chrt -p <pid>
```
