#!/usr/bin/env bash
#
# Copyright 2026 Ankit Agarwal
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# install.sh — Install AI Scrum Team agents into ~/.claude/agents/
#
# Usage:
#   ./install.sh              Install or update agents
#   ./install.sh --update     Same as above (explicit)
#   ./install.sh --uninstall  Remove installed agents
#   ./install.sh --help       Show usage information

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC_DIR="${SCRIPT_DIR}/agents"
AGENTS_DEST_DIR="${HOME}/.claude/agents"

# The six agent files that make up the AI scrum team.
AGENT_FILES=(
  "john.md"
  "penny.md"
  "aria.md"
  "dave.md"
  "remy.md"
  "tess.md"
)

# Agent display metadata: name | role | color-code
AGENT_META=(
  "john|Scrum Master & Orchestrator|green"
  "penny|Product Manager|blue"
  "aria|Architect|cyan"
  "dave|Developer|yellow"
  "remy|Code Reviewer|red"
  "tess|Tester|magenta"
)

# Legacy agent filenames from earlier releases: the v0.3.0 rename (Fenny/Disha/
# Parminder/David/Harpreet/Murat) and the v0.4.0 Dev->Dave rename (dev.md). Removed
# on install and uninstall so old files never linger in ~/.claude/agents/.
OLD_AGENT_FILES=(
  "fenny.md"
  "disha.md"
  "parminder.md"
  "david.md"
  "dev.md"
  "harpreet.md"
  "murat.md"
)

# Legacy per-agent memory filename -> current filename, for migrating a project's
# .scrum/memory/ after a rename. Covers the v0.3.0 real-name -> neutral-name rename
# and the v0.4.0 Dev -> Dave rename (both .david.md and .dev.md map to .dave.md).
# Each pair is applied independently — renamed only when the old file exists and the
# new one does not — so a project from any prior version lands on the current names.
MEMORY_RENAMES=(
  ".fenny.md:.john.md"
  ".disha.md:.penny.md"
  ".parminder.md:.aria.md"
  ".david.md:.dave.md"
  ".dev.md:.dave.md"
  ".harpreet.md:.remy.md"
  ".murat.md:.tess.md"
)

# ---------------------------------------------------------------------------
# Color support
# ---------------------------------------------------------------------------

setup_colors() {
  if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]] && [[ "${TERM:-}" != "dumb" ]]; then
    BOLD="\033[1m"
    RESET="\033[0m"
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    MAGENTA="\033[35m"
    CYAN="\033[36m"
    DIM="\033[2m"
  else
    BOLD="" RESET="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" DIM=""
  fi
}

# Map color names to ANSI codes for agent display.
color_for() {
  case "$1" in
    red)     printf '%b' "${RED}" ;;
    green)   printf '%b' "${GREEN}" ;;
    yellow)  printf '%b' "${YELLOW}" ;;
    blue)    printf '%b' "${BLUE}" ;;
    magenta) printf '%b' "${MAGENTA}" ;;
    cyan)    printf '%b' "${CYAN}" ;;
    *)       printf '%b' "${RESET}" ;;
  esac
}

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

info()    { printf "${BOLD}${BLUE}==>${RESET} %s\n" "$1"; }
success() { printf "${BOLD}${GREEN} ✓${RESET}  %s\n" "$1"; }
warn()    { printf "${BOLD}${YELLOW} !${RESET}  %s\n" "$1" >&2; }
error()   { printf "${BOLD}${RED} ✗${RESET}  %s\n" "$1" >&2; }

# ---------------------------------------------------------------------------
# Version detection
# ---------------------------------------------------------------------------

get_version() {
  local version_file="${SCRIPT_DIR}/VERSION"
  if [[ -f "${version_file}" ]]; then
    cat "${version_file}"
  else
    echo "dev"
  fi
}

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

check_claude_cli() {
  if command -v claude >/dev/null 2>&1; then
    success "Claude Code CLI detected"
  else
    warn "Claude Code CLI not found in PATH"
    warn "Install it from https://docs.anthropic.com/en/docs/claude-code"
    warn "Agents will be installed but won't work without the CLI"
    echo ""
  fi
}

