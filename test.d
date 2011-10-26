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




bool intersect(Line line, Sphere sphere, out vec3d result,
        bool is_refracting=false) {
    assert (sphere !is null);
    vec3d sphere_rel = sphere.pos - line.pos;
    vec3d pt_rel = sphere_rel.project_on(line.dir);

    double dist = pt_rel.distance_to(sphere_rel);

    if (dist > sphere.radius) {
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

Color cast_ray_into_scene(Sphere[] scene, Line line, bool is_refracting=false) {
    vec3d p = line.pos;
    vec3d closest;
    Sphere closest_sphere;
    bool found;
    foreach (sphere; scene) {
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
        return Color(255,192,192);
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
        assert (0);
    }
}


Color[][] whit(Sphere[] scene, vec3d camera_pos, vec3d camera_dir,
        double w, double h) {
    vec3d up = vec3d(0,0,1);

    vec3d side = up.cross(camera_dir).normalize();
    up = side.cross(camera_dir).normalize();

    Color[][] ret;
    for (double y = -h/2; y < h/2; y += 1) {
        Color[] row;
        for (double x = -w/2; x < w/2; x += 1) {
            vec3d v = camera_dir + up * x + side * y;
            Line l = Line(camera_pos, v);
            row ~= cast_ray_into_scene(scene, l);
            writeln(x, " ", y, " ", to!string(row[$-1]));
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

    auto scene = [new Sphere(vec3d(100,0,0), 50, true, false, Color(0,1,1))];
    auto line = Line(vec3d(0,0,0), vec3d(10,5.8,0));

    writeln(to!string(whit(scene, line.pos, line.dir, 320, 240)));
}

