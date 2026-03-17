# Testing Strategy — Claude Code Swarms in Docker

## Test Levels

### 1. Container Build Tests

Verify the image builds and has all required tools.

```bash
# Build succeeds
docker compose build

# Claude Code is installed and correct version
docker compose run --rm claude-swarm claude --version

# tmux is available (required for swarm pane spawning)
docker compose run --rm claude-swarm tmux -V

# git is available (required for worktrees)
docker compose run --rm claude-swarm git --version
```

### 2. Auth Tests

Verify authentication persists across restarts.

```bash
# First run — authenticate (interactive)
docker compose run --rm claude-swarm

# Second run — should NOT re-prompt for auth
docker compose run --rm claude-swarm claude --version
# Expected: prints version without auth prompt

# Verify config volume has token
docker volume inspect claude-config
```

### 3. Firewall Tests

Verify network isolation works.

```bash
# Run container with firewall
docker compose run --rm claude-swarm bash -c "
  # Should succeed: whitelisted domain
  curl -s --max-time 5 https://api.anthropic.com && echo 'API: OK'

  # Should fail: non-whitelisted domain
  curl -s --max-time 5 https://example.com && echo 'LEAK!' || echo 'Blocked: OK'
"
```

### 4. Swarm Functionality Tests

Verify agent teams actually work inside the container.

```bash
# Manual test: enter container and run Claude
docker compose run --rm claude-swarm

# Inside Claude, try spawning a team:
# Prompt: "Create a team with one teammate. Have them list files in /workspace."
# Expected: tmux splits into panes, teammate executes `ls`, reports back.
```

**What to verify:**

- [ ] `tmux list-panes` shows multiple panes after team spawn
- [ ] `~/.claude/teams/` directory is created with config.json
- [ ] `~/.claude/tasks/` directory is created with task entries
- [ ] Teammates can read/write files in `/workspace`
- [ ] Lead can shut down teammates gracefully

### 5. Resource Tests

Verify container doesn't run out of resources with multiple agents.

```bash
# Monitor memory during a swarm session
docker stats claude-swarm

# Expected: memory stays under the 8GB limit with 3 agents
# If it exceeds, increase mem_limit in docker-compose.yml
```

### 6. Persistence Tests

Verify workspace changes survive container restarts.

```bash
# Run 1: create a file via Claude
docker compose run --rm claude-swarm
# Prompt: "Create a file called test.txt with 'hello world'"
# Exit

# Verify file exists on host
cat test.txt
# Expected: "hello world"
```

## Automated Smoke Test Script

```bash
#!/bin/bash
# smoke-test.sh — Run after building the image
set -e

echo "=== Build test ==="
docker compose build

echo "=== Tool check ==="
docker compose run --rm --entrypoint bash claude-swarm -c "
  claude --version && echo 'claude: OK'
  tmux -V && echo 'tmux: OK'
  git --version && echo 'git: OK'
"

echo "=== Env check ==="
docker compose run --rm --entrypoint bash claude-swarm -c "
  [ \"\$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\" = 'true' ] && echo 'TEAMS env: OK'
  [ \"\$CLAUDE_CODE_SPAWN_BACKEND\" = 'tmux' ] && echo 'SPAWN env: OK'
"

echo "=== All smoke tests passed ==="
```
