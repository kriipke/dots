#!/usr/bin/env zsh

export ZSH="$HOME/.oh-my-zsh"
export MANPATH="/usr/local/man:$MANPATH"
export LANG=C.UTF-8
export KUBECONFIG="$HOME/.kube/config"

# plugins=(fzf)

function install-fzf-tab ()  {
  FZF_TAB_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab
  test -d "$FZF_TAB_DIR" && exit 0
  mkdir -p "${FZF_TAB_DIR:?}"
  set -x
  git clone https://github.com/Aloxaf/fzf-tab $FZF_TAB_DIR
  unset FZF_TAB_DIR
  set +x
}

function init-fzftab () {
  install-fzf-tab
  . "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh"
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
  [[ -d ~/.dots ]] && alias dots="git --git-dir=${HOME:?}/.dots --work-tree=${HOME:?}"
}

function init-kubectl () {
  command -v kubectl &>/dev/null || exit 0
  source <(kubectl completion zsh)
  alias kubectl=kubecolor
  compdef kubecolor=kubectl
  plugins+=(kubectl helm)
}


init-fzftab
init-dots
init-kubectl

#
#  [[ KUBERNETES TOOL CONFIGURATION ]]
#
export PATH="~/.local/bin:${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


ZSH_THEME="custom"
HYPHEN_INSENSITIVE="true"
CASE_SENSITIVE="off"

source $ZSH/oh-my-zsh.sh

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
  export GPG_TTY=$(tty)
fi


if [[ -d ~/.dots ]]; then
  # https://www.atlassian.com/git/tutorials/dotfiles
  alias dots="git --git-dir=${HOME:?}/.dots --work-tree=${HOME:?}"
fi

setopt auto_cd
cdpath=($HOME/.)

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

path=('~/.wasmtime' '~/.local/share/nvim/mason/bin' '~/.local/bin' '~/bin' $path)

export GITLAB_HOME=$HOME/src/docker-gitlab/data
export WASMTIME_HOME="$HOME/.wasmtime"



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
autoload -Uz compinit && compinit -i

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

### Added by Zinit's installer
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

### End of Zinit's installer chunk
export LIBGL_ALWAYS_INDIRECT=1 #GWSL
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

. /etc/profile.d/z.sh
# Copyright (c) 2009 rupa deadwyler.
