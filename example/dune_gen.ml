let print_rule test exitcode extraifs extralibs =
  let enabled_if out extraifs =
    Printf.fprintf out {|(enabled_if
  %a(= %%{context_name} solo5)%a)|}
      (fun out ifs ->
        match ifs with
        | [] -> ()
        | _ ->
            Printf.fprintf out {|(and
   |};
            List.iter (Printf.fprintf out {|%s
   |}) ifs)
      extraifs
      (fun out ifs -> match ifs with [] -> () | _ -> Printf.fprintf out ")")
      extraifs
  in
  Printf.printf
    {|(executable
 (name %s)
 %a
 (modules %s)
 (link_flags
  :standard
  -cclib
  "-z solo5-abi=%%{env:MODE=hvt}"
  ; Force linking the manifest in
  -cclib
  "-u __solo5_mft1_note")
 (libraries solo5os%a)
 (modes native))

(rule
 (alias runtest)
 %a
 (action
  %a(run "solo5-%%{env:MODE=hvt}" "%%{dep:%s.exe}")%a))

|}
    test enabled_if extraifs test
    (fun out -> List.iter (Printf.fprintf out " %s"))
    extralibs enabled_if extraifs
    (fun out exitcode ->
      match exitcode with
      | None -> ()
      | Some code ->
          Printf.fprintf out {|(with-accepted-exit-codes
   %d
   |} code)
    exitcode test
    (fun out exitcode ->
      match exitcode with None -> () | Some _ -> Printf.fprintf out ")")
    exitcode

let _ =
  print_rule "hello" None [] [];
  print_rule "sysfail" (Some 2) [] []
