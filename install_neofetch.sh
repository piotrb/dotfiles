set -e

# https://github.com/dylanaraps/neofetch/releases/latest
VERSION=7.1.0

mkdir -p tmp
rm -rf tmp/neofetch*

wget -O tmp/neofetch-${VERSION}.tar.gz https://github.com/dylanaraps/neofetch/archive/refs/tags/${VERSION}.tar.gz
tar -C tmp -xvzf tmp/neofetch-${VERSION}.tar.gz
chmod +x tmp/neofetch-${VERSION}/neofetch

rm -f bin/neofetch
cp tmp/neofetch-${VERSION}/neofetch bin/neofetch

rm -rf tmp

ln -s `pwd`/bin/neofetch ~/bin/neofetch
