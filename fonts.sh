# Install Fonts
cp fonts/*.ttf /Library/Fonts/ \
    && cp fonts/*.otf /Library/Fonts/ \
    && echo "Fonts installed.";

# Install font tools.
brew install woff2

# clone
git clone https://github.com/powerline/fonts.git powerline-fonts --depth=1
# install
cd powerline-fonts
./install.sh
# clean-up a bit
cd ..
rm -rf powerline-fonts
