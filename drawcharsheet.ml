open Cairo


let bg = Cairo_png.image_surface_create_from_file "cs.png" ;;
let circle = Cairo_png.image_surface_create_from_file "b.png" ;;
let bigcircle = Cairo_png.image_surface_create_from_file "BB.png" ;;
let width  = image_surface_get_width bg ;;
let height = image_surface_get_height bg ;;

let draw_rep ctx glyph num xc yc xi yi =
    for i = 0 to (num - 1) do
      Cairo.set_source_surface ctx glyph 
      (floor (((float_of_int i) *. xi) +. xc))
      (floor (((float_of_int i) *. yi) +. yc));
      Cairo.paint ctx
    done ;;

let draw_auto ctx glyph num xc yc xi yi =
  draw_rep ctx glyph num xc yc (xi +. (float_of_int (image_surface_get_width glyph)))
  (yi +. (float_of_int (image_surface_get_height glyph)));;

let draw_x ctx glyph (num: int) xc yc xi yi =
  draw_rep ctx glyph num xc yc (xi +. (float_of_int (image_surface_get_width glyph))) yi ;;

open BatOption
let may_draw_x ctx glyph (num: int option) xc yc xi yi =
  may (fun it -> draw_x ctx glyph it xc yc xi yi) num ;;

let draw_y ctx glyph num xc yc xi yi =
  draw_rep ctx glyph num xc yc xi (0. -. (yi +. (float_of_int
  (image_surface_get_height glyph)))) ;;

let may_draw_y ctx glyph num xc yc xi yi =
  may (fun it -> draw_y ctx glyph it xc yc xi yi) num ;;

let draw_text ctx text x y =
  Cairo.set_source_rgb ctx 0. 0. 0. ;
  Cairo.move_to ctx x y ;
  Cairo.show_text ctx text ;;

let may_text ctx text x y =
  may (fun txt -> draw_text ctx txt x y) text ;;

open Charsheetgen

let drawstats ctx sb =
  draw_x ctx circle sb.intelligence  568. 572. (-1.) 0. ;
  draw_x ctx circle sb.wit           568. 625. (-1.) 0. ;
  draw_x ctx circle sb.res           568. 678. (-1.) 0. ;
  draw_x ctx circle sb.str           920. 572. (-1.) 0. ;
  draw_x ctx circle sb.dex           920. 624. (-1.) 0. ;
  draw_x ctx circle sb.sta           920. 677. (-1.) 0. ;
  draw_x ctx circle sb.pre          1305. 573. (-1.) 0. ;
  draw_x ctx circle sb.man          1305. 625. (-1.) 0. ;
  draw_x ctx circle sb.com          1305. 678. (-1.) 0. ;;

let drawskills ctx (sk: Charsheetgen.skillblock) = 
  let dsk = (fun (num: int option) (y: float) -> 
    (may_draw_x ctx circle num 431. y (-0.5) 0.)) in
  dsk sk.academics      852.  ;
  dsk sk.computer       892.  ;
  dsk sk.crafts         931.  ;
  dsk sk.investigation  970.  ;
  dsk sk.medicine       1009. ;
  dsk sk.occult         1048. ;
  dsk sk.politics       1087. ;
  dsk sk.science        1126. ;
  dsk sk.athletics      1240. ;
  dsk sk.brawl          1279. ;
  dsk sk.drive          1318. ;
  dsk sk.firearms       1357. ;
  dsk sk.larceny        1396. ;
  dsk sk.stealth        1435. ;
  dsk sk.survival       1474. ;
  dsk sk.weaponry       1513. ;
  dsk sk.animal_ken     1601. ;
  dsk sk.empathy        1640. ;
  dsk sk.expression     1679. ;
  dsk sk.intimidation   1718. ;
  dsk sk.persuasion     1757. ;
  dsk sk.socialize      1796. ;
  dsk sk.streetwise     1835. ;
  dsk sk.subterfuge     1874. ;;

open Printf

