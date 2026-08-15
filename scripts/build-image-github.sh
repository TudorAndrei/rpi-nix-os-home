#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
output_dir="${repo_root}/build/github"
output_format="text"
dry_run=false
workflow="build-image.yml"

usage() {
  cat <<'EOF'
Start the GitHub Actions image build and download its artifacts.

Usage:
  scripts/build-image-github.sh [options]

Options:
  --output-dir PATH     Download artifacts to PATH. Default: ./build/github
  --output text|json   Select the final output format. Default: text
  --dry-run            Show remote changes without making them
  -h, --help           Show this help
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --output-dir)
      (($# >= 2)) || fail "--output-dir needs a path"
      output_dir="$2"
      shift 2
      ;;
    --output)
      (($# >= 2)) || fail "--output needs text or json"
      output_format="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

case "$output_format" in
  text|json) ;;
  *) fail "--output must be text or json" ;;
esac

if "$dry_run"; then
  printf 'gh workflow run %q\n' "$workflow"
  printf 'wait for the new workflow run\n'
  printf 'gh run download RUN_ID --name living-room-sd-image --dir %q\n' "$output_dir"
  exit 0
fi

command -v gh >/dev/null 2>&1 || fail "gh is not available"

gh auth status >/dev/null 2>&1 || fail "GitHub CLI is not authenticated"

previous_run="$(
  gh run list \
    --workflow "$workflow" \
    --event workflow_dispatch \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId // empty'
)"

gh workflow run "$workflow" >&2

run_id=""
for _ in $(seq 1 30); do
  run_id="$(
    gh run list \
      --workflow "$workflow" \
      --event workflow_dispatch \
      --limit 1 \
      --json databaseId \
      --jq '.[0].databaseId // empty'
  )"

  if [[ -n "$run_id" && "$run_id" != "$previous_run" ]]; then
    break
  fi

  sleep 2
done

[[ -n "$run_id" && "$run_id" != "$previous_run" ]] || fail "could not find the new workflow run"

gh run watch "$run_id" --exit-status >&2

run_output_dir="${output_dir}/${run_id}"
mkdir -p -- "$run_output_dir"
gh run download "$run_id" \
  --name living-room-sd-image \
  --dir "$run_output_dir" >&2

case "$output_format" in
  text)
    printf 'Run ID: %s\n' "$run_id"
    printf 'Artifacts: %s\n' "$run_output_dir"
    ;;
  json)
    printf '{"run_id":%s,"artifacts":"%s"}\n' "$run_id" "$run_output_dir"
    ;;
esac
