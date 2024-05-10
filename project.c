
///////////////////////////////////////////////////////////////////////////////
// Headers.

#include <stdint.h>
#include "system.h"
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>


#include "letter_sprites_rgb333.h"
#include "sans_sprites_rgb333.h"


#define TEXT_SPACE_WIDTH 3
#define TEXT_ROW_HEIGTH 9


///////////////////////////////////////////////////////////////////////////////
// HW stuff.

#define WAIT_UNITL_0(x) while(x != 0){}
#define WAIT_UNITL_1(x) while(x != 1){}

#define SCREEN_IDX1_W 640
#define SCREEN_IDX1_H 480
#define SCREEN_IDX4_W 320
#define SCREEN_IDX4_H 240
#define SCREEN_RGB333_W 160
#define SCREEN_RGB333_H 120

#define SCREEN_IDX4_W8 (SCREEN_IDX4_W/8)

#define gpu_p32 ((volatile uint32_t*)LPRS2_GPU_BASE)
#define palette_p32 ((volatile uint32_t*)(LPRS2_GPU_BASE+0x1000))
#define unpack_idx1_p32 ((volatile uint32_t*)(LPRS2_GPU_BASE+0x400000))
#define pack_idx1_p32 ((volatile uint32_t*)(LPRS2_GPU_BASE+0x600000))
#define unpack_idx4_p32 ((volatile uint32_t*)(LPRS2_GPU_BASE+0x800000))
#define pack_idx4_p32 ((volatile uint32_t*)(LPRS2_GPU_BASE+0xa00000))
#define unpack_rgb333_p32 ((volatile uint32_t*)(LPRS2_GPU_BASE+0xc00000))
#define joypad_p32 ((volatile uint32_t*)LPRS2_JOYPAD_BASE)

typedef struct {
	unsigned a      : 1;
	unsigned b      : 1;
	unsigned z      : 1;
	unsigned start  : 1; // s key
	unsigned up     : 1;
	unsigned down   : 1;
	unsigned left   : 1;
	unsigned right  : 1;
} bf_joypad;
#define joypad (*((volatile bf_joypad*)LPRS2_JOYPAD_BASE))

typedef struct {
	uint32_t m[SCREEN_IDX1_H][SCREEN_IDX1_W];
} bf_unpack_idx1;
#define unpack_idx1 (*((volatile bf_unpack_idx1*)unpack_idx1_p32))



///////////////////////////////////////////////////////////////////////////////
// Game config.

///////////////////////////////////////////////////////////////////////////////
// Game data structures.

typedef struct {
	uint8_t r;
	uint8_t g;
	uint8_t b;
} Color;

typedef struct {
	uint16_t x;
	uint16_t y;
} Vector2;

// rectange from two vectors
typedef struct {
	Vector2 pos;
	Vector2 size;
} Rect;

const char *letter_catalog[] = {
	"А", "Б", "В", "Г", "Д", "Ђ", "Е", "Ж", "З", "И", "Ј", "К", "Л", "Љ", "М", "Н", "Њ", "О", "П", "Р", "С", "Т", "Ћ", "У", "Ф", "Х", "Ц", "Ч", "Џ", "Ш",
};

const Vector2 letter_postions[] = {
	{0, 0}, {6, 0}, {12, 0}, {18, 0}, {23, 0}, {31, 0}, {38, 0}, {43, 0}, {52, 0}, {58, 0}, {64, 0}, {69, 0}, {75, 0}, {82, 0}, {92, 0}, {99, 0}, {105, 0}, {114, 0}, {120, 0}, {126, 0}, {132, 0}, {138, 0}, {144, 0}, {151, 0}, 
	{0, 9}, {8, 9}, {14, 9}, {21, 9}, {27, 9}, {34, 9}
};

const uint8_t letter_spacing[] = {
	6, 6, 6, 5, 8, 7, 5, 9, 6, 6, 5, 6, 7, 10, 7, 6, 9, 6, 6, 6, 6, 6, 7, 6, 8, 6, 7, 6, 7, 10
};


uint16_t quantitize_rgb333(uint8_t r, uint8_t g, uint8_t b) {
	uint16_t rgb333 = 0;

	rgb333 |= (r >> 5) & 0b111;
	rgb333 |= ((g >> 5) & 0b111) << 3;
	rgb333 |= ((b >> 5) & 0b111) << 6;

	return rgb333;
}

