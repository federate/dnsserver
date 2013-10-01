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

  INTERFACES = [
    [:udp, "0.0.0.0", 5300],
    [:tcp, "0.0.0.0", 5300]
  ]

  Name = Resolv::DNS::Name
  IN = Resolv::DNS::Resource::IN

  GOOGLE_RESOLVER = RubyDNS::Resolver.new([[:udp, "8.8.8.8", 53], [:udp, "8.8.4.4", 53]])
  TELASTIC_RESOLVER = RubyDNS::Resolver.new([[:udp, "184.173.103.52", 53]])

  module ClassMethods

    attr_accessor :config

    def run
      RubyDNS::run_server(:listen => INTERFACES) do
        match(/e164.arpa$/) do |transaction|
          transaction.passthrough!(TELASTIC_RESOLVER)
        end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough(GOOGLE_RESOLVER)
        end
      end
    end

    def init(config_file = nil)
      if config_file
        @config_file = Pathname.new config_file
        DNSServer::Config.source @config_file.realpath
      end
    end

  end

  extend ClassMethods
end
