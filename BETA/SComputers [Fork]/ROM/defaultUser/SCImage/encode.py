image = {}

width = False
height = False
with open("img.bmp", "rb") as bmp_file:
        bmp_header = bmp_file.read(54)

        width = bmp_header[18] + (bmp_header[19] << 8) + (bmp_header[20] << 16) + (bmp_header[21] << 24)
        height = bmp_header[22] + (bmp_header[23] << 8) + (bmp_header[24] << 16) + (bmp_header[25] << 24)
        bpp = bmp_header[28] + (bmp_header[29] << 8)

        has_alpha = False
        if bpp == 32:
            bmp_file.seek(54 + (4 * 24))
            has_alpha = True
        else:
            bmp_file.seek(54)
        

        # -------------

        if width > 256 or height > 256:
            print("the resolution should not exceed 256 by 256")
            exit()
       
        for y in range(height):
            for x in range(width):
                blue = int.from_bytes(bmp_file.read(1), byteorder='little')
                green = int.from_bytes(bmp_file.read(1), byteorder='little')
                red = int.from_bytes(bmp_file.read(1), byteorder='little')
                if has_alpha:
                    alpha = int.from_bytes(bmp_file.read(1), byteorder='little')
                else:
                    alpha = 255

                # print((x, (height - 1) - y))
                image[(x, (height - 1) - y)] = [red, green, blue, alpha]


with open("img.scimg", "wb") as out_file:
    out_file.write(bytes([width - 1]))
    out_file.write(bytes([height - 1]))

    for y in range(height):
        for x in range(width):
            color = image[(x, y)]

            for i in range(4):
                out_file.write(bytes([color[i]]))