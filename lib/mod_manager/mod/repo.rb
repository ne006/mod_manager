# frozen_string_literal: true

require 'mod_manager/mod/base'
require 'zip'
require 'mod_manager/paradox_config_parser'
require 'mod_manager/game'

Zip.on_exists_proc = true

module ModManager
  module Mod
    # Mod in repo, not installed
    class Repo < Base
      def initialize(archive_path)
        @archive_path = archive_path

        convert_archive_path_to_pathname

        raise ArgumentError, "File '#{@archive_path}' doesn't exist" unless File.exist?(@archive_path)

        load_metadata
      end

      def install(install_dir, mode: :keep) # rubocop:disable Metrics/AbcSize
        config_dir_path, asset_dir_path = setup_dirs(install_dir)

        return :exists if mode == :keep && installed?(config_dir_path)

        Zip::File.open(@archive_path) do |archive|
          archive.each do |entry|
            if mod_header?(entry.name)
              entry.extract config_dir_path.join(entry.name)
            elsif mod_asset?(entry.name)
              entry.extract asset_dir_path.join(
                entry.name.gsub(%r{^#{remote_file_id}/}, '')
              )
            end
          end
        end

        :ok
      end

      protected

      def convert_archive_path_to_pathname
        @archive_path = Pathname.new(@archive_path) unless @archive_path.is_a?(Pathname)
      end

      def installed?(config_dir_path)
        File.exist?(config_dir_path.join("#{remote_file_id}.mod"))
      end

      def load_metadata
        Zip::File.open(@archive_path) do |archive|
          entry = archive.glob('*.mod').first

          raise StandardError, "No .mod file found in archive #{@archive_path}" unless entry

          metadata = ParadoxConfigParser.parse(entry.get_input_stream.read)
          metadata['remote_file_id'] ||= File.basename(entry.name, '.mod')

          assign_metadata metadata
        end
      end

      def setup_dirs(install_dir)
        config_dir_path = Pathname.new(install_dir).join('mod')
        asset_dir_path = Pathname.new(install_dir).join(install_path)

        FileUtils.mkdir_p(config_dir_path)
        FileUtils.mkdir_p(asset_dir_path)

        [config_dir_path, asset_dir_path]
      end

      def mod_header?(filename)
        filename == "#{remote_file_id}.mod"
      end

      def mod_asset?(filename)
        filename.start_with? "#{remote_file_id}/"
      end
    end
  end
end
