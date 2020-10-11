# frozen_string_literal: true

RSpec.shared_examples 'event generation' do |cycles, executor|
  it 'should generate :install_start, :install_end events, :register_start and :register_end events' do
    catcher = proc {}

    if cycles.is_a?(Hash)
      install_cycles = cycles.fetch(:install, 0)
      register_cycles = cycles.fetch(:register, 0)
    else
      install_cycles = cycles
      register_cycles = cycles
    end

    install_cycles.times do
      expect(catcher).to receive(:call) do |arg|
        expect(arg).to be_a(ModManager::Event)
        expect(arg.type).to eql(:install_start)
        expect(arg.metadata[:mod]).not_to be_nil
      end.once.ordered

      expect(catcher).to receive(:call) do |arg|
        expect(arg).to be_a(ModManager::Event)
        expect(arg.type).to eql(:install_end)
        expect(arg.metadata[:mod]).not_to be_nil
        expect(arg.metadata[:result]).to eql(:ok).or eql(:exists)
      end.once.ordered
    end

    register_cycles.times do
      expect(catcher).to receive(:call) do |arg|
        expect(arg).to be_a(ModManager::Event)
        expect(arg.type).to eql(:register_start)
        expect(arg.metadata[:mod]).not_to be_nil
      end.once.ordered

      expect(catcher).to receive(:call) do |arg|
        expect(arg).to be_a(ModManager::Event)
        expect(arg.type).to eql(:register_end)
        expect(arg.metadata[:mod]).not_to be_nil
        expect(arg.metadata[:result]).to eql(:ok)
      end.once.ordered
    end

    instance_exec(catcher, &executor) if executor
  end
end

RSpec.shared_examples 'mods installation' do |executor|
  it 'should call #install on mods' do
    mods.each do |mod|
      expect(mod).to receive(:install)
    end

    instance_exec(&executor) if executor
  end
end

RSpec.describe ModManager::Instance do
  let(:repo_dir) { file_fixture('repo/2.7.1') }
  let(:game_dir) { file_fixture('stellaris') }

  subject { described_class.new(repo_dir: repo_dir, game_dir: game_dir) }

  before(:each) do
    repo_mod_klass = class_double('ModManager::Mod::Repo').as_stubbed_const

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

    allow(repo_mod_klass).to  receive(:new)
      .with(Pathname.new(repo_dir).join('1.zip'))
      .and_return(repo_mod1)
    allow(repo_mod_klass).to  receive(:new)
      .with(Pathname.new(repo_dir).join('2.zip'))
      .and_return(repo_mod2)

    game_mod_klass = class_double('ModManager::Mod::Game').as_stubbed_const

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

    game_mod2 = double(
      'ModManager::Mod::Game',
      name: 'Mod 2',
      tags: %w[
        Overhaul
        Gameplay
      ],
      remote_file_id: '2',
      path: 'workshop/content/281990/2/',
      game: stellaris27
    )

    allow(game_mod_klass).to receive(:new)
      .with(Pathname.new(game_dir).join('mod/1.mod'))
      .and_return(game_mod1)

    allow(game_mod_klass).to receive(:new)
      .with(Pathname.new(game_dir).join('mod/2.mod'))
      .and_return(game_mod2)
  end

  describe '#list' do
    context ':repo' do
      it 'lists mods in repo' do
        expect(subject.list(:repo).size).to eql(2)
      end
    end

    context ':game' do
      it 'lists mods in game dir' do
        expect(subject.list(:game).size).to eql(1)
      end
    end
  end

  describe '#install' do
    let(:mods) do
      ['1.zip', '2.zip']
        .map { |archive| ModManager::Mod::Repo.new(Pathname.new(repo_dir).join(archive)) }
    end

    let(:game_mods) do
      ['mod/1.mod', 'mod/2.mod']
        .map { |config| ModManager::Mod::Game.new(Pathname.new(game_dir).join(config)) }
    end

    context 'when mods are not installed' do
      before(:each) do
        mods.each do |mod|
          allow(mod).to receive(:install).and_return(:ok)
        end

        game_mods.each do |mod|
          allow(mod).to receive(:register).and_return(:ok)
        end
      end

      include_examples 'mods installation', (proc do
        subject.install
      end)

      include_examples 'event generation', { install: 2, register: 1 }, (proc do |catcher|
        subject.install(on_event: catcher)
      end)
    end

    context 'when mods are already installed' do
      before(:each) do
        mods.each do |mod|
          allow(mod).to receive(:install).with(anything, mode: :replace).and_return(:ok)
          allow(mod).to receive(:install).with(anything, mode: :keep).and_return(:exists)
        end

        game_mods.each do |mod|
          allow(mod).to receive(:register).and_return(:ok)
        end

        %i[keep replace].each do |mode|
          context "mode :#{mode}" do
            include_examples 'mods installation', (proc do
              subject.install(mode: mode)
            end)

            include_examples 'event generation', { install: 2, register: 1 }, (proc do |catcher|
              subject.install(mode: mode, on_event: catcher)
            end)
          end
        end
      end
    end
  end
end
