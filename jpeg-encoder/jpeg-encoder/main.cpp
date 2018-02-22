#if defined(_MSC_VER) && _MSC_VER >= 1400
#define _CRT_SECURE_NO_WARNINGS // suppress warnings about fopen()
#endif

#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <string>

extern std::string::size_type jo_write_jpg(const char  *data, int width, int height, int quality, char *output);

uint8_t default_image[] = {
#include "flower.inc"
};

bool convert_rgb_to_yuv(uint8_t *image, int width, int height, int comp, double* output)
{
    if (!image || !output || !width || !height || comp > 4 || comp < 1 || comp == 2)
    {
        return false;
    }
    auto* i = image;
    auto* o = output;
    for (auto y = 0; y != height; ++y)
    {
        for (auto x = 0; x != width; ++x)
        {
            auto r = *(i++);
            auto g = comp == 3 ? *(i++) : r;
            auto b = comp == 3 ? *(i++) : r;
            *(o++) =  0.29900 * r + 0.58700 * g + 0.11400 * b - 128;
            *(o++) = -0.16874 * r - 0.33126 * g + 0.50000 * b;
            *(o++) =  0.50000 * r - 0.41869 * g - 0.08131 * b;
        }
    }
    return true;
}

int main(int argc, char** argv)
{
    if (argc != 1 && argc != 7)
    {
        printf("%s <binary image file name> <jpeg output file name> <image width> <image height> <components> <jpeg quality>", argv[0]);
        exit(1);
    }
    const char *hex_image = argc == 7 ? argv[1] : nullptr;
    const char *filename  = argc == 7 ? argv[2] : "default.jpg";
    int width             = argc == 7 ? atoi(argv[3]) : 1024;
    int height            = argc == 7 ? atoi(argv[4]) : 768;
    int comp              = argc == 7 ? atoi(argv[5]) : 3;
    int quality           = argc == 7 ? atoi(argv[6]) : 90;
    printf("input file name %s, output file name %s, image width %d, height %d, components %d, jpeg quality %d\n", hex_image ? hex_image : "built-in", filename, width, height, comp, quality);
    std::FILE *fp = hex_image ? std::fopen(hex_image, "rb") : nullptr;
    if (fp == nullptr && hex_image)
    {
        printf("input file %s could not be opened.\n", hex_image);
        exit(1);
    }
    std::size_t filesize = 0;
    if (fp)
    {
        std::fseek(fp, 0, SEEK_END);
        filesize = std::ftell(fp);
        std::fseek(fp, 0, SEEK_SET);
    }
    uint8_t *buffer = fp ? new uint8_t[filesize] : default_image;
    if (fp)
    {
        std::fread(buffer, sizeof(uint8_t), filesize, fp);
    }
    double *yuv_image = new double [3 * width * height];
    bool result = convert_rgb_to_yuv(buffer, width, height, comp, yuv_image);

	char *yuv_char = new char[3 * width * height];
	for (int i = 0; i < 3 * width * height; i++)
	{
		//if (i%3 == 0)
			yuv_char[i] = (char)yuv_image[i];
		//else
		//	yuv_char[i] = 0;
	}
		
    if (result)
    {
        char* output = new char[width * height * 3];
        auto size = jo_write_jpg(yuv_char, width, height, quality, output);
        if (size > 0)
        {
            FILE *fp = fopen(filename, "wb");
            fwrite(output, size, 1, fp);
            fclose(fp);
        }
        else
        {
            result = false;
        }
        delete[] output;
    }
    delete[] yuv_image;
    if (fp)
    {
        delete[] buffer;
    }
    return result ? 0 : 1;
}
