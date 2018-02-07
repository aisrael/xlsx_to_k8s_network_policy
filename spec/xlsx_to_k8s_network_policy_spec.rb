# frozen_string_literal: true

require 'roo'
require 'xlsx_to_k8s_network_policy'

FRONT_END = 'Front End'
BACK_END = 'Back End'

RSpec.describe 'xlsx_to_k8s_network_policy' do
  describe NetworkPolicy do
    describe '#to_hash' do
      it 'generates a deny_all policy when empty' do
        network_policy = NetworkPolicy.new
        actual = network_policy.to_doc_hashes
        expected = YAML.load_stream(File.open('./test/fixtures/deny_all.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with a single zone' do
        network_policy = NetworkPolicy.new
        network_policy.add_zone(FRONT_END, %w[10.10.1.0/24])
        actual = network_policy.to_doc_hashes
        expect(actual.size).to eq(2)
        expected = YAML.load_stream(File.open('./test/fixtures/single_zone.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with a single zone with multiple CIDRs' do
        network_policy = NetworkPolicy.new
        network_policy.add_zone(FRONT_END, %w[10.10.1.0/24 10.10.2.0/24])
        actual = network_policy.to_doc_hashes
        expect(actual.size).to eq(2)
        expected = YAML.load_stream(File.open('./test/fixtures/single_zone_with_multiple_cidrs.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with two independent zones' do
        network_policy = NetworkPolicy.new
        network_policy.add_zone(FRONT_END, %w[10.10.1.0/24])
        network_policy.add_zone(BACK_END, %w[10.11.0.0/24])
        actual = network_policy.to_doc_hashes
        expect(actual.size).to eq(3)
        expected = YAML.load_stream(File.open('./test/fixtures/two_independent_zones.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with two connected zones' do
        network_policy = NetworkPolicy.new
        network_policy.add_zone(FRONT_END, %w[10.10.1.0/24])
        network_policy.add_zone(BACK_END, %w[10.11.0.0/24])
        network_policy.add_rule(FRONT_END, BACK_END)
        network_policy.add_rule(BACK_END, FRONT_END)
        actual = network_policy.to_doc_hashes
        expect(actual.size).to eq(5)
        expected = YAML.load_stream(File.open('./test/fixtures/two_connected_zones.yml'))
        expect(actual).to eq(expected)
      end
    end
  end

  describe Reader do
    it 'works' do
      network_policy = Reader.read('./test/fixtures/network_policy.xlsx')
      expect(network_policy.zones.size).to eq(3)
      expect(network_policy.zones.map(&:name)).to eq([FRONT_END, BACK_END, 'Infrastructure'])
      expected_cidrs = [%w[10.10.1.0/24 10.10.2.0/24], %w[10.11.0.0/24], %w[10.12.0.0/24]]
      expect(network_policy.zones.map(&:cidrs)).to eq(expected_cidrs)
      expect(network_policy.rules.size).to eq(2)
    end
  end

  describe Writer do
    it 'works' do
      network_policy = NetworkPolicy.new
      {
        FRONT_END => %w[10.10.1.0/24 10.10.2.0/24],
        BACK_END => %w[10.11.0.0/24],
        'Infrastructure' => %w[10.12.0.0/24]
      }.each_pair do |name, cidrs|
        network_policy.add_zone(name, cidrs)
      end
      network_policy.add_rule(FRONT_END, BACK_END)
      network_policy.add_rule(BACK_END, FRONT_END)
      Writer.write(network_policy, 'tmp/network_policy.yml')
      docs = YAML.load_stream(File.open('tmp/network_policy.yml'))
      expect(docs.size).to eq(6)
    end
  end
end
