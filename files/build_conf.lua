#!/usr/bin/lua

local lyaml = require "lyaml"
local ucursor = require "luci.model.uci"
local sys = require("luci.sys")

local config = "clash"
local yamlext = ".yaml"

local profile_dir = ucursor:get(config, "global", "profile_dir")
local current_profile = ucursor:get(config, "global", "current_profile")

local function profile_path()
    return profile_dir .. "/" .. current_profile .. yamlext
end

local function fetch_profile()
    local file, err = io.open(profile_path(), "r")
    if err == nil then
        return 0
    end

    file = io.open(profile_path(), "w")
    file:write("mode: direct")
    file:close()
end

local function load_profile()
    local profile = {}
    local file, err = io.open(profile_path(), "r")
    if err == nil then
        profile = lyaml.load(file:read("*a"), {all = true})[1]
        file:close()
    end
    return profile
end

local function general(profile)
    local tproxy_enabled = ucursor:get_bool(config, "global", "tproxy_enabled")
    local api_host = ucursor:get(config, "global", "api_host")
    local api_port = ucursor:get(config, "global", "api_port")

    if tproxy_enabled then
        local tproxy_port = ucursor:get(config, "global", "tproxy_port")
        profile["tproxy-port"] = tonumber(tproxy_port)
    else
        profile["tproxy-port"] = nil
    end

    profile["redir-port"] = nil
    profile["external-controller"] = api_host .. ":" .. api_port
    profile["ipv6"] = false
end

local function dns(profile)
    local dns_host = ucursor:get(config, "dns", "host")
    local dns_port = ucursor:get(config, "dns", "port")

    local profile_dns = {}
    profile_dns["enable"] = true
    profile_dns["ipv6"] = false
    profile_dns["enhanced-mode"] = "redir-host"
    profile_dns["listen"] = dns_host .. ":" .. dns_port
    profile_dns["nameserver"] = {"114.114.114.114"}
    profile_dns["fallback"] = {"https://1.1.1.1/dns-query"}
    profile["dns"] = profile_dns
end

local function build(profile)
    local confdir = ucursor:get(config, "global", "confdir")
    local confpath = confdir .. "/config.yaml"
    local file = io.open(confpath, "w")
    file:write(lyaml.dump({profile}))
    file:close()
end

local function main()
    fetch_profile()
    local profile = load_profile()
    general(profile)
    dns(profile)
    build(profile)
end

main()