Color hsvToRGB(float h, float s, float v) {
	float r, g, b;

	int i = h * 6;
	float f = h * 6 - i;
	float p = v * (1 - s);
	float q = v * (1 - f * s);
	float t = v * (1 - (1 - f) * s);

	switch(i % 6){
		case 0: r = v, g = t, b = p; break;
		case 1: r = q, g = v, b = p; break;
		case 2: r = p, g = v, b = t; break;
		case 3: r = p, g = q, b = v; break;
		case 4: r = t, g = p, b = v; break;
		case 5: r = v, g = p, b = q; break;
	}

	return (Color){r*255, g*255, b*255};
}

void draw_pixel_rgb333(Vector2 pos, Color color) {
	unpack_rgb333_p32[pos.y*SCREEN_RGB333_W + pos.x] = quantitize_rgb333(color.r, color.g, color.b);
}

void draw_circle_rgb333(Vector2 pos, uint16_t r, Color color) {
	for (uint16_t angle = 0; angle < 360; angle += 1) {
		float x_ = pos.x + r * cos(angle * 3.141592 / 180);
		float y_ = pos.y + r * sin(angle * 3.141592 / 180);
		
		if (x_ < 0 || x_ >= SCREEN_RGB333_W || y_ < 0 || y_ >= SCREEN_RGB333_H) {
			continue;
		}
		draw_pixel_rgb333((Vector2){x_, y_}, color);
	}
}

void draw_rectange_rgb333(Rect rect, Color color) {
	for (uint16_t x = rect.pos.x; x < rect.pos.x + rect.size.x; x++) {
		draw_pixel_rgb333((Vector2){x, rect.pos.y}, color);
		draw_pixel_rgb333((Vector2){x, rect.pos.y + rect.size.y}, color);
	}
	for (uint16_t y = rect.pos.y; y < rect.pos.y + rect.size.y; y++) {
		draw_pixel_rgb333((Vector2){rect.pos.x, y}, color);
		draw_pixel_rgb333((Vector2){rect.pos.x + rect.size.x, y}, color);
	}
}

void fill_rect_rgb333(Vector2 pos1, Vector2 pos2, Color color) {
	for (uint16_t r = pos1.y; r < pos2.y; r++) {
		for (uint16_t c = pos1.x; c < pos2.x; c++) {
			if (c < 0 || c >= SCREEN_RGB333_W || r < 0 || r >= SCREEN_RGB333_H) {
				continue;
			}
			draw_pixel_rgb333((Vector2){c, r}, color);
		}
	}
}

void fill_circle_rgb333(Vector2 pos, uint16_t r, Color color) {
	for (uint16_t y = pos.y - r; y < pos.y + r; y++) {
		for (uint16_t x = pos.x - r; x < pos.x + r; x++) {
			if (x < 0 || x >= SCREEN_RGB333_W || y < 0 || y >= SCREEN_RGB333_H) {
				continue;
			}
			if (pow(x - pos.x, 2) + pow(y - pos.y , 2) < pow(r, 2)) {
				draw_pixel_rgb333((Vector2){x, y}, color);
			}
		}
	}
}

void display_all_color() {
	for (uint16_t y = 0; y < SCREEN_RGB333_H; y++) {
		for (uint16_t x = 0; x < SCREEN_RGB333_W; x++) {
			float saturation = (y/(float)SCREEN_RGB333_H) * 2;
			if (saturation > 1) {
				saturation = 1;
			}
			float value = ((SCREEN_RGB333_H-y)/(float)SCREEN_RGB333_H) * 2;
			if (value > 1) {
				value = 1;
			}
			draw_pixel_rgb333((Vector2){x, y}, hsvToRGB(x/(float)SCREEN_RGB333_W, saturation, value));
		}
	}
}

void fill_background(Color color) {
	fill_rect_rgb333((Vector2){0, 0}, (Vector2){SCREEN_RGB333_W, SCREEN_RGB333_H}, color);
}

uint8_t get_num_bytes(uint8_t *ptr) {
	uint8_t num_bytes = 1;
	if ((*ptr & 0xC0) == 0xC0) {
		if ((*ptr & 0xE0) == 0xC0) {
			num_bytes = 2;
		} else if ((*ptr & 0xF0) == 0xE0) {
			num_bytes = 3;
		} else if ((*ptr & 0xF8) == 0xF0) {
			num_bytes = 4;
		}
	}

	return num_bytes;
}

void print_UTF8(char *str) {
	uint8_t *ptr = (uint8_t *)str;

	while (*ptr != '\0') {
		uint8_t num_bytes = get_num_bytes(ptr);

		for (uint8_t i = 0; i < num_bytes; i++) {
			printf("%c", *ptr);
			ptr++;
		}
	}
}

