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
  may (fun (it: int) -> draw_x ctx glyph it xc yc xi yi) num ;;

let may_draw_y ctx glyph num xc yc xi yi =
  may (fun it -> draw_rep ctx glyph it xc yc xi
  (yi +. (float_of_int (image_surface_get_height glyph)))) num ;;

let may_text ctx text x y =
  Cairo.set_source_rgb ctx 0. 0. 0. ;
  Cairo.move_to ctx x y ;
  may (Cairo.show_text ctx) text ;;

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
let drawsheet (cs: Charsheetgen.charsheet) = 
    (* Setup Cairo *)
    let surface = image_surface_create Cairo.FORMAT_ARGB32 ~width ~height in
    let ctx = Cairo.create surface in

    (* Set thickness of brush *)
    Cairo.set_line_width ctx 15. ;

    (* Draw out the triangle using absolute coordinates *)
    Cairo.move_to     ctx   200.  100. ;
    Cairo.line_to     ctx   300.  300. ;
    Cairo.rel_line_to ctx (-200.)   0. ;
    Cairo.close_path  ctx ;

    (* Apply the ink *)
    Cairo.stroke ctx ;

    Cairo.set_source_surface ctx bg 0. 0. ;
    Cairo.paint ctx ;
    Cairo.select_font_face ctx "Goudy" FONT_SLANT_NORMAL FONT_WEIGHT_NORMAL ;
    Cairo.set_font_size ctx 50. ;

    may_text ctx cs.player 318. 394. ;
    may_text ctx cs.virtue 840. 394. ;
    may_text ctx cs.vice   795. 449. ;

    may (drawskills ctx) cs.skills ;
    (match cs.stats with
      `Statblock sb ->
        drawstats ctx sb;
        print_string "Statblock"
    | `Spiritblock sb -> print_string "Spiritblock" );
    Cairo_png.surface_write_to_file surface "newcharsheet.png" ;
    print_string "Written new charsheet." ;;

open Http_types

let callback req outchan =
  print_string "init" ;
  print_string req#body ;
  let data = charsheet_of_string req#body in
  print_string "foo" ;
  drawsheet data ;
  Http_daemon.respond ~code:(`Code 200) ~body:("a") outchan

let spec =
  { Http_daemon.default_spec with
      callback = callback;
      port = 9999;
  }

let _ = Http_daemon.main spec


