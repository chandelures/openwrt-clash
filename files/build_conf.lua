#!/usr/bin/lua

local lyaml = require "lyaml"
local uci = require "uci"

local x = uci.cursor()

local config = "clash"
local yamlext = ".yaml"

local profile_dir = x:get(config, "global", "profile_dir")
local current_profile = x:get(config, "global", "current_profile")

local profile = {}

local function profile_path()
    return profile_dir .. "/" .. current_profile .. yamlext
end

local function fetch()
    local file, err = io.open(profile_path(), "r")
    if err == nil then
        return 0
    end

    file = io.open(profile_path(), "w")
    file:write("mode: direct")
    file:close()
end

local function load_origin()
    local file, err = io.open(profile_path(), "r")
    if err == nil then
        profile = lyaml.load(file:read("*a"), {all = true})[1]
        file:close()
    end
end

local function general()
    local tproxy_enabled = x:get(config, "global", "tproxy_enabled")
    local http_port = x:get(config, "global", "http_port")
    local socks_port = x:get(config, "global", "socks_port")
    local mixed_port = x:get(config, "global", "mixed_port")
    local allow_lan = x:get(config, "global", "allow_lan")
    local bind_addr = x:get(config, "global", "bind_addr")
    local mode = x:get(config, "global", "mode")
    local log_level = x:get(config, "global", "log_level")
    local api_host = x:get(config, "global", "api_host")
    local api_port = x:get(config, "global", "api_port")

    if tonumber(http_port) ~= 0 then
        profile["port"] = tonumber(http_port)
    else
        profile["port"] = nil
    end

    if tonumber(socks_port) ~= 0 then
        profile["socks-port"] = tonumber(socks_port)
    else
        profile["socks-port"] = nil
    end

    if tonumber(mixed_port) ~= 0 then
        profile["mixed-port"] = tonumber(mixed_port)
    else
        profile["mixed-port"] = nil
    end

    if tonumber(tproxy_enabled) == 1 then
        local tproxy_port = x:get(config, "global", "tproxy_port")
        profile["tproxy-port"] = tonumber(tproxy_port)
    else
        profile["tproxy-port"] = nil
    end

    profile["redir-port"] = nil

    if tonumber(allow_lan) == 1 then
        profile["allow-lan"] = true
        profile["bind-address"] = bind_addr
    else
        profile["allow-lan"] = false
        profile["bind-address"] = nil
    end

    profile["mode"] = mode
    profile["log-level"] = log_level
    profile["ipv6"] = false
    profile["external-controller"] = api_host .. ":" .. api_port
    profile["interface-name"] = nil
end

local function dns()
    local dns_host = x:get(config, "dns", "host")
    local dns_port = x:get(config, "dns", "port")
    local default_nameserver = x:get(config, "dns", "default_nameserver")
    local nameserver = x:get(config, "dns", "nameserver")
    local fallback = x:get(config, "dns", "fallback")

    local profile_dns = {}
    profile_dns["enable"] = true
    profile_dns["ipv6"] = false
    profile_dns["enhanced-mode"] = "redir-host"
    profile_dns["listen"] = dns_host .. ":" .. dns_port
    profile_dns["default-nameserver"] = default_nameserver 
    profile_dns["nameserver"] = nameserver
    profile_dns["fallback"] = fallback
    profile["dns"] = profile_dns
end

local function build()
    local confdir = x:get(config, "global", "confdir")
    local confpath = confdir .. "/config.yaml"
    local file = io.open(confpath, "w")
    file:write(lyaml.dump({profile}))
    file:close()
end

local function main()
    fetch()
    load_origin()
    general()
    dns()
    build()
end

main()
