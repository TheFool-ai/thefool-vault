#!/bin/sh
set -eu
cd "$(dirname "$0")"
npx --yes --package @c4a/agent-graph@0.3.1 agent-graph --manifest provider.json --format json validate
npx --yes --package @c4a/agent-graph@0.3.1 agent-graph --manifest provider.json --format json test tests
