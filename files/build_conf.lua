#!/usr/bin/lua

local lyaml = require "lyaml"
local ucursor = require "luci.model.uci"

local config = "clash"
local yamlext = ".yaml"

local profile_dir = ucursor:get(config, "global", "profile_dir")
local current_profile = ucursor:get(config, "global", "current_profile")

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
    local tproxy_enabled = ucursor:get_bool(config, "global", "tproxy_enabled")
    local http_port = ucursor:get(config, "global", "http_port")
    local socks_port = ucursor:get(config, "global", "socks_port")
    local mixed_port = ucursor:get(config, "global", "mixed_port")
    local allow_lan = ucursor:get_bool(config, "global", "allow_lan")
    local bind_addr = ucursor:get(config, "global", "bind_addr")
    local mode = ucursor:get(config, "global", "mode")
    local log_level = ucursor:get(config, "global", "log_level")
    local api_host = ucursor:get(config, "global", "api_host")
    local api_port = ucursor:get(config, "global", "api_port")

    if tonumber(http_port) then
        profile["port"] = tonumber(http_port)
    else
        profile["port"] = nil
    end

    if tonumber(socks_port) then
        profile["socks-port"] = tonumber(socks_port)
    else
        profile["socks-port"] = nil
    end

    if tonumber(mixed_port) then
        profile["mixed-port"] = tonumber(mixed_port)
    else
        profile["mixed-port"] = nil
    end

    if tproxy_enabled then
        local tproxy_port = ucursor:get(config, "global", "tproxy_port")
        profile["tproxy-port"] = tonumber(tproxy_port)
    else
        profile["tproxy-port"] = nil
    end

    profile["redir-port"] = nil

    profile["allow-lan"] = allow_lan
    if allow_lan then
        profile["bind_addr"] = bind_addr
    end

    profile["mode"] = mode
    profile["log-level"] = log_level
    profile["ipv6"] = false
    profile["external-controller"] = api_host .. ":" .. api_port
    profile["interface-name"] = nil
end

local function dns()
    local dns_host = ucursor:get(config, "dns", "host")
    local dns_port = ucursor:get(config, "dns", "port")
    local default_nameserver = ucursor:get(config, "dns", "default_nameserver")
    local nameserver = ucursor:get_list(config, "dns", "nameserver")
    local fallback = ucursor:get_list(config, "dns", "fallback")

    local profile_dns = {}
    profile_dns["enable"] = true
    profile_dns["ipv6"] = false
    profile_dns["enhanced-mode"] = "redir-host"
    profile_dns["listen"] = dns_host .. ":" .. dns_port
    profile_dns["default-nameserver"] = { default_nameserver }
    profile_dns["nameserver"] = nameserver
    profile_dns["fallback"] = fallback
    profile["dns"] = profile_dns
end

local function build()
    local confdir = ucursor:get(config, "global", "confdir")
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
