pacman -Syu --noconfirm
pacman -S --noconfirm base-devel wget dnsutils nginx cronie

########################################################################################################################
# SSL for quicksilver.zone
wget "http://tasks.web_config/config/quicksilver.zone-fullchain.pem" -O /etc/nginx/fullchain.pem
wget "http://tasks.web_config/config/quicksilver.zone-privkey.pem" -O /etc/nginx/privkey.pem

########################################################################################################################
# nginx
curl -s https://raw.githubusercontent.com/notional-labs/cosmosia/main/proxy_custom/quicksilver/nginx.conf > /etc/nginx/nginx.conf

########################################################################################################################
# generate config for the first time
curl -Ls "https://raw.githubusercontent.com/notional-labs/cosmosia/main/proxy_custom/quicksilver/generate_upstream.sh" > $HOME/generate_upstream.sh
sleep 1
source $HOME/generate_upstream.sh
echo "UPSTREAM_CONFIG_FILE=$UPSTREAM_CONFIG_FILE"
echo "UPSTREAM_CONFIG_FILE_TMP=$UPSTREAM_CONFIG_FILE_TMP"
sleep 1
cat "$UPSTREAM_CONFIG_FILE_TMP" > "$UPSTREAM_CONFIG_FILE"
sleep 1
#/usr/sbin/nginx -g "daemon off;"
/usr/sbin/nginx

########################################################################################################################
# cron
cat <<'EOT' >  $HOME/cron_update_upstream.sh
source $HOME/generate_upstream.sh
sleep 1

if cmp -s "$UPSTREAM_CONFIG_FILE" "$UPSTREAM_CONFIG_FILE_TMP"; then
  # the same => do nothing
  echo "no config change, do nothing..."
else
  # different

  # show the diff
  diff -c "$UPSTREAM_CONFIG_FILE" "$UPSTREAM_CONFIG_FILE_TMP"

  echo "found config changes, updating..."
  cat "$UPSTREAM_CONFIG_FILE_TMP" > "$UPSTREAM_CONFIG_FILE"
  sleep 1
  /usr/sbin/nginx -s reload
fi
EOT

sleep 1
echo "*/5 * * * * root /bin/bash $HOME/cron_update_upstream.sh" > /etc/cron.d/cron_update_upstream
sleep 1
crond

########################################################################################################################
## logrotate
#sed -i -e "s/{.*/{\n\tdaily\n\trotate 2/" /etc/logrotate.d/nginx
#sed -i -e "s/create.*/create 0644 root root/" /etc/logrotate.d/nginx

########################################################################################################################
echo "Done!"
# loop forever for debugging only
while true; do sleep 5; done
