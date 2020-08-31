(rule
 (with-stdout-to
  dune.hvt.gen
  (run ./build.exe hvt)))

(rule
 (alias runtest)
 (action
  (diff dune.hvt dune.hvt.gen)))

(rule
 (with-stdout-to
  dune.spt.gen
  (run ./build.exe spt)))

(rule
 (alias runtest)
 (action
  (diff dune.spt dune.spt.gen)))

(rule
 (with-stdout-to
  dune.virtio.gen
  (run ./build.exe virtio)))

(rule
 (alias runtest)
 (action
  (diff dune.virtio dune.virtio.gen)))

(rule
 (with-stdout-to
  dune.muen.gen
  (run ./build.exe muen)))

(rule
 (alias runtest)
 (action
  (diff dune.muen dune.muen.gen)))

(rule
 (with-stdout-to
  dune.genode.gen
  (run ./build.exe genode)))

(rule
 (alias runtest)
 (action
  (diff dune.genode dune.genode.gen)))

(rule
 (with-stdout-to
  dune.xen.gen
  (run ./build.exe xen)))

(rule
 (alias runtest)
 (action
  (diff dune.xen dune.xen.gen)))
