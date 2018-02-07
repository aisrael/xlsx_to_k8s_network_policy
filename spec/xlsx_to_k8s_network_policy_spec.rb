# frozen_string_literal: true

require 'roo'
require 'xlsx_to_k8s_network_policy'

RSpec.describe Reader do
  it 'works' do
    network_policy = Reader.read('./test/fixtures/network_policy.xlsx')
    expect(network_policy.zones.size).to eq(3)
    expect(network_policy.zones.map(&:name)).to eq(['Front End', 'Back End', 'Infrastructure'])
    expected_cidrs = [['10.10.1.0/24', '10.10.2.0/24'], ['10.11.0.0/24'], ['10.12.0.0/24']]
    expect(network_policy.zones.map(&:cidrs)).to eq(expected_cidrs)
    n = network_policy.zones.size
    expect(network_policy.rules.size).to eq((n * (n + 1)) / 2)
  end
end
