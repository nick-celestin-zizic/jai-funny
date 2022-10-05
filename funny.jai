// comment this line when u want to build
#run { (#import "Compiler").set_build_options_dc(.{do_output=false}); main(); } // set to script mode

#import "Basic";
#import "Window_Creation";
#import "Simp";
#import "Input";
#import "Math";
#import "Random";

window: *void;
window_width  := 640;
window_height := 480;

next_move: enum {
    NONE     :: 0;
    CONTINUE :: 1;
    TURN     :: 2;
    FLIP     :: 3;
};

player_direction: enum_flags u8 {
    RL :: 0b0000_0001;
    UD :: 0b0000_0010;
} // default is Left and Up

quit := false;

BORDER_THICKNESS :: 10.0;

player_points := 0;
player_target: Vector2;
player_position: Vector2;
player_color  := Vector4.{0.8, 0.5, 0.4, 1};
player_side: float;
player_moving := false;

Dump :: (t: $T) #expand { log("%", t); }

ITEM_COLOR :: Vector4.{0.0, 0.7, 0.5, 1.0};
ITEM_SCALE :: 0.5;
NUM_ITEMS :: 5;
items: [NUM_ITEMS]struct {
    using #as pos: Vector2;
    active: bool;
};
init_items :: () {
    for * items {
        ok := false;
        while !ok {
            it.x = random_get_within_range(player_side, xx window_width-player_side);
            it.y = random_get_within_range(player_side, xx window_height-player_side);
            it.active = true;

            ok = true;
            for     item, index: items
            if      index == it_index continue;
            else if distance(item, it) < player_side*4 then ok = false;
        }
    }
}
render_items :: () {
    for items if it.active then immediate_square(it, player_side * ITEM_SCALE, ITEM_COLOR);
}

init_player_render_info :: () {
    player_side     = xx (ifx window_width < window_height then window_width else window_height)/10.0;
    player_position = make_vector2(window_width/2.0, window_height/4.0);
    
    set_target_position();
}

get_player_delta :: inline () -> Vector2 {
    t := player_side;
    d: Vector2 = ---;
    d.x = ifx player_direction & .RL then t else -t;
    d.y = ifx player_direction & .UD then -t else t;
    return d;
}

set_target_position :: () {
    dir := get_player_delta();
    player_target = player_position + dir;
}

main :: () {
    window = create_window(window_width, window_height, "funny");

    window_width, window_height = get_render_dimensions(window);
    set_render_target(window);

    init_player_render_info();
    init_items();

    // TODO: texture_load_from_file(*image_test, "image_test.jpg")
    
    old_time := get_time();
    while !quit {
        reset_temporary_storage();
        update_window_events();
        for get_window_resizes() {
            update_window(it.window);
            
            if it.window == window {
                should_reinit := (it.width != window_width) || (it.height != window_height);

                window_width  = it.width;
                window_height = it.height;

                if should_reinit then init_player_render_info();
            }
        }

        for events_this_frame if it.type == {
            case .QUIT; quit = true;
            case .KEYBOARD; {
                if it.key_pressed if it.key_code == {
                    case .ESCAPE;    quit = true;
                    case .CTRL; {
                        next_move = .TURN;
                    }
                    case .SPACEBAR; {
                        next_move = .CONTINUE;
                    }
                    case .SHIFT; {
                        next_move = .FLIP;
                    }
                }
            }
        }

        update();
        render();
    }
}


