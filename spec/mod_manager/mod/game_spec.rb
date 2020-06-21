# frozen_string_literal: true

RSpec.describe ModManager::Mod::Game do
  describe '#new' do
    let(:mod_config) { file_fixture('stellaris/mod/1.mod') }
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

    subject { described_class.new(mod_config.path) }

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
end
