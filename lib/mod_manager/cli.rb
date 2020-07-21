# frozen_string_literal: true

require 'optparse'

module ModManager
  # CLI for the utility
  class CLI
    def initialize(out = STDOUT)
      @out = out
    end

    def start(argv)
      args = parser.parse! argv, into: options
      options[:command] = args.shift&.to_sym

      show_usage unless validate_options

      execute_command
    rescue OptionParser::ParseError
      show_usage
    end

    protected

    attr_reader :out

    def options
      @options ||= {
        mode: :keep,
        source: :all
      }
    end

    def parser
      return @parser if @parser

      @parser = OptionParser.new do |opts|
        opts.banner = 'Usage: command'

        opts.on('-m [MODE]', '--mode [MODE]', %w[keep replace], 'mode of operation') do |m|
          options[:mode] = m.to_sym
        end

        opts.on('-s [SOURCE]', '--source [SOURCE]', %w[all game repo], 'source to look for mods') do |s|
          options[:source] = s.to_sym
        end
      end
    end

    def show_usage
      out.puts parser.help
    end

    def validate_options
      return false unless validate_command

      case options[:command]
      when :list then validate_list_command
      when :install then validate_install_command
      else false
      end
    end

    def validate_command
      return false unless options[:command]

      return false unless %i[list install].include? options[:command]

      true
    end

    def validate_list_command
      return false unless options[:source]

      true
    end

    def validate_install_command
      return false unless options[:mode]

      true
    end

    def mod_manager
      @mod_manager ||= ModManager::Instance.new(game_dir: Settings.game_dir, repo_dir: Settings.repo_dir)
    end

    def execute_command
      case options[:command]
      when :list then execute_list_command
      when :install then execute_install_command
      end
    end

    def execute_list_command
      if options[:source] == :all
        output_mod_list 'Installed', mod_manager.list(:game)
        output_mod_list 'Repository', mod_manager.list(:repo)
      else
        output_mod_list 'List', mod_manager.list(options[:source])
      end
    end

    def output_mod_list(name, list)
      out.puts name.center(80, '-')
      list.each_with_index do |mod, index|
        out.puts "#{index + 1}. #{mod.name} (id: #{mod.remote_file_id}, for #{mod.game.name} #{mod.game.version})"
      end
    end

    def execute_install_command
      mod_manager.install(
        mode: options[:mode],
        on_event: proc { |e| on_event(e) }
      )
    end

    def on_event(event)
      case event.type
      when :install_start then on_install_start(event)
      when :install_end then on_install_end_event(event)
      end
    end

    def on_install_start(event)
      mod = event.metadata[:mod]
      out.puts "#{mod.name} (id: #{mod.remote_file_id}, for #{mod.game.name} #{mod.game.version})"
    end

    def on_install_end_event(event)
      case event.metadata[:result]
      when :error then out.puts "\terror: #{event.metadata[:exception].message}"
      else out.puts "\t#{event.metadata[:result]}"
      end
    end
  end
end
