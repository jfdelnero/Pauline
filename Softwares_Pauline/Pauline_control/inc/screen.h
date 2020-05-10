bitmap_data * load_screen(char * file);
void splash_screen(	bitmap_data * screen );
void printf_screen(unsigned char * buffer,int xpos, int ypos, char * string, ...);
void print_char_screen(unsigned char * buffer,int xpos, int ypos, unsigned char c);
void free_screen(bitmap_data * screen);

void display_bmp(char * file);
