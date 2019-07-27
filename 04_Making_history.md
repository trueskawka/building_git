# Making history

Goal: to build the relationship between commits

## Parent field

Each new commit after the root has a `parent` eader referencing the ID
of the previous commit. It's an explicit representation of the idea that
commit B was derived from commit A.

Why not a timestamp?
- it would be relatively time consuming to retrieve all the commits and
compare timestamps to retrieve the latest 5 commits
- in a distributed system, timestamps are unreliable, as every person's
machine can have a different clock
- commits follow logically from the code they were built on top of
- different people can have feature branches and timestamps from them
can precede commits on ever-changing `master`
- makes calculating and comparing changes more reliable

## Changes

We don't need to modify code for writing blobs and trees to the database.
We can continue to store the current state of files as blobs, form a tree,
and store it. And write the new commit's ID to `.git/HEAD`.

The `Commit` object needs to:
- be given the current value of `.git/HEAD`
- store this value in a `parent` field if necessary

## Safely updating `.git/HEAD`

Files in `.git/objects/` are immutable, whereas `.git/refs` change constantly.
Moreover, `.git/refs` files need to have stable, predictable names. Writes to them
are atomic, but two processes writing to them won't have the same data (as opposed
to trees and blobs which are based on content hash).

Two processes trying to change a reference at the same time is an error, as that
can cause a race condition. We can work around it using a lockfile.

## Improvements

The `Database` class is writing every object it was given. On subsequent commits, many of the objects that make up the commit already exist. Let's avoid writing them
if possible.