## macOS Specific
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Homebrew environment
  eval "$(/usr/local/bin/brew shellenv zsh)"

  # Swiftly
  [[ -f "$HOME/.swiftly/env.sh" ]] && . "$HOME/.swiftly/env.sh"

  # MacPorts
  export PATH="/opt/local/bin:/opt/local/sbin:/Users/rafa/.local/bin:$PATH"

  export VULKAN_SDK="/Users/rafa/Tools/VulkanSDK/1.3.204.1/macOS"

  export PATH="/usr/local/opt/swift/bin:/usr/local/opt/openssl/bin:$VULKAN_SDK/bin:$PATH"

  export DYLD_LIBRARY_PATH="$VULKAN_SDK/lib:$DYLD_LIBRARY_PATH"

  export VK_ICD_FILENAMES="$VULKAN_SDK/share/vulkan/icd.d/MoltenVK_icd.json" #:/usr/local/Cellar/mesa/26.2.1/share/vulkan/icd.d/lvp_icd.x86_64.json"

  export VK_LAYER_PATH="$VULKAN_SDK/share/vulkan/explicit_layer.d${VK_LAYER_PATH:+:$VK_LAYER_PATH}"
  
  export PATH="/usr/local/opt/trash-cli/bin:$PATH"

  export LDFLAGS="-L/usr/local/opt/openssl/lib $LDFLAGS"
  export CPPFLAGS="-I/usr/local/opt/openssl/include $CPPFLAGS"
  export PKG_CONFIG_PATH="/opt/local/lib/pkgconfig:/usr/local/opt/openssl/lib/pkgconfig:$VULKAN_SDK/lib/pkgconfig:$PKG_CONFIG_PATH" # ${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  #export PATH="/usr/local/opt/opencl-icd-loader/bin:/usr/local/opt/ocl-icd/bin
  #export LDFLAGS="-L/usr/local/opt/opencl-icd-loader/lib -L/usr/local/opt/ocl-icd/lib $LDFLAGS"
  #export CPPFLAGS="-I/usr/local/opt/opencl-clhpp-headers/include -I/usr/local/opt/ocl-icd/include $CPPFLAGS"
  #export PKG_CONFIG_PATH="/usr/local/opt/opencl-icd-loader/lib/pkgconfig:/usr/local/opt/opencl-clhpp-headers/share/pkgconfig:/usr/local/opt/ocl-icd/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  #export CMAKE_PREFIX_PATH="/usr/local/opt/opencl-icd-loader:/usr/local/opt/opencl-clhpp-headers${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

  #Fix kitten ssh terminfo path resolution
  #if [[ -n "$SSH_CONNECTION" && "$TERM" == "xterm-kitty" ]]; then
  #     export TERMINFO_DIRS="$HOME/.terminfo:/usr/share/terminfo"
  #fi

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
