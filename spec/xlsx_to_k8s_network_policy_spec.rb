require "roo"
require "xlsx_to_k8s_network_policy"

RSpec.describe Reader do
  it "works" do
    config = Reader.read("./test/fixtures/network_policy.xlsx")
    expect(config.zones.size).to eq(3)
    expect(config.zones.map(&:name)).to eq(["Front End", "Back End", "Infrastructure"])
    expect(config.zones.map(&:cidrs)).to eq([["10.10.1.0/24", "10.10.2.0/24"], ["10.11.0.0/24"], ["10.12.0.0/24"]])
  end
end
