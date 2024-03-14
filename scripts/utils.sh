function handle_error() {
    echo "ERROR: $1" >&2
    exit 1
}

function is_online() {
	local url="https://www.cvut.cz/sites/default/files/favicon.ico"
	local domain="cvut.cz"
	if which wget >/dev/null; then
		timeout 1 wget --spider -q -O /dev/null "$url" && return 0 || return 1
	elif which curl >/dev/null; then
		timeout 1 curl -sfI -o /dev/null "$url" && echo 1 || echo 0
	elif which ping; then
		timeout 1 ping -c1 "$domain" 2>/dev/null 1>/dev/null
		[ "$?" = "0" ] && return 1
		[ "$?" = "126" ] && return 1  # Operation not permitted; this happens inside Singularity. In that case, succeed.
		return 0
	else
		return 0
	fi
}

function in_singularity() {
  [ -n "$SINGULARITY_CONTAINER" ]
}

function export_environment_variable_if_present() {
    local var_name="$1"
    if [ -n "${!var_name}" ]; then
        export "SINGULARITYENV_$var_name"="${!var_name}"
    fi
}

# include the branch name and its dirtiness in the bash prompt
function parse_git_dirty() {
  git status --porcelain 2>/dev/null | grep -q -c -v "^??" && echo "*"
}

function parse_git_branch() {
  local branch
  branch=$(git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/[\1$(parse_git_dirty)]/")
  if [ -n "$branch" ]; then
    echo " $branch"
  else
    echo ""
  fi
}

# Check if in a Singularity container
function detect_singularity() {
  if [ -n "$SINGULARITY_CONTAINER" ]; then
    echo " S"
  else
    echo ""
  fi
}