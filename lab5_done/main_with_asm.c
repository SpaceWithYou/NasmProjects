#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <time.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

unsigned char* read_img(char* filename, int width, int height, int n)
{
	unsigned char* data = stbi_load(filename, &width, &height, &n, 3);
	return data;
}

int	write_img(unsigned char* data, char* filename, int width, int height, int channel_num, int quality)
{
	return stbi_write_jpg(filename, width, height, channel_num, data, quality);
}

int main()
{
	char filename[256], o_filename[256];
	int x, y, n, quality = 0;
	double alpha = 0;
	clock_t start_time, end_time;
	extern void Rotate(unsigned char* data, int width, int height, unsigned char* output, double sin_a, double cos_a, double o_width, double o_height);
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
	int new_width = floor((fabs(cos(alpha)) * x + fabs(sin(alpha)) * y));
	int new_height = floor((fabs(cos(alpha)) * y + fabs(sin(alpha)) * x));
	unsigned char* output = (unsigned char*)malloc(sizeof(unsigned char) * (new_width * new_height * n));
	start_time = clock();
	Rotate(data, x, y, output, sin(alpha), cos(alpha), (double)new_width, (double)new_height);
	end_time = clock();
	double time_used = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
	printf("Print filename for output\n");
	scanf("%s", o_filename);
	write_img(output, o_filename, new_width, new_height, n, quality);
	stbi_image_free(data);
	free(output);
	printf("Done, time = %3.6f seconds\n", time_used);
	return 0;
}
