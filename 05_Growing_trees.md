# Growing trees

Goals:
- store more than a flat list of files in a single directory
- store executable files

## File modes

- `100644` - non-executable file
- `100755` - executable file

A file's mode is one of the metadata returned from a `stat()` system call
(one of the functions returning information about a file). Git uses an octal
representation of the mode.

In Ruby:
```
>> File.stat("hello.txt").mode 
=> 33188

>> File.stat("hello.txt").mode.to_s(8)
=> "100644"
```

In Bash:
```
$ stat -f "%p" hello.txt
100644
```

The octal representation is compact, and the underlying binary for a non-executable file looks like:
```
1000      000       110       100       100
----      ---       ---       ---       ---
file    special     user     group     other
type    ------------------------------------
                     permissions
```

- `1000` - file type
- `000` - special permissions (`setuid`, `setgid`, and sticky bits)
- `110` - user read/write/execute permissions
- `100` - group read/write/execute permissions
- `100` - other read/write/execute permissions

```
Octal     Binary      Permissions
-------------------------------------------
    0        000      none
    1        001      execute
    2        010      write
    3        011      write and execute
    4        100      read
    5        101      read and execute
    6        110      read and write
    7        111      all
  ```

So for the octal:
```
     10             0             6             4            4
regular file   no special     owner can     group can    other can
               permissions  read and write     read         read
```

```
     10             0             7              5                5
regular file   no special     owner can      group can        other can
               permissions       all       read and exec    read and exec
```

Git only stores two file modes:
- `100755` for executables
- `100644` for everything else

## Make `kit` executable

1. Move `kit.rb` to `bin/kit`
2. `chmod +x`
3. Add environment variables:
```
export PATH="$PWD/bin:$PATH"
export RUBYOPT="--disable gems" # only for this shell
```

## Storing directories

Git stores a directory mode as `40000` and ignores the full mode (`40755`), to only
mark it's a directory. Directories have "execute" permissions, meaning you need to
be able to traverse it to access the files in it. "Reading" a directory means listing files. To read a file, you need to have a "read" permission to the file and
"execute" permissions on all the directories leading to it.

It represents trees of files in a direct way - parent directory is a tree that contains a reference to the child directory tree. Since objects are hashed based on
content, if we see two trees with te sae hash, we know their contents are exactly
the same and we can skip them. It's a performance win for comparing repositories,
downloading assets, and detecting that a tree has been move without changing files
in it.

This structure is called a Merkle tree (or a hash tree), and is also used in other
systems, like blockchain.

## Building a Merkle tree

1. Recurse into subdirectories when checking files
2. Build a recursive tree