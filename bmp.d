import std.range, std.stdio;


struct Color {
    double r, g, b;
}

ubyte[4] get_ubytes(uint x) {
    return *cast(ubyte[4]*)&x;
}

ubyte color_value(double x) {
    if (x == 0) return 0;

    //writeln("Color value of: ", x, " = ", x * 255);
    auto ret = cast(ubyte)(x * 255);
    //writeln("in ubyte: ", ret);
    return ret;
}

ubyte[] encode(Color[][] colors) {

    uint width = colors[0].length;
    uint height = colors.length;

    ubyte[] bmp = new ubyte[](0x36);
    bmp[0x00 .. 0x02] = [0x42, 0x4D]; //B M
    bmp[0x0a] = 0x36; //offset
    bmp[0x0e] = 0x28; // dib header size ???
    bmp[0x12 .. 0x16] = get_ubytes(width);    // image size
    bmp[0x16 .. 0x1a] = get_ubytes(height); // image size
    bmp[0x1a] = 0x01; // 1 plane
    bmp[0x1c] = 0x18; // 24 bits
    bmp[0x26 .. 0x2a] = get_ubytes(2835u); // pixels per meter, lol
    bmp[0x2a .. 0x2e] = get_ubytes(2835u); // pixels per meter, lol
    // 0x2e .. 0x36 is zeroes

    size_t row_length = width * 3;

    while (row_length % 4) {
        row_length += 1;
    }

    ubyte[] row_data = new ubyte[](row_length);

    foreach (row; retro(colors)) {
        size_t i = 0;
        foreach (c; row) {
            row_data[i++] = color_value(c.b);
            row_data[i++] = color_value(c.g);
            row_data[i++] = color_value(c.r);
        }
        bmp ~= row_data;
        row_data[] = 0;
    }

    bmp[0x02 .. 0x06] = get_ubytes(bmp.length); // total bmp size;
    bmp[0x22 .. 0x26] = get_ubytes(bmp.length - 0x36); // size of pixel array

    return bmp;
}




