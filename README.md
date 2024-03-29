<h1 align="center">
  <img src="https://github.com/Dreamacro/clash/raw/master/docs/logo.png"
   alt="Clash" width="200" align="center">
  <br>Openwrt Clash<br>
</h1>

[![build](https://github.com/chandelures/openwrt-clash/actions/workflows/build.yml/badge.svg)](https://github.com/chandelures/openwrt-clash/actions)

## Description

This repository is the clash package based on
[Dreamacro/clash](https://github.com/Dreamacro/clash) for Openwrt.

**LuCI support** is on the https://github.com/chandelures/luci-app-simple-clash.

## Features

- Most of the features of open-source clash core are supported
- Transparent proxy support
- Forwarding DNS query to clash core
- (Optional) Clash geoip support
- (Optional) Clash dashboard support

## Installation

### Manual Install

1. Update list of available packages

```shell
$ opkg update
```

2. Choose correct .ipk based on the architecture of router from release page, and use Opkg package manager to install.

```shell
$ opkg install clash_*.ipk
```

### Build From Source

1. First, You should download the Openwrt Source Code or SDK as the basic enviroment
   to build the package.

```shell
$ git clone https://github.com/openwrt/openwrt

$ cd openwrt
```

or download Openwrt SDK from https://downloads.openwrt.org/

```shell
$ tar -Jxvf openwrt-sdk_*.tar.xz

$ cd openwrt-sdk_*
```

2. Prepare build environment

```shell
$ ./scripts/feeds update -a

$ ./scripts/feeds install -a

$ git clone https://github.com/chandelures/openwrt-clash package/openwrt-clash
```

3. Choose clash as a module or built-in module

```shell
$ make menuconfig

Network  --->
    <M> clash
        Clash Configuration  --->
            [*] Include Country.mmdb
    < > clash-dashboard
```

4. Build packages

```shell
$ make package/openwrt-clash/{clean,compile} V=s
```
