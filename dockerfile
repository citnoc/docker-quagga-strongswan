# docker-quagga-strongswan
FROM            centos:7

# CentOS
RUN     yum clean all && yum -y update && \        
	yum -y install --setopt=tsflags=nodocs bind-utils pwgen psmisc hostname nc which nano epel-release && \ 
	yum -y erase vim-minimal && \
	yum -y update && yum clean all

# strongSWAN
RUN	yum -y install strongswan
RUN	cp -rp /etc/strongswan /usr/share/
RUN	mv /usr/share/strongswan/strongswan.d/charon-logging.conf /usr/share/strongswan/strongswan.d/charon-logging.conf-dist
ADD	charon-logging.conf /usr/share/strongswan/strongswan.d/charon-logging.conf

# Quagga
RUN     yum -y install quagga
RUN     mkdir -p /usr/share/quagga
ADD     bgpd.conf /usr/share/quagga/bgpd.conf
ADD     ospf6d.conf /usr/share/quagga/ospf6d.conf
ADD     ospfd.conf /usr/share/quagga/ospfd.conf
ADD     ripd.conf /usr/share/quagga/ripd.conf
ADD     ripngd.conf /usr/share/quagga/ripngd.conf
ADD     vtysh.conf /usr/share/quagga/vtysh.conf
ADD     zebra.conf /usr/share/quagga/zebra.conf

# Zebra2
ADD	zebra2 /usr/sbin/zebra2
RUN	chmod +x /usr/sbin/zebra2

# Routing
RUN	yum -y install iproute traceroute
RUN     echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Bootstrap
ADD     bootstrap.sh /bootstrap.sh
RUN     chmod +x /bootstrap.sh
CMD     sh /bootstrap.sh
