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

## Author and commit message information for commits

We don't have a configuration system yet, we're not parsing command-line arguments. But we can easily set environent variables.

Create a `~/.profile` file with:
```
export GIT_AUTHOR_NAME="<name>"
export GIT_AUTHOR_EMAIL="<email>"
```

For commit messages, we can use the stdin. 

## Summary

This now works as a valid Git directory, yay!

```
ruby kit.rb init
echo "This is a commit." | ruby kit.rb commit
git show
git log
```

This commit records a minimal set of functionality necessary for the
code to store itself as a valid Git commit. This includes writing the
following object types to the database:
- Blobs of ASCII text
- Trees containing a flat list of regular files
- Commits that contain a tree pointer, author info and message
These objects are written to `.git/objects`, compressed using zlib.
At this stage, there is no index and no `add` command; the `commit`
command simply writes everything in the working tree to the database and
commits it.