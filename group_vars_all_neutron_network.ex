---
# Operator User
operate_user: stack
operate_user_home: /home/stack
# make_pass-> openssl passwd -salt openstack -1 stack
operate_user_password: $1$openstac$ZyvPxUXR5eJLA0ClbcZRe1

#VirtType
virt_type: kvm

# Proxy
#http_proxy: http://192.168.1.1:8080/
proxy_env:
  http_proxy: "{{ http_proxy }}"
  https_proxy: "{{ http_proxy }}"

# NIC
int_nic: eth0
ext_nic: eth1

# NTP Options
ntp_servers:
  - ntp1.jst.mfeed.ad.jp
  - ntp2.jst.mfeed.ad.jp
  - ntp3.jst.mfeed.ad.jp

# Controller Host IP's
controller_ext_ip: 192.168.10.50
controller_int_ip: 192.168.10.50

# MySQL Options
mysql_root_password: root

# Keystone Options
mysql_keystone_password: password
admin_token: ADMIN
cert_subject_cn: JP
cert_subject_st: Tokyo
cert_subject_ln: Chiyoda
cert_subject_on: openstack
cert_subject_cn: openstack.server
admin_tenant: admin
admin_user: admin
admin_password: secrete
generic_tenant01: stack
generic_user01: stack
generic_password01: secrete
generic_role01: admin
#generic_role01: Member

# Glance Options
mysql_glance_password: password
glance_keystone_password: secrete
glance_mq_user: glance
glance_mq_password: secrete
glance_image_tmp_dir: /opt/openstack/images

#Glance Image Options
#cirros_password: test

# Nova Options
mysql_nova_password: password
nova_keystone_password: secrete
nova_mq_user: nova
nova_mq_password: secrete

# Ceilometer Options
use_ceilometer: not_use
mysql_ceilometer_password: password
ceilometer_keystone_password: secrete
ceilometer_mq_user: ceilometer
ceilometer_mq_password: secrete
metering_secret: secrete

# Cinder Options
use_cinder: use
mysql_cinder_password: password
cinder_keystone_password: secrete
cinder_mq_user: cinder
cinder_mq_password: secrete
cinder_storage_node_ip: "{{ controller_int_ip }}"
#for lvm
use_loopback_device: not_use
cinder_backend: lvm
use_loopback_device: False
cinder_vg_name: cinder-volumes
#for nfs
#cinder_backend: nfs

# Network(for nova-network)
#network_type: nova-network
nova_networks:
  network01:
    fixed_range: 10.10.10.0/24
    dns1: 8.8.8.8
    bridge_interface: "{{ int_nic }}"
secgroup_rules:
  rule01:
    name: default
    protocol: tcp
    from_port: 22
    to_port: 22
    cidr: 0.0.0.0/0
  rule02:
    name: default
    protocol: icmp
    from_port: -1
    to_port: -1
    cidr: 0.0.0.0/0
float_ip_ranges:
  range01: 
    ranges: 192.168.10.112/28

# Network(for neutron)
#network_type: neutron-l3
network_type: neutron-flat
mysql_neutron_password: password
neutron_keystone_password: secrete
neutron_mq_user: neutron
neutron_mq_password: secrete
# For Neutron Flat
neutron_flat_networks:
  network01:
    name: sharednet1
    sbunet: 192.168.10.0/24
    ip_pool_start: 192.168.10.151
    iP_pool_end: 192.168.10.200
    dns1: 8.8.4.4
    dns2: 8.8.8.8
secgroup_rules:
  rule01:
    name: default
    protocol: tcp
    from_port: 22
    to_port: 22
    cidr: 0.0.0.0/0
  rule02:
    name: default
    protocol: icmp
    from_port: -1
    to_port: -1
    cidr: 0.0.0.0/0

# Keypair
keypaire_name: mykey

# Region
region: RegionOne

# Log Options
#log_debug: True
#log_verbose: True
log_debug: False
log_verbose: False
