#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

__powerline() {
    # Colorscheme
    readonly RESET='\[\033[m\]'
    readonly COLOR_CWD='\[\033[0;34m\]' # blue
    readonly COLOR_GIT='\[\033[0;36m\]' # cyan
    readonly COLOR_VENV='\[\033[0;32m\]' # green
    readonly COLOR_SUCCESS='\[\033[0;32m\]' # green
    readonly COLOR_FAILURE='\[\033[0;31m\]' # red

    readonly SYMBOL_GIT_BRANCH='⑂'
    readonly SYMBOL_GIT_MODIFIED='*'
    readonly SYMBOL_GIT_PUSH='↑'
    readonly SYMBOL_GIT_PULL='↓'

    if [[ -z "$PS_SYMBOL" ]]; then
        case "$(uname)" in
            Darwin)   PS_SYMBOL='';;
            Linux)    PS_SYMBOL='$';;
            *)        PS_SYMBOL='%';;
        esac
    fi

__git_info() { 
        [[ $POWERLINE_GIT = 0 ]] && return # disabled
        hash git 2>/dev/null || return # git not found
        local git_eng="env LANG=C git"   # force git output in English to make our work easier

        # get current branch name
        local ref=$($git_eng symbolic-ref --short HEAD 2>/dev/null)

        if [[ -n "$ref" ]]; then
            # prepend branch symbol
            ref=$SYMBOL_GIT_BRANCH$ref
        else
            # get tag name or short unique hash
            ref=$($git_eng describe --tags --always 2>/dev/null)
        fi

        [[ -n "$ref" ]] || return  # not a git repo

        local marks

        # scan first two lines of output from `git status`
        while IFS= read -r line; do
            if [[ $line =~ ^## ]]; then # header line
                [[ $line =~ ahead\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PUSH${BASH_REMATCH[1]}"
                [[ $line =~ behind\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PULL${BASH_REMATCH[1]}"
            else # branch is modified if output contains more lines after the header line
                marks="$SYMBOL_GIT_MODIFIED$marks"
                break
            fi
        done < <($git_eng status --porcelain --branch 2>/dev/null)  # note the space between the two <

        # print the git branch segment without a trailing newline
        printf " $ref$marks"
    }

    __venv_info () {
        # Taken from...
        # https://stackoverflow.com/questions/14987013/why-is-virtualenv-not-setting-my-terminal-prompt/14987716#14987716

        local venv_info=""
        if [ -z "$VIRTUAL_ENV_DISABLE_PROMPT" ] ; then
            if [ "`basename \"$VIRTUAL_ENV\"`" = "__" ] ; then
                # special case for Aspen magic directories
                # see http://www.zetadev.com/software/aspen/
                venv_info="[`basename \`dirname \"$VIRTUAL_ENV\"\``]"
            elif [ "$VIRTUAL_ENV" != "" ]; then
                venv_info="(`basename \"$VIRTUAL_ENV\"`)"
            fi
            printf "$venv_info"
        fi
    }

    ps1() {
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly. 
        if [ $? -eq 0 ]; then
            local symbol="$COLOR_SUCCESS $PS_SYMBOL $RESET"
        else
            local symbol="$COLOR_FAILURE $PS_SYMBOL $RESET"
        fi

        local cwd="$COLOR_CWD\w$RESET"
        # Bash by default expands the content of PS1 unless promptvars is disabled.
        # We must use another layer of reference to prevent expanding any user
        # provided strings, which would cause security issues.
        # POC: https://github.com/njhartwell/pw3nage
        # Related fix in git-bash: https://github.com/git/git/blob/9d77b0405ce6b471cb5ce3a904368fc25e55643d/contrib/completion/git-prompt.sh#L324
        if shopt -q promptvars; then
            __powerline_git_info="$(__git_info)"
            __powerline_venv_info="$(__venv_info)"
            local git="$COLOR_GIT\${__powerline_git_info}$RESET"
            local venv="$COLOR_VENV\${__powerline_venv_info}$RESET"
        else
            # promptvars is disabled. Avoid creating unnecessary env var.
            local git="$COLOR_GIT$(__git_info)$RESET"
            local venv="$COLOR_VENV$(__venv_info)$RESET"
        fi
        PS1="$venv$cwd$git$symbol"
    }

    PROMPT_COMMAND=ps1
}

__powerline
unset __powerline