let drawsheet (cs: Charsheetgen.charsheet) surface  = 
    let ctx = Cairo.create surface in

    (* Set thickness of brush *)
    Cairo.set_line_width ctx 4. ;

    Cairo.set_source_surface ctx bg 0. 0. ;
    Cairo.paint ctx ;
    Cairo.select_font_face ctx "Goudy" FONT_SLANT_NORMAL FONT_WEIGHT_NORMAL ;
    Cairo.set_font_size ctx 50. ;

    draw_text ctx cs.name  300. 335. ;
    may_text ctx cs.player 318. 394. ;
    may_text ctx cs.virtue 840. 394. ;
    may_text ctx cs.vice   795. 449. ;

    may_text ctx cs.first_affiliation   1214. 334. ;
    may_text ctx cs.second_affiliation  1233. 397. ;
    may_text ctx cs.cabal               1231. 453. ;

    draw_x ctx bigcircle cs.power 1036. 1132. 13.75 0. ;
    (match cs.stats with
      `Statblock sb ->
        may (fun size ->
          draw_x ctx bigcircle (sb.sta + size) 1036. 827. (-0.5) 0.)
        cs.character_size ;
        draw_x ctx bigcircle (sb.com + sb.res) 1036. 921. 13.75 0.
    | `Spiritblock sb -> print_string "Spiritblock should not appear here" ) ;
    may (fun morals -> draw_y ctx circle morals.moral_amount 1378. 1512. 0.
    9.5) cs.morality ;

    may (fun ar ->
      let dar num y = may_draw_x ctx circle num 871. y (-0.5) 0. in
      dar ar.death  1588. ;
      dar ar.fate   1620. ;
      dar ar.forces 1650. ;
      dar ar.life   1682. ;
      dar ar.mind   1742. ;
      dar ar.matter 1712. ;
      dar ar.prime  1773. ;
      dar ar.space  1804. ;
      dar ar.spirit 1835. ;
      dar ar.time   1866. ;
    ) cs.arcana ;

    Cairo.select_font_face ctx "bulkyRefuse Type" FONT_SLANT_NORMAL FONT_WEIGHT_NORMAL ;
    Cairo.set_font_size ctx 26. ;
    may (fun merits -> 
      for i = 0 to ((List.length merits) - 1) do
        draw_text ctx (fst (List.nth merits i)) 615. (869. +. ((float_of_int
        i) *. 39.)) ;
        draw_x ctx circle (snd (List.nth merits i)) 870. (852. +. ((float_of_int
        i) *. 39.)) (-0.5) 0. 
      done
    ) cs.merits ;
    may (fun flaws ->
      for i = 0 to ((List.length flaws) - 1) do
        draw_text ctx (List.nth flaws i) 615. (1238. +. ((float_of_int
        i) *. 41.)) ;
      done
    ) cs.flaws ;
    Cairo.select_font_face ctx "Goudy" FONT_SLANT_NORMAL FONT_WEIGHT_NORMAL ;
    may (fun size -> draw_text ctx (string_of_int size) 670. 1358. )
      cs.character_size ;

    Cairo.set_font_size ctx 24. ;
    may (fun xp -> draw_text ctx 
      ((string_of_int xp) ^ " unspent" ^ (if (cs.xp_total != 0) || (xp == 0)
      then ", of " ^ (string_of_int cs.xp_total) ^ " total" else "")) 735. 1516. ) cs.xp ;

    Cairo.set_font_size ctx 26. ;
    may (drawskills ctx) cs.skills ;
    (match cs.stats with
      `Statblock sb ->
        drawstats ctx sb ;
        (* Draw derived stats defence, initiative mod, and speed here.
         * This should take into account merits, spells etc as well    *)
        draw_text ctx (string_of_int (min sb.dex sb.wit)) 715. 1398. ;
        draw_text ctx (string_of_int (sb.dex + sb.com)) 777. 1438. ;
        draw_text ctx (string_of_int (sb.str + sb.dex + 5)) 700. 1478. ;
    | `Spiritblock sb -> print_string "Spiritblock should not appear here" ) ;
    may (fun rotes ->
      Cairo.set_source_rgb ctx 0. 0. 0. ;
      List.iter (fun rote ->
        Cairo.move_to ctx 200. (match rote with 
            `Academics      ->  843.
          | `Computer       ->  881.
          | `Crafts         ->  920.
          | `Investigation  ->  959.
          | `Medicine       ->  997.
          | `Occult         -> 1035.
          | `Politics       -> 1073.
          | `Science        -> 1111.
          | `Athletics      -> 1232.
          | `Brawl          -> 1271.
          | `Drive          -> 1309.
          | `Firearms       -> 1348.
          | `Larceny        -> 1386.
          | `Stealth        -> 1424.
          | `Survival       -> 1462.
          | `Weaponry       -> 1500.
          | `Animal_ken     -> 1591.
          | `Empathy        -> 1629.
          | `Expression     -> 1667.
          | `Intimidation   -> 1705.
          | `Persuasion     -> 1743.
          | `Socialize      -> 1781.
          | `Streetwise     -> 1819.
          | `Subterfuge     -> 1857.) ;
        Cairo.rel_line_to ctx 30. 30. ;
        Cairo.close_path ctx ;
        (*Cairo.stroke ctx ;*)
        Cairo.rel_move_to ctx 30. 0. ;
        Cairo.rel_line_to ctx (-30.) 30. ;
        Cairo.close_path ctx ;
        Cairo.stroke ctx ;
      ) rotes ;
    ) cs.rote_skills;
    Cairo.set_font_size ctx 14. ;    
    draw_text ctx (match cs.power with
        0  -> "N/A"
      | 1  -> "1"
      | 2  -> "2"
      | 3  -> "3"
      | 4  -> "4"
      | 5  -> "5"
      | 6  -> "6"
      | 7  -> "7"
      | 8  -> "8"
      | 9  -> "10"
      | 10 -> "15"
      | _  -> "?") 1266. 1087. ;;

