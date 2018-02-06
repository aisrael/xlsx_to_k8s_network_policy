require "roo"

RSpec.describe "it" do
  it "works" do
    xlsx = Roo::Spreadsheet.open("./test/fixtures/network_policy.xlsx")
    puts xlsx.info
  end
end
