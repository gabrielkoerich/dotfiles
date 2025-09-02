set dotenv-load

_default:
  just --list

[confirm("Setup Mac? This should be only done on a fresh install. (y/n)")]
setup:
  ./macos

[confirm("This may overwrite existing files in your home directory. Are you sure? (y/n)")]
sync:
  #!/usr/bin/env bash
  rsync home/. ~ --exclude ".git/" --exclude ".DS_Store" -avh --no-perms;
  exec $SHELL -l

[confirm("Install brew dependencies? (y/n)")]
_brew:
  ./bin/install/brew

[confirm("Install fonts? (y/n)")]
_fonts:
  ./bin/install/fonts

[confirm("Install brew cask apps? (y/n)")]
_cask:
  ./bin/install/cask

[confirm("Install cron jobs? (y/n)")]
_cron:
  ./bin/install/cron

install target:
  just _{{ target }} || echo "Invalid install"

backup:
  mackup backup --force && mackup uninstall --force

[confirm("Restore mackup backup? This should be only done on a fresh install. (y/n)")]
restore:
  mackup restore
