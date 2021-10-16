include $(TOPDIR)/rules.mk

PKG_NAME:=clash
PKG_VERSION:=1.7.1
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/Dreamacro/clash/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=18c2ef10df608392435a1277d3f2e256c65bec3662bf0a6c325f02be6deb4fce

PKG_MAINTAINER:=chandelures <me@chandelure.com>
PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DIR:=$(BUILD_DIR)/clash-$(PKG_VERSION)
PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1

GO_PKG:=github.com/Dreamacro/clash
GO_PKG_BUILD_PKG:=$(GO_PKG)
GO_PKG_LDFLAGS_X:= \
	$(GO_PKG)/constant.Version=$(PKG_VERSION) 

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/../feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
	TITLE:=A rule-based tunnel in Go
	SECTION:=net
	CATEGORY:=Network
	URL:=https://github.com/dreamacro/clash
	DEPENDS:=$(GO_ARCH_DEPENDS) \
		+procd-ujail \
		+iptables \
		+iptables-mod-extra \
		+iptables-mod-tproxy \
		+libuci-lua \
		+lyaml \
		+ca-bundle
	USERID:=clash=7890:clash=7890
endef

define Package/$(PKG_NAME)/description
	Clash, A rule based tunnel in Go, support VMess, Shadowsocks,
	Trojan, Snell protocol for remote connections.
endef

define Package/$(PKG_NAME)/config
	menu "Clash Counfiguration"
		depends on PACKAGE_$(PKG_NAME)
	
	config PACKAGE_CLASH_INCLUDE_COUNTRY_MMDB
		bool "Include Country.mmdb"
		default y

	endmenu
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/clash
endef

COUNTRY_MMDB_VER=20211012
COUNTRY_MMDB_FILE:=Country.$(COUNTRY_MMDB_VER).mmdb

define Download/country_mmdb
	URL:=https://github.com/Dreamacro/maxmind-geoip/releases/download/$(COUNTRY_MMDB_VER)/
	URL_FILE:=Country.mmdb
	FILE:=$(COUNTRY_MMDB_FILE)
	HASH:=1aa79e4d93b2312bdd6a9251580e48e16d756c6cd159e7275a23f615d46e98ac
endef

define Build/Prepare
	$(call Build/Prepare/Default)

ifdef CONFIG_PACKAGE_CLASH_INCLUDE_COUNTRY_MMDB
	$(call Download,country_mmdb)
endif
endef

define Package/$(PKG_NAME)/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/clash $(1)/usr/bin/clash

	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(CURDIR)/files/clash.init $(1)/etc/init.d/clash

	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_CONF) $(CURDIR)/files/clash.conf $(1)/etc/config/clash

ifdef CONFIG_PACKAGE_CLASH_INCLUDE_COUNTRY_MMDB
	$(INSTALL_DIR) $(1)/etc/clash/
	$(INSTALL_DATA) $(DL_DIR)/$(COUNTRY_MMDB_FILE) $(1)/etc/clash/Country.mmdb
endif

	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) $(CURDIR)/files/clash.defaults $(1)/etc/uci-defaults/clash

	$(INSTALL_DIR) $(1)/usr/share/clash/
	$(INSTALL_BIN) $(CURDIR)/files/firewall.include $(1)/usr/share/clash/firewall.include
	$(INSTALL_BIN) $(CURDIR)/files/build_conf.lua $(1)/usr/share/clash/build_conf.lua

	$(INSTALL_DIR) $(1)/etc/capabilities/
	$(INSTALL_BIN) $(CURDIR)/files/clash.capabilities $(1)/etc/capabilities/clash.json
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