void render_letter(uint8_t letter_index, Vector2 pos) {
	uint16_t letter_x = letter_postions[letter_index].x;
	uint16_t letter_y = letter_postions[letter_index].y;
	uint8_t letter_width = letter_spacing[letter_index];

	for (uint16_t i = 0; i < 9; ++i) {
		for (uint16_t j = 0; j < letter_width; ++j) {
			uint16_t rgb333 = letter_sprites__p[(letter_y + i)*letter_sprites__w + letter_x + j];
			if (rgb333 == 0xffff) {
				continue;
			}
			unpack_rgb333_p32[(pos.y + i)*SCREEN_RGB333_W + pos.x + j] = rgb333;
		}
	}
}

void render_character(char *character, Vector2 pos) {
	uint8_t *ptr = (uint8_t *)character;
	uint8_t num_bytes = get_num_bytes(ptr);

	char *character_str = (char *)malloc(num_bytes + 1);
	for (uint8_t i = 0; i < num_bytes; i++) {
		character_str[i] = *ptr;
		ptr++;
	}
	character_str[num_bytes] = '\0';

	uint8_t index = 0;
	for (uint8_t i = 0; i < 30; i++) {
		if (strcmp(character_str, letter_catalog[i]) == 0) {
			index = i;
			break;
		}
	}

	render_letter(index, pos);

	free(character_str);
}

uint8_t get_character_index(char *character) {
	for (uint8_t i = 0; i < 30; i++) {
		if (strcmp(character, letter_catalog[i]) == 0) {
			return i;
		}
	}

	return 0;
}

void render_text(char *text, Vector2 startPos) {
	uint8_t *ptr = (uint8_t *)text;
	Vector2 pos = startPos;

	while (*ptr != '\0') {
		if (*ptr == ' ') {
			pos.x += TEXT_SPACE_WIDTH;
			ptr++;
			continue;
		} else if (*ptr == '\n') {
			pos.x = startPos.x;
			pos.y += TEXT_ROW_HEIGTH + 1;
			ptr++;
			continue;
		}

		uint8_t num_bytes = get_num_bytes(ptr);

		char *character_str = (char *)malloc(num_bytes + 1);
		for (uint8_t i = 0; i < num_bytes; i++) {
			character_str[i] = *ptr;
			ptr++;
		}
		character_str[num_bytes] = '\0';

		uint8_t index = get_character_index(character_str);

		render_letter(index, pos);
		pos.x += letter_spacing[index] + 1;

		free(character_str);
	}
}

Rect get_text_bounding_box(char *text, Vector2 startPos) {
    uint8_t *ptr = (uint8_t *)text;
    Vector2 pos = startPos;
    Rect bounding_box = {startPos, {0, 0}};
	uint16_t max_x = 0;
    uint8_t last_char_index = 0;

    while (*ptr != '\0') {
        if (*ptr == ' ') {
            pos.x += TEXT_SPACE_WIDTH;
            ptr++;
            continue;
        } else if (*ptr == '\n') {
			if (pos.x > max_x) {
				max_x = pos.x;
			}
            pos.x = startPos.x;
            pos.y += TEXT_ROW_HEIGTH + 1;
            ptr++;
            continue;
        }

        uint8_t num_bytes = get_num_bytes(ptr);

        char *character_str = (char *)malloc(num_bytes + 1);
        for (uint8_t i = 0; i < num_bytes; i++) {
            character_str[i] = *ptr;
            ptr++;
        }
        character_str[num_bytes] = '\0';

        uint8_t index = get_character_index(character_str);

        pos.x += letter_spacing[index] + 1;
        last_char_index = index;

        free(character_str);
    }

    if (*(ptr - 1) != '\n') {
        pos.x += letter_spacing[last_char_index];
    }
	pos.y += TEXT_ROW_HEIGTH;

	if (pos.x > max_x) {
		max_x = pos.x;
	}

	pos.x = max_x - 1;

    bounding_box.size.x = pos.x - startPos.x - 1;
    bounding_box.size.y = pos.y - startPos.y - 1;

    return bounding_box;
}



///////////////////////////////////////////////////////////////////////////////
// Game code.

