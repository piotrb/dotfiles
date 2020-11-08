# Apple nukes the whle PATH between zshenv and zshrc due to /etc/zprofile .. 
# So we load it back up here
export PATH=$BACKUP_PATH
unset BACKUP_PATH
