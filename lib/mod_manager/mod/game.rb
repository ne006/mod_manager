# frozen_string_literal: true

require 'mod_manager/mod/base'
require 'mod_manager/paradox_config_parser'
require 'mod_manager/game'

module ModManager
  module Mod
    # Mod installed in game directory
    class Game < Base
      def initialize(config_path)
        @config_path = config_path

        raise ArgumentError, "File '#{@config_path}' doesn't exist" unless File.exist?(@config_path)

        load_metadata
      end

      protected

      def load_metadata
        metadata = ParadoxConfigParser.parse(File.new(@config_path))
        metadata['remote_file_id'] ||= File.basename(@config_path, '.mod')

        assign_metadata metadata
      end
    end
  end
end
