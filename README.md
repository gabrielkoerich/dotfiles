# Gabriel's dotfiles 

My dotfiles, based on [Mathias’s dotfiles](https://github.com/mathiasbynens/dotfiles).

<!-- [![.dotfiles](https://cloud.githubusercontent.com/assets/1981726/16643374/6276bd6c-43ea-11e6-9b09-3bea66ead643.png)](https://cloud.githubusercontent.com/assets/1981726/16643374/6276bd6c-43ea-11e6-9b09-3bea66ead643.png) -->

This config uses [zsh](http://www.zsh.org) and [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh). If you want to change your shell to zsh, [install it](https://github.com/robbyrussell/oh-my-zsh/wiki/Installing-ZSH) and run ``chsh -s $(which zsh)``.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. 

## Instructions

Read all scripts *before* executing them.

1. `git clone https://github.com/gabrielkoerich/dotfiles.git`
2. `sh sync.sh` to sync the dotfiles
3. `sh macos.sh` to configure macos
4. `sh install.sh` to install applications
5. `mackup restore` to restore app settings

To update, `cd` into your local `dotfiles` repository and then `sh sync.sh`.

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