let drawsheet_png cs =
  (* Setup Cairo *)
  let surface = image_surface_create Cairo.FORMAT_ARGB32 ~width ~height in
  drawsheet cs surface;
  (* Rain dance to serve the image *)
  let img = Filename.temp_file ~temp_dir:"/home/justin/code/Android-Nexus/temp/" "charsheet" ".png" in
  Cairo_png.surface_write_to_file surface img ;
  ("../../../../.." ^ img) ;; (* this is needed as Http_Daemon only supports
  relative file paths *)
  (*Cairo_png.surface_write_to_channel surface outchan ;; *)

let drawsheet_pdf cs =
  (* Setup Cairo *)
  let img = Filename.temp_file ~temp_dir:"/home/justin/code/Android-Nexus/temp/"
  "charsheet" ".pdf" in
  let outout = open_out_bin img in
  let surface = Cairo_pdf.surface_create_for_channel outout
  (float_of_int width) (float_of_int height) in
  drawsheet cs surface;
  (* Rain dance to serve the image *)
  surface_flush surface;
  surface_finish surface;
  flush outout ;
  close_out outout ;
  ("../../../../.." ^ img) ;; (* this is needed as Http_Daemon only supports
  relative file paths *)
  (*Cairo_png.surface_write_to_channel surface outchan ;; *)


open Http_types

let callback req outchan =
  let data = charsheet_of_string req#body in
  print_string "foo" ;
  let img = (match req#path with
    "/png" -> drawsheet_png data
  | "/pdf" -> drawsheet_pdf data) in
  (* Http.daemon.send_basic_headers ~code:(`Code 200) outchan ; *)
  (* Http_daemon.send_status_line ~code:(`Code 200) outchan ;
  Http_daemon.send_CRLF outchan ; *)
  Http_daemon.respond_file img outchan ;;
  (*drawsheet data outchan ;
  close_out outchan;;*)

let spec =
  { Http_daemon.default_spec with
      callback = callback;
      port = 9999;
  }

let _ = Http_daemon.main spec


