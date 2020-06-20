# frozen_string_literal: true

RSpec.describe ModManager::ParadoxConfigParser do
  describe '.parse' do
    [
      {
        name: 'pairs without nesting',
        source: <<~CONF,
          picture="thumbnail.png"
          supported_version="2.7"
          remote_file_id="2094171721"
          path="workshop/content/281990/2094171721/"
        CONF
        result: {
          'picture' => 'thumbnail.png',
          'supported_version' => '2.7',
          'remote_file_id' => '2094171721',
          'path' => 'workshop/content/281990/2094171721/'
        }
      },
      {
        name: 'pairs with arrays as values',
        source: <<~CONF,
          tags={
            "Overhaul"
            "Graphics"
          }
          versions={
            '2.6'
            '2.7'
          }
        CONF
        result: {
          'tags' => %w[Overhaul Graphics],
          'versions' => ['2.6', '2.7']
        }
      },
      {
        name: 'nested hash',
        source: <<~CONF,
          game={
            name='Stellaris'
            versions={
              '2.6'
              '2.7'
            }
          }
        CONF
        result: {
          'game' => {
            'name' => 'Stellaris',
            'versions' => [
              '2.6', '2.7'
            ]
          }
        }
      }
    ].each do |test_case|
      context test_case[:name] do
        it 'should parse string into data structure' do
          expect(described_class.parse(test_case[:source])).to eql test_case[:result]
        end
      end
    end
  end
end
