(executable
 (name hello)
 (enabled_if
  (= %{context_name} solo5))
 (modules hello)
 (link_flags
  :standard
  -cclib
  "-z solo5-abi=%{env:MODE=hvt}"
  ; Force linking the manifest in
  -cclib
  "-u __solo5_mft1_note")
 (libraries solo5os)
 (modes native))

(rule
 (alias runtest)
 (enabled_if
  (= %{context_name} solo5))
 (action
  (run "solo5-%{env:MODE=hvt}" "%{dep:hello.exe}")))

(executable
 (name sysfail)
 (enabled_if
  (= %{context_name} solo5))
 (modules sysfail)
 (link_flags
  :standard
  -cclib
  "-z solo5-abi=%{env:MODE=hvt}"
  ; Force linking the manifest in
  -cclib
  "-u __solo5_mft1_note")
 (libraries solo5os)
 (modes native))

(rule
 (alias runtest)
 (enabled_if
  (= %{context_name} solo5))
 (action
  (with-accepted-exit-codes
   2
   (run "solo5-%{env:MODE=hvt}" "%{dep:sysfail.exe}"))))

