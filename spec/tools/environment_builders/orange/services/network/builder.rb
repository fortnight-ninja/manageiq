require_relative 'builder/neutron'
require_relative 'builder/nova'

module Orange
  module Services
    module Network
      class Builder
        def self.build_all(ems, project, service_type = :neutron)
          builder_class = case service_type
                          when :neutron
                            Orange::Services::Network::Builder::Neutron
                          when :nova
                            Orange::Services::Network::Builder::Nova
                          end

          builder_class.new(ems, project).build_all
        end
      end
    end
  end
end
