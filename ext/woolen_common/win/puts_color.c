#include <windows.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#define BACK 0
#define FORE 1
#define COLOR_COUNT 9

//支持的颜色选项 
char g_colors_name[17][20] =
{
    "default",	"black",		"navy",			"green",
    "teal",		"maroon",		"purple",		"olive",
    "silver",	"gray",			"blue",			"lime",
    "aqua",		"red",			"fuchsia",		"yellow",
    "white"
};
//颜色排列的系统值组合 
int g_front_colors_id[COLOR_COUNT] =
{
    -1,0,
    FOREGROUND_BLUE , FOREGROUND_GREEN ,FOREGROUND_BLUE | FOREGROUND_GREEN,
    FOREGROUND_RED,	FOREGROUND_BLUE | FOREGROUND_RED,FOREGROUND_RED | FOREGROUND_GREEN,
    FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED
};

int g_back_colors_id[COLOR_COUNT] =
{
    -1,0,
    BACKGROUND_BLUE , BACKGROUND_GREEN ,BACKGROUND_BLUE | BACKGROUND_GREEN,
    BACKGROUND_RED,	BACKGROUND_BLUE | BACKGROUND_RED,BACKGROUND_RED | BACKGROUND_GREEN,
    BACKGROUND_BLUE | BACKGROUND_GREEN | BACKGROUND_RED
};
// 根据side确定是取背景还是字体的颜色
// color是一个字符串,定位颜色 
int get_one_color_mod(const char * color,int side)
{
    int count = 0;
    for(count =0; count<17; count++)
    {
        if(stricmp(color,g_colors_name[count]) == 0)
        {
            if(count >= COLOR_COUNT)
            {
                int result_count = count +1 ;
                if (side == BACK)
                {
                    return g_back_colors_id[result_count % COLOR_COUNT] | BACKGROUND_INTENSITY;
                }
                else
                {
                    return g_front_colors_id[result_count % COLOR_COUNT] | FOREGROUND_INTENSITY;
                }
            }
            else
            {
                if (side == BACK)
                {
                    return g_back_colors_id[count % COLOR_COUNT]  ;
                }
                else
                {
                    return g_front_colors_id[count % COLOR_COUNT] ;
                }
            }
        }
    }
    int num =  atoi(color);
    if(num >= COLOR_COUNT)
    {
        int result_count = num +1 ;
        if (side == BACK)
        {
            return g_back_colors_id[result_count % COLOR_COUNT] | BACKGROUND_INTENSITY ;
        }
        else
        {
            return g_front_colors_id[result_count % COLOR_COUNT] | FOREGROUND_INTENSITY;
        }
    }
    else
    {
        if (side == BACK)
        {
            return g_back_colors_id[num % COLOR_COUNT] ;
        }
        else
        {
            return g_front_colors_id[num % COLOR_COUNT] ;
        }
    }
}

int get_color_mod(const char * front_color, const char * back_color)
{
    assert(front_color != NULL);
    assert(back_color != NULL);
    assert(strlen(front_color) != 0);
    assert(strlen(back_color) != 0);
    //cout << front_color << endl;
    //cout << back_color << endl;
    int front_color_mod = 0;
    int back_color_mod = 0;
    // 根据不同字符串,去获取颜色值,其中字体值和背景值根据第二个参数确定的 
    front_color_mod = get_one_color_mod(front_color,FORE);
    back_color_mod = get_one_color_mod(back_color,BACK);
    if(front_color_mod == -1)
    {
        return back_color_mod;
    }
    if(back_color_mod == -1)
    {
        return front_color_mod;
    }
    return back_color_mod | front_color_mod;
}
//重置颜色值,这里还原环境,假设默认环境是白字黑底的 
void reset_color()
{
	HANDLE hOut = NULL;
	hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	int mod_mask = 0x00ff,color_mod = 0;
    color_mod = get_color_mod("silver","black");
    SetConsoleTextAttribute(hOut,mod_mask & color_mod);
    //printf("");
}
int puts_color(const char * front, const char * back, const char * msg)
{
    HANDLE hOut;
    int mod_mask = 0x00ff;  
    int color_mod = 0;
    color_mod = get_color_mod(front,back);
    hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    SetConsoleTextAttribute(hOut,mod_mask & color_mod);
    printf(msg);
    reset_color();
    return 0;
}