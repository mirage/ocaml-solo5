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

(executable
 (name config)
 (enabled_if
  (= %{context_name} solo5))
 (modules config)
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
  (run "solo5-%{env:MODE=hvt}" "%{dep:config.exe}")))

(executable
 (name compilerlibsx86)
 (enabled_if
  (and
   (>= %{ocaml_version} 5.3.0)
   (= %{architecture} amd64)
   (= %{context_name} solo5)))
 (modules compilerlibsx86)
 (link_flags
  :standard
  -cclib
  "-z solo5-abi=%{env:MODE=hvt}"
  ; Force linking the manifest in
  -cclib
  "-u __solo5_mft1_note")
 (libraries solo5os compiler-libs.optcomp)
 (modes native))

(rule
 (alias runtest)
 (enabled_if
  (and
   (>= %{ocaml_version} 5.3.0)
   (= %{architecture} amd64)
   (= %{context_name} solo5)))
 (action
  (run "solo5-%{env:MODE=hvt}" "%{dep:compilerlibsx86.exe}")))

