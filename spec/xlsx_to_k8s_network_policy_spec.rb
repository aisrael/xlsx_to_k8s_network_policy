# frozen_string_literal: true

require 'roo'
require 'xlsx_to_k8s_network_policy'

FRONT_END = 'Front End'
BACK_END = 'Back End'

RSpec.describe 'xlsx_to_k8s_network_policy' do
  describe NetworkPolicies do
    describe '#to_hash' do
      it 'generates a deny_all policy when empty' do
        network_policies = NetworkPolicies.new
        actual = network_policies.to_doc_hashes
        expected = YAML.load_stream(File.open('./test/fixtures/deny_all.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with a single zone' do
        network_policies = NetworkPolicies.new
        network_policies.add_zone(FRONT_END, %w[10.10.1.0/24])
        actual = network_policies.to_doc_hashes
        expect(actual.size).to eq(2)
        expected = YAML.load_stream(File.open('./test/fixtures/single_zone.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with a single zone with multiple CIDRs' do
        network_policies = NetworkPolicies.new
        network_policies.add_zone(FRONT_END, %w[10.10.1.0/24 10.10.2.0/24])
        actual = network_policies.to_doc_hashes
        expect(actual.size).to eq(2)
        expected = YAML.load_stream(File.open('./test/fixtures/single_zone_with_multiple_cidrs.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with two independent zones' do
        network_policies = NetworkPolicies.new
        network_policies.add_zone(FRONT_END, %w[10.10.1.0/24])
        network_policies.add_zone(BACK_END, %w[10.11.0.0/24])
        actual = network_policies.to_doc_hashes
        expect(actual.size).to eq(3)
        expected = YAML.load_stream(File.open('./test/fixtures/two_independent_zones.yml'))
        expect(actual).to eq(expected)
      end
      it 'works with two connected zones' do
        network_policies = NetworkPolicies.new
        network_policies.add_zone(FRONT_END, %w[10.10.1.0/24])
        network_policies.add_zone(BACK_END, %w[10.11.0.0/24])
        network_policies.allow(FRONT_END, BACK_END)
        network_policies.allow(BACK_END, FRONT_END)
        actual = network_policies.to_doc_hashes
        expect(actual.size).to eq(3)
        expected = YAML.load_stream(File.open('./test/fixtures/two_connected_zones.yml'))
        expect(actual).to eq(expected)
      end
    end
  end

  describe Reader do
    it 'works' do
      network_policies = Reader.read('./test/fixtures/network_policy.xlsx')
      expect(network_policies.zones.size).to eq(3)
      expect(network_policies.zones.values.map(&:name)).to eq([FRONT_END, BACK_END, 'Infrastructure'])
      expected_cidrs = [%w[10.10.1.0/24 10.10.2.0/24], %w[10.11.0.0/24], %w[10.12.0.0/24]]
      expect(network_policies.zones.values.map(&:cidrs)).to eq(expected_cidrs)
    end
  end

  describe Writer do
    it 'works' do
      network_policies = NetworkPolicies.new
      {
        FRONT_END => %w[10.10.1.0/24 10.10.2.0/24],
        BACK_END => %w[10.11.0.0/24],
        'Infrastructure' => %w[10.12.0.0/24]
      }.each_pair do |name, cidrs|
        network_policies.add_zone(name, cidrs)
      end
      network_policies.allow(FRONT_END, BACK_END)
      network_policies.allow(BACK_END, FRONT_END)
      Writer.write(network_policies, 'tmp/writer_test.yml')
      docs = YAML.load_stream(File.open('tmp/writer_test.yml'))
      expect(docs.size).to eq(4)
    end
  end

  specify 'the end to end chain works' do
    network_policies = Reader.read('./test/fixtures/network_policies.xlsx')
    Writer.write(network_policies, 'tmp/network_policies.yml')
    docs = YAML.load_stream(File.open('tmp/network_policies.yml'))
    expect(docs.size).to eq(4)
  end
end
