#if [ ! $TMUX ]; then
#  tmux has-session -t shell 2>/dev/null && tmux attach-session -t shell || tmux new-session -s shell
#fi