# frozen_string_literal: true

module ModManager
  module Mod
    # Shared for Mod::Game and Mod::Repo
    class Base
      attr_reader :name, :game, :remote_file_id, :install_path, :tags

      def initialize
        raise StandardError, 'Class is abstract'
      end

      protected

      def assign_metadata(metadata)
        @game = ModManager::Game.new('Stellaris', metadata['supported_version'])

        @name = metadata['name']
        @tags = metadata['tags']

        @remote_file_id = metadata['remote_file_id']

        @install_path = Pathname.new(metadata['path'])
      end
    end
  end
end
