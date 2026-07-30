#!/bin/bash
#############################################################
#
# Xray for Alwaysdata.com (Updated 2026)
# Based on original work by: ifeng
# Updated with Shadowsocks support
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

# Download config template
wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/YOUR_USERNAME/V2ray-for-AlwaysData/main/config.json

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
sslink="ss://$(echo -n "2022-blake3-aes-128-gcm:${SS_PASSWORD}@${URL}:443?plugin=shadow-tls%3Bhost%3D${URL}%3Bpath%3D${SS_WSPATH}%3Bmode%3Dwebsocket" | base64 -w 0)#Alwaysdata-Shadowsocks"

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
#
#############################################################
EOF
)

# Create index page
cat > $HOME/www/index.html<<-EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Alwaysdata - Xray</title>
<style type="text/css">
body {
    font-family: Geneva, Arial, Helvetica, san-serif;
}
</style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
<div align="center"><b>Hello World</b></div>
</body>
</html>
EOF

# Create node info page
cat > $HOME/www/$UUID.html<<-EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Alwaysdata - Xray Nodes</title>
<style type="text/css">
body {
    font-family: Geneva, Arial, Helvetica, san-serif;
}
div {
    margin: 0 auto;
    text-align: left;
    white-space: pre-wrap;
    word-break: break-all;
    max-width: 80%;
    margin-bottom: 10px;
}
</style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
<div><font color="#009900"><b>VMESS协议链接：</b></font></div>
<div>$vmlink</div>
<div><font color="#009900"><b>VMESS协议二维码：</b></font></div>
<div><img src="/M$UUID.png"></div>
<div><font color="#009900"><b>VLESS协议链接：</b></font></div>
<div>$vllink</div>
<div><font color="#009900"><b>VLESS协议二维码：</b></font></div>
<div><img src="/L$UUID.png"></div>
<div><font color="#009900"><b>Shadowsocks协议链接：</b></font></div>
<div>$sslink</div>
<div><font color="#009900"><b>Shadowsocks二维码：</b></font></div>
<div><img src="/S$UUID.png"></div>
</body>
</html>
EOF

clear

echo -e "\e[32m$Author\e[0m"

echo -e "\n\e[33m请 COPY 以下绿色文字到 SERVICE Command* 中：\n\e[0m"
echo -e "\e[32m./xray -config config.json\e[0m"
echo -e "\n\e[33m请 COPY 以下绿色文字到 Advanced Settings 中：\n\e[0m"
echo -e "\e[32m$Advanced_Settings\e[0m"

echo -e "\n\e[33m点击以下链接获取节点信息：\n\e[0m"
echo -e "\e[32mhttps://$URL/$UUID.html\n\e[0m"

echo -e "\n\e[33mShadowsocks密码：\e[0m"
echo -e "\e[32m$SS_PASSWORD\n\e[0m"
