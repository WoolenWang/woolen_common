#include "ruby.h"
#include "win/puts_color.h"
static VALUE woolen_common_module_rb = 0;
static VALUE my_logger_rb = 0;

#ifdef 

static VALUE puts_color_rb(VALUE self, VALUE front, VALUE back, VALUE msg)
{
    char * front_c = StringValueCStr(front);
    char * back_c = StringValueCStr(back);
    char * msg_c = StringValueCStr(msg);
    puts_color(front_c,back_c,msg_c);
}

static void setup_win_method()
{
    rb_define_method(my_logger_rb,"c_puts_color",puts_color_rb,3);
}

void Init_woolen_common()
{
    woolen_common_module_rb = rb_define_module("WoolenCommon");
    my_logger_rb = rb_define_class_under(woolen_common_module_rb,"MyLogger",rb_cObject);
    setup_win_method();
}