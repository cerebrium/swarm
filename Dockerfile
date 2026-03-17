FROM node:20-bookworm-slim

# System deps: tmux for swarm pane spawning, git for worktrees
RUN apt-get update && apt-get install -y --no-install-recommends \
  tmux git curl ca-certificates iptables sudo \
  && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m -s /bin/bash claude \
  && echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Firewall script (copy your own or use Anthropic's reference)
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

# Switch to non-root user
USER claude
WORKDIR /workspace

# Enable agent teams + force tmux backend
ENV CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true
ENV CLAUDE_CODE_SPAWN_BACKEND=tmux
ENV CLAUDE_CONFIG_DIR=/home/claude/.claude

# Ensure a proper interactive terminal
ENV TERM=xterm-256color

# Entrypoint: runs Claude directly; agent teams manage their own tmux
COPY --chown=claude:claude entrypoint.sh /home/claude/entrypoint.sh
RUN chmod +x /home/claude/entrypoint.sh

ENTRYPOINT ["/home/claude/entrypoint.sh"]
