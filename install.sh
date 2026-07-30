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

Author=$(cat <<-EOF
#############################################################
#
# Xray for Alwaysdata.com
# Original Author: ifeng
# Updated with Shadowsocks & Xray
# Repository: https://github.com/mrsoul000/alwaysdata
#
#############################################################
EOF
)

# Create index page
cat > $HOME/www/index.html<<-EOF
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Alwaysdata - Xray</title>
<style>
  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #1e1e1e;
    color: #e0e0e0;
    margin: 0;
    padding: 20px;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
  }
  .container {
    text-align: center;
  }
  h1 {
    color: #4CAF50;
    font-size: 3em;
    margin: 0;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
  }
  p {
    color: #888;
    font-size: 1.2em;
  }
</style>
</head>
<body>
<div class="container">
  <h1>Hello World</h1>
  <p>Xray is running...</p>
</div>
</body>
</html>
EOF

# Create node info page 
PAGE_FILE="$HOME/www/$UUID.html"

cat > "$PAGE_FILE" <<-HTMLEOF
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Alwaysdata - Xray Nodes</title>
<style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #1a1a2e;
    color: #e0e0e0;
    padding: 20px;
    direction: rtl;
  }
  .container {
    max-width: 900px;
    margin: 0 auto;
    background: linear-gradient(135deg, #16213e 0%, #0f3460 100%);
    border-radius: 20px;
    padding: 30px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.5);
  }
  .header {
    text-align: center;
    margin-bottom: 30px;
    color: #e94560;
    font-size: 2em;
    font-weight: bold;
  }
  .section {
    background-color: rgba(255,255,255,0.05);
    border-radius: 15px;
    padding: 20px;
    margin-bottom: 25px;
    border: 1px solid rgba(255,255,255,0.1);
  }
  .section h2 {
    color: #4CAF50;
    margin-bottom: 15px;
    font-size: 1.5em;
  }
  .link-box {
    background-color: #0a0a1a;
    padding: 15px;
    border-radius: 10px;
    word-break: break-all;
    font-family: 'Courier New', monospace;
    font-size: 13px;
    border: 1px solid #333;
    margin: 15px 0;
    direction: ltr;
    text-align: left;
    color: #a5d6a7;
    overflow-x: auto;
    white-space: pre-wrap;
  }
  .qr-container {
    text-align: center;
    margin: 20px 0;
  }
  .qr-container img {
    max-width: 200px;
    border: 3px solid #4CAF50;
    border-radius: 10px;
    background: white;
    padding: 10px;
  }
  .copy-btn {
    background-color: #4CAF50;
    color: white;
    border: none;
    padding: 10px 25px;
    border-radius: 25px;
    cursor: pointer;
    font-size: 14px;
    font-weight: bold;
    transition: all 0.3s;
    margin: 5px;
  }
  .copy-btn:hover {
    background-color: #45a049;
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(76, 175, 80, 0.3);
  }
  .alert {
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background-color: #4CAF50;
    color: white;
    padding: 15px 30px;
    border-radius: 30px;
    z-index: 1000;
    display: none;
  }
</style>
</head>
<body>

<div id="alertBox" class="alert">✅ لینک با موفقیت کپی شد!</div>

<div class="container">
  <div class="header">
    🚀 Alwaysdata Xray Nodes
  </div>

  <div class="section">
    <h2>🔵 VMESS پروتکل</h2>
    <div class="link-box" id="vmessLink">${vmlink}</div>
    <button class="copy-btn" onclick="copyText('vmessLink')">📋 کپی لینک VMess</button>
    <div class="qr-container">
      <img src="/M${UUID}.png" alt="VMess QR Code" onerror="this.parentElement.style.display='none'">
    </div>
  </div>

  <div class="section">
    <h2>🟣 VLESS پروتکل</h2>
    <div class="link-box" id="vlessLink">${vllink}</div>
    <button class="copy-btn" onclick="copyText('vlessLink')">📋 کپی لینک VLESS</button>
    <div class="qr-container">
      <img src="/L${UUID}.png" alt="VLESS QR Code" onerror="this.parentElement.style.display='none'">
    </div>
  </div>

  <div class="section">
    <h2>🟢 Shadowsocks پروتکل</h2>
    <div class="link-box" id="ssLink">${sslink}</div>
    <button class="copy-btn" onclick="copyText('ssLink')">📋 کپی لینک Shadowsocks</button>
    <div class="qr-container">
      <img src="/S${UUID}.png" alt="Shadowsocks QR Code" onerror="this.parentElement.style.display='none'">
    </div>
  </div>
</div>

<script>
function copyText(elementId) {
  var text = document.getElementById(elementId).innerText;
  navigator.clipboard.writeText(text).then(function() {
    var alertBox = document.getElementById('alertBox');
    alertBox.style.display = 'block';
    setTimeout(function() {
      alertBox.style.display = 'none';
    }, 2000);
  });
}
</script>

</body>
</html>
HTMLEOF

clear

echo -e "\e[32m$Author\e[0m"

echo -e "\n\e[33mلطفا متن سبز زیر را در قسمت SERVICE Command* کپی کنید:\n\e[0m"
echo -e "\e[32m./xray -config config.json\e[0m"
echo -e "\n\e[33mلطفا متن سبز زیر را در قسمت Advanced Settings کپی کنید:\n\e[0m"
echo -e "\e[32m$Advanced_Settings\e[0m"

echo -e "\n\e[33mبرای دریافت اطلاعات نود روی لینک زیر کلیک کنید:\n\e[0m"
echo -e "\e[32mhttps://$URL/$UUID.html\n\e[0m"

echo -e "\n\e[33mShadowsocks رمز عبور:\e[0m"
echo -e "\e[32m$SS_PASSWORD\n\e[0m"
