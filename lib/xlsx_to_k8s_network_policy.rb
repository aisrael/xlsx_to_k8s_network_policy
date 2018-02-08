# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/hash'
require 'roo'
require 'yaml'

# A base label selector
class LabelSelector
  # A `matchLabels` label selector
  class MatchLabels < LabelSelector
    attr_reader :labels
    def initialize(labels = nil)
      @labels = labels || {}
    end

    def []=(key, value)
      @labels[key] = value
    end

    def as_hash
      return {} if @labels.empty?
      {
        matchLabels: @labels
      }
    end
  end
  # TODO: MatchExpressions < LabelSelector
  def ==(other)
    other.class == self.class && other.labels == labels
  end
end

# A `podSelector`
class PodSelector
  attr_reader :label_selector

  def initialize(label_selector = nil)
    @label_selector = label_selector || LabelSelector::MatchLabels.new
  end

  def []=(key, value)
    @label_selector[key] = value
  end

  def as_hash
    {
      podSelector: label_selector.as_hash
    }
  end

  def ==(other)
    other.class == self.class && other.label_selector == label_selector
  end
end

# The _real_ NetworkPolicy
class NetworkPolicy
  attr_reader :name
  attr_reader :pod_selector
  attr_reader :ingresses
  attr_reader :egresses

  def self.deny_all
    NetworkPolicy.new('default-deny', PodSelector.new)
  end

  def initialize(name, pod_selector)
    raise %(Invalid name "#{name}". Must consist of [a-z_-]+) unless /^[a-z_-]+$/ =~ name
    @name = name
    @pod_selector = pod_selector
    @ingresses = []
    @egresses = []
  end

  class NetworkPolicyPeer
    # An {ipBlock: cidr} NetworkPolicyPeer
    class IPBlock < NetworkPolicyPeer
      attr_reader :cidr
      def initialize(cidr = nil)
        @cidr = cidr || []
      end

      def as_hash
        {
          ipBlock: cidr
        }
      end

      def ==(other)
        other.class == self.class && other.cidr == cidr
      end
    end

    # A {podSelector: {...}} NetworkPolicyPeer
    class PodSelectorNPP < NetworkPolicyPeer
      attr_reader :pod_selector
      def initialize(pod_selector)
        @pod_selector = pod_selector
      end
      delegate :as_hash, to: :pod_selector
      def ==(other)
        other.class == self.class && other.pod_selector == pod_selector
      end
    end

    # A {namespaceSelector: {...}} NetworkPolicyPeer
    class NamespaceSelector < NetworkPolicyPeer
      attr_reader :label_selector
      def initialize(label_selector = nil)
        @label_selector = label_selector || LabelSelector::MatchLabels.new
      end

      def []=(key, value)
        @label_selector[key] = value
      end

      def as_hash
        {
          labelSelector: @label_selector.as_hash
        }
      end

      def ==(other)
        other.class == self.class && other.label_selector == label_selector
      end
    end
  end

  def add_pod_selector_ingress(pod_selector)
    add_ingress(NetworkPolicyPeer::PodSelectorNPP.new(pod_selector))
  end

  def add_pod_selector_egress(pod_selector)
    add_egress(NetworkPolicyPeer::PodSelectorNPP.new(pod_selector))
  end

  def add_cidr_ingress(cidr)
    add_ingress(NetworkPolicyPeer::IPBlock.new(cidr))
  end

  def add_cidr_egress(cidr)
    add_egress(NetworkPolicyPeer::IPBlock.new(cidr))
  end

  def add_ingress(ingress)
    npp = case ingress
          when PodSelector
            NetworkPolicyPeer::PodSelectorNPP.new(ingress)
          when NetworkPolicyPeer
            ingress
          else
            raise "Don't know how to handle ingress of type #{ingress.class}!"
          end
    @ingresses << npp unless @ingresses.include?(npp)
  end

  def add_egress(egress)
    npp = case egress
          when PodSelector
            NetworkPolicyPeer::PodSelectorNPP.new(egress)
          when NetworkPolicyPeer
            egress
          else
            raise "Don't know how to handle ingress of type #{egress.class}!"
          end
    @egresses << npp unless @egresses.include?(npp)
  end

  def as_hash
    policy_types = []
    policy_types << 'Ingress' if !@ingresses.empty? || @egresses.empty?
    policy_types << 'Egress' if !@egresses.empty? || @ingresses.empty?
    spec = pod_selector.as_hash
    spec[:policyTypes] = policy_types
    hash = {
      apiVersion: 'networking.k8s.io/v1',
      kind: 'NetworkPolicy',
      metadata: {
        name: name
      },
      spec: spec
    }
    add_ingress_and_egress(hash)
    hash.deep_stringify_keys
  end

  private

  def add_ingress_and_egress(hash)
    unless @ingresses.empty?
      hash[:spec][:ingress] = [
        {
          from: @ingresses.map(&:as_hash)
        }
      ]
    end
    return if @egresses.empty?
    hash[:spec][:egress] = [
      {
        to: @egresses.map(&:as_hash)
      }
    ]
  end
end

# A collection of `NetworkPolicy`s
class NetworkPolicies
  attr_reader :zones
  attr_reader :policies

  def initialize
    @zones = {}
    @policies = {}
  end

  def zone_names
    @zones.values.map(&:name)
  end

  def add_zone(name, cidrs)
    zone = Zone.new(name, cidrs)
    @zones[name] = zone
    @policies[zone] = zone.to_network_policy
  end

  def allow(from_zone_name, to_zone_name)
    from_zone = @zones[from_zone_name]
    raise "No zone named #{from_zone_name}!" unless from_zone
    to_zone = @zones[to_zone_name]
    raise "No zone named #{to_zone_name}!" unless to_zone
    from_zone.add_ingress_rules_to(policies[to_zone])
    to_zone.add_egress_rules_to(policies[from_zone])
  end

  def to_doc_hashes
    docs = [NetworkPolicy.deny_all] + @policies.values
    docs.map(&:as_hash)
  end

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

    def to_pod_selector
      @pod_selector ||= begin
        label_selector = LabelSelector::MatchLabels.new(zone: normalized_name)
        PodSelector.new(label_selector)
      end
    end

    def to_network_policy
      np = NetworkPolicy.new("#{normalized_name}-zone", to_pod_selector)
      add_ingress_rules_to(np)
      add_egress_rules_to(np)
      np
    end

    def add_ingress_rules_to(np)
      np.add_pod_selector_ingress(to_pod_selector)
      @cidrs.each do |cidr|
        np.add_cidr_ingress(cidr)
      end
    end

    def add_egress_rules_to(np)
      np.add_pod_selector_egress(to_pod_selector)
      @cidrs.each do |cidr|
        np.add_cidr_egress(cidr)
      end
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
    @network_policy = NetworkPolicies.new
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
      create_rules_from_row(column_zones, row, from_zone)
    end
  end

  def create_rules_from_row(column_zones, row, from_zone)
    column_zones.size.times do |i|
      target = row.find do |cell|
        cell.coordinate.column == i + 2
      end
      if target && target.value == 'Y'
        to_zone = column_zones[i]
        @network_policy.allow(from_zone, to_zone)
      end
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
