require 'slop'
require 'logger'
require 'yaml'
require 'hashie'
require 'settingslogic'
require 'dante'
require 'pry'
require 'rubydns'
require 'pathname'
require 'ext/naptr'
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
            if matcher.respond_to?(:question_matcher) && matcher.respond_to?(:question_template)
              question_matcher_regexp = Regexp.new matcher.question_matcher

              transaction.query.question.each do |question|
                name, klass = question
                name = name.to_s.sub(/\.{1}$/, '')
                matches = name.match question_matcher_regexp

                if matches && matches[1]
                  q = Resolv::DNS::Name.create(matcher.question_template.gsub('${match}', matches[1]))
                  resolver = DNSServer.resolver(matcher.resolver)
                  @resp = resolver.query(q, transaction.resource_class)

                  if @resp && !@resp.answer.empty?
                    @resp.answer.each do |answer|
                      a = answer.last unless answer.empty?
                      next unless a

                      if matcher.respond_to?(:answer_substitutions) && !matcher.answer_substitutions.empty?
                        matcher.answer_substitutions.each do |m,s|
                          a.regex = a.regex.gsub(Regexp.new(m), s)
                        end
                      end

                      transaction.add [a]
                    end
                  end
                end

              end

            end
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

      if !self.config.log_level || self.config.log_level.downcase == 'debug'
        @logger.level = Logger::DEBUG
      else
        @logger.level = Logger::INFO
      end
    end

  end

  extend ClassMethods
end
