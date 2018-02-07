# frozen_string_literal: true

require 'active_support/core_ext/hash'
require 'roo'
require 'yaml'

# The NetworkPolicy
class NetworkPolicy
  attr_reader :zones, :rules

  # A Zone
  class Zone
    attr_reader :name, :cidrs
    def initialize(name, cidrs)
      @name = name
      @cidrs = cidrs
    end

    def normalized_name
      name.parameterize
    end

    def as_partition_label_selector_hash
      @hash ||= {
        matchLabels: {
          partition: normalized_name
        }
      }
    end
  end

  # A Rule
  class Rule
    attr_accessor :from_zone, :to_zone
    def initialize(from_zone, to_zone)
      @from_zone = from_zone
      @to_zone = to_zone
    end

    # rubocop:disable Metrics/AbcSize
    def to_network_policy_doc
      # rubocop:enable Metrics/AbcSize
      normalized_from_zone_name = from_zone.normalized_name
      normalized_to_zone_name = to_zone.normalized_name
      npd = NetworkPolicyDoc.new("#{normalized_from_zone_name}-to-#{normalized_to_zone_name}")
      npd.pod_selector = to_zone.as_partition_label_selector_hash
      npd.allow_ingress(from_zone.as_partition_label_selector_hash)
      npd.allow_egress(from_zone.as_partition_label_selector_hash)
      from_zone.cidrs.each do |cidr|
        npd.allow_ingress(cidr)
        npd.allow_egress(cidr)
      end
      npd.to_hash
    end
  end

  def initialize
    @zones = []
    @rules = []
  end

  def zone_names
    @zones.map(&:name)
  end

  def add_zone(name, cidrs)
    @zones << Zone.new(name, cidrs)
  end

  def add_rule(from_zone_name, to_zone_name)
    from_zone = @zones.find { |z| z.name == from_zone_name }
    raise "No zone named #{from_zone_name}!" unless from_zone
    to_zone = @zones.find { |z| z.name == to_zone_name }
    raise "No zone named #{to_zone_name}!" unless to_zone
    @rules << Rule.new(from_zone, to_zone)
  end

  def to_doc_hashes
    docs = [NetworkPolicyDoc.deny_all.to_hash]
    docs += hash_zones
    docs + hash_rules
  end

  private

  def hash_zones
    @zones.map do |zone|
      normalized_zone_name = zone.normalized_name
      npd = NetworkPolicyDoc.new("intra-#{normalized_zone_name}")
      zone_partition_label_selector = zone.as_partition_label_selector_hash
      npd.pod_selector = zone_partition_label_selector
      npd.allow_ingress(zone_partition_label_selector)
      npd.allow_egress(zone_partition_label_selector)
      zone.cidrs.each do |cidr|
        npd.allow_ingress(cidr)
        npd.allow_egress(cidr)
      end
      npd.to_hash
    end
  end

  def hash_rules
    @rules.map(&:to_network_policy_doc)
  end

  # A NetworkPolicyDoc is a hash generator
  class NetworkPolicyDoc
    attr_reader :name
    attr_accessor :pod_selector
    attr_reader :ingresses
    def initialize(name)
      @name = name
      @pod_selector = {}
      @ingresses = []
      @egresses = []
    end

    def self.deny_all
      NetworkPolicyDoc.new('default-deny')
    end

    def allow_ingress(cidr_or_selector)
      case cidr_or_selector
      when String
        @ingresses << cidr_or_selector
      when Hash
        @ingresses << cidr_or_selector
      else
        raise "Don't know how to handle ingress spec: #{cidr_or_selector}!"
      end
    end

    def allow_egress(cidr_or_selector)
      case cidr_or_selector
      when String
        @egresses << cidr_or_selector
      when Hash
        @egresses << cidr_or_selector
      else
        raise "Don't know how to handle egress spec: #{cidr_or_selector}!"
      end
    end

    def to_hash
      hash = {
        apiVersion: 'networking.k8s.io/v1',
        kind: 'NetworkPolicy',
        metadata: {
          name: name
        },
        spec: {
          podSelector: pod_selector,
          policyTypes: %w[Ingress Egress]
        }
      }
      add_ingress_and_egress(hash)
      hash.deep_stringify_keys
    end

    def map_ingress_or_egress(ioe)
      ioe.map do |ingress|
        case ingress
        when String
          {
            ipBlock: ingress
          }
        else
          {
            podSelector: ingress
          }
        end
      end
    end

    private

    def add_ingress_and_egress(hash)
      unless @ingresses.empty?
        hash[:spec][:ingress] = [
          {
            from: map_ingress_or_egress(@ingresses)
          }
        ]
      end
      return if @egresses.empty?
      hash[:spec][:egress] = [
        {
          to: map_ingress_or_egress(@egresses)
        }
      ]
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
      @network_policy.add_zone(h[:name], h[:cidrs].split(/\s*,\s*/))
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
      @network_policy.add_rule(from_zone, to_zone) if target.value == 'Y'
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

# Writes a NetworkPolicy to YAML
class Writer
  attr_reader :filename

  def initialize(filename)
    @filename = filename
  end

  def self.write(network_policy, filename)
    Writer.new(filename).write(network_policy)
  end

  def write(network_policy)
    File.open(filename, 'w') do |f|
      f.write YAML.dump_stream(*network_policy.to_doc_hashes)
    end
  end
end
