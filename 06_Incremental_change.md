# Incremental change

Goal: compose commits from the index.

## Update the index incrementally

Read the existing index before update. First acquire a lock on the file, to
prevent `add` clashes between processes and lose updates (pessimistic 
locking).

1. Load data from disk.
2. Store updated to the index.

## Change the `commit` command