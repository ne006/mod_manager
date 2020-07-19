# frozen_string_literal: true

require 'mod_manager/mod/repo'
require 'mod_manager/mod/game'
require 'mod_manager/event'

module ModManager
  # An instance of mod manager
  class Instance
    attr_reader :game_dir, :repo_dir

    def initialize(game_dir:, repo_dir:)
      @game_dir = to_dir(game_dir)
      @repo_dir = to_dir(repo_dir)

      @repo_mods = nil
      @game_mods = nil
    end

    def list(source)
      case source
      when :repo
        repo_mods
      when :game
        game_mods
      end
    end

    def reload
      @repo_mods = nil
      @game_mods = nil

      self
    end

    def install(mode: :keep, on_event: nil)
      list(:repo).each do |mod|
        on_event&.call(::ModManager::Event.new(:install_start, { mod: mod }))

        result = mod.install(game_dir, mode: mode)

        on_event&.call(Event.new(:install_end, { mod: mod, result: result }))
      rescue StandardError => e
        on_event&.call(Event.new(:install_end, { mod: mod, result: :error, exception: e }))
      end
    end

    protected

    def to_dir(path)
      return path if path.is_a? Dir

      Dir.new(path)
    end

    def repo_mods
      @repo_mods ||= repo_dir.entries.each_with_object([]) do |entry, list|
        next if %w[. ..].include? entry

        list << Mod::Repo.new(Pathname.new(repo_dir).join(entry))
      end
    end

    def game_mods
      config_folder_path = Pathname.new(game_dir).join('mod')
      @game_mods ||= Dir.new(config_folder_path).entries.each_with_object([]) do |entry, list|
        next if %w[. ..].include? entry

        list << Mod::Game.new(config_folder_path.join(entry))
      end
    end
  end
end
