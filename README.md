<h1 align="center">
  <img src="https://github.com/Dreamacro/clash/raw/master/docs/logo.png"
   alt="Clash" width="200" align="center">
  <br>Openwrt Clash<br>
</h1>

## Description

This repository is the clash package and optional Country.mmdb download support based on
[Dreamacro/clash](https://github.com/Dreamacro/clash) and
[Dreamacro/maxmind-geoip](https://github.com/Dreamacro/maxmind-geoip) for Openwrt.

## Features

- Most features of open source clash core
- Transparent proxy support
- Forwarding DNS query to clash core

## Build

You should use the Openwrt source code or SDK to build the package.

```shell
$ git clone https://github.com/chandelures/openwrt-clash

$ make menuconfig

Network  --->
    <M> clash
        Clash Configuration  --->
            [*] Include Country.mmdb

$ make package/openwrt-clash/compile V=s
```

### Warning

If any download errors occurred, please try to run `export GOPROXY=https://goproxy.io` before building.
