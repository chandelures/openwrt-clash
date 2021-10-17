<h1 align="center">
  <img src="https://github.com/Dreamacro/clash/raw/master/docs/logo.png"
   alt="Clash" width="200" align="center">
  <br>Openwrt Clash<br>
</h1>

## Description

This repository is the clash package based on
[Dreamacro/clash](https://github.com/Dreamacro/clash) for Openwrt.

## Features

- Most features of open source clash core
- Transparent proxy support
- Forwarding DNS query to clash core
- (Optional) Clash geoip support
- (Optional) Clash dashboard support

## Build

1. First, You should download the Openwrt Source Code or SDK as the basic enviroment
  to build the package.

```shell

$ git clone https://github.com/openwrt/openwrt

$ cd openwrt
```

or download openwrt sdk from https://downloads.openwrt.org/

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

3. Choice clash as a module or built-in module

```shell
$ make menuconfig

Network  --->
    <M> clash
        Clash Configuration  --->
            [*] Include Country.mmdb
    < > clash-dashboard
```

4. Building the package

```shell
$ make package/openwrt-clash/{clean,compile} V=s
```

### Warning

If any download errors occurred, please try to run `export GOPROXY=https://goproxy.io` before building.
