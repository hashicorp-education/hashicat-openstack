[[local|localrc]]
HOST_IP=${public_ip}
FORCE=yes
ADMIN_PASSWORD=${password}
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD

# Enable Swift
enable_service s-proxy s-object s-container s-account
SWIFT_REPLICAS=1
SWIFT_HASH=66a3d6b56c1f479c8b4e70ab5c2000f5
SWIFT_DATA_DIR=/opt/stack/data/swift

# Disable services
disable_service etcd3
disable_service ovn
disable_service ovn-controller
disable_service ovn-northd
disable_service q-ovn-metadata-agent

# Use openvswitch as the ml2 plugin driver
Q_AGENT=openvswitch

# Enable Neutron services neutron-server, neutron-openvswitch-agent,
# neutron-dhcp-agent, neutron-l3-agent and neutron-metadata-agent
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta

## Neutron options
#Q_USE_SECGROUP=True
FLOATING_RANGE="192.168.100.0/24"
IPV4_ADDRS_SAFE_TO_USE="10.0.0.0/22"
Q_FLOATING_ALLOCATION_POOL=start=192.168.100.50,end=192.168.100.250
PUBLIC_NETWORK_GATEWAY="192.168.100.1"
PUBLIC_INTERFACE=mybr0

# Open vSwitch provider networking configuration
Q_USE_PROVIDERNET_FOR_PUBLIC=True
OVS_PHYSICAL_BRIDGE=br-ex
PUBLIC_BRIDGE=br-ex
OVS_BRIDGE_MAPPINGS=public:br-ex

[[post-config|/$Q_PLUGIN_CONF_FILE]]
[ml2]
type_drivers=flat,gre,vlan,vxlan
tenant_network_types=vxlan
mechanism_drivers=openvswitch,l2population

[agent]
tunnel_types=vxlan,gre