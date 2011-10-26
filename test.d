import std.math, std.stdio, std.conv;
import std.file;

import bmp;

struct vec3d {
    double x, y, z;

    vec3d opBinary(string op)(vec3d o) if (op == "+") {
        return vec3d(x+o.x, y+o.y, z+o.z);
    }
    vec3d opBinary(string op)(vec3d o) if (op == "-") {
        return vec3d(x-o.x, y-o.y, z-o.z);
    }
    vec3d opUnary(string op)() if (op == "-") {
        return -1 * this;
    }
    vec3d opBinaryRight(string op)(double d) if (op == "*") {
        return vec3d(d*x, d*y, d*z);
    }
    vec3d opBinary(string op)(double d) if (op == "*") {
        return vec3d(d*x, d*y, d*z);
    }

    vec3d normalize() {
        return (1/this.length) * this;
    }

    double dot(vec3d o) {
        return x*o.x + y*o.y + z*o.z;
    }
    double length_sq() @property {
        return dot(this);
    }
    double length() @property {
        return sqrt(this.length_sq);
    }

    vec3d cross(vec3d o) {
        return vec3d(y*o.z - z*o.y, z*o.x - x*o.z, x*o.y - y*o.x);
    }


    double distance_to(vec3d o) {
        return (this - o).length;
    }

    vec3d project_on(vec3d o) {
        return o.dot(this) / o.length ^^ 2 * o;
    }
}

struct Line {
    vec3d pos;
    vec3d dir;
}


enum refractive_index = 2.2;

class Sphere {
    vec3d pos;
    double radius;


    bool reflective;
    bool see_through_able;

    Color color;

    this(vec3d pos_, double radius_, bool reflective_, bool see_through_able_,
            Color color_) {
        pos = pos_;
        radius = radius_;
        reflective = reflective_;
        see_through_able = see_through_able_;
        color = color_;
    }

    vec3d normal_for(vec3d point, bool is_refracting=false) {
        if (!is_refracting) {
            return (point - pos).normalize();
        } else {
            return (pos - point).normalize();
        }
    }
}

class Light {
    vec3d pos;
    Color color;

    this(vec3d pos_, Color color_) {
        pos = pos_;
        color = color_;
    }
}

class Scene {
    Sphere[] shapes;
    Light[] lights;

    this(Sphere[] shapes_, Light[] lights_) {
        shapes = shapes_;
        lights = lights_;
    }
}




bool intersect(Line line, Sphere sphere, out vec3d result,
        bool is_refracting=false) {
    assert (sphere !is null);
    vec3d sphere_rel = sphere.pos - line.pos;
    vec3d pt_rel = sphere_rel.project_on(line.dir);

    double dist = pt_rel.distance_to(sphere_rel);

    if (dist > sphere.radius) {
        return false;
    }

    if (line.dir.dot(pt_rel) <= 0) {
        return false;
    }

    double to_edge = sqrt((sphere.radius + 0.1)^^2 - dist^^2);

    if (is_refracting) {
        to_edge = -to_edge;
    }

    result = pt_rel - (to_edge * line.dir.normalize()) + line.pos;
    return true;
}

vec3d reflect(vec3d dir, vec3d normal) {
    vec3d to_normal = (-dir).project_on(normal) - (-dir);

    return to_normal*2 - dir;
}

unittest {
    vec3d a,b,c;

    a = vec3d(1,0,0);
    b = vec3d(0,1,0);
    c = vec3d(0,0,1);


    writeln(to!string(a));
    writeln(to!string(b));
    writeln(to!string(c));
    writeln();
    writeln(to!string(a+b));
    writeln(to!string(a+c));
    writeln(to!string(b+c));
    writeln();
    writeln(to!string(a-b));
    writeln(to!string(a-c));
    writeln(to!string(b-c));
    writeln();
    writeln(to!string(-a-b));
    writeln(to!string(-a-c));
    writeln(to!string(-b-c));
    writeln();
    writeln(to!string(a.dot(b)));
    writeln(to!string(a.dot(c)));
    writeln(to!string(b.dot(c)));
    writeln();
    writeln(to!string(a.dot(a)));
    writeln(to!string(b.dot(b)));
    writeln(to!string(c.dot(c)));

    vec3d d = vec3d(-1,1,0);
    writeln(to!string(d.length));
    writeln(to!string(d.length_sq));
    
    writeln();
    writeln(to!string(a.dot(d)));
    writeln(to!string(b.dot(d)));
    writeln(to!string(c.dot(d)));
    writeln();
    writeln(to!string(a.cross(b)));
    writeln(to!string(b.cross(c)));
    writeln(to!string(c.cross(a)));
    writeln();
    writeln(to!string(a.cross(-b)));
    writeln(to!string(b.cross(-c)));
    writeln(to!string(c.cross(-a)));
    

    vec3d e = vec3d(0,0,3);
    vec3d f = vec3d(0,1,1);

    writeln();
    writeln(to!string(f.project_on(e)));
    writeln(to!string(e.project_on(f)));
    
    auto sphere = new Sphere(vec3d(100,0,0), 50, false, false, Color(0,1,1));
    auto line = Line(vec3d(0,0,0), vec3d(100,58,0));
    vec3d result;
    if (intersect(line, sphere, result)) {
        writeln(to!string(result));
    } else {
        writeln("inge krock!");
    }
}

