// LOWER CHASSIS. Print upright: floor on the bed, open top, posts vertical.
// Interfaces provided (all real Boolean cuts):
//   - 4 corner posts: M3 insert holes on front, rear, top and outer-side faces + dowel holes
//   - 2 inward bosses per side wall for side-panel screws
//   - camera cradle pads + 1/4"-20 bolt path (counterbored from underside)
//   - battery-door floor cutout, left ports window, right media window, wall vents
// All window/battery/tripod positions are [ASSUMED] until measured.

function wall_x0(s) = s < 0 ? -chassis_w/2 : chassis_w/2 - wall_t;

module chassis_outline() {
    translate([-chassis_w/2, 0])
        offset(r = corner_r) offset(delta = -corner_r)
            square([chassis_w, chassis_d]);
}

// hole helpers (d = diameter, h = depth from the face)
module hole_front(x, z, d, h) translate([x, -eps, z])             rotate([-90, 0, 0]) cylinder(d = d, h = h + eps);
module hole_rear (x, z, d, h) translate([x, chassis_d + eps, z])  rotate([ 90, 0, 0]) cylinder(d = d, h = h + eps);
module hole_top  (x, y, d, h) translate([x, y, chassis_h + eps])  rotate([180, 0, 0]) cylinder(d = d, h = h + eps);
module hole_side (s, y, z, d, h) {
    if (s < 0) translate([-chassis_w/2 - eps, y, z]) rotate([0,  90, 0]) cylinder(d = d, h = h + eps);
    else       translate([ chassis_w/2 + eps, y, z]) rotate([0, -90, 0]) cylinder(d = d, h = h + eps);
}

module chassis() {
    post_xc = chassis_w/2 - post_x/2;
    tp = cam_xy(tripod_local);

    difference() {
        // ---------- solid ----------
        intersection() {
            linear_extrude(height = chassis_h) chassis_outline();
            union() {
                // floor
                translate([-chassis_w/2, 0, 0]) cube([chassis_w, chassis_d, floor_t]);
                // side walls
                for (s = [-1, 1])
                    translate([wall_x0(s), 0, 0]) cube([wall_t, chassis_d, chassis_h]);
                // corner posts
                for (s = [-1, 1], ry = [0, 1])
                    translate([s < 0 ? -chassis_w/2 : chassis_w/2 - post_x,
                               ry == 0 ? 0 : chassis_d - post_y, 0])
                        cube([post_x, post_y, chassis_h]);
                // inward bosses on side walls
                for (s = [-1, 1], b = mid_bosses)
                    translate([s < 0 ? -chassis_w/2 : chassis_w/2 - (wall_t + boss_len), b[0], b[1]])
                        rotate([0, 90, 0]) cylinder(d = boss_d, h = wall_t + boss_len);
                // camera cradle pads
                for (p = cam_pads)
                    translate(concat(cam_xy(p), [0])) rotate([0, 0, cam_rot[2]])
                        translate([-pad_size/2, -pad_size/2, 0]) cube([pad_size, pad_size, floor_t + pad_h]);
                // tripod-bolt boss
                translate([tp[0], tp[1], 0]) cylinder(d = tripod_boss_d, h = floor_t + pad_h);
            }
        }

        // ---------- subtractions ----------
        // 1/4"-20 bolt path + underside counterbore
        translate([tp[0], tp[1], -eps]) cylinder(d = tripod_clear_d, h = floor_t + pad_h + 2*eps);
        translate([tp[0], tp[1], -eps]) cylinder(d = tripod_head_d, h = tripod_head_depth + eps);

        // battery-door cutout through floor
        bc = cam_xy([batt_x0 + batt_w/2, batt_y0 + batt_len/2]);
        translate([bc[0], bc[1], -eps]) rotate([0, 0, cam_rot[2]])
            translate([-batt_w/2, -batt_len/2, 0]) cube([batt_w, batt_len, floor_t + 2*eps]);

        // side windows (left = ports, right = media door)
        translate([wall_x0(-1) - 1, cam_pos[1] + port_win[0],  cam_pos[2] + port_win[2]])
            cube([wall_t + 2, port_win[1],  port_win[3]]);
        translate([wall_x0( 1) - 1, cam_pos[1] + media_win[0], cam_pos[2] + media_win[2]])
            cube([wall_t + 2, media_win[1], media_win[3]]);

        // wall vents
        for (s = [-1, 1], i = [0 : vent_n - 1])
            translate([wall_x0(s) - 1, vent_y0, vent_z0 + i * vent_pitch])
                cube([wall_t + 2, vent_len, vent_h]);

        // front / rear face: M3 insert holes + dowel holes
        for (s = [-1, 1]) {
            x = s * post_xc;
            for (z = post_screw_z) {
                hole_front(x, z, insert_d, insert_depth);
                hole_rear (x, z, insert_d, insert_depth);
            }
            hole_front(x, dowel_z, dowel_d, dowel_depth);
            hole_rear (x, dowel_z, dowel_d, dowel_depth);

            // top face: screw + dowel per post
            hole_top(x, 6,             insert_d, insert_depth);
            hole_top(x, 13.5,          dowel_d,  dowel_depth);
            hole_top(x, chassis_d - 6,    insert_d, insert_depth);
            hole_top(x, chassis_d - 13.5, dowel_d,  dowel_depth);

            // outer-side face: panel screws into posts
            for (z = side_post_z) {
                hole_side(s, post_y/2,             z, insert_d, insert_depth);
                hole_side(s, chassis_d - post_y/2, z, insert_d, insert_depth);
            }
            // outer-side face: panel screws into wall bosses
            for (b = mid_bosses) hole_side(s, b[0], b[1], insert_d, insert_depth);
        }
    }
}
