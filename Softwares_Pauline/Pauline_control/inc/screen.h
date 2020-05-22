#define PRINTSCREEN_TRANSPARENT 0x00000001
#define PRINTSCREEN_BLACK_FG    0x00000002

bitmap_data * load_screen(char * file);
void splash_screen(bitmap_data * screen );
void printf_screen(int xpos, int ypos,unsigned int flags, char * string, ...);
void print_char_screen(unsigned char * buffer,int xpos, int ypos,unsigned int flags, unsigned char c);
void free_screen(bitmap_data * screen);

void display_bmp(char * file);

void screen_printtime(int x, int y, unsigned int flags);

