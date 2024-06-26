#!/usr/bin/env zsh

export OMZ="$HOME/.oh-my-zsh"
export MANPATH="/usr/local/man:$MANPATH"
export LANG=C.UTF-8
export ZSH_CUSTOM="${ZSH_CUSTOM:-"~/.oh-my-zsh/custom"}"

plugins=(git fzf)


function kubectl () {
    command kubectl $*
    if [[ -z $KUBECTL_COMPLETE ]]
    then
        source <(command kubectl completion zsh)
        KUBECTL_COMPLETE=1 
    fi
}

function install-lscolors {
  export LSCOLORS_DIR=${ZSH_CUSTOM:?}/plugins/LS_COLORS
  mkdir -p ${LSCOLORS_DIR:?}
  curl -Ll https://api.github.com/repos/trapd00r/LS_COLORS/tarball/master \
    | tar xzf - --directory=$LSCOLORS_DIR --strip=1
}


function install-fzf-tab ()  {
  FZF_TAB_DIR=${ZSH_CUSTOM:?}/plugins/fzf-tab
  test -d "$FZF_TAB_DIR" && return
  mkdir -p "${FZF_TAB_DIR:?}"
  set -x
  git clone https://github.com/Aloxaf/fzf-tab $FZF_TAB_DIR
  unset FZF_TAB_DIR
  set +x
}

function init-fzf-tab () {
  FZF_TAB_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
  test -d "$FZF_TAB_DIR" && install-fzf-tab
  . "${ZSH_CUSTOM:?}/plugins/fzf-tab/fzf-tab.plugin.zsh"
  . "/plugins/fzf-tab/fzf-tab.plugin.zsh"

  plugins+=(fzf-tab)

  # disable sort when completing `git checkout`
  zstyle ':completion:*:git-checkout:*' sort false
  # set descriptions format to enable group support
  # NOTE: don't use escape sequences here, fzf-tab will ignore them
  zstyle ':completion:*:descriptions' format '[%d]'
  # set list-colors to enable filename colorizing
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
  zstyle ':completion:*' menu no
  # preview directory's content with eza when completing cd
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  # switch group using `<` and `>`
  zstyle ':fzf-tab:*' switch-group '<' '>'
  # zi light "Aloxaf/fzf-tab"
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
  # disable sort when completing options of any command
  zstyle ':completion:complete:*:options' sort false
  # use input as query string when completing zlua
  zstyle ':fzf-tab:complete:_zlua:*' query-string input
  
  zstyle ':fzf-tab:complete:*' fzf-bindings \
  	'ctrl-v:execute-silent({_FTB_INIT_}code "$realpath")'\
      'ctrl-e:execute-silent({_FTB_INIT_}kwrite "$realpath")'

}

function init-dots () {
  # https://www.atlassian.com/git/tutorials/dotfiles
  if [[ -d ~/.dots ]]; then
    alias dots="git --git-dir=${HOME:?}/.dots --work-tree=${HOME:?}"
  else
    git clone --bare https://github.com/kriipke/dots $HOME/.cfg
    function config {
      /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
    }
    mkdir -p .config-backup
    config checkout
    if [ $? = 0 ]; then
      echo "Checked out config.";
      else
        echo "Backing up pre-existing dot files.";
        config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
    fi;
    config checkout
    config config status.showUntrackedFiles no
    git clone --bare https://github.com/kriipke/dots $HOME/.cfg
    function config {
      /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
    }
    mkdir -p .config-backup
    config checkout
    if [ $? = 0 ]; then
      echo "Checked out config.";
      else
        echo "Backing up pre-existing dot files.";
        config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
    fi;
    config checkout
    config config status.showUntrackedFiles no
  fi
}

init-dots


#init-fzf-tab

#
#  [[ KUBERNETES TOOL CONFIGURATION ]]
#
#
#  [ KREW ]
#  
export PATH="~/.local/bin:${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
#
#  [ KUBECTL ]
#
#
#
function init-kubectl () {
  command -v kubectl &>/dev/null || exit 0
  source <(kubectl completion zsh)
  alias k=kubecolor
  alias kubectl=kubecolor

  compdef kubecolor=kubectl
  plugins+=(kubectl helm)
}
init-kubectl



ZSH_THEME="custom"
HYPHEN_INSENSITIVE="true"
CASE_SENSITIVE="off"


if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
  export GPG_TTY=$(tty)
fi


setopt auto_cd
cdpath=($HOME/. $HOME/src)

function km() {
  #
  # TO INSTALL: 
  #   sudo apt install -y bat fzf
  #   curl -sSL https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz | tar xz
  #   sudo install k9s /usr/bin/
  #
  kubeconfig=$(find  $HOME/.kube -maxdepth 1 -type f | grep -v '\.sw[po]$' | fzf --preview 'batcat  --language=yaml --color=always {}' --preview-window '~3')
  namespace=$(kubectl --kubeconfig=$kubeconfig get ns | tail -n+2 | awk '{print $1}' | fzf)
  k9s --kubeconfig=$kubeconfig --namepsace=$namespace
}

nnn_cd()                                                                                                   
{
    if ! [ -z "$NNN_PIPE" ]; then
        printf "%s\0" "0c${PWD}" > "${NNN_PIPE}" !&
    fi  
}
trap nnn_cd EXIT

path=('~/go/bin' '/opt/node/bin' '~/.wasmtime' '~/.local/share/nvim/mason/bin' '~/.local/bin' '~/bin' $path)

export GITLAB_HOME=~/src/docker-gitlab/data
export WASMTIME_HOME=~/.wasmtime



