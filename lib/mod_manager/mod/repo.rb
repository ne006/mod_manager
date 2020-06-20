# frozen_string_literal: true

require 'zip'
require 'mod_manager/paradox_config_parser'
require 'mod_manager/game'

module ModManager
  module Mod
    # Mod in repo, not installed
    class Repo
      Game = Struct.new(:name, :version)

      attr_reader :name, :game, :remote_file_id, :install_path, :tags

      def initialize(archive_path)
        @archive_path = archive_path

        raise ArgumentError, "File '#{@archive_path}' doesn't exist" unless File.exist?(@archive_path)

        load_metadata
      end

      protected

      def load_metadata
        Zip::File.open(@archive_path) do |archive|
          entry = archive.glob('*.mod').first

          raise StandardError, "No .mod file found in archive #{@archive_path}" unless entry

          metadata = ParadoxConfigParser.parse(entry.get_input_stream.read)

          assign_metadata metadata
        end
      end

      def assign_metadata(metadata)
        @game = Game.new('Stellaris', metadata['supported_version'])

        @name = metadata['name']
        @tags = metadata['tags']

        @remote_file_id = metadata['remote_file_id']

        @install_path = Pathname.new(metadata['path'])
      end
    end
  end
end