check_source_agents() {
  if [[ ! -d "${AGENTS_SRC_DIR}" ]]; then
    error "Source agents directory not found: ${AGENTS_SRC_DIR}"
    error "Run this script from the project root"
    exit 1
  fi

  local missing=()
  for file in "${AGENT_FILES[@]}"; do
    if [[ ! -f "${AGENTS_SRC_DIR}/${file}" ]]; then
      missing+=("${file}")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing agent files (will skip): ${missing[*]}"
  fi
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

do_install() {
  local version
  version="$(get_version)"

  echo ""
  printf "${BOLD}  AI Scrum Team Installer${RESET}"
  if [[ "${version}" != "dev" ]]; then
    printf "  ${DIM}v%s${RESET}" "${version}"
  fi
  echo ""
  echo ""

  check_claude_cli
  check_source_agents

  # Ensure destination directory exists.
  if [[ ! -d "${AGENTS_DEST_DIR}" ]]; then
    info "Creating ${AGENTS_DEST_DIR}"
    mkdir -p "${AGENTS_DEST_DIR}"
  fi

  info "Installing agents to ${AGENTS_DEST_DIR}"
  echo ""

  local installed=0
  local skipped=0
  local updated=0
  local removed=0

  # Remove any legacy-named agent files from before the v0.3.0 rename so a
  # re-install replaces the old team instead of leaving stale duplicates behind.
  for old in "${OLD_AGENT_FILES[@]}"; do
    if [[ -f "${AGENTS_DEST_DIR}/${old}" ]]; then
      rm -f "${AGENTS_DEST_DIR}/${old}"
      printf "  ${DIM}[  --  ]${RESET}  %s ${DIM}(removed legacy file)${RESET}\n" "${old}"
      removed=$((removed + 1))
    fi
  done

  for meta in "${AGENT_META[@]}"; do
    IFS='|' read -r name role color <<< "${meta}"
    local file="${name}.md"
    local src="${AGENTS_SRC_DIR}/${file}"
    local dest="${AGENTS_DEST_DIR}/${file}"
    local c
    c="$(color_for "${color}")"

    if [[ ! -f "${src}" ]]; then
      printf "  ${DIM}[ skip ]${RESET}  %s — source file not found\n" "${name}"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ -f "${dest}" ]] && diff -q "${src}" "${dest}" >/dev/null 2>&1; then
      printf "  ${DIM}[  up  ]${RESET}  ${c}%-12s${RESET} %s ${DIM}(already current)${RESET}\n" "${name}" "${role}"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ -f "${dest}" ]]; then
      cp "${src}" "${dest}"
      printf "  ${BOLD}[  !!  ]${RESET}  ${c}%-12s${RESET} %s ${DIM}(updated)${RESET}\n" "${name}" "${role}"
      updated=$((updated + 1))
    else
      cp "${src}" "${dest}"
      printf "  ${BOLD}[  ++  ]${RESET}  ${c}%-12s${RESET} %s\n" "${name}" "${role}"
      installed=$((installed + 1))
    fi
  done

  echo ""
  echo "  ─────────────────────────────────────────"
  printf "  ${GREEN}%d installed${RESET}  ${YELLOW}%d updated${RESET}  ${DIM}%d unchanged${RESET}  ${DIM}%d legacy removed${RESET}\n" \
    "${installed}" "${updated}" "${skipped}" "${removed}"
  echo ""

  if [[ $((installed + updated)) -gt 0 ]]; then
    info "Agents are ready. Use them in Claude Code with: /agents"
  else
    info "Everything is already up to date."
  fi

  # Migrate the memory of the project this installer was run from (if any). Other
  # projects migrate automatically the first time John boots in them.
  migrate_project "${PWD}"
  info "Other projects migrate automatically the first time you invoke John there."

  echo ""
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

do_uninstall() {
  echo ""
  printf "${BOLD}  AI Scrum Team Uninstaller${RESET}\n"
  echo ""

  local found=()
  for file in "${AGENT_FILES[@]}" "${OLD_AGENT_FILES[@]}"; do
    if [[ -f "${AGENTS_DEST_DIR}/${file}" ]]; then
      found+=("${file}")
    fi
  done

  if [[ ${#found[@]} -eq 0 ]]; then
    info "No AI Scrum Team agents found in ${AGENTS_DEST_DIR}"
    echo ""
    return 0
  fi

  info "The following agents will be removed from ${AGENTS_DEST_DIR}:"
  echo ""
  for file in "${found[@]}"; do
    printf "    - %s\n" "${file}"
  done
  echo ""

  # Prompt for confirmation.
  printf "  ${BOLD}Continue? [y/N]${RESET} "
  read -r confirm
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    warn "Uninstall cancelled"
    echo ""
    return 0
  fi

  echo ""

  for file in "${found[@]}"; do
    rm "${AGENTS_DEST_DIR}/${file}"
    success "Removed ${file}"
  done

  echo ""
  info "Uninstall complete."
  echo ""
}

# ---------------------------------------------------------------------------
# Per-project memory migration (v0.3.0 agent rename)
# ---------------------------------------------------------------------------

# Rename legacy per-agent memory files in the project's .scrum/memory/ to the new
# agent names. Idempotent: a file is renamed only when the old name exists and the
# new one does not. Silent when there is nothing to do; a missing project is fine.
migrate_project() {
  local dir="$1"
  local mem="${dir}/.scrum/memory"

  [[ -d "${mem}" ]] || return 0

  local moved=0 pair old new
  for pair in "${MEMORY_RENAMES[@]}"; do
    old="${mem}/${pair%%:*}"
    new="${mem}/${pair##*:}"
    if [[ -f "${old}" && ! -f "${new}" ]]; then
      mv "${old}" "${new}"
      moved=$((moved + 1))
    fi
  done

  if [[ ${moved} -gt 0 ]]; then
    success "Migrated ${moved} legacy memory file(s) in ${mem}"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

show_help() {
  local version
  version="$(get_version)"

  cat <<USAGE

  ${BOLD}AI Scrum Team Installer${RESET}  ${DIM}v${version}${RESET}

  ${BOLD}Usage:${RESET}
    ./install.sh              Install/update agents; migrate the current project
    ./install.sh --update     Same as default install (explicit)
    ./install.sh --uninstall  Remove installed agents
    ./install.sh --help       Show this help message

  ${BOLD}Agents:${RESET}
    john        Scrum Master & Orchestrator
    penny       Product Manager
    aria        Architect
    dave        Developer
    remy        Code Reviewer
    tess        Tester

  ${BOLD}Files:${RESET}
    Source:      ./agents/*.md
    Destination: ~/.claude/agents/

  ${BOLD}Migration (v0.3.0 / v0.4.0 renames):${RESET}
    A normal install migrates the current project's .scrum/ memory to the new
    agent names. Other projects migrate the first time you invoke John there.

USAGE
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  setup_colors

  case "${1:-}" in
    --help|-h)
      show_help
      exit 0
      ;;
    --uninstall)
      do_uninstall
      exit 0
      ;;
    --update|"")
      do_install
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