# Setup 1Password SSH authentication
export SSH_AUTH_SOCK=~/.1password/agent.sock
source $HOME/.agent-bridge.sh

# Facilities ZSH ssh auto-completion as described erer:
# https://www.codyhiar.com/blog/zsh-autocomplete-with-ssh-config-file/

# Highlight the current autocomplete option
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# # Better SSH/Rsync/SCP Autocomplete
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
 
# Allow for autocomplete to be case insensitive
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|?=** r:|?=**'

 # Initialize the autocompletion
#autoload -Uz compinit && compinit -i
autoload -U +X compinit && compinit

eval "$(starship init zsh)"

# basic file preview for ls (you can replace with something more sophisticated than head)
zstyle ':completion::*:ls::*' fzf-completion-opts --preview='eval head {1}'

# preview when completing env vars (note: only works for exported variables)
# eval twice, first to unescape the string, second to expand the $variable
zstyle ':completion::*:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-completion-opts --preview='eval eval echo {1}'

# preview a `git status` when completing git add
zstyle ':completion::*:git::git,add,*' fzf-completion-opts --preview='git -c color.status=always status --short'

# if other subcommand to git is given, show a git diff or git log
zstyle ':completion::*:git::*,[a-z]*' fzf-completion-opts --preview='
eval set -- {+1}
for arg in "$@"; do
    { git diff --color=always -- "$arg" | git log --color=always "$arg" } 2>/dev/null
done'

## Added by Zinit's installer
 if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
     print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
     command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
     command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
         print -P "%F{33} %F{34}Installation successful.%f%b" || \
         print -P "%F{160} The clone has failed.%f%b"
 fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

zinit pack for fzf

### End of Zinit's installer chunk
export LIBGL_ALWAYS_INDIRECT=1 #GWSL
alias vim=nvim
alias k=kubecolor
alias kubectl=kubecolor
alias kg='kubecolor get'
alias kd='kubecolor describe'
alias kga='kubecolor get -A'
alias vim='nvim'
alias fugitive='nvim +Git +only'
alias ls='lsd -l'
alias l='lsd -l --group-directories-first'
alias lx='lsd -tFSX  --group-directories-first --date=relative'
alias ll='lsd -lFS --group-directories-first --permission=octal --date=relative '

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf "$@" --preview 'tree -C {} | head -200' ;;
    *)            fzf "$@" ;;
  esac
}

# kill -9 **<TAB>
# ssh **<TAB>
# telnet **<TAB>
# unset **<TAB>
# export **<TAB>
# unalias **<TAB>
alias kg.apps='kubecolor get -A daemonsets.apps,statefulsets.apps,deployments.apps'
alias vim='nvim -u $HOME/.config/nvim/init.lua'
alias nvim='nvim -u $HOME/.config/nvim/init.lua'
alias vi='nvim -u $HOME/.config/nvim/init.lua'

. /etc/profile.d/z.sh
# Copyright (c) 2009 rupa deadwyler.

  ### ZNT's installer added snippet ###
  fpath=( "$fpath[@]" "$HOME/.config/znt/zsh-navigation-tools" )
  autoload n-aliases n-cd n-env n-functions n-history n-kill n-list n-list-draw n-list-input n-options n-panelize n-help
  autoload znt-usetty-wrapper znt-history-widget znt-cd-widget znt-kill-widget
  alias naliases=n-aliases ncd=n-cd nenv=n-env nfunctions=n-functions nhistory=n-history
  alias nkill=n-kill noptions=n-options npanelize=n-panelize nhelp=n-help
  zle -N znt-history-widget
  bindkey '^R' znt-history-widget
  setopt AUTO_PUSHD HIST_IGNORE_DUPS PUSHD_IGNORE_DUPS
  zstyle ':completion::complete:n-kill::bits' matcher 'r:|=** l:|=*'
  ### END ###

#alias kubefile='export KUBECONFIG=$(fd -a -e kubeconfig . /home/spencer/.kube/pail | fzf --no-sort --preview="kubectl config get-contexts --kubeconfig {}")'
alias kubefile='export KUBECONFIG=$(fd -a -e kubeconfig .   /IAC/KUBECONFIGS/ | fzf --no-sort --preview="KUBECONFIG={} k9s")'
 

# oh-my-zsh seems to enable this by default, not desired for 
# workflow of controlling terminal title.
export DISABLE_AUTO_TITLE="true"
#function set_win_title(){
#  kubectl config 
#}

export LS_COLORS="$(vivid -d /home/spencer/.config/vivid/config/filetypes.yml generate rose-pine-dawn)"

function set_prompt() {
  if [[ -f $KUBECONFIG ]]; then
    export STARSHIP_CONFIG=$HOME/.config/starship.toml
  else
    export STARSHIP_CONFIG=$HOME/.config/starship/sans-kubeconfig.toml
  fi
}
function set_terminal_title() {
  echo -en "\e]2;$kubectl config current-context 2>/dev/null || echo $SHELL\a"
}
precmd_functions+=(set_terminal_title set_prompt)

#nnn_cd()                                                                                                   
#{
#    if ! [ -z "$NNN_PIPE" ]; then
#        printf "%s\0" "0c${PWD}" > "${NNN_PIPE}" !&
#    fi  
#}
#trap nnn_cd EXIT

export NNN_TMPFILE="/tmp/nnn"

n()
{
    nnn "$@"

    if [ -f $NNN_TMPFILE ]; then
        . $NNN_TMPFILE
        rm $NNN_TMPFILE
    fi
}

alias fzf=/home/spencer/.fzf/bin/fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
