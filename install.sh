#!/bin/bash
#############################################################
#
# Xray for Alwaysdata.com (Updated 2026)
# Based on original work by: ifeng
# Updated with Shadowsocks support
# Repository: https://github.com/mrsoul000/alwaysdata
#
#############################################################

TMP_DIRECTORY=$(mktemp -d)

UUID=$(grep -o 'UUID=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/UUID=//')
VMESS_WSPATH=$(grep -o 'VMESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VMESS_WSPATH=//')
VLESS_WSPATH=$(grep -o 'VLESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VLESS_WSPATH=//')
SS_WSPATH=$(grep -o 'SS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/SS_WSPATH=//')
SS_PASSWORD=$(grep -o 'SS_PASSWORD=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/SS_PASSWORD=//')

UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
SS_WSPATH=${SS_WSPATH:-'/shadowsocks'}
SS_PASSWORD=${SS_PASSWORD:-$(head -c 16 /dev/urandom | base64 | tr -d '/+=')}
URL=${USER}.alwaysdata.net

# Download latest Xray (v1.8.x series - stable)
XRAY_VERSION="v1.8.23"
wget -q -O $TMP_DIRECTORY/xray.zip https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip
unzip -oq -d $HOME $TMP_DIRECTORY/xray.zip xray geoip.dat geosite.dat

# Download config template from your repository
wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/mrsoul000/alwaysdata/main/config.json

# Replace placeholders
sed -i "s#UUID#$UUID#g" $TMP_DIRECTORY/config.json
sed -i "s#VMESS_WSPATH#$VMESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#VLESS_WSPATH#$VLESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#SS_WSPATH#$SS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#SS_PASSWORD#$SS_PASSWORD#g" $TMP_DIRECTORY/config.json

cp $TMP_DIRECTORY/config.json $HOME
rm -rf $HOME/admin/tmp/*.*

# Advanced Settings for Apache
Advanced_Settings=$(cat <<-EOF
#UUID=${UUID}
#VMESS_WSPATH=${VMESS_WSPATH}
#VLESS_WSPATH=${VLESS_WSPATH}
#SS_WSPATH=${SS_WSPATH}
#SS_PASSWORD=${SS_PASSWORD}

ProxyRequests off
ProxyPreserveHost On
ProxyPass "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8300${VMESS_WSPATH}"
ProxyPassReverse "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8300${VMESS_WSPATH}"
ProxyPass "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
ProxyPassReverse "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
ProxyPass "${SS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8500${SS_WSPATH}"
ProxyPassReverse "${SS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8500${SS_WSPATH}"
EOF
)

# Generate links
vmlink=vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"Alwaysdata-VMess\",\"add\":\"$URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$URL\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\"}" | base64 -w 0)
vllink="vless://${UUID}@${URL}:443?encryption=none&security=tls&type=ws&host=${URL}&path=${VLESS_WSPATH}#Alwaysdata-VLess"

# Generate Shadowsocks SIP002 link
SS_BASE64=$(echo -n "2022-blake3-aes-128-gcm:${SS_PASSWORD}" | base64 -w 0)
sslink="ss://${SS_BASE64}@${URL}:443?path=${SS_WSPATH}&security=tls&type=ws&host=${URL}#Alwaysdata-Shadowsocks"

# Generate QR codes (if qrencode is available)
if command -v qrencode &> /dev/null; then
    qrencode -o $HOME/www/M$UUID.png $vmlink
    qrencode -o $HOME/www/L$UUID.png $vllink
    qrencode -o $HOME/www/S$UUID.png $sslink
fi

# ============================================
# CREATE SIMPLE HTML PAGE (NO COMPLEX FORMATTING)
# ============================================

PAGE_URL="https://${URL}/${UUID}.html"

cat > $HOME/www/$UUID.html <<-HTMLEOF
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Alwaysdata - Xray Nodes</title>
<style>
  body {
    font-family: Tahoma, sans-serif;
    background-color: #1a1a2e;
    color: #ffffff;
    padding: 20px;
    margin: 0;
  }
  .box {
    background-color: #16213e;
    border-radius: 10px;
    padding: 20px;
    margin: 15px auto;
    max-width: 800px;
  }
  h2 {
    color: #4CAF50;
    margin-top: 0;
  }
  .link {
    background-color: #0a0a1a;
    padding: 12px;
    border-radius: 5px;
    word-break: break-all;
    font-family: monospace;
    direction: ltr;
    text-align: left;
    margin: 10px 0;
    font-size: 13px;
    color: #a5d6a7;
  }
  button {
    background-color: #4CAF50;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 5px;
    cursor: pointer;
    font-size: 14px;
    margin: 5px;
  }
  button:hover {
    background-color: #45a049;
  }
  img {
    max-width: 200px;
    margin: 10px;
    background: white;
    padding: 5px;
    border-radius: 5px;
  }
  .qrcode {
    text-align: center;
    margin: 15px 0;
  }
</style>
</head>
<body>

<div class="box">
  <h2>🔵 VMESS</h2>
  <div class="link">${vmlink}</div>
  <button onclick="navigator.clipboard.writeText('${vmlink}')">📋 کپی VMess</button>
  <div class="qrcode">
    <img src="/M${UUID}.png" alt="VMess QR">
  </div>
</div>

<div class="box">
  <h2>🟣 VLESS</h2>
  <div class="link">${vllink}</div>
  <button onclick="navigator.clipboard.writeText('${vllink}')">📋 کپی VLESS</button>
  <div class="qrcode">
    <img src="/L${UUID}.png" alt="VLESS QR">
  </div>
</div>

<div class="box">
  <h2>🟢 Shadowsocks</h2>
  <div class="link">${sslink}</div>
  <button onclick="navigator.clipboard.writeText('${sslink}')">📋 کپی Shadowsocks</button>
  <div class="qrcode">
    <img src="/S${UUID}.png" alt="SS QR">
  </div>
</div>

</body>
</html>
HTMLEOF

# Create simple index page
cat > $HOME/www/index.html<<-EOF
<html>
<body style="background:#1a1a2e;color:white;text-align:center;padding-top:100px;font-family:Tahoma;">
<h1 style="color:#4CAF50;">Hello World</h1>
<p>Xray is running...</p>
</body>
</html>
EOF

clear

echo ""
echo "=============================================="
echo "  Xray for Alwaysdata"
echo "  Updated 2026"
echo "=============================================="
echo ""

echo "SERVICE Command (اینو کپی کن):"
echo "------------------------------------------------"
echo "./xray -config config.json"
echo "------------------------------------------------"
echo ""

echo "Advanced Settings (اینو کپی کن):"
echo "------------------------------------------------"
echo "$Advanced_Settings"
echo "------------------------------------------------"
echo ""

echo "لینک صفحه نودها:"
echo "------------------------------------------------"
echo "$PAGE_URL"
echo "------------------------------------------------"
echo ""

echo "Shadowsocks Password: $SS_PASSWORD"
echo ""
