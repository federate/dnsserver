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
                                            },
                                            :sequence_max => (resolver['sequence_max'].to_i || 65536),
                                            :logger => DNSServer.logger,
                                            :timeout => 1)
        }
      end
    end

    def resolver(name)
      r = self.resolvers.find { |resolver| resolver[:name] == name }
      r[:resolver]
    end

    def run
      RubyDNS::run_server(:listen => self.interfaces) do

        @logger = DNSServer.logger

        DNSServer.config.matchers.each do |matcher|
          match(Regexp.new(matcher.expression)) do |transaction|
            transaction.passthrough!(DNSServer.resolver(matcher.resolver))
          end
        end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough!(DNSServer.resolver(DNSServer.config.default_resolver))
        end
      end
    end

    def init(config_file = nil, environment = 'development')
      @environment = environment

      if config_file
        @config_file = Pathname.new config_file
        DNSServer::Config.source @config_file.realpath
      end

      DNSServer::Config.namespace @environment

      init_logger
    end

    def init_logger
      @logger = if !self.config.log || self.config.log.upcase == 'STDOUT'
        Logger.new(STDOUT)
      else
        Logger.new(self.config.log)
      end

      if !self.config.log_level || self.config.log.downcase == 'debug'
        @logger.level = Logger::DEBUG
      else
        @logger.level = Logger::INFO
      end
    end

  end

  extend ClassMethods
end
