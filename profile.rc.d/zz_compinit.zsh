# Set up completion system
fpath+=~/.zfunc
autoload -Uz compinit

# Quick check: are there any foreign-owned completion files?
# If not, we can skip the complex multi-user logic entirely.
() {
  zmodload -F zsh/stat b:zstat
  local -i uid
  local has_foreign=false
  
  # Quick scan for any foreign-owned fpath directories
  for dir in "${fpath[@]}"; do
    [[ -d "$dir" ]] || continue
    zstat -A uid +uid "$dir" 2>/dev/null || continue
    if (( uid != 0 && uid != UID )); then
      has_foreign=true
      break
    fi
  done
  
  # If no foreign directories found, still check completion files in owned dirs
  if ! $has_foreign; then
    for dir in "${fpath[@]}"; do
      [[ -d "$dir" ]] || continue
      for file in "$dir"/_*(N); do
        [[ -f "$file" ]] || continue
        zstat -A uid +uid "$file" 2>/dev/null || continue
        if (( uid != 0 && uid != UID )); then
          has_foreign=true
          break 2
        fi
      done
    done
  fi
  
  # No foreign-owned paths - run compinit normally and exit
  if ! $has_foreign; then
    compinit
    return
  fi
  
  # Handle multi-user homebrew environment where compinit complains about
  # insecure directories. Check if all foreign-owned paths are in /opt/homebrew
  # and owned by the same user, then trust them with compinit -u.
  local all_homebrew=true
  local -a foreign_uids
  
  # Check each fpath directory and its completion files
  for dir in "${fpath[@]}"; do
    [[ -d "$dir" ]] || continue
    
    # Check the directory itself
    zstat -A uid +uid "$dir" 2>/dev/null || continue
    if (( uid != 0 && uid != UID )); then
      [[ "$dir" != /opt/homebrew/* ]] && all_homebrew=false
      foreign_uids+=("$uid")
    fi
    
    # Check completion files in this directory
    for file in "$dir"/_*(N); do
      [[ -f "$file" ]] || continue
      zstat -A uid +uid "$file" 2>/dev/null || continue
      if (( uid != 0 && uid != UID )); then
        [[ "$file" != /opt/homebrew/* ]] && all_homebrew=false
        foreign_uids+=("$uid")
      fi
    done
  done
  
  # Check if all foreign owners are the same single user
  local -a unique_uids=(${(u)foreign_uids[@]})
  
  if $all_homebrew && (( ${#unique_uids} == 1 )); then
    # All foreign paths in homebrew, all owned by same user - trust them
    compinit -u
  else
    # Mixed ownership or paths outside homebrew - show the warning
    compinit
  fi
}

