include $(TOPDIR)/rules.mk

PKG_NAME:=clash
PKG_VERSION:=1.17.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/Dreamacro/clash/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=cd30a27f801652151eea129e9cb00e4a3ee28d45982dad835f4546691796d9d7

PKG_MAINTAINER:=Chandelure Wang <me@chandelure.com>
PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DIR:=$(BUILD_DIR)/clash-$(PKG_VERSION)
PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

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
endef

YACD_DASHBOARD_VER=0.3.8

define Package/clash-dashboard
	$(call Package/$(PKG_NAME)/template)
	TITLE:=Web Dashboard for Clash
	URL:=https://github.com/dreamacro/clash-dashboard
	DEPENDS:=$(PKG_NAME)
	PKGARCH:=all
	VERSION:=$(YACD_DASHBOARD_VER)
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

COUNTRY_MMDB_VER=20230612
COUNTRY_MMDB_FILE:=Country.$(COUNTRY_MMDB_VER).mmdb

define Download/country_mmdb
	URL:=https://github.com/Dreamacro/maxmind-geoip/releases/download/$(COUNTRY_MMDB_VER)/
	URL_FILE:=Country.mmdb
	FILE:=$(COUNTRY_MMDB_FILE)
	HASH:=b83f94ccc8e942fb8d31c2319b88872e72708715ecb44dd6fb4c42b9ff63fe2f
endef

define Download/clash-dashboard
	URL:=https://github.com/haishanh/yacd/releases/download/v$(YACD_DASHBOARD_VER)/
	URL_FILE:=yacd.tar.xz
	FILE:=yacd.tar.xz
	HASH:=d5d7ecde91a708a79386116753e32a59f32c8cb8eec80ded56c3ab94e511ba50
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

	$(INSTALL_DIR) $(1)/usr/lib/clash/
	$(INSTALL_BIN) $(CURDIR)/files/create_rules.sh $(1)/usr/lib/clash/create_rules.sh
	$(INSTALL_BIN) $(CURDIR)/files/clear_rules.sh $(1)/usr/lib/clash/clear_rules.sh
	$(INSTALL_BIN) $(CURDIR)/files/build_conf.lua $(1)/usr/lib/clash/build_conf.lua
	$(INSTALL_BIN) $(CURDIR)/files/update_profile.sh $(1)/usr/lib/clash/update_profile.sh
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
