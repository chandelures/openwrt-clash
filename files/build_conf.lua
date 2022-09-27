#!/usr/bin/lua

local lyaml = require "lyaml"
local uci = require "uci"

local x = uci.cursor()

local config = "clash"
local yamlext = ".yaml"
local confdir = "/etc/clash"
local profile_dir = "/etc/clash/profiles"
local update_profile_script = "/usr/lib/clash/update_profile.sh"
local current_profile = x:get(config, "global", "current_profile")

local function path_exist(path)
    local file, err = io.open(path, "r")
    if err == nil then
        file:close()
        return true
    end
    return false
end

local function get(section, option, default)
    value = x:get(config, section, option)
    if value == nil then
        return default
    end
    return value
end

local function get_bool(section, option, default)
    value = x:get(config, section, option)
    if value == nil then
        return default
    end
    return value == "1" or value == "true"
end

local function get_number(section, option, default)
    value = x:get(config, section, option)
    if value == nil then
        return default
    end
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

    local type = get(current_profile, "type", "Static")

    if type == "Static" then
        file = io.open(profile_path(), "w")
        file:write("")
        file:close()
        return
    end

    if type == "URL" then
        os.execute(update_profile_script .. " " .. current_profile)
        return
    end
end

local function load()
    local file = io.open(profile_path(), "r")
    profile = lyaml.load(file:read("*a"), {all = true})[1]
    file:close()
    return profile
end

local function update_general(profile)
    local mixed_port = get_number("global", "mixed_port", nil)
    local tproxy_enabled = get_bool("global", "tproxy_enabled", true)
    local tproxy_port = get_number("global", "tproxy_port", 7890)
    local allow_lan = get_bool("global", "allow_lan", true)
    local bind_addr = get("global", "bind_addr", "0.0.0.0")
    local mode = get("global", "mode", "rule")
    local log_level = get("global", "log_level", "warning")
    local api_host = get("global", "api_host", "0.0.0.0")
    local api_port = get_number("global", "api_port", 9090)
    local ipv6 = get_bool("global", "ipv6", false)
    local routing_mark = get_number("global", "routing_mark", 255)

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
    profile["ipv6"] = ipv6
    profile["routing-mark"] = routing_mark
end

local function update_dns(profile)
    local tproxy_enabled = get_bool("global", "tproxy_enabled", true)
    local dns_host = get("global", "dns_host", "127.0.0.1")
    local dns_port = get_number("global", "dns_port", "5353")
    local dns_mode = get("global", "dns_mode", "fake-ip")
    local fake_ip_range = get("global", "fake_ip_range", "198.18.0.1/16")
    local default_nameserver = get("global", "default_nameserver", nil)
    local nameserver = get("global", "nameserver", nil)
    local fallback = get("global", "fallback", nil)
    local ipv6 = get_bool("global", "ipv6", false)

    local profile_dns = {}
    profile_dns["enable"] = tproxy_enabled
    profile_dns["ipv6"] = ipv6
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
    profile["port"] = nil
    profile["socks-port"] = nil
    profile["redir-port"] = nil
    profile["external-ui"] = nil
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
