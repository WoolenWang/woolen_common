#ifdef _WIN32
#include "ruby.h"
#include "win/puts_color.c"
#include "woolen_common.h"
static VALUE puts_color_rb(VALUE self, VALUE front, VALUE back, VALUE msg)
{
    char * front_c = StringValueCStr(front);
    char * back_c = StringValueCStr(back);
    char * msg_c = StringValueCStr(msg);
    puts_color(front_c,back_c,msg_c);
    return 0;
}

void setup_win_method()
{
    rb_define_method(my_logger_rb,"c_puts_color",puts_color_rb,3);
}
#endif
