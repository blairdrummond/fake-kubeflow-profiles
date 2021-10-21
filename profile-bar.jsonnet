local name = "bar";
local owners = ["blair.drumond@cloud.statcan.ca"];
local profile = import 'profile.libsonnet';

profile(name, owners)
