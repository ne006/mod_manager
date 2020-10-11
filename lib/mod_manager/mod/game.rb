# frozen_string_literal: true

require 'mod_manager/mod/base'
require 'mod_manager/paradox_config_parser'
require 'mod_manager/game'

require 'json'
require 'securerandom'

module ModManager
  module Mod
    # Mod installed in game directory
    class Game < Base
      def initialize(config_path)
        @config_path = config_path

        convert_config_path_to_pathname

        raise ArgumentError, "File '#{@config_path}' doesn't exist" unless File.exist?(@config_path)

        load_metadata
      end

      # TODO: extract to ModRegistry class
      def register(registry_path)
        uuid, record = registry(registry_path, reload: true).find do |_key, value|
          value['steamId'] == remote_file_id.to_s
        end

        new_data = if uuid
                     {
                       uuid => record.merge(to_registry_record)
                     }
                   else
                     uuid = SecureRandom.uuid

                     {
                       uuid => to_registry_record.merge({ 'id' => uuid })
                     }
                   end

        registry(registry_path).merge!(new_data)

        write_registry(registry_path)

        :ok
      end

      def install_dir
        @config_path.realpath
                    .ascend.find { |path| path.basename.to_s == 'mod' }
                    .ascend.tap(&:next).next
      end

      protected

      def convert_config_path_to_pathname
        @config_path = Pathname.new(@config_path) unless @config_path.is_a?(Pathname)
      end

      def load_metadata
        metadata = ParadoxConfigParser.parse(File.new(@config_path))
        metadata['remote_file_id'] ||= File.basename(@config_path, '.mod')

        assign_metadata metadata
      end

      def registry(registry_path, reload: false)
        return @registry if @registry && !reload

        @registry = if File.exist?(registry_path)
                      JSON.parse(File.read(registry_path))
                    else
                      {}
                    end
      end

      def write_registry(registry_path)
        File.write(registry_path, JSON.generate(registry(registry_path)))
      end

      def to_registry_record
        {
          "gameRegistryId": @config_path.relative_path_from(install_dir).to_s,
          "source": 'local',
          "steamId": remote_file_id,
          "displayName": name,
          "tags": tags,
          "requiredVersion": game&.version,
          "dirPath": install_path.to_s,
          "status": 'ready_to_play'
        }
      end
    end
  end
end
