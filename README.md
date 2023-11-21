# dotfiles

## Installing

## Debian/Ubuntu

```
sudo apt install zsh git vim direnv ruby

sh -c "$(curl -fsSL https://starship.rs/install.sh)"

cd ~
git clone git@github.com:piotrb/dotfiles.git
cd dotfiles
./install

```

## Asdf

```
asdf plugin-add direnv
asdf direnv setup --shell bash --version system --no-touch-rc-file
asdf direnv setup --shell zsh --version system --no-touch-rc-file
```

