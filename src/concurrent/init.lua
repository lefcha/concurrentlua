-- Main module for concurrent programming that loads all the submodules.
concurrent = {}

concurrent._option = require 'concurrent.option'

concurrent._process = require 'concurrent.process'
concurrent._message = require 'concurrent.message'
concurrent._scheduler = require 'concurrent.scheduler'

concurrent._register = require 'concurrent.register'

concurrent._link = require 'concurrent.link'
concurrent._monitor = require 'concurrent.monitor'

concurrent._root = require 'concurrent.root'

-- Main module for distributed programming that loads all the submodules.
concurrent._distributed = {}

concurrent._distributed._network = require 'concurrent.distributed.network'
concurrent._distributed._node = require 'concurrent.distributed.node'
concurrent._distributed._cookie = require 'concurrent.distributed.cookie'

concurrent._distributed._process = require 'concurrent.distributed.process'
concurrent._distributed._message = require 'concurrent.distributed.message'
concurrent._distributed._scheduler = require 'concurrent.distributed.scheduler'

concurrent._distributed._register = require 'concurrent.distributed.register'

concurrent._distributed._link = require 'concurrent.distributed.link'
concurrent._distributed._monitor = require 'concurrent.distributed.monitor'

return concurrent
