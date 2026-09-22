#!/usr/bin/env bash
# Cut a weekly patch on the TEST server. Two steps:
#
#   tools/custom/release.sh notes patch-2026-09-29   add a draft section to docs/custom/RELEASES.md from the
#                                                    commits since the last patch-* tag; then edit it by hand
#   tools/custom/release.sh tag patch-2026-09-29     after the notes are edited and committed: push `custom`,
#                                                    create the annotated tag (message = the notes) and push it
#
# Then on prod: tools/custom/deploy.sh --dry-run patch-2026-09-29, and tools/custom/deploy.sh patch-2026-09-29.
# See docs/custom/DEPLOY.md.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

NOTES_FILE="docs/custom/RELEASES.md"
BRANCH="custom"
MARKER="<!-- new releases go below this line -->"

red()   { printf '\e[31m%s\e[0m\n' "$*"; }
green() { printf '\e[32m%s\e[0m\n' "$*"; }
die()   { red "ERROR: $*"; exit 1; }
usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

check_tag_name() {
    [[ "$1" =~ ^patch-[0-9]{4}-[0-9]{2}-[0-9]{2}(-[0-9a-z]+)?$ ]] || die "tag must look like patch-YYYY-MM-DD (optionally -2, -hotfix, ...)"
    ! git rev-parse -q --verify "refs/tags/$1" > /dev/null || die "tag $1 already exists"
}

# Start of the range: the last patch tag, or (first release) where custom branched from upstream.
range_start() {
    git describe --tags --abbrev=0 --match 'patch-*' 2>/dev/null || git merge-base HEAD upstream/base
}

# The notes section for a tag: from its "## <tag>" heading up to the next "## " heading.
section() {
    awk -v h="## $1" '$0 == h {on=1; print; next} on && /^## / {exit} on {print}' "$NOTES_FILE"
}

cmd_notes() {
    local tag="$1"
    check_tag_name "$tag"
    grep -qxF "## $tag" "$NOTES_FILE" && die "$NOTES_FILE already has a section for $tag"
    grep -qxF "$MARKER" "$NOTES_FILE" || die "marker line missing from $NOTES_FILE: $MARKER"

    local from; from="$(range_start)"
    local label; label="$(git describe --tags --exact-match "$from" 2>/dev/null || git rev-parse --short "$from")"
    local commits; commits="$(git log --first-parent --no-merges --reverse --format='- %s (%h)' "$from..HEAD")"
    [[ -n "$commits" ]] || die "no commits since $label"
    local upstream_n; upstream_n=$(( $(git rev-list --count "$from..HEAD") - $(git rev-list --count --first-parent "$from..HEAD") ))
    local changed; changed="$(git diff --name-only "$from" HEAD)"

    local rebuild="no"
    grep -q '^src/\|CMake\|^cmake/\|^ext/' <<< "$changed" && rebuild="yes (C++ changed)"
    local sqlfiles; sqlfiles="$(grep '^sql/.*\.sql$' <<< "$changed" | sed 's/^/  - /' || true)"
    local migrations; migrations="$(grep '^tools/custom/migrations/.*\.sql$' <<< "$changed" | sed 's/^/  - /' || true)"
    local defaults; defaults="$(grep '^settings/default/' <<< "$changed" | sed 's/^/  - /' || true)"

    local draft
    draft="$(cat <<EOF
## $tag

**Status: DRAFT** (remove this line when the notes are done)

### For players
TODO: a few plain sentences about what changed in game. Leave out anything testers won't notice.

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored \`settings/*.lua\`: TODO (write "none" if none)
- Other manual steps (sudo, systemd, one-off commands): TODO (write "none" if none)
- Rebuild: $rebuild
- \`sql/\` files that \`dbtool update\` will re-import:
${sqlfiles:-  - none}
- New custom migrations:
${migrations:-  - none}
- \`settings/default/\` changed upstream (compare with prod's \`settings/*.lua\`):
${defaults:-  - none}

### Commits since $label
$commits
$( (( upstream_n > 0 )) && echo "- plus $upstream_n upstream LandSandBoat commit(s) merged" )

EOF
)"
    # Insert right after the marker, so the newest release is on top.
    local tmp; tmp="$(mktemp)"
    DRAFT="$draft" awk -v m="$MARKER" '{print} $0 == m {print ""; print ENVIRON["DRAFT"]}' "$NOTES_FILE" > "$tmp"
    mv "$tmp" "$NOTES_FILE"
    green "Draft added to $NOTES_FILE. Fill in the TODOs, delete the DRAFT line, commit, then run:"
    echo "  tools/custom/release.sh tag $tag"
}

cmd_tag() {
    local tag="$1"
    check_tag_name "$tag"
    [[ "$(git branch --show-current)" == "$BRANCH" ]] || die "not on branch $BRANCH"
    [[ -z "$(git status --porcelain --untracked-files=no)" ]] || { git status --short --untracked-files=no; die "commit or stash your changes first"; }

    local notes; notes="$(section "$tag")"
    [[ -n "$notes" ]] || die "no '## $tag' section in $NOTES_FILE; run: release.sh notes $tag"
    grep -q 'DRAFT\|TODO' <<< "$notes" && die "the $tag notes still contain DRAFT or TODO"
    git diff --quiet HEAD -- "$NOTES_FILE" || die "$NOTES_FILE has uncommitted edits"

    echo "Tagging $(git log -1 --format='%h %s') as $tag with these notes:"
    echo "----------------------------------------"
    echo "$notes"
    echo "----------------------------------------"
    read -r -p "Push $BRANCH and $tag to origin? [y/N] " answer
    [[ "$answer" == [yY] ]] || die "aborted"

    git push origin "$BRANCH"
    git tag -a "$tag" --cleanup=verbatim -F - <<< "$notes"
    git push origin "$tag"
    green "Pushed $tag. On prod:"
    echo "  tools/custom/deploy.sh --dry-run $tag"
    echo "  tools/custom/deploy.sh $tag"
}

case "${1:-}" in
    notes) [[ -n "${2:-}" ]] || usage; cmd_notes "$2" ;;
    tag)   [[ -n "${2:-}" ]] || usage; cmd_tag "$2" ;;
    *)     usage ;;
esac
