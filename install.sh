#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIONS_DIR="${HOME}/.local/share/nemo/actions"
ACTION_FILE="batch-resize-images@badmotorfinger.nemo_action"
ACTION_DIR_NAME="batch-resize-images"
REQUIRED_CMDS=(zenity convert file gettext)

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mWarning:\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; }

run_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    err "Root privileges are required to install packages, but 'sudo' was not found."
    return 1
  fi
}

detect_pm() {
  local pm
  for pm in apt-get dnf yum pacman zypper; do
    if command -v "${pm}" >/dev/null 2>&1; then
      [[ ${pm} == apt-get ]] && echo apt || echo "${pm}"
      return 0
    fi
  done
  return 1
}

pkg_name() {
  local pm="$1" cmd="$2"
  case "${cmd}" in
    zenity) echo zenity ;;
    file)   echo file ;;
    convert)
      case "${pm}" in
        dnf|yum|zypper) echo ImageMagick ;;
        *)              echo imagemagick ;;
      esac ;;
    gettext)
      case "${pm}" in
        apt)    echo gettext-base ;;
        zypper) echo gettext-runtime ;;
        *)      echo gettext ;;
      esac ;;
  esac
}

install_packages() {
  local pm="$1"; shift
  case "${pm}" in
    apt)    run_root apt-get update && run_root apt-get install -y "$@" ;;
    dnf)    run_root dnf install -y "$@" ;;
    yum)    run_root yum install -y "$@" ;;
    pacman) run_root pacman -S --needed --noconfirm "$@" ;;
    zypper) run_root zypper install -y "$@" ;;
    *)      return 1 ;;
  esac
}

missing_cmds() {
  local cmd result=()
  for cmd in "${REQUIRED_CMDS[@]}"; do
    command -v "${cmd}" >/dev/null 2>&1 || result+=("${cmd}")
  done
  [[ ${#result[@]} -gt 0 ]] && printf '%s\n' "${result[@]}"
}

install_dependencies() {
  local missing
  mapfile -t missing < <(missing_cmds)

  if [[ ${#missing[@]} -eq 0 ]]; then
    info "All dependencies are already installed."
    return 0
  fi

  info "Missing dependencies: ${missing[*]}"

  local pm
  if ! pm="$(detect_pm)"; then
    warn "Could not detect a supported package manager (apt, dnf, yum, pacman, zypper)."
    warn "Please install these commands manually: ${missing[*]}"
    return 0
  fi

  local cmd pkgs=()
  for cmd in "${missing[@]}"; do
    pkgs+=("$(pkg_name "${pm}" "${cmd}")")
  done

  info "Installing with ${pm}: ${pkgs[*]}"
  install_packages "${pm}" "${pkgs[@]}" || warn "Package installation reported a problem; continuing."

  local still
  mapfile -t still < <(missing_cmds)
  if [[ ${#still[@]} -gt 0 ]]; then
    warn "These commands are still missing: ${still[*]}"
    warn "The action may not work correctly until they are installed."
  fi
}

install_action() {
  if [[ ! -d "${SCRIPT_DIR}/${ACTION_DIR_NAME}" || ! -f "${SCRIPT_DIR}/${ACTION_FILE}" ]]; then
    err "Cannot find the action files next to this script (${SCRIPT_DIR})."
    exit 1
  fi

  info "Installing action into ${ACTIONS_DIR}"
  mkdir -p "${ACTIONS_DIR}"
  cp -rf "${SCRIPT_DIR}/${ACTION_DIR_NAME}" "${ACTIONS_DIR}/"
  cp -f "${SCRIPT_DIR}/${ACTION_FILE}" "${ACTIONS_DIR}/"
  chmod +x "${ACTIONS_DIR}/${ACTION_DIR_NAME}/batch-resize-images.sh"
}

main() {
  info "Nemo Batch Resize Images installer"
  install_dependencies
  install_action

  if ! command -v nemo >/dev/null 2>&1; then
    warn "The 'nemo' file manager was not found on PATH; the action is installed but Nemo does not appear to be present."
  fi

  info "Installation complete."
  info "Restart Nemo to load the action:  nemo -q"
}

main "$@"
