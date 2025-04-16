
# Modify default IP
# sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# Replace ash with bash
sed -i 's/\/bin\/ash/\/bin\/bash/' package/base-files/files/etc/passwd

# Partition alignment
sed -i 's/256/4096/g' target/linux/x86/image/Makefile

# Navigate to the xray-core package directory and modify the version
sed -i 's/PKG_VERSION:=v1.4.0/PKG_VERSION:=v1.8.24/' feeds/packages/net/xray-core/Makefile

# Change system title to DotyWrt
sed -i 's/ImmortalWrt/DotyWrt/g' package/base-files/files/etc/banner
sed -i 's/ImmortalWrt/DotyWrt/g' package/base-files/files/bin/config_generate

# Change default WiFi SSID to DotyWrt
sed -i 's/ssid=ImmortalWrt/ssid=DotyWrt/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
