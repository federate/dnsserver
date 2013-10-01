require "dnsserver/version"
require 'slop'
require 'logger'
require 'yaml'
require 'hashie'
require 'settingslogic'
require 'rubydns'

module DNSServer

  INTERFACES = [
      [:udp, "0.0.0.0", 53],
      [:tcp, "0.0.0.0", 53]
  ]

  Name = Resolv::DNS::Name
  IN = Resolv::DNS::Resource::IN

  GOOGLE_RESOLVER = RubyDNS::Resolver.new([[:udp, "8.8.8.8", 53], [:udp, "8.8.4.4", 53]])
  TELASTIC_RESOLVER = RubyDNS::Resolver.new([[:udp, "184.173.103.52", 53]])

  def self.run
      # Start the RubyDNS server
      RubyDNS::run_server(:listen => INTERFACES) do
          match(/test.mydomain.org/, IN::A) do |transaction|
              transaction.respond!("10.0.0.80")
          end

          match(/e164.arpa$/) do |transaction|
              transaction.passthrough!(TELASTIC_RESOLVER)
          end

          # Default DNS handler
          otherwise do |transaction|
              transaction.passthrough(GOOGLE_RESOLVER)
          end
      end
  end

  run

end
