package: alidist.bits
version: "1"
tag: "master"
provides_repository: true
always_load: true
source: https://github.com/alisw/alidist
# Read-only reuse store for the prebuilt tarballs of the alidist recipes (the
# aliBuild build cache). bits reads it as the remote store when this provider is
# loaded, and writes freshly-built packages to the community store instead —
# so a build using alidist recipes reuses these tarballs with no extra flags.
# Non-hashed. Requires no credentials.
read_store: https://s3.cern.ch/swift/v1/alibuild-repo
---

