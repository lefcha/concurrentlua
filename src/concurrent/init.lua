-- Main module for concurrent programming that loads all the submodules.
module('concurrent', package.seeall)

require 'concurrent.option'

require 'concurrent.process'
require 'concurrent.message'
require 'concurrent.scheduler'

require 'concurrent.register'

require 'concurrent.link'
require 'concurrent.monitor'

require 'concurrent.root'

require 'concurrent.distributed'
