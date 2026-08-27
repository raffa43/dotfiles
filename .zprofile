## macOS Specific
if [[ "$OSTYPE" == "darwin"* ]]; then
# Homebrew environment
  eval "$(/usr/local/bin/brew shellenv zsh)"
  
  # PATHs & Compilation Flags
  export PATH="/usr/local/opt/opencl-icd-loader/bin:/usr/local/opt/ocl-icd/bin:/usr/local/opt/swift/bin:/usr/local/opt/openal-soft/bin:$PATH"
  export LDFLAGS="-L/usr/local/opt/opencl-icd-loader/lib -L/usr/local/opt/ocl-icd/lib $LDFLAGS"
  export CPPFLAGS="-I/usr/local/opt/opencl-clhpp-headers/include -I/usr/local/opt/ocl-icd/include $CPPFLAGS"
  export PKG_CONFIG_PATH="/usr/local/opt/opencl-icd-loader/lib/pkgconfig:/usr/local/opt/opencl-clhpp-headers/share/pkgconfig:/usr/local/opt/ocl-icd/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  export CMAKE_PREFIX_PATH="/usr/local/opt/opencl-icd-loader:/usr/local/opt/opencl-clhpp-headers${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
  
  # export VK_ICD_FILENAMES="/usr/local/opt/mesa/share/vulkan/icd.d/lvp_icd.x86_64.json"

  # Swiftly
  [[ -f "$HOME/.swiftly/env.sh" ]] && . "$HOME/.swiftly/env.sh"

  # Fix kitten ssh terminfo path resolution
  if [[ -n "$SSH_CONNECTION" && "$TERM" == "xterm-kitty" ]]; then
      export TERMINFO_DIRS="$HOME/.terminfo:/usr/share/terminfo"
  fi
## Linux Specific
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"

  # Hardware & Video
  export ONEDNN_MAX_CPU_ISA=AVX512_CORE_VNNI
  export ANV_VIDEO_DECODE=1
  export ANV_VIDEO_ENCODE=1
  export ANV_DEBUG=video-decode,video-encode

  # Puro & Flutter
  export PURO_ROOT="$HOME/.puro"
  export PATH="$PATH:$PURO_ROOT/bin:$PURO_ROOT/shared/pub_cache/bin:$PURO_ROOT/envs/default/flutter/bin"

  export CHROME_EXECUTABLE="/usr/bin/google-chrome-stable"

fi
