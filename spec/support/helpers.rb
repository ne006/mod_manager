# frozen_string_literal: true

module Helpers
  def file_fixture(sub_path)
    path = Pathname.new(__dir__).join('..', 'fixtures', 'files', sub_path)

    raise StandardError, "File '#{path}' doesn't exist" unless File.exist?(path)

    if File.directory? path
      Dir.new(path)
    else
      File.new(path)
    end
  end
end
