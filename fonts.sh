# Install Fonts
cp fonts/*.ttf /Library/Fonts/ && echo "Fonts installed.";

# clone
git clone https://github.com/powerline/fonts.git powerline-fonts --depth=1
# install
cd powerline-fonts
./install.sh
# clean-up a bit
cd ..
rm -rf powerline-fonts
