if [ "$(uname -s)" = "Darwin" ] && command -v xcrun >/dev/null 2>&1; then
  export SDKROOT="${SDKROOT:-$(xcrun --show-sdk-path)}"
fi
