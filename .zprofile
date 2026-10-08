## macOS Specific
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Homebrew environment
  # eval "$(/usr/local/bin/brew shellenv zsh)"
  # export PATH="/usr/local/opt/swift/bin:/usr/local/opt/openssl/bin:$VULKAN_SDK/bin:$PATH"
  # export PATH="/usr/local/opt/trash-cli/bin:$PATH"
  # Disabled in favor of MacPorts

  # Swiftly
  [[ -f "$HOME/.swiftly/env.sh" ]] && . "$HOME/.swiftly/env.sh"

  #export VULKAN_SDK="/Users/rafa/Tools/VulkanSDK/1.3.296.0/macOS"

  # MacPorts
  # export PATH="/opt/local/bin:/opt/local/sbin:$HOME/.local/bin:$PATH" 
  export PATH="/opt/local/bin:/opt/local/sbin:$VULKAN_SDK/bin:$HOME/.local/bin:$PATH"
  
  # export PATH="$PATH:$VULKAN_SDK/bin"
  #export DYLD_LIBRARY_PATH="$VULKAN_SDK/lib:${DYLD_LIBRARY_PATH:-}"
  #export VK_ADD_LAYER_PATH="$VULKAN_SDK/share/vulkan/explicit_layer.d"
  #export VK_ICD_FILENAMES="$VULKAN_SDK/share/vulkan/icd.d/MoltenVK_icd.json"
  #export VK_DRIVER_FILES="$VULKAN_SDK/share/vulkan/icd.d/MoltenVK_icd.json"
  #export VK_LAYER_SETTINGS_PATH="$VULKAN_SDK/share/vulkan/config/vk_layer_settings.txt"

  export LDFLAGS="-L/opt/local/lib/openssl-3 -L/opt/local/lib $LDFLAGS"
  export CPPFLAGS="-I/opt/local/include/openssl-3 -I/opt/local/include $CPPFLAGS"
  export PKG_CONFIG_PATH="/opt/local/lib/pkgconfig:/opt/local/lib/openssl-3/pkgconfig:$VULKAN_SDK/lib/pkgconfig:$PKG_CONFIG_PATH"  

## Linux Specific
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"

  # Hardware & Video
  export ONEDNN_MAX_CPU_ISA=AVX512_CORE_VNNI
  export OMP_NUM_THREADS=4
  export TF_ENABLE_ONEDNN_OPTS=1
  
  export LIBVA_DRIVER_NAME=iHD
  export VDPAU_DRIVER=va_gl
  export VK_VIDEO_DECODE_ENABLE=1
  export ANV_VIDEO_DECODE=1
  export ANV_VIDEO_ENCODE=1
  export ANV_DEBUG=video-decode,video-encode
  
  export QSG_USE_SIMPLE_ANIMATION_DRIVER=1
  export QSG_NO_VSYNC=1
  export MOZ_ENABLE_WAYLAND=0

  # Puro & Flutter
  export PURO_ROOT="$HOME/.puro"
  export PATH="$PATH:$PURO_ROOT/bin:$PURO_ROOT/shared/pub_cache/bin:$PURO_ROOT/envs/default/flutter/bin"

  export CHROME_EXECUTABLE="/usr/bin/google-chrome-stable"

fi

# Fix kitten ssh terminfo path resolution
if [[ -n "$SSH_CONNECTION" && "$TERM" == "xterm-kitty" ]]; then
     export TERMINFO_DIRS="$HOME/.terminfo:/usr/share/terminfo"
fi
