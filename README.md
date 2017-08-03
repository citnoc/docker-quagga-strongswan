Docker - Quagga / StrongSWAN
============================
This router containers supports several daemons and protocols for routing and VPN functionality, and has an alternative route processing mechanism to allow operation without privileged mode. The container's main function are suppored by the following daemons:
+ StrongSWAN (IPsec)
+ Quagga (BGP, OSPF, RIP etc)

#### StrongSWAN
Strongswan is disabled by default. To enable StrongSWAN, copy the default configuration files from /usr/share/strongswan to /etc/strongswan and start the StrongSWAN daemon manually.
```
cp -rp /usr/share/strongswan/* /etc/strongswan/
/usr/sbin/strongswan start
```

#### Quagga
Default routing and BGP are enabled by default. To enable other protocols like OSPF, copy the config file from /usr/share/quagga to /etc/quagga and start the daemon manually.
```
cp /usr/share/quagga/ospfd.conf /etc/quagga/
ospfd -d
```

#### Route processing alternative
Quagga's routing daemon (zebra) requires privileged mode, wich is a security issue. To be able to run BGP without privileged mode this container provides a simple script (zebra2) to process routes obtained by BGP. Beware that the alternative still needs additional privileges to be able to run BGP and add routes (NET_ADMIN, NET_BROADCAST). At startup, the container automatically starts zebra or zebra2, depending on the detected environment.

#### Starting the container
Non-privileged:
```
mkdir -p /citnoc/router/etc/{strongswan,quagga}
mkdir -p /citnoc/router/log/{strongswan,quagga}
docker run -d \
-v /citnoc/router/etc/strongswan:/var/etc/strongswan -v /citnoc/router/log/strongswan:/var/log/strongswan \
-v /citnoc/router/etc/quagga:/var/etc/quagga -v /citnoc/router/log/quagga:/var/log/quagga \
--net network1 --ip 10.100.0.1 --cap-add NET_ADMIN --cap-add NET_BROADCAST --name router1 img_router
```
Privileged:
```
mkdir -p /citnoc/router/etc/{strongswan,quagga}
mkdir -p /citnoc/router/log/{strongswan,quagga}
docker run -d \
-v /citnoc/router/etc/strongswan:/var/etc/strongswan -v /citnoc/router/log/strongswan:/var/log/strongswan \
-v /citnoc/router/etc/quagga:/var/etc/quagga -v /citnoc/router/log/quagga:/var/log/quagga \
--net network1 --ip 10.100.0.1 --privileged --name router1 img_router
```

### BGP Example network
```
docker network create --driver macvlan --subnet=10.8.0.0/24 -o parent=eth0 MGMT
docker network create --driver macvlan --subnet=10.1.0.0/24 PRV1
docker network create --driver macvlan --subnet=10.2.0.0/24 PRV2

mkdir -p /citnoc/AS65001/{etc/quagga,log/quagga}
mkdir -p /citnoc/AS65002/{etc/quagga,log/quagga}
mkdir -p /citnoc/AS64961/{etc/quagga,log/quagga}
mkdir -p /citnoc/AS65261/{etc/quagga,log/quagga}
mkdir -p /citnoc/AS65530/{etc/quagga,log/quagga}

docker run -d --privileged --net MGMT --ip=10.8.0.11 -v /citnoc/AS65001/etc/quagga:/var/etc/quagga -v /citnoc/AS65001/log/quagga:/var/log/quagga --name AS65001 -t img_bgp
docker run -d --privileged --net MGMT --ip=10.8.0.12 -v /citnoc/AS65002/etc/quagga:/var/etc/quagga -v /citnoc/AS65002/log/quagga:/var/log/quagga --name AS65002 -t img_bgp
docker network connect --ip=10.1.0.11 PRV1 AS65001
docker network connect --ip=10.1.0.12 PRV1 AS65002

docker run -d --privileged --net PRV1 --ip=10.1.0.21 -v /citnoc/AS64961/etc/quagga:/var/etc/quagga -v /citnoc/AS64961/log/quagga:/var/log/quagga --name AS64961 -t img_bgp
docker run -d --privileged --net PRV1 --ip=10.1.0.22 -v /citnoc/AS65261/etc/quagga:/var/etc/quagga -v /citnoc/AS65261/log/quagga:/var/log/quagga --name AS65261 -t img_bgp
docker run -d --privileged --net PRV1 --ip=10.1.0.23 -v /citnoc/AS65530/etc/quagga:/var/etc/quagga -v /citnoc/AS65530/log/quagga:/var/log/quagga --name AS65530 -t img_bgp
docker network connect --ip=10.2.0.23 PRV2 AS65530

docker exec -it AS65001 vtysh
conf t
no router bgp 65001
router bgp 65001
 bgp router-id 10.8.0.11
 neighbor 10.8.0.12 remote-as 65002
 neighbor 10.1.0.21 remote-as 64961
exit
exit
wr
exit

docker exec -it AS65002 vtysh
conf t
no router bgp 65001
router bgp 65002
 bgp router-id 10.8.0.12
 neighbor 10.8.0.11 remote-as 65001
 neighbor 10.1.0.22 remote-as 65261
exit
exit
wr
exit

docker exec -it AS64961 vtysh
conf t
no router bgp 65001
router bgp 64961
 bgp router-id 10.1.0.21
 neighbor 10.1.0.11 remote-as 65001
 neighbor 10.1.0.23 remote-as 65530
exit
exit
wr
exit

docker exec -it AS65261 vtysh
conf t
no router bgp 65001
router bgp 65261
 bgp router-id 10.1.0.22
 neighbor 10.1.0.12 remote-as 65002
 neighbor 10.1.0.23 remote-as 65530
exit
exit
wr
exit

docker exec -it AS65530 vtysh
conf t
no router bgp 65001
router bgp 65530
 bgp router-id 10.8.0.23
 network 10.2.0.0/24
 neighbor 10.1.0.21 remote-as 64961
 neighbor 10.1.0.22 remote-as 65261
exit
exit
wr
exit
```
