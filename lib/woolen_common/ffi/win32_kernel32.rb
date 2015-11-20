# -*- encoding : utf-8 -*-
require 'ffi'
module WoolenCommon
    module Win32Kernel32
        STD_INPUT_HANDLE = 0xfffffff6
        STD_OUTPUT_HANDLE = 0xfffffff5
        STD_ERROR_HANDLE = 0xfffffff4
        
        extend FFI::Library
        ffi_lib 'kernel32'
        attach_function  :setConsoleTextAttribute,            # method name  (your choice)
            :SetConsoleTextAttribute,       # DLL function name (given)
            [ :uint, :uint], :int
        attach_function  :getStdHandle,            # method name  (your choice)
                         :GetStdHandle,       # DLL function name (given)
                         [ :uint], :uint
        # specify C param / return value types
    end
end