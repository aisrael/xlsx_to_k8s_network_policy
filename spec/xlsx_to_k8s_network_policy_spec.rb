require "roo"
require "xlsx_to_k8s_network_policy"

RSpec.describe Reader do
  it "works" do
    config = Reader.read("./test/fixtures/network_policy.xlsx")
    expect(config.zones.size).to eq(2)
  end
end
