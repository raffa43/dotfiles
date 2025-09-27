
eval "$(/usr/local/bin/brew shellenv)"

export PATH="$PATH:$HOME/.puro/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/shared/pub_cache/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/envs/default/flutter/bin" # Added by Puro
export PURO_ROOT="/Users/raffa43/.puro" # Added by Puro

# QT
export PATH="/usr/local/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@5/lib"
export CPPFLAGS="-I/usr/local/opt/qt@5/include"

# Java
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/usr/local/opt/openjdk/include:$CPPFLAGS"

