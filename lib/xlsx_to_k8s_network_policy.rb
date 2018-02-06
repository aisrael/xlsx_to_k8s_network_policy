require "roo"

class Config
  attr_reader :zones
  def initialize
    @zones = {}
  end
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
    zones_sheet.each(zone: "Zone", cidr: "CIDRs") do |h|
      next if h[:zone] == "Zone" && h[:cidr] == "CIDRs"
      config.zones[h[:zone]] = h[:cidr]
    end
    config
  end
end