previous_target: Vector2;
move_start_time: float64;
update :: () {
    if !player_moving if #complete next_move == {
        case .NONE;
        case .TURN; {
            player_moving = true;
            move_start_time = get_time();
            
            player_direction ^= .RL;
            previous_target = player_target;
            set_target_position();
        }
        case .FLIP; {
            player_moving = true;
            move_start_time = get_time();
            
            player_direction ^= .UD;
            previous_target = player_target;
            set_target_position();
        }
        case .CONTINUE; {
            player_moving = true;
            move_start_time = get_time();
            previous_target = player_target;
        }
    }

    for * items if it.active && check_collision(it, player_side*ITEM_SCALE, player_position, player_side) {
        it.active = false;
        player_points += 1;
        log("TODO: ADD POINTS TO UI %", player_points);
    }

    {
        using player_position;
        min_x := player_position.x-(player_side/2);
        max_x := player_position.x+(player_side/2);
        min_y := player_position.y-(player_side/2);
        may_y := player_position.y+(player_side/2);
        if min_x < BORDER_THICKNESS
            || max_x > window_width - BORDER_THICKNESS
            || min_y < BORDER_THICKNESS
            || may_y > window_height - BORDER_THICKNESS {
               quit = true;
        }
        //if x+playe
    }

    all_dead := true;
    for items if it.active then all_dead = false;
    if all_dead then init_items();
}

animate :: (a: Vector2, b: Vector2, t: float) -> Vector2 {
    
    return a + (b - a) * t;//*t*t;//(3*t*t - 2*t*t*t);
}

bg_color := Vector4.{154/255.0, 169/255.0, 192/255.0, 0};
render :: () {
    { using bg_color; clear_render_target(x, y, z, w); }
    set_shader_for_color();

    

    render_items();

    CURSOR_RIM :: 5;
    cursor_side := player_side * 0.3;
    if player_moving {
        completion := cast(float)saturate((get_time()-move_start_time)/0.1);

        future_target := player_target + get_player_delta();
        //immediate_square(animate(previous_target, future_target, completion), cursor_side, player_color);
        //immediate_square(animate(previous_target, future_target, completion), cursor_side, player_color);
        immediate_hollow_square(lerp(player_target, future_target, completion), player_side, CURSOR_RIM, player_color);
        immediate_square(animate(player_position, player_target, completion), player_side, player_color);
        if completion == 1 {
            player_position = player_target;
            player_moving = false;
            set_target_position();
            next_move = .NONE;
        }
    } else {
        immediate_hollow_square(player_target, player_side, CURSOR_RIM, player_color);
        //immediate_square(player_target, cursor_side, player_color);
        immediate_square(player_position, player_side, player_color);
    }

    {
        lx := 0;
        ly := 0;
        w := cast(float) window_width;
        h := cast(float) window_height;
        BORDER_COLOR :: Vector4.{.8, .1, .2, 1};
        immediate_quad(0.0, 0.0  , w, BORDER_THICKNESS, BORDER_COLOR);
        immediate_quad(0.0, h-BORDER_THICKNESS, w, h  , BORDER_COLOR);

        immediate_quad(0.0  , 0.0, BORDER_THICKNESS, h, BORDER_COLOR);
        immediate_quad(w-BORDER_THICKNESS, 0.0, w  , h, BORDER_COLOR);
    }
    

    swap_buffers(window);
}

check_collision :: inline (a: Vector2, a_side: float, b: Vector2, b_side: float) -> bool {

    ax := a.x - (a_side/2);
    ay := a.y - (a_side/2);
    bx := b.x - (b_side/2);
    by := b.y - (b_side/2);
    return (ax <= bx+b_side && ax+a_side >= bx) &&
        (ay <= by+b_side && ay+a_side >= by);
}

immediate_square :: (center: Vector2, side: float, color: Vector4) {
    half_side := side/2.0;
    x0 := center.x - half_side;
    y0 := center.y - half_side;
    x1 := x0 + side;
    y1 := y0 + side;
    immediate_quad(x0, y0, x1, y1, color);
}

immediate_hollow_square :: (center: Vector2, side: float, rim: float, color: Vector4) {
    half_side := side/2;
    lx := center.x-half_side;
    ly := center.y-half_side;
    hx := lx+side;
    hy := ly+side;

    immediate_quad(lx, ly, lx+rim, hy, color);
    immediate_quad(lx, ly, hx, ly+rim, color);

    immediate_quad(hx-rim, hy, hx, hy-side, color);
    immediate_quad(lx, hy, hx, hy-rim, color);
    //immediate_quad()
    
}
