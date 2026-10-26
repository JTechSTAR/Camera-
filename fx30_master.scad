// ============================================================
//  FX30 ENCLOSED CINEMA BODY  -  MASTER ASSEMBLY  (stage 1: chassis + placeholder)
//  Requires OpenSCAD 2021.01 or newer (uses assert, let, matrix math).
//
//  Preview:   open this file, F5.
//  Export a part to STL (command line, run from this folder):
//      openscad -D 'part="chassis"' -o chassis.stl fx30_master.scad
//  Parts available now:  "chassis"
//  Other modes:          "assembly" | "camera" | "validate_collision" | "validate_screen"
//  Parts still to come:  front bezel, side panels, top panel, handle, side handles, rear cover, accessories
//
//  validate_collision : chassis INTERSECT camera keep-out (with margin).
//                       Expected result = EMPTY (OpenSCAD warns "object is empty").
//  validate_screen    : chassis INTERSECT flipped-screen volume.
//                       Expected result = NOT empty with the assumed values (see notes).
// ============================================================

include <fx30_params.scad>
include <fx30_camera_placeholder.scad>
include <fx30_chassis.scad>

part                = "assembly";
show_camera         = true;     // show/hide FX30 placeholder in "assembly"
show_screen_keepout = false;    // ghost the flipped-out screen volume
explode             = 0;        // 0 = assembled, 1 = fully exploded
explode_gap         = 60;       // mm of camera lift at explode = 1

// ---------- hard checks (stop the render if violated) ----------
assert(chassis_w <= print_env[0] - print_margin, "Chassis too wide for print envelope");
assert(chassis_d <= print_env[1] - print_margin, "Chassis too deep for print envelope");
assert(chassis_h <= print_env[2] - print_margin, "Chassis too tall for print envelope");
assert(abs(lens_axis_world[0]) < 0.5, "Lens axis is not centred on X=0 (front opening would be off-centre)");

// ---------- diagnostics (read the console) ----------
corners = [for (x = [-fx30_w/2, fx30_w/2], y = [0, fx30_d], z = [0, fx30_h]) cam_to_world([x, y, z])];
echo(str("Chassis part size  : ", chassis_w, " x ", chassis_d, " x ", chassis_h, " mm  (envelope ", print_env, ")"));
echo(str("Lens axis (world)  : ", lens_axis_world, "   [x should be 0]"));
echo(str("Margin camera->left wall inner  : ", min([for (c = corners) c[0]]) - (-chassis_w/2 + wall_t), " mm"));
echo(str("Margin camera->right wall inner : ", (chassis_w/2 - wall_t) - max([for (c = corners) c[0]]), " mm"));
echo(str("Margin camera rear->chassis rear: ", chassis_d - max([for (c = corners) c[1]]), " mm"));
echo(str("Margin camera top+shoe->deck    : ", chassis_h - (max([for (c = corners) c[2]]) + shoe_h), " mm"));

module assembly() {
    color("slategray") chassis();
    if (show_camera)
        translate([0, 0, explode * explode_gap]) color("royalblue", 0.55) camera_world();
    if (show_screen_keepout)
        translate([0, 0, explode * explode_gap]) color("orange", 0.30) screen_world();
}

if      (part == "assembly")           assembly();
else if (part == "chassis")            chassis();
else if (part == "camera")             camera_world();
else if (part == "validate_collision") intersection() { chassis(); camera_world(cam_margin, 0); }
else if (part == "validate_screen")    intersection() { chassis(); screen_world(); }
else echo("Unknown part: ", part);
