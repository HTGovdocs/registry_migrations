require 'registry/registry_record'
require 'registry/source_record'
require './header' 
require 'pp'

include Registry
include Registry::Series
# Parse enumchrons for Congressional Record registry records 
#
deprecate_count = 0
source_count = 0
rr_count = 0

=begin
=end
RegistryRecord.where(series:"Congressional Record",
                     deprecated_timestamp:{"$exists":0}).no_timeout.each do |reg|
  reg.deprecate('Improved enum/chron parsing.')
  deprecate_count += 1
end

# Re-extract all the Source Records
SourceRecord.where(series: "CongressionalRecord",
                   deprecated_timestamp:{"$exists":0}).no_timeout.each do |src|
  source_count += 1

  # wth flasus?
  if src.org_code == 'flasus'
    f = src.source['fields'].find {|f| f['955'] }['955']['subfields']
    v = f.select { |h| h['v'] }[0]
    junk_sf = f.select { |h| h.keys[0] =~ /\./ }[0]
    if !junk_sf.nil?
      junk = junk_sf.keys[0]
      v['v'] = junk
      f.delete_if { |h| h.keys[0] =~ /\./ }
    end
  end

  src.source = src.source.to_json #re-extraction done here
  src.enum_chrons.each do | ec | 
    if regrec = RegistryRecord.where(series:"Congressional Record", 
                                     deprecated_timestamp:{"$exists":0}, 
                                     enumchron_display:ec).first
      if !regrec.source_record_ids.include? src.source_id 
        regrec.add_source(src)
        regrec.save
      end
    else
      regrec = RegistryRecord.new([src.source_id], ec, "Improved enum/chron parsing.")
      rr_count += 1
      regrec.series = "Congressional Record"
      regrec.save
    end
  end
  src.save

end

puts "# new RegRecs: #{rr_count}"
puts "Deprecated records: #{deprecate_count}"
puts "Source records: #{source_count}"
