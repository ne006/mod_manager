# frozen_string_literal: true

module ModManager
  # Parse Paradox configuration files
  module ParadoxConfigParser
    class << self
      def parse(string)
        io = wrap_string_in_io(string)

        struct = nil

        while (line = io.gets&.strip)
          type = type_of line

          case type
          when :pair
            struct = merge_pair(struct, line, io)
          when :pair_substruct_start
            struct = merge_pair(struct, line, io, deep: true)
          when :substruct_end
            break
          when :atom
            struct = merge_atom(struct, line, io)
          else
            raise "Line #{io.lineno} could not be parsed"
          end
        end

        struct
      end

      protected

      def type_of(line)
        if line.index('={')
          :pair_substruct_start
        elsif line == '}'
          :substruct_end
        elsif line.index('=')
          :pair
        else
          :atom
        end
      end

      def merge_pair(struct, line, io, deep: false)
        struct ||= {}

        raise "Line #{io.lineno} could not be appended to its parent struct" unless struct.is_a? Hash

        if deep
          struct.merge!(parse_pair(line, parse(io)))
        else
          struct.merge!(parse_pair(line))
        end

        struct
      end

      def parse_pair(line, subst_val = nil)
        key, val = line.split('=', 2)

        key = parse_atom(key)

        if subst_val
          { key => subst_val }
        else
          val = parse_atom(val)

          { key => val }
        end
      end

      def merge_atom(struct, line, _io)
        struct ||= []
        struct.push << (parse_atom line)
      end

      def parse_atom(line)
        line.gsub(/['"]/, '')
      end

      def wrap_string_in_io(string)
        if string.is_a?(StringIO) || string.is_a?(IO)
          string
        else
          StringIO.new string
        end
      end
    end
  end
end
