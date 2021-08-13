#!/bin/sh

# Scrape the live profiles

ADMIN="nobody@statcan.gc.ca"

DIR="$1"
if test -z "$DIR"; then
	echo "Need to specify and output dir" >&2
	exit 1
else
	mkdir -p $DIR
fi

kubectl get profiles -o json | 
	jq -r '.items[] | .metadata.name' |
	while read name; do
		OWNER=$(kubectl get profile $name -o json | jq -r '.spec.owner.name')
		test "$OWNER" = "$ADMIN" && continue

		cat <<EOF | tee $DIR/profile-${name}.yaml
---
name: $name
owners:
  - $OWNER
EOF

	done
