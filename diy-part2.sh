#!/bin/bash

# Replace ash with bash
sed -i 's/\/bin\/ash/\/bin\/bash/' package/base-files/files/etc/passwd
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' openwrt/package/lean/default-settings/files/zzz-default-settings
# Navigate to the xray-core package directory and modify the version
sed -i 's/PKG_VERSION:=v1.4.0/PKG_VERSION:=v1.8.24/' feeds/packages/net/xray-core/Makefile
