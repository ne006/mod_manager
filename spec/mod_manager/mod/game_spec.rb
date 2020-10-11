# frozen_string_literal: true

require 'json'

RSpec.describe ModManager::Mod::Game do
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

  describe '#register' do
    let(:registry_path) { Pathname.new('tmp/mods_registry.json') }
    let(:expected_registry_record) do
      {
        'gameRegistryId' => 'mod/1.mod',
        'source' => 'local',
        'steamId' => '1',
        'displayName' => 'Mod 1',
        'tags' => %w[
          Overhaul
          Graphics
        ],
        'requiredVersion' => '2.6',
        'dirPath' => 'workshop/content/281990/1/',
        'status' => 'ready_to_play'
      }
    end
    after(:each) { FileUtils.rm_f(registry_path) if File.exist?(registry_path) }

    def registry
      return {} unless File.exist?(registry_path)

      JSON.parse(File.read(registry_path))
    end

    def registry_record(steam_id:)
      registry
        .find { |_uuid, record| record['steamId'] == steam_id }
    end

    context 'when not registered' do
      it 'writes mod to the registry' do
        subject.register(registry_path)

        expect(registry_record(steam_id: '1')&.last).to include(expected_registry_record)
      end

      it 'generates UUID not present in the registry' do
        uuids = registry.keys

        subject.register(registry_path)

        expect(uuids).not_to include(registry_record(steam_id: '1')&.first)
      end
    end

    context 'when registered' do
      before(:each) { subject.register(registry_path) }

      it 'updates the mod in the registry matching on steamId' do
        new_name = subject.instance_variable_set(:@name, 'Mod 1: Remake')
        new_expected_registry_record = expected_registry_record.merge({ 'displayName' => new_name })

        subject.register(registry_path)

        expect(registry_record(steam_id: '1')&.last).to include(new_expected_registry_record)
      end

      it 'reuses the UUID' do
        uuid = registry_record(steam_id: '1')&.first

        subject.register(registry_path)

        expect(registry_record(steam_id: '1')&.first).to eql(uuid)
        expect(registry_record(steam_id: '1')&.last&.fetch('id', '')).to eql(uuid)
      end
    end
  end
end
