module Orange
  module HelperMethods
    def base_dir
      Rails.root.to_s
    end

    def vcr_base_dir
      File.join(base_dir, 'spec/vcr_cassettes/manageiq/providers/orange/cloud_manager')
    end

    def test_base_dir
      File.join(base_dir, 'spec/models/manageiq/providers/orange/cloud_manager')
    end

    def orange_environment_file
      File.join(base_dir, "orange_environments.yml")
    end

    def orange_environments
      @orange_environments ||= YAML.load_file(orange_environment_file)
    end

    def create_or_update_ems(name, hostname, password, port, userid, version)
      puts "Finding EMS for environment #{hostname}"
      attributes = {:name                  => name + " " + hostname,
                    :hostname              => hostname,
                    :ipaddress             => hostname,
                    :port                  => port,
                    :api_version           => version,
                    :zone                  => Zone.first,
                    :security_protocol     => 'no_ssl',
                    :keystone_v3_domain_id => 'default'}

      @ems = ManageIQ::Providers::Orange::CloudManager.joins(:endpoints).where(:endpoints => {
                                                                                    :hostname => hostname}).first
      puts "Creating EMS for environment #{hostname}" unless @ems
      @ems ||= ManageIQ::Providers::Orange::CloudManager.new
      @ems.update_attributes(attributes)
      @ems.save

      @ems.update_authentication(:default => {:userid => userid, :password => password})
    end
  end
end
