require 'slop'
require 'logger'
require 'yaml'
require 'hashie'
require 'settingslogic'
require 'dante'
require 'pry'
require 'rubydns'
require 'pathname'
require 'dnsserver/version'
require 'dnsserver/config'

module DNSServer

  Name = Resolv::DNS::Name
  IN = Resolv::DNS::Resource::IN

  module ClassMethods

    attr_accessor :config_file, :environment, :logger

    def config
      DNSServer::Config
    end

    def interfaces
      self.config.server.interfaces.collect { |int| [int['protocol'].to_sym, int['addr'], int['port'].to_i] }
    end

    def resolvers
      @resolvers ||= self.config.resolvers.collect do |resolver|
        {
          :name => resolver['name'],
          :resolver => RubyDNS::Resolver.new(resolver.servers.collect { |server|
                                             [server['protocol'].to_sym, server['addr'], server['port'].to_i]
                                            })
        }
      end
    end

    def resolver(name)
      r = self.resolvers.find { |resolver| resolver[:name] == name }
      r[:resolver]
    end

    def run
      RubyDNS::run_server(:listen => self.interfaces) do
        match(/e164.arpa$/) do |transaction|
          transaction.passthrough!(DNSServer.resolver('telaris'))
        end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough!(DNSServer.resolver('google'))
        end
      end
    end

    def init(config_file = nil, environment = 'development')
      @environment = environment
      @logger ||= Logger.new(STDOUT)

      if config_file
        @config_file = Pathname.new config_file
        DNSServer::Config.source @config_file.realpath
      end

      DNSServer::Config.namespace @environment
    end

  end

  extend ClassMethods
end
