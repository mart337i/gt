# Changelog

All notable changes to `gt` will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-12-01

### Changed
- Forked from iridakos/goto as maintained continuation
- Renamed command from `goto` to `gt` for brevity
- Renamed all internal functions and variables for consistency
- Configuration file now at `~/.config/gt` (was `~/.config/goto`)

### Fixed
- Enhanced subpath navigation with slash notation (e.g., `gt alias/path/to/dir`)
- Improved tab completion for both slash and space-separated paths
- Tab completion now adds trailing `/` after directories (not spaces), enabling seamless deep navigation
- Both formats support continuous path building: `gt alias/path/to/dir` and `gt alias path/to/dir`

### Maintained
- All features from goto 2.1.0 preserved
- Full backward compatibility via GT_DB environment variable
- Legacy space-separated format still supported (e.g., `gt alias subdir`)

### Credits
- Original project by Lazarus Lazaridis: https://github.com/iridakos/goto

## [2.1.0] - 2020-11-15

### Added

- [Allow users to navigate to special directories with goto](https://github.com/iridakos/goto/pull/62)

### Change

- [Improve the display of alias list](https://github.com/iridakos/goto/pull/63)

### Fixed

- [Missing config directory in MacOS](https://github.com/iridakos/goto/pull/64)

## [2.0.0] - 2020-01-27

### Changed
- Default to $XDG_CONFIG_HOME for storing the goto DB

## [1.2.4.1] - 2019-06-02

### Fixed
- fix completion for zsh

## [1.2.4] - 2019-05-30

### Added
- support bash completion for aliases of `goto`

## [1.2.3] - 2018-03-14

### Added
- align columns when displaying the list of aliases or similar results

### Changed
- removed shebang since the script is sourced
- updated README with valid information on supported shells

## [1.2.2] - 2018-03-13

### Added
- zsh completion for -x, -p, -o

## [1.2.1] - 2018-03-13

### Added

- Users can set the `GOTO_DB` environment variable to override the default database file which is `$HOME/.goto`
- Introduced the `CHANGELOG.md`
