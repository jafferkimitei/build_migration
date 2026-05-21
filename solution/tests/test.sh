#!/usr/bin/env bash
set -u

RUN_DIR="$(pwd -P)"

TASK_ROOT=""
WORKSPACE_ROOT=""

if [ -f "$RUN_DIR/workspace/package.json" ]; then
  TASK_ROOT="$RUN_DIR"
  WORKSPACE_ROOT="$RUN_DIR/workspace"
elif [ -f "/workspace/workspace/package.json" ]; then
  TASK_ROOT="/workspace"
  WORKSPACE_ROOT="/workspace/workspace"
elif [ -f "/app/workspace/package.json" ]; then
  TASK_ROOT="/app"
  WORKSPACE_ROOT="/app/workspace"
else
  echo "Could not locate workspace/package.json"
  echo "Current directory: $RUN_DIR"
  find /workspace /app /tmp -maxdepth 4 -path "*/workspace/package.json" 2>/dev/null || true

  if mkdir -p /logs/verifier >/dev/null 2>&1 && [ -w /logs/verifier ]; then
    echo 0 > /logs/verifier/reward.txt
  else
    mkdir -p "$RUN_DIR/.logs/verifier"
    echo 0 > "$RUN_DIR/.logs/verifier/reward.txt"
  fi

  exit 1
fi

if [ -f "/tests/test_frontend_build.py" ]; then
  TEST_ROOT="/tests"
else
  TEST_ROOT="$TASK_ROOT/tests"
fi

if mkdir -p /logs/verifier >/dev/null 2>&1 && [ -w /logs/verifier ]; then
  REWARD_FILE="/logs/verifier/reward.txt"
else
  mkdir -p "$TASK_ROOT/.logs/verifier"
  REWARD_FILE="$TASK_ROOT/.logs/verifier/reward.txt"
fi

rm -f "$REWARD_FILE"

export TASK_ROOT_FOR_TESTS="$TASK_ROOT"
export WORKSPACE_ROOT_FOR_TESTS="$WORKSPACE_ROOT"

echo "TASK_ROOT=$TASK_ROOT"
echo "WORKSPACE_ROOT=$WORKSPACE_ROOT"
echo "TEST_ROOT=$TEST_ROOT"

cd "$TEST_ROOT"
python -m pytest -q test_frontend_build.py
test_status=$?

if [ "$test_status" -eq 0 ]; then
  echo 1 > "$REWARD_FILE"
else
  echo 0 > "$REWARD_FILE"
fi

exit "$test_status"
