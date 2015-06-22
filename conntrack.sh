#!/bin/bash
# higher conntrack limit
echo "ip_conntrack" >> /etc/modules
/sbin/modprobe ip_conntrack
/sbin/sysctl -w net.netfilter.nf_conntrack_max=991072

