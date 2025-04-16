#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
# sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# Replace ash with bash
sed -i 's/\/bin\/ash/\/bin\/bash/' package/base-files/files/etc/passwd

# Partition alignment
sed -i 's/256/4096/g' target/linux/x86/image/Makefile

# Change Xray version to 1.5
# Navigate to the xray-core package directory and modify the version
sed -i 's/PKG_VERSION:=v1.4.0/PKG_VERSION:=v1.8.24/' feeds/packages/net/xray-core/Makefile
# Xray-core v1.8.24
# You can also manually download and set a specific version for Xray here
# In case you're fetching the release via GitHub or custom sources, you can add additional steps if required
# Example of downloading the specific version if required
# curl -L https://github.com/XTLS/Xray-core/releases/download/v1.5.0/xray-linux-amd64-v1.5.0.tar.gz -o /tmp/xray-v1.5.0.tar.gz
# tar -xzf /tmp/xray-v1.5.0.tar.gz -C /tmp

