#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
ln -s /bin/true "$TMP/bin/tangent"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

run_live_case() {
    local state_root="$1" parent_id="$2" expected_lines="$3"
    local output new_id events

    output=$(PATH="$TMP/bin:$PATH" \
        COPILOT_STATE_ROOT="$state_root" \
        COPILOT_AGENT_SESSION_ID="$parent_id" \
        "$ROOT/tangent-full" test-branch "test prompt")
    new_id=$(sed -n 's/^tangent-full: forked session .* -> //p' <<< "$output")
    events="$state_root/$new_id/events.jsonl"

    [[ -f "$events" ]] || fail "forked event log was not created"
    [[ $(wc -l < "$events") -eq "$expected_lines" ]] ||
        fail "expected $expected_lines retained events in $events"
    grep -q 'trimmed triggering command turn' <<< "$output" ||
        fail "live fork did not report trimming its trigger turn"
    ! grep -q '/tangent:full' "$events" ||
        fail "triggering user command survived in $events"
}

CURRENT_ID=11111111-1111-1111-1111-111111111111
CURRENT_ROOT="$TMP/current"
mkdir -p "$CURRENT_ROOT/$CURRENT_ID"
cat > "$CURRENT_ROOT/$CURRENT_ID/workspace.yaml" <<EOF
id: $CURRENT_ID
cwd: $ROOT
git_root: $ROOT
EOF
cat > "$CURRENT_ROOT/$CURRENT_ID/events.jsonl" <<'EOF'
{"type":"session.start","data":{}}
{"type":"user.message","data":{"content":"earlier question"}}
{"type":"assistant.turn_start","data":{}}
{"type":"assistant.message","data":{"content":"earlier answer"}}
{"type":"assistant.turn_end","data":{}}
{"type":"system.message","data":{"content":"system"}}
{"type":"user.message","data":{"content":"/tangent:full eval-test run this prompt without shell quotes"}}
{"type":"assistant.turn_start","data":{}}
{"type":"tool.execution_start","data":{"toolName":"skill","arguments":{"skill":"full"}}}
{"type":"tool.execution_complete","data":{}}
{"type":"session.resume","data":{}}
{"type":"system.message","data":{"content":"system"}}
{"type":"user.message","data":{"content":"Run this prompt without shell quotes"}}
{"type":"assistant.turn_start","data":{}}
{"type":"tool.execution_start","data":{"toolName":"bash","arguments":{"command":"tangent-full \"eval-test\" \"Run this prompt without shell quotes\""}}}
EOF
run_live_case "$CURRENT_ROOT" "$CURRENT_ID" 5

LEGACY_ID=22222222-2222-2222-2222-222222222222
LEGACY_ROOT="$TMP/legacy"
mkdir -p "$LEGACY_ROOT/$LEGACY_ID"
cat > "$LEGACY_ROOT/$LEGACY_ID/workspace.yaml" <<EOF
id: $LEGACY_ID
cwd: $ROOT
git_root: $ROOT
EOF
cat > "$LEGACY_ROOT/$LEGACY_ID/events.jsonl" <<'EOF'
{"type":"session.start","data":{}}
{"type":"user.message","data":{"content":"earlier question"}}
{"type":"assistant.turn_end","data":{}}
{"type":"system.message","data":{"content":"system"}}
{"type":"user.message","data":{"content":"/tangent:full eval-test \"run this quoted prompt\""}}
{"type":"assistant.turn_start","data":{}}
{"type":"skill.invoked","data":{"name":"full","pluginName":"tangent"}}
{"type":"user.message","data":{"content":"<skill-context name=\"full\">"}}
{"type":"assistant.turn_end","data":{}}
{"type":"assistant.turn_start","data":{}}
{"type":"tool.execution_start","data":{"toolName":"bash","arguments":{"command":"tangent-full \"eval-test\" \"run this quoted prompt\""}}}
EOF
run_live_case "$LEGACY_ROOT" "$LEGACY_ID" 3

echo "PASS: tangent-full removes quoted and unquoted triggering turns"
