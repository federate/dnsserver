class Resolv
  class DNS
    class Resource
      module IN
        class NAPTR < Resource
          TypeValue = 35 # :nodoc:
          ClassValue = IN::ClassValue
          ClassHash[[TypeValue, ClassValue]] = self

          attr_accessor :order
          attr_accessor :preference
          attr_accessor :flag
          attr_accessor :service_name
          attr_accessor :regex
          attr_accessor :replacement

          def initialize(order, preference, flag, service_name, regex, replacement)
            @order = order
            @preference = preference
            @flag = flag
            @service_name = service_name
            @regex = regex
            @replacement = replacement
          end

          def encode_rdata(msg)
            msg.put_pack('n', @order)
            msg.put_pack('n', @preference)
            msg.put_string(@flag)
            msg.put_string(@service_name)
            msg.put_string(@regex)
            msg.put_string(@replacement)
          end

          def self.decode_rdata(msg)
            order, preference = msg.get_unpack('nn')
            flag = msg.get_string
            service_name = msg.get_string
            regex = msg.get_string
            replacement = msg.get_string
            new(order, preference, flag, service_name, regex, replacement)
          end
        end
      end
    end
  end
end
