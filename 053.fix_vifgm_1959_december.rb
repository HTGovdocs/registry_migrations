require 'registry/registry_record'
require 'registry/source_record'
require './header' 
require 'pp'

include Registry
include Registry::Series

# George Mason gave us 50k records with a garbage enumchron of '1959 December' 
# Only ~10k of these made it into the registry. Fix the ones already in there,
# ignore the ones we have been ignoring up till now. 
SourceRecord.where(org_code:"vifgm",
                   enum_chrons:"1959 DECEMBER",
                   in_registry:true, 
                   deprecated_timestamp:{"$exists":0}).no_timeout.each do |src|

  src.source = src.source.to_json #re-extract enumchrons
  res = src.update_in_registry("Fixing bad enum/chrons. #{REPO_VERSION}")
  src.save
end    
