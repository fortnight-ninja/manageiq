require 'fog/orange'

$LOAD_PATH.push(Rails.root.to_s)
require_relative 'orange/interaction_methods'
require_relative 'orange/helper_methods'
include Orange::InteractionMethods
include Orange::HelperMethods

require "#{test_base_dir}/refresh_spec_environments"
include Orange::RefreshSpecEnvironments

require_relative 'orange/services/identity/builder'
require_relative 'orange/services/network/builder'
require_relative 'orange/services/compute/builder'
require_relative 'orange/services/volume/builder'
require_relative 'orange/services/image/builder'
require_relative 'orange/services/orchestration/builder'

def usage(s)
  $stderr.puts(s)
  $stderr.puts("Usage: bundle exec rails r spec/tools/environment_builders/orange_install_environments.rb --install")
  $stderr.puts("- installs Orange on servers using packstack")
  $stderr.puts("Usage: bundle exec rails r spec/tools/environment_builders/orange_install_environments.rb --activate_paginations")
  $stderr.puts("- activate paginations for Orange on servers")
  $stderr.puts("Usage: bundle exec rails r spec/tools/environment_builders/orange_install_environments.rb --deactivate_paginations")
  $stderr.puts("- deactivate paginations for Orange on servers")
  $stderr.puts("Filter one with --only-environment")
  $stderr.puts("Options:")
  $stderr.puts("         [--only-environment <name>]  - allowed values #{allowed_environments}")
  exit(2)
end

unless File.exist?(orange_environment_file)
  raise ArgumentError, usage("expecting #{orange_environment_file}")
end

@only_environment = nil

loop do
  option = ARGV.shift
  case option
  when '--only-environment', '-o'
    argv      = ARGV.shift
    supported = allowed_environments
    raise ArgumentError, usage("supported --identity options are #{supported}") unless supported.include?(argv.to_sym)
    @only_environment = argv.to_sym
  when '--activate-paginations', '--deactivate-paginations', '--install'
    @method = option
  when /^-/
    usage("Unknown option: #{option}")
  else
    break
  end
end

def install_environments
  orange_environments.each do |env|
    env_name     = env.keys.first
    env          = env[env_name]
    ssh_user     = env["ssh_user"] || "root"

    @environment = env_name.to_sym

    unless @only_environment.blank?
      puts "Skipping enviroment #{@environment}"
      next unless @environment == @only_environment
    end

    cmd = "ssh-copy-id #{ssh_user}@#{env["ip"]}"
    puts "Executing: #{cmd}"
    ` #{cmd} `
  end

  orange_environments.each do |env|
    env_name     = env.keys.first
    env          = env[env_name]
    ssh_user     = env["ssh_user"] || "root"

    @environment = env_name.to_sym

    unless @only_environment.blank?
      puts "Skipping enviroment #{@environment}"
      next unless @environment == @only_environment
    end

    cmd = ""
    case @environment
    when :grizzly
      cmd += "ssh #{ssh_user}@#{env["ip"]}"\
             " 'curl http://file.brq.redhat.com/~mcornea/miq/orange/orange-install-grizzly | bash -x' "
    when :havana
      cmd += "ssh #{ssh_user}@#{env["ip"]}"\
             " 'curl http://file.brq.redhat.com/~mcornea/miq/orange/orange-install-havana | bash -x' "
    else
      cmd += "ssh #{ssh_user}@#{env["ip"]}"\
             " 'curl http://file.brq.redhat.com/~mcornea/miq/orange/orange-install > orange-install; "\
             "  chmod 755 orange-install; "\
             "  ./orange-install #{environment_release_number} #{networking_service} #{identity_service};' "
    end

    puts "Executing: #{cmd}"
    puts ` #{cmd} `
  end

  puts "---------------------------------------------------------------------------------------------------------------"
  puts "------------------------------------------- instalation finished ----------------------------------------------"

  orange_environments.each do |env|
    env_name     = env.keys.first
    env          = env[env_name]
    ssh_user     = env["ssh_user"] || "root"

    @environment = env_name.to_sym

    unless @only_environment.blank?
      puts "Skipping enviroment #{@environment}"
      next unless @environment == @only_environment
    end

    stackrc_name = 'keystonerc_admin'
    stackrc_name += '_v3' if identity_service == :v3

    puts "Obtaining credentials of installed Orange #{env_name}"
    cmd     = "ssh #{ssh_user}@#{env["ip"]} 'cat #{stackrc_name}'"
    puts stackrc = ` #{cmd} `

    env["password"] = stackrc.match(/OS_PASSWORD=(.*?)$/)[1]
    env["user"]     = stackrc.match(/OS_USERNAME=(.*?)$/)[1]
  end

  puts "---------------------------------------------------------------------------------------------------------------"
  puts "Updating #{orange_environment_file} with Orange credentials"
  File.open(orange_environment_file, 'w') { |f| f.write orange_environments.to_yaml }
end

def activate_paginations
  orange_environments.each do |env|
    env_name     = env.keys.first
    env          = env[env_name]
    ssh_user     = env["ssh_user"] || "root"

    @environment = env_name.to_sym

    unless @only_environment.blank?
      puts "Skipping enviroment #{@environment}"
      next unless @environment == @only_environment
    end

    case @environment
    when :grizzly
      puts " We don't support pagination for grizzly"
      next
    when :havana
      file = "orange-activate-pagination-rhel6"
    else
      file = "orange-activate-pagination"
    end

    puts "-------------------------------------------------------------------------------------------------------------"
    puts "Activate paginations in installed Orange #{env_name}"
    cmd = " ssh #{ssh_user}@#{env["ip"]} "\
          " 'curl http://file.brq.redhat.com/~lsmola/miq/#{file} | bash -x' "
    puts cmd
    ` #{cmd} `
  end
end

def deactivate_paginations
  orange_environments.each do |env|
    env_name     = env.keys.first
    env          = env[env_name]
    ssh_user     = env["ssh_user"] || "root"

    @environment = env_name.to_sym

    unless @only_environment.blank?
      puts "Skipping enviroment #{@environment}"
      next unless @environment == @only_environment
    end

    puts "-------------------------------------------------------------------------------------------------------------"
    case @environment
    when :grizzly
      puts " We don't support pagination for grizzly"
      next
    when :havana
      file = "orange-deactivate-pagination-rhel6"
    else
      file = "orange-deactivate-pagination"
    end

    puts "Deactivate paginations in installed Orange #{env_name}"
    cmd = " ssh #{ssh_user}@#{env["ip"]} "\
          " 'curl http://file.brq.redhat.com/~lsmola/miq/#{file} | bash -x' "
    puts cmd
    ` #{cmd} `
  end
end

case @method
when "--install"
  install_environments
when "--activate-paginations"
  activate_paginations
when "--deactivate-paginations"
  deactivate_paginations
end
