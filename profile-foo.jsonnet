local name = "foo";
local owners = ["blair.drummond@cloud.statcan.ca"];
local profile = import 'profile.libsonnet';

profile(name, owners)
