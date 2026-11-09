# Nx `projectsAffectedByDependencyUpdates` array repro

With `projectsAffectedByDependencyUpdates` set to an array, Nx marks the matching projects as affected on every change, not only when the lock file changes. A README edit makes `nx show projects --affected` and legacy `nx affected` list them. Task-based `nx affected` does not, so the two commands disagree.

The workspace has three npm workspace packages, `a`, `b` and `c`, with no dependencies between them:

```json
{
  "pluginsConfig": {
    "@nx/js": {
      "projectsAffectedByDependencyUpdates": ["*", "!b"]
    }
  }
}
```

## Run

```sh
npm install
./repro.sh
```

Output on Nx 24.0.5:

```text
nx show projects --affected --files=README.md                  expected: (none)   actual: a c
nx show projects --affected --files=packages/a/index.js        expected: a        actual: a c
nx show projects --affected --files=package-lock.json          expected: a c      actual: a c
nx affected -t test --files=README.md                          expected: (none)   actual: (none)
NX_LEGACY_AFFECTED=true nx affected -t test --files=README.md  expected: (none)   actual: a:test c:test
```

Rows 1, 2 and 5 are wrong: a README edit marks `a` and `c`, and an edit to `a` also marks `c`. Row 3 is the setting doing its job, since a lock file change should mark every project except `b`.

## Cause

`getTouchedProjectsFromLockFile` ([lock-file-changes.ts](https://github.com/nrwl/nx/blob/master/packages/nx/src/plugins/js/project-graph/affected/lock-file-changes.ts)) returns nothing without a lock file change in the `"auto"` and `"all"` branches, but the array branch has no such check:

```ts
} else if (Array.isArray(projectsAffectedByDependencyUpdates)) {
  return findMatchingProjects(projectsAffectedByDependencyUpdates, projectGraphNodes);
}
```

Task-based selection (`lockFileDependencyChanges`) checks for the lock file first, which is why row 4 is correct.

[nrwl/nx#37764](https://github.com/nrwl/nx/pull/37764) moves the check to the top of the function. With that change applied to `node_modules/nx`, the five rows print `(none)`, `a`, `a c`, `(none)` and `(none)`.

Also seen on 22.7.5, 23.2.1, 23.3.1 and 24.0.4.

## Workaround

Use `"all"` (the default) or `"auto"` instead of an array. To keep a project out of lock file changes, filter it from the affected list yourself.
