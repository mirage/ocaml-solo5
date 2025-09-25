(* This file is largely extracted from Opam's OpamSystem module, with a lot *)
(* of shortcuts^W simplifications on the way                                *)
(*                                                                          *)
(* SPDX-License-Identifier: LGPL-2.1-only WITH OCaml-LGPL-linking-exception *)
(* Copyright 2012-2020 OCamlPro                                             *)
(* Copyright 2012 INRIA                                                     *)
(* Copyright 2025 Tarides                                                   *)

let realpath p =
  let open Filename in
  match try Some (Sys.is_directory p) with Sys_error _ -> None with
  | None ->
      let rec resolve dir =
        if Sys.file_exists dir then Unix.realpath dir
        else
          let parent = dirname dir in
          if dir = parent then dir else concat (resolve parent) (basename dir)
      in
      let p = if is_relative p then concat (Sys.getcwd ()) p else p in
      resolve p
  | Some true -> Unix.realpath p
  | Some false -> (
      let dir = Unix.realpath (dirname p) in
      match basename p with "." -> dir | base -> concat dir base)

let read path = In_channel.(with_open_bin path input_all)

let write path content =
  Out_channel.(with_open_bin path (fun oc -> output_string oc content))

let apply ~force ~dir diffs =
  (* NOTE: It is important to keep this `concat dir ""` to ensure the
     is_prefix_of below doesn't match another similarly named directory *)
  let dir = Filename.concat (realpath dir) "" in
  let get_path file =
    let file = realpath (Filename.concat dir file) in
    if not (String.starts_with ~prefix:dir file) then
      invalid_arg "Patch tried to escape its scope";
    file
  in
  let patch content diff =
    (* NOTE: The None case returned by [Patch.patch] is only returned
       if [diff = Patch.Delete _]. This sub-function is not called in
       this case so we [assert false] instead. *)
    match Patch.patch ~cleanly:true content diff with
    | Some x -> x
    | None -> assert false (* See NOTE above *)
    | exception _ when not force -> invalid_arg "Patch does not apply cleanly"
    | exception _ -> (
        match Patch.patch ~cleanly:false content diff with
        | Some x -> x
        | None -> assert false (* See NOTE above *)
        | exception _ -> invalid_arg "Patch does not apply")
  in
  let apply diff =
    match diff.Patch.operation with
    | Patch.Edit (file1, file2) ->
        let file1 = get_path file1 in
        let file2 = get_path file2 in
        let file1_exists = Sys.file_exists file1 in
        (* That seems to be the GNU patch behaviour *)
        let file = if file1_exists then file1 else file2 in
        let content = read file in
        let content = patch (Some content) diff in
        write file2 content
        (* FIXME: remove directory of file1 if now empty? *)
    | Patch.Delete file | Patch.Git_ext (file, _, Patch.Delete_only) ->
        let file = get_path file in
        Unix.unlink file
        (* FIXME: Windows *)
        (* FIXME: remove directory of file if now empty? *)
    | Patch.Create file | Patch.Git_ext (_, file, Patch.Create_only) ->
        let file = get_path file in
        let content = patch None diff in
        write file content
    | Patch.Git_ext (_, _, Patch.Rename_only (src, dst)) ->
        let src = get_path src in
        let dst = get_path dst in
        (* FIXME: create directory of dst if needed *)
        Unix.rename src dst
        (* FIXME: remove directory of src if now empty? *)
  in
  List.iter apply diffs

let main ~dir patch =
  let content = In_channel.input_all patch in
  let diffs = Patch.parse ~p:1 content in
  apply ~force:false ~dir diffs

let _ = main ~dir:"." In_channel.stdin
