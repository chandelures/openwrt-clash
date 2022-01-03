#!/usr/bin/lua

local lyaml = require "lyaml"
local uci = require "uci"

local x = uci.cursor()

local config = "clash"
local yamlext = ".yaml"
local confdir = "/etc/clash"
local profile_dir = "/etc/clash/profiles"
local current_profile = x:get(config, "global", "current_profile")

local function path_exist(path)
    local file, err = io.open(path, "r")
    if err == nil then
        file:close()
        return true
    end
    return false
end

local function get(section, option)
    return x:get(config, section, option)
end

local function get_bool(section, option)
    value = x:get(config, section, option)
    return value == "1" or value == "true"
end

local function get_number(section, option)
    value = x:get(config, section, option)
    if tonumber(value) == 0 then
        return nil
    end
    return tonumber(value)
end

local function profile_path()
    return profile_dir .. "/" .. current_profile .. yamlext
end

local function fetch()
    if path_exist(profile_dir) == false then
        os.execute("mkdir -p " .. profile_dir)
    end

    if path_exist(profile_path()) then
        return
    end

    file = io.open(profile_path(), "w")
    file:write("mode: direct")
    file:close()
end

local function load()
    local file = io.open(profile_path(), "r")
    profile = lyaml.load(file:read("*a"), {all = true})[1]
    file:close()
    return profile
end

local function update_general(profile)
    local http_port = get_number("global", "http_port")
    local socks_port = get_number("global", "socks_port")
    local mixed_port = get_number("global", "mixed_port")
    local tproxy_enabled = get_bool("global", "tproxy_enabled")
    local tproxy_port = get_number("global", "tproxy_port")
    local allow_lan = get_bool("global", "allow_lan")
    local bind_addr = get("global", "bind_addr")
    local mode = get("global", "mode")
    local log_level = get("global", "log_level")
    local api_host = get("global", "api_host")
    local api_port = get_number("global", "api_port")

    profile["http-port"] = http_port
    profile["socks-port"] = socks_port
    profile["mixed-port"] = mixed_port
    if tproxy_enabled then
        profile["tproxy-port"] = tproxy_port
    else
        profile["tproxy-port"] = nil
    end

    if allow_lan then
        profile["allow-lan"] = true
        profile["bind-address"] = bind_addr
    else
        profile["allow-lan"] = false
        profile["bind-address"] = nil
    end

    profile["mode"] = mode
    profile["log-level"] = log_level
    profile["external-controller"] = api_host .. ":" .. api_port
end

local function update_dns(profile)
    local dns_host = get("global", "dns_host")
    local dns_port = get_number("global", "dns_port")
    local dns_mode = get("global", "dns_mode")
    local fake_ip_range = get("global", "fake_ip_range")
    local default_nameserver = get("global", "default_nameserver")
    local nameserver = get("global", "nameserver")
    local fallback = get("global", "fallback")

    local profile_dns = {}
    profile_dns["enable"] = true
    profile_dns["ipv6"] = false
    profile_dns["enhanced-mode"] = dns_mode
    profile_dns["fake-ip-range"] = fake_ip_range
    profile_dns["listen"] = dns_host .. ":" .. dns_port
    profile_dns["default-nameserver"] = default_nameserver
    profile_dns["nameserver"] = nameserver
    if dns_mode == "redir-host" then
        profile_dns["fallback"] = fallback
    else
        profile_dns["fallback"] = nil
    end

    profile["dns"] = profile_dns
end

local function drop_useless(profile)
    profile["redir-port"] = nil
    profile["external-ui"] = nil
    profile["ipv6"] = false
end

local function dump(profile)
    local file = io.open(confdir .. "/config.yaml", "w")
    file:write(lyaml.dump({profile}))
    file:close()
end

local function main()
    fetch()
    profile = load()
    update_general(profile)
    update_dns(profile)
    drop_useless(profile)
    dump(profile)
end

main()
