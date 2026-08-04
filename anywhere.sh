temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT