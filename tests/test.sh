#!/usr/bin/env bash
set -u

RUN_DIR="$(pwd -P)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

TASK_ROOT=""
WORKSPACE_ROOT=""

exact_candidates=(
  "$RUN_DIR/workspace/package.json"
  "/workspace/workspace/package.json"
  "/app/workspace/package.json"
)

for package_file in "${exact_candidates[@]}"; do
  if [ -f "$package_file" ]; then
    WORKSPACE_ROOT="$(cd "$(dirname "$package_file")" && pwd -P)"
    TASK_ROOT="$(cd "$WORKSPACE_ROOT/.." && pwd -P)"
    break
  fi
done

if [ -z "$WORKSPACE_ROOT" ]; then
  found_package="$(
    find /workspace /app /tmp "$RUN_DIR" -maxdepth 6 -path "*/workspace/package.json" 2>/dev/null | head -n 1
  )"
  if [ -n "$found_package" ] && [ -f "$found_package" ]; then
    WORKSPACE_ROOT="$(cd "$(dirname "$found_package")" && pwd -P)"
    TASK_ROOT="$(cd "$WORKSPACE_ROOT/.." && pwd -P)"
  fi
fi

if [ -z "$WORKSPACE_ROOT" ]; then
  TASK_ROOT="$RUN_DIR"
  WORKSPACE_ROOT="$RUN_DIR/workspace"
  echo "Could not locate workspace/package.json"
  echo "Current directory: $RUN_DIR"
  find /workspace /app /tmp "$RUN_DIR" -maxdepth 6 -path "*/workspace/package.json" 2>/dev/null || true
fi

if [ -f "/tests/test_frontend_build.py" ]; then
  TEST_ROOT="/tests"
elif [ -f "$TASK_ROOT/tests/test_frontend_build.py" ]; then
  TEST_ROOT="$TASK_ROOT/tests"
else
  found_test="$(
    find /tests /workspace /app /tmp "$RUN_DIR" -maxdepth 6 -path "*/tests/test_frontend_build.py" 2>/dev/null | head -n 1
  )"
  if [ -n "$found_test" ] && [ -f "$found_test" ]; then
    TEST_ROOT="$(cd "$(dirname "$found_test")" && pwd -P)"
  else
    TEST_ROOT="$SCRIPT_DIR"
  fi
fi

if mkdir -p /logs/verifier >/dev/null 2>&1 && [ -w /logs/verifier ]; then
  REWARD_FILE="/logs/verifier/reward.txt"
else
  mkdir -p "$TASK_ROOT/.logs/verifier" >/dev/null 2>&1 || mkdir -p "$RUN_DIR/.logs/verifier"
  if [ -d "$TASK_ROOT/.logs/verifier" ]; then
    REWARD_FILE="$TASK_ROOT/.logs/verifier/reward.txt"
  else
    REWARD_FILE="$RUN_DIR/.logs/verifier/reward.txt"
  fi
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