int main(void) {
	
	// Setup.
	gpu_p32[0] = 3; // RGB333 mode.
	gpu_p32[0x800] = 0x0000ff00; // Magenta for HUD.


	// Game state.

	Vector2 player = {SCREEN_RGB333_W/2, SCREEN_RGB333_H/2};
	Vector2 player_velocity = {0, 0};

	Vector2 text_pos = {0, 0};
	Vector2 text_velocity = {1, 1};

	uint16_t angle = 0;
	uint16_t animation_tick = 0;

	char text[] = "СУБОТИЋ ЈАШЕ ФОКУ";
	
	while(1){
		
		angle += 1;
		/////////////////////////////////////
		// Poll controls.

		if (joypad.up) {
			player_velocity.y = -1;
		} else if (joypad.down) {
			player_velocity.y = 1;
		} else {
			player_velocity.y = 0;
		}

		if (joypad.left) {
			player_velocity.x = -1;
		} else if (joypad.right) {
			player_velocity.x = 1;
		} else {
			player_velocity.x = 0;
		}

		if (player.x + (int16_t)player_velocity.x < 0 || player.x + (int16_t)player_velocity.x > SCREEN_RGB333_W - 23) {
			player_velocity.x = 0;
		}
		if (player.y + (int16_t)player_velocity.y < 0 || player.y + (int16_t)player_velocity.y > SCREEN_RGB333_H - 30) {
			player_velocity.y = 0;
		}
		player.x += player_velocity.x;
		player.y += player_velocity.y;

		Rect text_bounding_box = get_text_bounding_box(text, text_pos);

		if (text_pos.x + (int16_t)text_velocity.x < 0 || text_pos.x + (int16_t)text_velocity.x > SCREEN_RGB333_W - text_bounding_box.size.x) {
			text_velocity.x = -text_velocity.x;
		}
		if (text_pos.y + (int16_t)text_velocity.y < 0 || text_pos.y + (int16_t)text_velocity.y > SCREEN_RGB333_H - text_bounding_box.size.y) {
			text_velocity.y = -text_velocity.y;
		}
		text_pos.x += text_velocity.x;
		text_pos.y += text_velocity.y;

		text_bounding_box.pos = text_pos;
		
		
		/////////////////////////////////////
		// Gameplay.


		/////////////////////////////////////
		// Drawing.
		
		
		// Detecting rising edge of VSync.
		WAIT_UNITL_0(gpu_p32[2]);
		WAIT_UNITL_1(gpu_p32[2]);
		// Draw in buffer while it is in VSync.
		
		if (joypad.start) {
			fill_background((Color){0, 255, 0});
		} else {
			fill_background((Color){255, 255, 255});
		}

		for (uint16_t y = 0; y < SCREEN_RGB333_H; y++) {
			for (uint16_t x = 0; x < SCREEN_RGB333_W; x++) {
				uint16_t hue = (x + angle)%SCREEN_RGB333_W;
				float saturation = (y/(float)SCREEN_RGB333_H) * 2;
				if (saturation > 1) {
					saturation = 1;
				}
				float value = ((SCREEN_RGB333_H-y)/(float)SCREEN_RGB333_H) * 2;
				if (value > 1) {
					value = 1;
				}
				draw_pixel_rgb333((Vector2){x, y}, hsvToRGB(hue/(float)SCREEN_RGB333_W, saturation, value));
			}
		}
		
		draw_circle_rgb333((Vector2){text_bounding_box.pos.x + text_bounding_box.size.x/2, text_bounding_box.pos.y + text_bounding_box.size.y/2}, 50, (Color){0, 0, 0});

		draw_rectange_rgb333(text_bounding_box, (Color){0, 0, 0});
		render_text(text, text_pos);

		uint8_t sprite = 0;

		if (joypad.left) {
			sprite = 1;
			animation_tick++;
		} else if (joypad.right) {
			sprite = 2;
			animation_tick++;
		} else if (joypad.up) {
			sprite = 3;
			animation_tick++;
		} else if (joypad.down) {
			sprite = 0;
			animation_tick++;
		} else {
			animation_tick = 0;
		}

		sprite *= 30;

		uint8_t animation = 0;

		if (animation_tick/8 % 4 == 0) {
			animation = 0;
		} else if (animation_tick/8 % 4 == 1) {
			animation = 23;
		} else if (animation_tick/8 % 4 == 2) {
			animation = 0;
		} else if (animation_tick/8 % 4 == 3) {
			animation = 46;
		}

		for (uint16_t i = 0; i < 30; ++i) {
			for (uint16_t j = 0; j < 23; ++j) {
				uint16_t rgb333 = sans_sprites__p[(sprite + i)*letter_sprites__w + animation + j];
				if (rgb333 == 0xffff) {
					continue;
				}
				unpack_rgb333_p32[(player.y + i)*SCREEN_RGB333_W + player.x + j] = rgb333;
			}
		}
		
	}

	return 0;
}

///////////////////////////////////////////////////////////////////////////////
