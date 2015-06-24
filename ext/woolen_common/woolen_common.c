#include "ruby.h"
VALUE woolen_common_module_rb = 0;
VALUE my_logger_rb = 0;

#ifdef _WIN32
#include "win.h"
#endif

#ifdef __linux__
#include "linux.h"
#endif

void Init_woolen_common()
{
    woolen_common_module_rb = rb_define_module("WoolenCommon");
    my_logger_rb = rb_define_class_under(woolen_common_module_rb,"MyLogger",rb_cObject);
    #ifdef _WIN32
    setup_win_method();
    #endif
}