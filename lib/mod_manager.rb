# frozen_string_literal: true

require 'mod_manager/version'

require 'mod_manager/cli'

require 'mod_manager/instance'

require 'config'

config_file_path = if File.exist?('mod_manager.yml')
                     'mod_manager.yml'
                   else
                     Pathname.new(__FILE__).ascend.take(3).last.join('mod_manager.yml')
                   end

Config.load_and_set_settings(config_file_path)

# Top-level module and entrypoint
module ModManager
  class << self
    def cli
      ModManager::CLI.new.start(ARGV)
    end
  end
end
