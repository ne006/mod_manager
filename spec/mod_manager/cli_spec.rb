# frozen_string_literal: true

RSpec.shared_examples 'invalid usage' do |executor|
  it 'should output usage' do
    expect(out).to receive(:puts).with(<<~USAGE
      Usage: command
          -m, --mode [MODE]                mode of operation
          -s, --source [SOURCE]            source to look for mods
    USAGE
                                      )

    instance_exec(&executor) if executor
  end
end

RSpec.describe ModManager::CLI do
  let(:out) do
    io = double(IO)

    allow(io).to receive(:puts)

    io
  end

  subject { described_class.new(out) }

  let(:instance) { double(ModManager::Instance) }

  before(:each) do
    stellaris26 = double('ModManager::Game', name: 'Stellaris', version: '2.6')
    stellaris27 = double('ModManager::Game', name: 'Stellaris', version: '2.7')

    repo_mod1 = double(
      'ModManager::Mod::Repo',
      name: 'Mod 1',
      tags: %w[
        Overhaul
        Graphics
      ],
      remote_file_id: '1',
      path: 'workshop/content/281990/1/',
      game: stellaris26
    )

    repo_mod2 = double(
      'ModManager::Mod::Repo',
      name: 'Mod 2',
      tags: %w[
        Overhaul
        Gameplay
      ],
      remote_file_id: '2',
      path: 'workshop/content/281990/2/',
      game: stellaris27
    )

    game_mod1 = double(
      'ModManager::Mod::Game',
      name: 'Mod 1',
      tags: %w[
        Overhaul
        Graphics
      ],
      remote_file_id: '1',
      path: 'workshop/content/281990/1/',
      game: stellaris26
    )

    allow(instance).to receive(:list).with(:repo).and_return([repo_mod1, repo_mod2])
    allow(instance).to receive(:list).with(:game).and_return([game_mod1])

    allow(instance).to receive(:install) do |args|
      mode = args.fetch(:mode, :keep)
      callback = args.fetch(:on_event, proc {})

      case mode
      when :replace
        callback.call(ModManager::Event.new(:install_start, { mod: repo_mod1 }))
        callback.call(ModManager::Event.new(:install_end, { mod: repo_mod1, result: :ok }))
        callback.call(ModManager::Event.new(:install_start, { mod: repo_mod2 }))
        callback.call(ModManager::Event.new(:install_end, { mod: repo_mod2, result: :ok }))
      when :keep
        callback.call(ModManager::Event.new(:install_start, { mod: repo_mod1 }))
        callback.call(ModManager::Event.new(:install_end, { mod: repo_mod1, result: :exists }))
        callback.call(ModManager::Event.new(:install_start, { mod: repo_mod2 }))
        callback.call(ModManager::Event.new(:install_end, { mod: repo_mod2, result: :ok }))
      end
    end

    instance_klass = class_double(ModManager::Instance).as_stubbed_const

    allow(instance_klass).to receive(:new).and_return(instance)
  end

  describe '#start' do
    context 'list' do
      let(:execute) { subject.start(%w[list]) }

      it 'list mods in game dir then list mods in repo' do
        expect(out).to receive(:puts).with('Installed'.center(80, '-')).ordered
        expect(out).to receive(:puts).with('1. Mod 1 (id: 1, for Stellaris 2.6)').ordered
        expect(out).to receive(:puts).with('Repository'.center(80, '-')).ordered
        expect(out).to receive(:puts).with('1. Mod 1 (id: 1, for Stellaris 2.6)').ordered
        expect(out).to receive(:puts).with('2. Mod 2 (id: 2, for Stellaris 2.7)').ordered

        execute
      end

      context '--source repo' do
        let(:execute) { subject.start(%w[list --source repo]) }

        it 'lists mods in repo' do
          expect(out).to receive(:puts).with('List'.center(80, '-')).ordered
          expect(out).to receive(:puts).with('1. Mod 1 (id: 1, for Stellaris 2.6)').ordered
          expect(out).to receive(:puts).with('2. Mod 2 (id: 2, for Stellaris 2.7)').ordered

          execute
        end
      end

      context '--source repo' do
        let(:execute) { subject.start(%w[list --source game]) }

        it 'lists mods in game dir' do
          expect(out).to receive(:puts).with('List'.center(80, '-')).ordered
          expect(out).to receive(:puts).with('1. Mod 1 (id: 1, for Stellaris 2.6)').ordered

          execute
        end
      end

      context 'invalid options' do
        include_examples 'invalid usage', (proc do
          subject.start(%w[list --source invalid_source])
        end)
      end
    end

    context 'install' do
      let(:execute) { subject.start(%w[install]) }

      it 'should call install on instance' do
        expect(instance).to receive(:install).with(hash_including(mode: :keep))

        execute
      end

      it 'should output progress of installation' do
        expect(out).to receive(:puts).with('Mod 1 (id: 1, for Stellaris 2.6)').ordered
        expect(out).to receive(:puts).with("\texists").ordered
        expect(out).to receive(:puts).with('Mod 2 (id: 2, for Stellaris 2.7)').ordered
        expect(out).to receive(:puts).with("\tok").ordered

        execute
      end

      context '--mode replace' do
        let(:execute) { subject.start(%w[install --mode replace]) }

        it 'should call install on instance' do
          expect(instance).to receive(:install).with(hash_including(mode: :replace))

          execute
        end

        it 'should output progress of installation' do
          expect(out).to receive(:puts).with('Mod 1 (id: 1, for Stellaris 2.6)').ordered
          expect(out).to receive(:puts).with("\tok").ordered
          expect(out).to receive(:puts).with('Mod 2 (id: 2, for Stellaris 2.7)').ordered
          expect(out).to receive(:puts).with("\tok").ordered

          execute
        end
      end

      context '--mode keep' do
        let(:execute) { subject.start(%w[install --mode keep]) }

        it 'should call install on instance' do
          expect(instance).to receive(:install).with(hash_including(mode: :keep))

          execute
        end

        it 'should output progress of installation' do
          expect(out).to receive(:puts).with('Mod 1 (id: 1, for Stellaris 2.6)').ordered
          expect(out).to receive(:puts).with("\texists").ordered
          expect(out).to receive(:puts).with('Mod 2 (id: 2, for Stellaris 2.7)').ordered
          expect(out).to receive(:puts).with("\tok").ordered

          execute
        end
      end

      context 'invalid options' do
        include_examples 'invalid usage', (proc do
          subject.start(%w[install --mode invalid_mode])
        end)
      end
    end

    context 'invalid command' do
      include_examples 'invalid usage', (proc do
        subject.start(%w[invalid_command --invalid_option])
      end)
    end
  end
end
