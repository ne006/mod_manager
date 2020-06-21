# frozen_string_literal: true

RSpec.describe ModManager::Instance do
  let(:repo_dir) { file_fixture('repo/2.7.1') }
  let(:game_dir) { file_fixture('stellaris') }

  subject { described_class.new(repo_dir: repo_dir, game_dir: game_dir) }

  before(:each) do
    repo_mod_klass = class_double('ModManager::Mod::Repo')

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

    game_mod_klass = class_double('ModManager::Mod::Game')

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

    allow(game_mod_klass).to receive(:new)
      .with(Pathname.new(game_dir).join('stellaris/mod/1.mod'))
      .and_return(game_mod1)
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
end
