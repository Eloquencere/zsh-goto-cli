# goto.zsh

`goto.zsh` is a *Zsh ONLY* script designed to efficiently manage and navigate directory aliases, making it easier to switch between frequently used directories. The script supports global and environment-specific aliases, and provides additional functionality such as cleaning up invalid aliases and directory stacks for quick navigation.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Command Options](#command-options)
- [Environment Modes](#environment-modes)
- [Autocomplete](#autocomplete)
- [Examples](#examples)
- [License](#license)

---

## Features

- **Global and Environment-specific Aliases:**
  - Use global aliases by default or switch to local environment-specific aliases by setting the `GOTO_ENV_DIR` variable.
- **Alias Management:**
  - Register (`-r`) and unregister (`-u`) aliases for directories.
- **Alias Listing and Expansion:**
  - List all aliases (`-l`) or expand an alias to its full directory path (`-x`).
- **Directory Navigation:**
  - Navigate to an alias or stack (`-p` and `-o`) directories for quick jumps.
- **Alias Cleanup:**
  - Remove aliases pointing to non-existent directories with the `-c` option.
- **Customizable:**
  - Easily adapt the script to new environments with minimal configuration.
- **Autocomplete:**
  - Autocompletion for all options and aliases.

---

## Installation

### Via zinit - Zsh Package Manager
    zinit light Eloquencere/goto-cli

### Manually
1. Clone or download the script to a location of your choice:

   ```zsh
   git clone https://github.com/Eloquencere/goto-cli.git
   cd goto
   ````

2. Source the script in your `.zshrc` file:

   ```zsh
   source /path/to/goto.zsh
   ```

3. Reload your `.zshrc`:

   ```zsh
   source ~/.zshrc
   ```

---

## Usage

### Command Options

| Option             | Description                                                                                     |
|--------------------|-------------------------------------------------------------------------------------------------|
| `-m`, `--mode`     | Display the current mode (global or local environment).                                          |
| `-r`, `--register` | Register a new alias for a directory. Usage: `goto -r <alias> <directory>`.                      |
| `-u`, `--unregister`| Unregister an alias. Usage: `goto -u <alias>`.                                                 |
| `-p`, `--push`     | Push the current directory onto the stack and navigate to an alias. Usage: `goto -p <alias>`.   |
| `-o`, `--pop`      | Pop the top directory from the stack and navigate to it.                                        |
| `-l`, `--list`     | List all registered aliases.                                                                    |
| `-x`, `--expand`   | Expand an alias to show its full directory path. Usage: `goto -x <alias>`.                      |
| `-c`, `--cleanup`  | Remove aliases pointing to non-existent directories.                                            |
| `-h`, `--help`     | Display the help message.                                                                       |
| `-v`, `--version`  | Display the script version.                                                                     |

---

## Environment Modes

The script operates in two modes:

1. **Global Mode:**
   - Default mode that stores aliases globally in `~/.config/goto`.

2. **Local Environment Mode:**
   - Set the `GOTO_ENV_DIR` environment variable to a directory. This will store aliases in a `.goto_aliases` file in the specified directory.

   ```zsh
   export GOTO_ENV_DIR=/path/to/local/env
   ```

- Switching modes will notify the user of the change.

---

## Autocomplete

The script supports autocomplete for:

- Command options (e.g., `-r`, `-u`, `-l`, etc.)
- Registered aliases

Autocomplete will trigger when you start typing the `goto` command and press `TAB`.

---

## Examples

### Register and Use an Alias

1. Register a new alias:

   ```zsh
   goto -r project /path/to/my/project
   ```

2. Navigate to the registered alias:

   ```zsh
   goto project
   ```

### List Aliases

List all registered aliases:

```zsh
goto -l
```

### Expand an Alias

Display the full path of an alias:

```zsh
goto -x project
```

### Cleanup Aliases

Remove aliases pointing to non-existent directories:

```zsh
goto -c
```

### Push and Pop Directories

Push the current directory onto the stack and navigate to an alias:

```zsh
goto -p project
```

Pop the top directory from the stack:

```zsh
goto -o
```

---

## License

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT). See the header of the script for details.

