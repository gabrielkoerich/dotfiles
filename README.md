# Gabriel's dotfiles

My dotfiles, based on [Mathias’s dotfiles](https://github.com/mathiasbynens/dotfiles).

This config uses [zsh](http://www.zsh.org) and [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh). If you want to change your shell to zsh, [install it](https://github.com/robbyrussell/oh-my-zsh/wiki/Installing-ZSH) and run ``chsh -s $(which zsh)``.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need.

## Instructions

Read all scripts *before* executing them.

1. Configure iCloud, SSH, etc.
2. `git clone https://github.com/gabrielkoerich/dotfiles.git`
3. `just setup` to setup macos
4. `just install brew` to install brew & dependencies
5. `just install fonts` to install fonts
6. `just install cask` to install cask apps
7. `just install cron` to install the cron tasks
8. `just sync` to sync the dotfiles to `~`
9. Run `just restore` to restore app settings

To sync the dotfiles, run step 8 again.

## License

#### The MIT License (MIT)

Copyright (c) Gabriel Koerich

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
