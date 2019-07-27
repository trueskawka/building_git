# The first commit

Goal: write just enough code that can store itself as a valid Git commit

Limitations:
- no subdirectories, executables, nor symlinks - only regular files
- no `add` command and no index - `commit` will commit everything as is
- no command-line processing of the `commit` command - everything read from environment variables and stdin

## Init command

The bear necessities of the `.git` directory are:
- `objects` and `refs` directories
- a `HEAD` file that's a symref to a file in `refs` - initially `init` won't create it

The initial command will use Ruby's method of running files:
```
ruby kit.rb init path/to/repository
```
If no path is provided, it will use the current directory.