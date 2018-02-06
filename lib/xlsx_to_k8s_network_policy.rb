require "roo"

class Config
  attr_reader :zones
  def initialize
    @zones = []
  end

  Zone = Struct.new(:name, :cidrs)
end

class Reader
  attr_reader :file

  def self.read(file)
    Reader.new(file).read
  end

  def initialize(file)
    @file = file
  end

  def read
    @xlsx = Roo::Spreadsheet.open("./test/fixtures/network_policy.xlsx")
    config = Config.new
    zones_sheet = @xlsx.sheet("Zones")
    zones_sheet.each(name: "Zone", cidrs: "CIDRs") do |h|
      next if h[:name] == "Zone" && h[:cidrs] == "CIDRs"
      config.zones << Config::Zone.new(h[:name], h[:cidrs].split(/\s*,\s*/))
    end
    config
  end
end
