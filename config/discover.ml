module C = Configurator.V1

let failwithf fmt = Printf.ksprintf failwith fmt

let ( / ) = Filename.concat

let package = "solo5-bindings"

let pkg_config

let run = function
  | [] -> failwith "cannot run empty commands"
  | h::t ->
    match C.Process.run c h t with
    | { exit_code = 0; stdout; stderr = _ } -> String.trim stdout
    | t ->
      failwith "`%s' failed with exit code %d: %S"
        (String.concat " " (h :: t))
        t.exit_code t.stderr

let () =
  C.main ~name:"foo" (fun c ->
      let opam_prefix = run [ "opam"; "config"; "var"; "prefix" ] in
      let dune_prefix =
        let root =
          try Sys.getenv "INSIDE_DUNE" with Not_found -> assert false
        in
        let context = Filename.basename root in
        let root = Filename.dirname root in
        root / "install" / context
      in
      let path prefix = prefix / "lib" / "pkgconfig" in
      let pkg_config_path = [ path opam_prefix; path dune_prefix ] in
      Unix.putenv "PKG_CONFIG_PATH" (String.concat ":" pkg_config_path);
      let conf =
        match C.Pkg_config.get c with
        | None -> failwith "cannot find pkg-config"
        | Some pc -> (
            match C.Pkg_config.query pc ~package with
            | Some deps -> deps
            | None -> failwithf "cannot find %s's pkg-config info" package )
      in
      C.Flags.write_sexp "cflags" conf.cflags)
