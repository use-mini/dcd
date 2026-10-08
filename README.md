# dcd - A Dynamic Change Directory

`dcd` is a command-line tool to change your directory dynamically.

## How it works

dcd has three ways to change directories:

- `spawn`: It spawns the `terminal` configured, replacing `%s` with the new directory. It will only work if the terminal you use supports this operation, like [alacritty](https://alacritty.org/);
- `exec`: It changes the current path for `dcd` process and exec your current `shell` (configured or via `$SHELL`). If you exit the new shell, you'll go back to the previous process: `shell -> dcd`, `shell -> shell (new_dir)`, `shell`;
- `exec_quit`: It changes the current path for `dcd` process and exec your current `shell` (configured or via `$SHELL`). When you exit the shell, `dcd` will send a `SIGHUP` signal to the parent process, exiting the shell: `shell -> dcd`, `shell -> shell (new_dir)`, `<no remaining shell>`;

## How to use

- `dcd`: Opens an interactive picker. You can type the name and it will fuzzy match by name (with more weight) and directory. Pressing `Return` will change your directory using your `launch` mode;
- `dcd <name>`: Changes your directory to `<name>` using your `launch` mode;

### Commands

- `list`: Lists every directory in your config;
- `add <name> [<path>] [-r]`: Adds a directory in your config named `<name>`. If provided, it will add the `<path>`. If `<name>` already exists, `-r` will replace it;
- `rm <name>`: Removes the directory named `<name>`;
- `completions bash`: Prints the bash completion script;

### Shell completion

Pressing `TAB` completes directory names, subcommands and flags. When several candidates match, each one is listed with its destination path:

```
$ dcd <TAB><TAB>
add   -- add a directory
code  -- ~/code
dots  -- ~/.config
list  -- list directories
rm    -- remove a directory
work  -- ~/work
```

Only bash is supported. Add this to your `~/.bashrc`, after the point where `dcd` is put on your `PATH`:

```bash
eval "$(dcd completions bash)"
```

The script registers the completion only for the name it was invoked as. If you use both `dcd` and `dc`, add one line for each:

```bash
eval "$(dcd completions bash)"
eval "$(dc completions bash)"
```

If your `.bashrc` is shared with machines where `dcd` may not be installed, guard the line:

```bash
command -v dcd >/dev/null && eval "$(dcd completions bash)"
```

The flake packages also install the script under `share/bash-completion/completions`, where [bash-completion](https://github.com/scop/bash-completion) loads it on demand if it searches your Nix profile. The `eval` line does not depend on that and works on any system.

### Override configuration

- `--config <config-path>`: Uses the config in `<config-path>`;
- `--launch [exec, exec_quit, spawn]`: Launches using the provided launch mode;

## Compatibility

The program was tested only on Linux [NixOS](https://nixos.org/) 25.05. The `exec_quit` launch mode is only compatible with Linux.

## Flakes

Binaries available through [Nix flakes](https://nixos.wiki/wiki/Flakes): `dcd` and `dc`.
