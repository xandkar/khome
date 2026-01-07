export EDITOR=nvim
export VISUAL=$EDITOR

### DIRs ###
export DIR_ARCHIVE="/mnt/arc"
export DIR_GITHUB="${DIR_ARCHIVE}/sw/src/repos/remote/github.com"
export DIR_AUDIO="${DIR_ARCHIVE}/aud"
export DIR_VIDEO="${DIR_ARCHIVE}/vid"
export DIR_YOUTUBE_VIDEO="${DIR_VIDEO}/web/youtube.com"
export DIR_YOUTUBE_AUDIO="${DIR_AUDIO}/youtube.com"
export DIR_NOTES="$HOME/doc/notes"
export DIR_LOG="$HOME/var/log"
export DIR_LOG_MPD="$DIR_LOG/mpd"
export DIR_NQ="$HOME/var/run/nq"
export DIR_WALLPAPERS="${DIR_ARCHIVE}/img/Wallpapers"
export DIR_TODO="$HOME/doc/TODO"

# ensure all DIRs exist:
env | grep ^DIR_ | awk -F= '{print $2}' | xargs -I% mkdir -p '%'

### FILEs ###
export FILE_LOG_MPD="$DIR_LOG_MPD/mpd.log"
export FILE_VIDEO_CATALOG="$DIR_VIDEO/catalog"
export FILE_WALLPAPER_CURR="$HOME/wallpaper_curr.txt"
export FILE_WALLPAPER_FAVS="$HOME/wallpaper_favs.txt"

# .Net Core
#DOTNET_ROOT_path=$(which dotnet)
#DOTNET_ROOT_realpath=$(realpath "$DOTNET_ROOT_path")
#DOTNET_ROOT_dirname=$(dirname "$DOTNET_ROOT_realpath")
#export DOTNET_ROOT="$DOTNET_ROOT_dirname"
export PATH=$PATH:$HOME/.dotnet/tools

# Erlang
ERL_AFLAGS="+pc unicode"
ERL_AFLAGS="$ERL_AFLAGS -kernel shell_history enabled"
ERL_AFLAGS="$ERL_AFLAGS -kernel shell_history_path '\"$HOME/.erl_history\"'"
export ERL_AFLAGS
. /home/xand/.kerl/installations/25.3.2.13/activate

# Rust / cargo
export PATH=$PATH:$HOME/.cargo/bin

# Racket packages
RACKET_VERSION=$(racket --version | awk '{for (i=1; i<=NF; i++) {if ($i ~ /^v[0-9]+\.[0-9]+/) {sub("^v", "", $i); print $i; exit 0}}}')
export PATH=$PATH:$HOME/.racket/"$RACKET_VERSION"/bin

# Gambit Scheme
export PATH=$PATH:/usr/local/Gambit/bin

# Doom
export PATH=$PATH:$HOME/.emacs.d/bin

# Ruby
export PATH="$PATH":"$HOME"/.gem/ruby/2.5.0/bin

# Go
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:"$PATH"

# Node.js
export PATH="$HOME"/node_modules/.bin:"$PATH"

# Solana
export PATH="$HOME"/.local/share/solana/install/active_release/bin:"$PATH"

# VS Code
export PATH=/opt/VSCode/bin:"$PATH"

# CLion
export PATH=/opt/clion/bin:"$PATH"

# RustRover
export PATH=/opt/RustRover/bin:"$PATH"

# DataGrip
export PATH=/opt/DataGrip/bin:"$PATH"

# JetBrains Toolbox
export PATH="$PATH":"$HOME"/.local/share/JetBrains/Toolbox/scripts

# Alloy
export PATH=/opt/alloy/bin:"$PATH"

# Windsurf
export PATH=/opt/Windsurf/bin:"$PATH"

# personal
export PATH=$HOME/bin:$HOME/.local/bin:/snap/bin:/sbin:/usr/sbin:"$PATH"
