let _ =
  Printf.printf "Version: %s\nOS: %s\nUnix: %b\nWin: %b\nCygwin: %b\n"
    Sys.ocaml_version Sys.os_type Sys.unix Sys.win32 Sys.cygwin
