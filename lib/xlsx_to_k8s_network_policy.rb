# frozen_string_literal: true

require 'active_support/core_ext/hash'
require 'roo'
require 'yaml'

# The NetworkPolicy
class NetworkPolicy
  attr_reader :zones, :rules
  def initialize
    @zones = []
    @rules = []
  end

  def zone_names
    @zones.map(&:name)
  end

  Zone = Struct.new(:name, :cidrs)

  Rule = Struct.new(:from_zone, :to_zone, :allow)

  def to_doc_hashes
    [NetworkPolicyDoc.new.to_hash]
  end

  private

  class NetworkPolicyDoc
    attr_reader :name
    def initialize(name = 'default-deny')
      @name = name
    end
    def to_hash
      {
        apiVersion: 'networking.k8s.io/v1',
        kind: 'NetworkPolicy',
        metadata: {
          name: name
        },
        spec: {
          podSelector: {},
          policyTypes: %w[Ingress Egress]
        }
      }.deep_stringify_keys
    end
  end
end

# Reads an XLSX file and creates the NetworkPolicy
class Reader
  attr_reader :file

  def self.read(file)
    Reader.new(file).read
  end

  def initialize(file)
    @file = file
  end

  def read
    @xlsx = Roo::Spreadsheet.open('./test/fixtures/network_policy.xlsx')
    @network_policy = NetworkPolicy.new
    read_zones
    read_rules
    @network_policy
  end

  private

  def read_zones
    zones_sheet = @xlsx.sheet('Zones')
    zones_sheet.each(name: 'Zone', cidrs: 'CIDRs') do |h|
      next if h[:name] == 'Zone' && h[:cidrs] == 'CIDRs'
      @network_policy.zones << NetworkPolicy::Zone.new(h[:name], h[:cidrs].split(/\s*,\s*/))
    end
  end

  def read_rules
    rules_sheet = @xlsx.sheet_for('ZoneToZone')
    column_zones = extract_column_zones(rules_sheet)
    extract_rules(rules_sheet, column_zones)
  end

  def extract_rules(rules_sheet, column_zones)
    rules_sheet.each_row(offset: 1) do |row|
      from_zone = row[0].value
      start_from = column_zones.index(from_zone) + 1
      raise %(From zone "#{from_zone}" not found in zones) unless start_from
      create_rules_from_row(column_zones, row, from_zone, start_from)
    end
  end

  def create_rules_from_row(column_zones, row, from_zone, start_from)
    (start_from...column_zones.size).each do |i|
      target = row.find do |cell|
        cell.coordinate.column == i + 2
      end
      to_zone = column_zones[i]
      rule = NetworkPolicy::Rule.new(from_zone, to_zone, target.value == 'Y')
      @network_policy.rules << rule
    end
  end

  def extract_column_zones(rules_sheet)
    first_row = rules_sheet.row(rules_sheet.first_row)
    column_zones = first_row[1..-1]
    column_zones.each do |to_name|
      raise %(To zone "#{from_zone}" not found in zones) unless @network_policy.zone_names.include?(to_name)
    end
    column_zones
  end
end

class Writer

  attr_reader :filename

  def initialize(filename)
    @filename = filename
  end

  def self.write(network_policy, filename)
    Writer.new(filename).write(network_policy)
  end

  def write(network_policy)
    File.open(filename, 'w+') do |f|
      YAML.dump_stream(network_policy.to_doc_hashes, f)
    end
  end

end
