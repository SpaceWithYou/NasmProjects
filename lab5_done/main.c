#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <time.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

int get_x(double alpha, int x, int y)
{
	return round((x * cos(alpha) - y * sin(alpha)));
}

int get_y(double alpha, int x, int y)
{
	return round((x * sin(alpha) + y * cos(alpha)));
}

//Get (i, j) pixel : unsigned char* pixelOffset = data + (i + x * j) * bytePerPixel;
//Rotate (x, y) get (x * cosa - y * sina, x * sina + y * cosa)
void Rotate(double alpha, unsigned char* data, unsigned char* output, int width, int height, int o_width, int o_height, int channel_num)
{
	unsigned bytePerPixel = channel_num;
	int add_x = 0; //correction term for x
	int add_y = 0; //correction term for y
	int cx = width / 2 - !(width & 1), cy = height / 2 - !(height & 1);
	if (!(o_width & 1) && cx >= o_width / 2) add_x = -1;
	if (!(o_height & 1) && cy >= o_height / 2) add_y = -1;
	for (int j = 0; j < height; j++)
		for (int i = 0; i < width; i++)
		{
			//move point to center of img
			int a = i - cx;
			int b = -j + cy;
			//rotate point
			int x = get_x(alpha, a, b);
			int y = get_y(alpha, a, b);
			//move to old center
			x += o_width / 2 + add_x;
			y = -y + o_height / 2 + add_y;
			if (x < 0 || y < 0 || x >= o_width || y >= o_height) continue;
			unsigned char* pixelOffset_original = data + (i + width * j) * bytePerPixel;
			output[(x + o_width * y) * channel_num] = pixelOffset_original[0];
			output[(x + o_width * y) * channel_num + 1] = pixelOffset_original[1];
			output[(x + o_width * y) * channel_num + 2] = pixelOffset_original[2];
			if (channel_num >= 4) output[(x + o_width * y) * channel_num + 3] = pixelOffset_original[3];
		}
}

unsigned char* read_img(char* filename, int width, int height, int n)
{
	unsigned char* data = stbi_load(filename, &width, &height, &n, 3);
	return data;
}

int write_img(unsigned char* data, char* filename, int width, int height, int channel_num, int quality)
{
	return stbi_write_jpg(filename, width, height, channel_num, data, quality);
}

int main()
{
	char filename[256], o_filename[256];
	int x, y, n, quality = 0;
	double alpha = 0;
	clock_t start_time, end_time;
	printf("Print filename, x, y, n, quality\n");
	scanf("%s", filename);
	scanf("%d", &x);
	scanf("%d", &y);
	scanf("%d", &n);
	scanf("%d", &quality);
	int ok = stbi_info(filename, &x, &y, &n);
	if (!ok)
	{
		printf("Incorrect file\n");
		exit(-1);
	}
	printf("Print angle\n");
	scanf("%lf", &alpha);
	unsigned char* data = read_img(filename, x, y, n);
	int new_width = floor(fabs(cos(alpha)) * x + fabs(sin(alpha)) * y);
	int new_height = floor(fabs(cos(alpha)) * y + fabs(sin(alpha)) * x);
	unsigned char* output = (unsigned char*)malloc(sizeof(unsigned char) * (new_width * new_height * n));
	start_time = clock();
	Rotate(alpha, data, output, x, y, new_width, new_height, n);
	end_time = clock();
	double time_used = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
	printf("Print filename for output\n");
	scanf("%s", o_filename);
	write_img(output, o_filename, new_width, new_height, n, quality);
	stbi_image_free(data);
	free(output);
	printf("Done, time = %3.6f seconds", time_used);
	return 0;
}
