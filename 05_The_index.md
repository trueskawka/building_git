## The index

As the project grows:
- performance will get worse - `commit` reads all the files and usually not all
the files are being changed; comparing for `status` and `diff` would be slow
- it can become cumbersome with no `add` command

Goal: implement the `add` command and the index (provide a cache of all the blobs
in the current state of the project)

## The `add` command

In Git, `add` let's us pick which changes are going to be commited. Untracked
files are not in the latest commit nor in the index.

If we `add` a file, it's put in the index as a change to the previous state,
to be commited.

If we add changes to a file in the index, it's going to have two listings:
- changes to be committed - file is in the index with a blob ID different from
the blob ID in the latest commit
- changes not staged for commit (everything changed since last adding it) -
file is in te index, but the working tree differs from its information that's
stored in the index (metadata and blob ID are different); we must `add` it to
write the latest version as a blo and store its ID in the index

Exploring the `.git/index`, the file begins with a header:
```quote
  A 12-byte header consisting of
    4-byte signature:
      The signature is { 'D', 'I', 'R', 'C' } (stands for "dircache")

    4-byte version number:
      The current supported versions are 2, 3 and 4.

    32-bit number of index entries.
```

e.g.
```
44 49 52 43 00 00 00 02  00 00 00 06           |DIRC........    |
 D  I  R  C   version 2    entries 6
```

The entries for files contain ten 4-byte numbers:
```quote
(timestaps)
32-bit ctime seconds, the last time a file's metadata changed
32-bit ctime nanosecond fractions
32-bit mtime seconds, the last time a file's data changed
32-bit mtime nanosecond fractions

(IDs, mode, size)
32-bit dev
32-bit ino
32-bit mode
32-bit uid
32-bit gid
32-bit file size
```

- timestamps
```
00000000                                       5a 4f 7e c1  |            ZO~.|
                                                  seconds
00000010  00 00 00 00 5a 4f 7e c0  00 00 00 00              |....ZO~.....    |
                        seconds
```

- IDs, mode, size
```
00000010                                       00 00 00 29  |            ...)|
                                                device ID
00000020  00 00 00 52 00 00 81 a4  00 00 03 e8 00 00 03 e8  |...R............|
            inode ID      mode       user ID    group ID     
00000030  00 00 00 00                                       |....            |
           file size
```

- SHA-1
```
00000030              e6 9d e2 9b  b2 d1 d6 43 4b 8b 29 ae  |    .......CK.).|
00000040  77 5a d8 c2 e4 8c 53 91                           |wZ....S.        |
```

- 2-byte set of flags, file name - padded to a multiple of 8
```
00000040                           00 08 66 69 6c 65 2e 74  |        ..file.t|
                                   flags filename
00000050  78 74 00 00                                       |xt..            |
```

- index SHA-1 (for integrity)
```
00000050              4d 1e 21 ff  5f ef 09 29 52 d2 7d f4  |    M.!._..)R.}.|
00000060  83 ac d5 a7 20 49 d8 0f                           |.... I..|
```

Blobs are added to the database on `git add`. When the index is updated, the old
blob isn't removed - we only add new blobs to the database and change what the
index points to. 

Git `add`:
- stores file as a blob in `.git/objects`
- adds a reference to that blo along with a cache of the file's current metadata
in `.git/index`

## Basic `add` implementation

1. Add things to the index and commit will be unchanged
  - start with a single file
  - store multiple entries
  - add files from directories
2. Commit will read from index rather than the working tree.