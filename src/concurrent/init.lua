-- Main module for concurrent programming that loads all the submodules.
local concurrent = {}

local mod

mod = require 'concurrent.option'
concurrent.setoption = mod.setoption
concurrent.getoption = mod.getoption

mod = require 'concurrent.process'
concurrent.spawn = mod.spawn
concurrent.self = mod.self
concurrent.isalive = mod.isalive
concurrent.exit = mod.exit
concurrent.whereis = mod.whereis

mod = require 'concurrent.message'
concurrent.send = mod.send
concurrent.receive = mod.receive

mod = require 'concurrent.scheduler'
concurrent.step = mod.step
concurrent.tick = mod.tick
concurrent.loop = mod.loop
concurrent.interrupt = mod.interrupt
concurrent.sleep = mod.sleep

mod = require 'concurrent.register'
concurrent.register = mod.register
concurrent.unregister = mod.unregister
concurrent.registered = mod.registered
concurrent.whereis = mod.whereis

mod = require 'concurrent.link'
concurrent.link = mod.link
concurrent.unlink = mod.unlink
concurrent.spawnlink = mod.spawnlink

mod = require 'concurrent.monitor'
concurrent.monitor = mod.monitor
concurrent.demonitor = mod.demonitor
concurrent.spawnmonitor = mod.spawnmonitor

mod = require 'concurrent.root'
concurrent.self = mod.self
concurrent.isalive = mod.isalive

mod = require 'concurrent.distributed.network'
concurrent.init = mod.init
concurrent.shutdown = mod.shutdown

mod = require 'concurrent.distributed.node'
concurrent.node = mod.node
concurrent.nodes = mod.nodes
concurrent.isnodealive = mod.isnodealive
concurrent.monitornode = mod.monitornode
concurrent.demonitornode = mod.demonitornode

mod = require 'concurrent.distributed.cookie'
concurrent.setcookie = mod.setcookie
concurrent.getcookie = mod.getcookie

mod = require 'concurrent.distributed.process'
concurrent.spawn = mod.spawn

mod = require 'concurrent.distributed.message'
concurrent.send = mod.send

mod = require 'concurrent.distributed.scheduler'
concurrent.step = mod.step
concurrent.tick = mod.tick
concurrent.loop = mod.loop

mod = require 'concurrent.distributed.register'
concurrent.register = mod.register
concurrent.unregister = mod.unregister
concurrent.whereis = mod.whereis

mod = require 'concurrent.distributed.link'
concurrent.link = mod.link
concurrent.spawnlink = mod.spawnlink
concurrent.unlink = mod.unlink

mod = require 'concurrent.distributed.monitor'
concurrent.monitor = mod.monitor
concurrent.spawnmonitor = mod.spawnmonitor
concurrent.demonitor = mod.demonitor

return concurrent
