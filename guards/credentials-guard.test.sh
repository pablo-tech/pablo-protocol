#!/usr/bin/env bash
# credentials-guard.sh against the index of a scratch repository, and against its policy files.
#   bash guards/credentials-guard.test.sh
# shellcheck disable=SC2016 # the fixtures below are credential literals; a `$` in one is the point
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../bin/check.sh"

fresh() { scratch_repo "$t/repo" >/dev/null; }
# stage path content
stage() { mkdir -p "$t/repo/$(dirname "$1")" && printf '%s\n' "$2" >"$t/repo/$1" && git -C "$t/repo" add -A; }
# allow name lines: write one of the repo's policy files
allow() { mkdir -p "$t/repo/.protocol" && printf '%s\n' "$2" >"$t/repo/.protocol/$1" && git -C "$t/repo" add -A; }
guard() { (cd "$t/repo" && bash "$DIR/credentials-guard.sh" >/dev/null 2>&1); }

KEY='-----BEGIN OPENSSH PRIVATE KEY-----'

fresh
stage notes.md "nothing to see"
check "an ordinary file passes" "guard"

fresh
stage infra/prod.env "REGION=us-west-2"
check "a file whose name has a credential shape is refused whatever it holds" "! guard"

fresh
stage infra/prod.env "REGION=us-west-2"
allow credentials-allow-name 'infra/prod.env'
check "credentials-allow-name exempts a named path from the shape rule" "guard"

fresh
stage infra/prod.env "PASSPHRASE=hunter2correct"
allow credentials-allow-name 'infra/prod.env'
check "a path exempt from the shape rule is still read for content" "! guard"

fresh
stage infra/a.env x && stage infra/b.env y
allow credentials-allow-name 'infra/*.env'
check "a policy entry is a glob, not one literal path" "guard"

fresh
stage secrets.env "$KEY"
allow credentials-allow-name '*'
allow credentials-allow-content '*'
check "a repository whose job is credentials lists * in both and commits them" "guard"

fresh
stage scratch/tunnel_token.txt "$KEY"
check "a key header is refused at a path no rule anticipated" "! guard"

fresh
stage doc.md 'the file starts `BEGIN OPENSSH PRIVATE KEY` on its first line'
check "prose naming a key header without its delimiters is documentation" "guard"

fresh
stage deploy.sh 'VAULT_PASSPHRASE=s3cretvalue'
check "a credential-named variable assigned a literal is refused" "! guard"

fresh
stage deploy.sh ': "${VAULT_PASSPHRASE:?set it}"'
check "a script declaring the credential it needs is correct code" "guard"

fresh
stage deploy.sh 'API_KEY=$(read_secret vault)'
check "a value derived by a command is not a literal" "guard"

fresh
stage README.md 'PASSWORD=CHANGEME'
check "a masked value reads as documentation" "guard"

fresh
stage suite.test.sh "KEY='$KEY'"
check "a test carrying a fixture is refused until it is named" "! guard"

fresh
stage suite.test.sh "KEY='$KEY'"
allow credentials-allow-content 'suite.test.sh'
check "credentials-allow-content exempts a named suite from the content rules" "guard"

fresh
stage suite.test.sh "KEY='$KEY'"
allow credentials-allow-content 'other.test.sh'
check "naming one suite does not exempt every suite" "! guard"

fresh
stage keys/id_ed25519 x
check "an ssh identity is refused by name" "! guard"

finish
