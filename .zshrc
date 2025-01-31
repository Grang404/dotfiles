fastfetch

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_CUSTOM=$HOME/.config/oh-my-zsh/
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
# plugins=(git zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
fi

export EDITOR='nvim'
export PATH=$PATH:~/go/bin/

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Set autosuggestion color
source ~/.config/oh-my-zsh/.zsh_highlight_styles

alias todo='nvim ~/Documents/tasks.txt'
alias gpwd='cat ~/Documents/token.txt | xclip -selection clipboard'
alias kali='sudo docker run -it kali'
alias venv='[[ -d .venv ]] && source .venv/bin/activate || echo "No .venv found"'

precmd() {
    print ""
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export LS_COLORS="ow=1;34;40:di=34"

# precmd() {
#     # Get the last executed command and append it to the file
#     echo "$(date "+%Y-%m-%d %H:%M:%S") $(fc -ln -1)" >> ~/Vault/Security/WriteUps/agent_sudo_shell.md
#     print ""
# }
