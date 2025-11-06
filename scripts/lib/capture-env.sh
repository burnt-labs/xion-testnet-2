#!/bin/bash
# Helper function to capture script output and write to GITHUB_ENV
# Usage: source scripts/lib/capture-env.sh && capture_env <command>

capture_env() {
  local output
  output=$("$@")
  local exit_code=$?

  # Print output for logging
  echo "$output"

  # If successful, parse key=value pairs and write to GITHUB_ENV
  if [ $exit_code -eq 0 ] && [ -n "$GITHUB_ENV" ]; then
    echo "$output" | grep -E '^[A-Z_]+=' >> "$GITHUB_ENV" || true
  fi

  return $exit_code
}
