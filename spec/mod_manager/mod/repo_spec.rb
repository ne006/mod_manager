# frozen_string_literal: true

RSpec.describe ModManager::Mod::Repo do
  describe '#new' do
    let(:mod_archive) { file_fixture('repo/2.7.1/2094171721_War_Name_Variety_-_UPDATED.zip') }
    let(:metadata_raw) do
      {
        'version' => '2.7',
        'tags' => %w[
          Overhaul
          Graphics
        ],
        'name' => 'War Name Variety - UPDATED',
        'picture' => 'thumbnail.png',
        'supported_version' => '2.7',
        'remote_file_id' => '2094171721',
        'path' => 'workshop/content/281990/2094171721/'
      }
    end

    before(:each) do
      pdx_config_parser = class_double('ModManager::ParadoxConfigParser')
      allow(pdx_config_parser).to receive(:parse).and_return(metadata_raw)
    end

    subject { described_class.new(mod_archive.path) }

    it 'loads mod metadata' do
      expect(subject.name).to eql 'War Name Variety - UPDATED'
      expect(subject.game.name).to eql 'Stellaris'
      expect(subject.game.version).to eql '2.7'
      expect(subject.tags).to match_array %w[Overhaul Graphics]
      expect(subject.remote_file_id).to eql '2094171721'
      expect(subject.install_path).to eql Pathname.new('workshop/content/281990/2094171721/')
    end

    it 'raises ArgumentError when file at specified path doesn\'t exist' do
      expect do
        described_class.new('non_existing_path')
      end.to raise_error ArgumentError, "File 'non_existing_path' doesn\'t exist"
    end
  end
end
