if [ -d /var/etc/strongswan ]; then
  rm -rf /etc/strongswan
  ln -s /var/etc/strongswan /etc/strongswan
fi
if [ ! -f /etc/strongswan/strongswan.conf ]; then
  echo "To enable strongswan: cp -rp /usr/share/strongswan/* /etc/strongswan/" >/etc/strongswan/README.txt
else
  rm -f /etc/strongswan/README.txt
fi

if [ -d /var/etc/quagga ]; then
  rm -rf /etc/quagga
  ln -s /var/etc/quagga /etc/quagga
fi
if [ ! -f /etc/quagga/vtysh.conf ]; then cp /usr/share/quagga/vtysh.conf /etc/quagga/; fi
if [ ! -f /etc/quagga/zebra.conf ]; then cp /usr/share/quagga/zebra.conf /etc/quagga/; fi
if [ ! -f /etc/quagga/bgpd.conf ]; then cp /usr/share/quagga/bgpd.conf /etc/quagga/; fi
chown -R quagga:root /var/etc/quagga

touch /var/log/quagga/bgpd.log
touch /var/log/quagga/ospf6d.log
touch /var/log/quagga/ospfd.log
touch /var/log/quagga/ripd.log
touch /var/log/quagga/ripngd.log
touch /var/log/quagga/zebra.log
chown -R quagga:root /var/log/quagga
chmod -R 760 /var/log/quagga

if [ -f /etc/strongswan/strongswan.conf ]; then /usr/sbin/strongswan start; fi
if [ -f /etc/quagga/zebra.conf ]; then zebra -d; fi
if [ -f /etc/quagga/bgpd.conf ]; then bgpd -d; fi
if [ -f /etc/quagga/ospfd.conf ]; then ospfd -d; fi
if [ -f /etc/quagga/ospf6d.conf ]; then ospf6d -d; fi
if [ -f /etc/quagga/ripd.conf ]; then ripd -d; fi
if [ -f /etc/quagga/ripngd.conf ]; then ripngd -d; fi

if pgrep -x bgpd > /dev/null; then 
  if pgrep -x zebra > /dev/null; then
    while pgrep -x zebra > /dev/null; do sleep 1; done
  else
    /usr/sbin/zebra2 &>/var/log/quagga/zebra2.log
  fi
fi
