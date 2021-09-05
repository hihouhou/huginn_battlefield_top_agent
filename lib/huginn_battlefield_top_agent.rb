require 'huginn_agent'
require 'net/http'
require 'uri'
require 'json'
require 'deep_merge'

#HuginnAgent.load 'huginn_battlefield_top_agent/concerns/my_agent_concern'
HuginnAgent.register 'huginn_battlefield_top_agent/battlefield_top_agent'
