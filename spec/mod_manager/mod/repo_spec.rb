# frozen_string_literal: true

RSpec.shared_examples 'succesful installation' do |mode, check_file_presence|
  it 'should copy mod header to /mod' do
    expect(File.exist?(Pathname.new(install_dir).join('mod', '1.mod'))).not_to be true if check_file_presence

    subject.install(install_dir, mode: mode)

    expect(File.exist?(Pathname.new(install_dir).join('mod', '1.mod'))).to be true
  end

  it 'should copy mod files to install install_path' do
    if check_file_presence
      %w[descriptor.mod thumbnail.png common/random_names/a_file.txt].each do |asset|
        expect(File.exist?(asset_path.join(asset))).not_to be true
      end
    end

    subject.install(install_dir, mode: mode)

    %w[descriptor.mod thumbnail.png common/random_names/a_file.txt].each do |asset|
      expect(File.exist?(asset_path.join(asset))).to be true
    end
  end

  it 'should return :ok' do
    expect(subject.install(install_dir, mode: mode)).to eql(:ok)
  end
end

RSpec.describe ModManager::Mod::Repo do
  let(:mod_archive) { file_fixture('repo/2.7.1/1.zip') }
  let(:metadata_raw) do
    {
      'version' => '2.6',
      'tags' => %w[
        Overhaul
        Graphics
      ],
      'name' => 'Mod 1',
      'picture' => 'thumbnail.png',
      'supported_version' => '2.6',
      'remote_file_id' => '1',
      'path' => 'workshop/content/281990/1/'
    }
  end

  before(:each) do
    pdx_config_parser = class_double('ModManager::ParadoxConfigParser')
    allow(pdx_config_parser).to receive(:parse).and_return(metadata_raw)
  end

  subject { described_class.new(mod_archive.path) }

  describe '#new' do
    it 'loads mod metadata' do
      expect(subject.name).to eql 'Mod 1'
      expect(subject.game.name).to eql 'Stellaris'
      expect(subject.game.version).to eql '2.6'
      expect(subject.tags).to match_array %w[Overhaul Graphics]
      expect(subject.remote_file_id).to eql '1'
      expect(subject.install_path).to eql Pathname.new('workshop/content/281990/1/')
    end

    it 'raises ArgumentError when file at specified path doesn\'t exist' do
      expect do
        described_class.new('non_existing_path')
      end.to raise_error ArgumentError, "File 'non_existing_path' doesn\'t exist"
    end
  end

  describe '#install' do
    let(:install_dir) do
      path = 'tmp/stellaris'

      FileUtils.mkdir_p(path) unless Dir.exist?(path)

      Dir.new(path)
    end
    let(:asset_path) do
      Pathname.new(install_dir.path).join('workshop/content/281990/1/')
    end

    after(:each) { FileUtils.rm_rf(install_dir, secure: true) }

    context 'when NO mod with the same remote file id is installed' do
      include_examples 'succesful installation', :keep, true
    end

    context 'when mod with the same remote file id is installed' do
      before(:each) { subject.install(install_dir) }

      context 'when mode :replace' do
        include_examples 'succesful installation', :replace
      end

      context 'when mode :keep' do
        it 'should return :exists' do
          expect(subject.install(install_dir, mode: :keep)).to eql(:exists)
        end
      end
    end
  end
end
