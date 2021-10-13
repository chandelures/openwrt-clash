<h1 align="center">
  <img src="https://github.com/Dreamacro/clash/raw/master/docs/logo.png"
   alt="Clash" width="200" align="center">
  <br>Openwrt Clash<br>
</h1>

## Description

This repository is the clash binary package and optional Country.mmdb download support based on [Dreamacro/clash](https://github.com/Dreamacro/clash) for Openwrt.

## Build

You should use the Openwrt source code or SDK to build the package.

```shell
$ git clone https://github.com/chandelures/openwrt-clash

$ make menuconfig

Extra Packages ---> <M> openwrt-clash

$ make package/openwrt-clash/compile V=s
```

### Warning

If any download error occurred, please try to run `export GOPROXY=https://goproxy.io` before building.
