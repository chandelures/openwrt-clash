include $(TOPDIR)/rules.mk

PKG_NAME:=clash
PKG_VERSION:=1.8.0
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/Dreamacro/clash/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=e1bae0ba88a0e2ba36702f95fe95fdc8fee58db4751b5b108ea600563c36a972

PKG_MAINTAINER:=Chandelure Wang <me@chandelure.com>
PKG_LICENSE:=GPL-3.0-only
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

define Package/$(PKG_NAME)/template
	SECTION:=net
	CATEGORY:=Network
endef

define Package/$(PKG_NAME)
	$(call Package/$(PKG_NAME)/template)
	TITLE:=A rule-based tunnel in Go
	URL:=https://github.com/dreamacro/clash
	DEPENDS:=$(GO_ARCH_DEPENDS) \
		+iptables \
		+iptables-mod-tproxy \
		+libuci-lua \
		+lyaml \
		+ca-bundle
	USERID:=clash=7890:clash=7890
endef

define Package/clash-dashboard
	$(call Package/$(PKG_NAME)/template)
	TITLE:=Web Dashboard for Clash
	URL:=https://github.com/dreamacro/clash-dashboard
	DEPENDS:=$(PKG_NAME)
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Clash, A rule based tunnel in Go, support VMess, Shadowsocks,
	Trojan, Snell protocol for remote connections.
endef

define Package/clash-dashboard/description
	Web Dashboard for Clash
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
/etc/clash/profiles/
/etc/config/clash
endef

COUNTRY_MMDB_VER=20211112
COUNTRY_MMDB_FILE:=Country.$(COUNTRY_MMDB_VER).mmdb

define Download/country_mmdb
	URL:=https://github.com/Dreamacro/maxmind-geoip/releases/download/$(COUNTRY_MMDB_VER)/
	URL_FILE:=Country.mmdb
	FILE:=$(COUNTRY_MMDB_FILE)
	HASH:=4c9535085fca950d1a2ebda9c1f625947971e98e4dc1a93cf7800a44dbb7ba5b
endef

YACD_DASHBOARD_VER=0.3.4

define Download/clash-dashboard
	URL:=https://github.com/haishanh/yacd/releases/download/$(YACD_DASHBOARD_VER)/
	URL_FILE:=yacd.tar.xz
	FILE:=yacd.tar.xz
	HASH:=c24683776ff1d16ce66ef64fc86b47c1254046ded3432e8d2387d0b6c6e50193
endef

define Build/Prepare
	$(call Build/Prepare/Default)

ifdef CONFIG_PACKAGE_CLASH_INCLUDE_COUNTRY_MMDB
	$(call Download,country_mmdb)
endif

ifdef CONFIG_PACKAGE_clash-dashboard
	$(call Download,clash-dashboard)
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

	$(INSTALL_DIR) $(1)/usr/lib/clash/
	$(INSTALL_BIN) $(CURDIR)/files/build_conf.lua $(1)/usr/lib/clash/build_conf.lua

	$(INSTALL_DIR) $(1)/etc/capabilities/
	$(INSTALL_BIN) $(CURDIR)/files/clash.capabilities $(1)/etc/capabilities/clash.json
endef

define Package/clash-dashboard/install
	$(INSTALL_DIR) $(1)/www/clash-dashboard/
	$(TAR) -C $(DL_DIR) -Jxvf $(DL_DIR)/yacd.tar.xz
	$(CP) \
		$(DL_DIR)/public/assets \
		$(DL_DIR)/public/index.html \
		$(DL_DIR)/public/registerSW.js \
		$(DL_DIR)/public/sw.js \
		$(DL_DIR)/public/yacd-128.png \
		$(DL_DIR)/public/yacd-64.png \
		$(DL_DIR)/public/yacd.ico \
		$(DL_DIR)/public/_headers \
		$(1)/www/clash-dashboard/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,clash-dashboard))
