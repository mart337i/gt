# gt

Navigate to aliased directories in your shell with tab completion.

![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)

## What is gt?

`gt` lets you bookmark directories and jump to them instantly. No more typing long paths or spamming `cd ../../../`.

```bash
# Register a directory
gt -r dev ~/projects/development

# Jump to it
gt dev
```

Tab completion shows all your aliases and their paths.

## Installation

### Via install script
```bash
git clone https://github.com/YOUR_USERNAME/gt.git
cd gt
sudo ./install
```

### Manual
Add this to your `.bashrc` or `.zshrc`:
```bash
source /path/to/gt.sh
```

Restart your shell after installation.

## Usage

**Navigate to alias:**
```bash
gt <alias>
```

**Register alias:**
```bash
gt -r <alias> <directory>
gt -r dots ~/.config
gt -r here .  # current directory
```

**List aliases:**
```bash
gt -l
```

**Unregister alias:**
```bash
gt -u <alias>
```

**Expand alias (show path):**
```bash
gt -x <alias>
```

**Cleanup broken aliases:**
```bash
gt -c
```

**Push/pop directory stack:**
```bash
gt -p <alias>  # push current, then goto alias
gt -o          # pop back
```

**Help:**
```bash
gt -h
```

## Examples

```bash
# Setup
gt -r api ~/work/backend/api
gt -r web ~/sites/production

# Navigate
gt api
gt web/static

# Stack navigation
gt -p api        # saves current location
gt -o            # returns to saved location

# Cleanup
gt -c            # remove dead aliases
```

## Configuration

Aliases are stored in `~/.config/gt` (or `$XDG_CONFIG_HOME/gt`).

To use a custom location:
```bash
export GT_DB="/path/to/your/alias/file"
```

## Troubleshooting

**zsh: command not found: compdef**

Add to `.zshrc`:
```bash
autoload bashcompinit
bashcompinit
```

**Migrating from goto**

Rename your config file:
```bash
mv ~/.config/goto ~/.config/gt
```

Or point to the old file:
```bash
export GT_DB="$HOME/.config/goto"
```

## About

`gt` is a maintained fork of [iridakos/goto](https://github.com/iridakos/goto) by [Lazarus Lazaridis](https://github.com/iridakos).

The original project is no longer maintained. This fork continues development with a shorter command name and active maintenance.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-feature`)
3. Commit your changes (`git commit -am 'Add feature'`)
4. Push to the branch (`git push origin my-feature`)
5. Run [ShellCheck](https://www.shellcheck.net/) on your changes
6. Create a Pull Request

## License

MIT License - see [LICENSE](LICENSE)

Original project: [iridakos/goto](https://github.com/iridakos/goto) by Lazarus Lazaridis