Sphere find_closest_collision(Scene scene, Line line, out vec3d point, 
        bool accepts_invisible, bool is_refracting) {
    vec3d p = line.pos;
    bool found;
    vec3d closest;
    Sphere closest_sphere;
    foreach (sphere; scene.shapes) {
        if (!accepts_invisible && sphere.see_through_able) {
            continue;
        }
        vec3d result;
        if (intersect(line, sphere, result, is_refracting)) {
            if (!found || p.distance_to(result) < p.distance_to(closest)) {
                found = true;
                closest = result;
                closest_sphere = sphere;
            }
        }
    }

    if (!found) {
        return null;
    }

    point = closest;
    return closest_sphere;
}

Color cast_shadow_ray(Scene scene, vec3d pos, vec3d normal, Light light) {
    vec3d pos_to_light = light.pos - pos;
    Line line = Line(pos, pos_to_light);

    vec3d point;
    Sphere sphere = find_closest_collision(scene, line, point, false, false);

    if (sphere !is null 
            && pos.distance_to(point) <= pos.distance_to(light.pos)) {
        return Color(0,0,0);
    }

    Color color = light.color;
    double dot = pos_to_light.dot(normal);
    if (dot <= 0) {
        return Color(0,0,0);
    }
    double factor = dot * 50/(pos.distance_to(light.pos)^^2);

    assert (factor > 0);

    color.r *= factor;
    color.g *= factor;
    color.b *= factor;

    return color;
}

Color cast_ray_into_scene(Scene scene, Line line, bool is_refracting=false) {
    vec3d closest;
    Sphere closest_sphere = find_closest_collision(scene, 
            line, closest, true, is_refracting);

    if (closest_sphere is null) {
        return Color(1,0.75,0.75);
    }

    if (closest_sphere.reflective) {
        vec3d normal = closest_sphere.normal_for(closest, is_refracting);
        vec3d new_dir = reflect(line.dir, normal);

        Line new_line = Line(closest, new_dir);
        writeln(to!string(new_line));
        return cast_ray_into_scene(scene, new_line, is_refracting);
    } else if (closest_sphere.see_through_able) {
        assert (0);
    } else {
        vec3d normal = closest_sphere.normal_for(closest);

        Color color;
        foreach (light; scene.lights) {
            Color temp_color = cast_shadow_ray(scene, closest, normal, light);
            color.r += temp_color.r;
            color.g += temp_color.g;
            color.b += temp_color.b;
        }

        color.r *= closest_sphere.color.r;
        color.g *= closest_sphere.color.g;
        color.b *= closest_sphere.color.b;

        return color;
    }
}


Color[][] whit(Scene scene, vec3d camera_pos, vec3d camera_dir,
        double w, double h, double res = 0.1) {
    vec3d up = vec3d(0,0,1);

    vec3d side = camera_dir.cross(up).normalize();
    up = -camera_dir.cross(side).normalize();

    Color[][] ret;
    for (double y = h/2; y > -h/2; y -= res) {
        Color[] row;
        for (double x = -w/2; x < w/2; x += res) {
            vec3d v = camera_dir + up * y + side * x;
            Line l = Line(camera_pos, v);
            row ~= cast_ray_into_scene(scene, l);
            //writeln(x, " ", y, " ", to!string(row[$-1]));
        }
        ret ~= row;
    }
    return ret;
}

void main() {
    Color[][] boo = [[Color(0,0,1), Color(0,1,0), Color(1,0,0)],
                     [Color(1,0,0), Color(1,1,1), Color(1,0,0)],
                     [Color(1,0,0), Color(1,1,1), Color(1,0,0)]];

    std.file.write("o.bmp", bmp.encode(boo));

    auto spheres = [new Sphere(vec3d(0,0,0), 10, false, false, Color(1,1,1))];
    auto lights = [new Light(vec3d(60, -50, 20), Color(0,1,1)),
         new Light(vec3d(-60, -50, 20), Color(1,1,0))];

    Scene scene = new Scene(spheres, lights);
    auto line = Line(vec3d(0, -1000,0), vec3d(0,900,0));

    auto data = whit(scene, line.pos, line.dir, 32, 24, 0.05);

    std.file.write("o.bmp", data.encode());
}

