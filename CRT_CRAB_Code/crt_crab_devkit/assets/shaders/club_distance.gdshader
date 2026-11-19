shader_type sky;
#include "res://assets/shaders/club_haze.gdshaderinc"
void sky() { COLOR = club_haze(EYEDIR); }
