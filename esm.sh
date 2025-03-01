#!/bin/bash
# Entropy Setup Manager (ESM)
# Needs: git, jq, dialog (optional), fzf (optional)
# JSON configs in /bin/setup-manager/data/ or ./data/
# Use --data <file.json> to specify config
# Use --no-dialog to disable dialog UI

# Ask for sudo
[[ $EUID -ne 0 ]] && { echo "Need sudo!"; sudo -v || { echo "Denied!"; exit 1; }; }

# Check dependencies
for p in git jq; do
  command -v $p &>/dev/null || { 
    echo "Missing: $p"
    echo "Run setup.sh if running ESM for the first time to install dependencies and sync data"
    exit 1
  }
done

# Check optional dependencies
HAS_DIALOG=false
command -v dialog &>/dev/null && HAS_DIALOG=true

HAS_FZF=false
command -v fzf &>/dev/null && HAS_FZF=true

# Determine data directory
if [ -d "/bin/setup-manager/data/" ]; then
  D="/bin/setup-manager/data/"
elif [ -d "./data" ]; then
  D="./data"
elif ls ./*.json &>/dev/null; then
  D="."
else
  echo "ESM Not Installed! No valid data directory or JSON file found."
  exit 1
fi

# Parse args
df=""
USE_DIALOG=$HAS_DIALOG
while [[ $# -gt 0 ]]; do
  case "$1" in
    --data) shift; df="$1" ;;
    --no-dialog) USE_DIALOG=false ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

# Pick JSON file if not given
pick_json() {
  local d="$D"
  while true; do
    opts=()
    [ "$d" != "$D" ] && opts+=( "../" "Back" )

    for i in "$d"/*; do
      [ -d "$i" ] && opts+=( "$(basename "$i")/" "Dir" )
      [[ "$i" == *.json ]] && opts+=( "$(basename "$i")" "JSON" )
    done

    [ ${#opts[@]} -eq 0 ] && { echo "No JSON found."; return 1; }

    if $USE_DIALOG; then
      sel=$(dialog --stdout --menu "Pick JSON" 15 50 10 "${opts[@]}")
    elif $HAS_FZF; then
      sel=$(printf "%s\n" "${opts[@]}" | fzf --height=10 --prompt "Pick JSON: ")
    else
      echo "Select JSON file:"
      select sel in "${opts[@]}"; do
        break
      done
    fi

    [ -z "$sel" ] && { echo "No selection."; exit 0; }

    if [[ "$sel" == */ ]]; then
      d="$d/${sel%/}"
    elif [[ "$sel" == "../" ]]; then
      [ "$d" != "$D" ] && d="$(dirname "$d")"
    else
      echo "Using: $d/$sel"
      df="$d/$sel"
      break
    fi
  done
}

# Validate JSON selection
[ -z "$df" ] && pick_json || [ -f "$df" ] || { echo "Invalid file."; exit 1; }

# Build options list
opts=()
while IFS="=" read -r k v; do
  opts+=( "$k" "" off )
done < <(jq -r 'to_entries | map("\(.key)=\(.value)") | .[]' "$df")

# Show checklist
if $USE_DIALOG; then
  sel=$(dialog --stdout --checklist "Select Scripts" 0 0 0 "${opts[@]}")
else
  if $HAS_FZF; then
    sel=$(printf "%s\n" "${opts[@]}" | fzf --multi --height=10 --prompt "Select Scripts: ")
  else
    echo "Select scripts (Spacebar to mark, Enter to confirm):"
    select sel in "${opts[@]}"; do
      break
    done
  fi
fi

clear
[ -z "$sel" ] && { echo "Nothing selected."; exit 0; }

# Extract selected scripts
scr=()
IFS=' ' read -r -a arr <<< "$sel"
for k in "${arr[@]}"; do
  scr+=( "$(jq -r --arg k "$k" '.[$k]' "$df")" )
done

# Determine script directory
if [ -d "/bin/setup-manager/scripts" ]; then
  SCRIPTS_DIR="/bin/setup-manager/scripts"
elif [ -d "./scripts" ]; then
  SCRIPTS_DIR="./scripts"
elif ls ./*.sh &>/dev/null; then
  SCRIPTS_DIR="."
else
  echo "ESM Not Installed! No valid script directory or .sh files found."
  exit 1
fi

# Confirm execution
if $USE_DIALOG; then
  dialog --title "Confirm" --yesno "Run these?\n\n${scr[*]// /\\n}\n\nProceed?" 15 50
  [[ $? -ne 0 ]] && { echo "Aborted."; exit 0; }
else
  echo "Selected scripts:"
  printf "%s\n" "${scr[@]}"
  read -p "Proceed? (y/n) " confirm
  [[ "$confirm" != "y" ]] && { echo "Aborted."; exit 0; }
fi

# Run scripts
for s in "${scr[@]}"; do
  script_path="$SCRIPTS_DIR/$s"
  if [ -f "$script_path" ]; then
    echo "Running $script_path..."
    bash "$script_path"
  else
    echo "Script not found: $script_path"
  fi
done
