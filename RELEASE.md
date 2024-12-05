# Release a new version

- have all the patches / PRs merged
- update CHANGES.md
- push everything to GitHub
- go to https://github.com/mirage/ocaml-solo5/releases and click
  "Draft a new release"
- Select as tag a good version number (e.g. v1.1.2), the target branch
  (main for OCaml 5.x, 4.14 for OCaml 4.14)
- enter a release title and description
- click "Publish release"
- download the GitHub-generated tarball (e.g.
  https://github.com/mirage/ocaml-solo5/archive/refs/tags/v1.1.2.tar.gz)
- go to your opam-repository clone, copy over the latest release to the new
  one (e.g. cp -R ocaml-solo5.1.1.1 ocaml-solo5.1.1.2)
- adjust the opam file with release tarball, checksum, eventually dependencies
  (run a diff between this opam-solo5.opam and the one in opam-repository)
- also adjust the ocaml-solo5-cross-aarch64 package as above
- open a PR to ocaml/opam-repository
