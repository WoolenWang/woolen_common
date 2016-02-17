# -*- encoding : utf-8 -*-
require 'ffi'
module WoolenCommon
    module Win32Kernel32
        STD_INPUT_HANDLE = 0xfffffff6
        STD_OUTPUT_HANDLE = 0xfffffff5
        STD_ERROR_HANDLE = 0xfffffff4

        #磁盘需要用到的常量
        FILE_SHARE_READ = 0x00000000
        FILE_SHARE_WRITE = 0x00000002
        OPEN_EXISTING = 3
        IOCTL_DISK_PERFORMANCE = 458784
        wszDrive = "\\\\.\\PhysicalDrive0"

        class Filetime < FFI::Struct
            layout :dwLowDateTime, :uint,
                   :dwHighDateTime, :uint
        end

        class MemoryStatus < FFI::Struct
            layout :dwLength, :uint,
                   :dwMemoryLoad, :uint,
                   :dwTotalPhys, :uint,
                   :dwAvailPhys, :uint,
                   :dwTotalPageFile, :uint,
                   :dwAvailPageFile, :uint,
                   :dwTotalVirtual, :uint,
                   :dwAvailVirtual, :uint
        end

        class Disk_Perfomance < FFI::Struct
            layout :BytesRead, :int64,
                   :BytesWritten, :int64,
                   :ReadTime, :int64,
                   :WriteTime, :int64,
                   :IdleTime, :int64,
                   :ReadCount, :uint,
                   :WriteCount, :uint,
                   :QueueDepth, :uint,
                   :SplitCount, :uint,
                   :QueryTime, :int64,
                   :StorageDeviceNumber, :uint,
                   :StorageManagerName, [:ushort, 8]
        end


        extend FFI::Library
        ffi_lib 'kernel32'

        # 设置输出格式
        attach_function :setConsoleTextAttribute, # method name  (your choice)
                        :SetConsoleTextAttribute, # DLL function name (given)
                        [:uint, :uint], :int
        # 获取标准输出的Handle
        attach_function :getStdHandle, # method name  (your choice)
                        :GetStdHandle, # DLL function name (given)
                        [:uint], :uint # specify C param / return value types
        # 获取标准输出的Handle
        attach_function :getSystemTimes, # method name  (your choice)
                        :GetSystemTimes, # DLL function name (given)
                        [:pointer, :pointer, :pointer], :int # specify C param / return value types
        # 查询内存状态API
        attach_function :globalMemoryStatus, # method name  (your choice)
                        :GlobalMemoryStatus, # DLL function name (given)
                        [:pointer], :void # specify C param / return value types
        #创建物理磁盘文件
        attach_function :createFileA, # method name  (your choice)
                        :CreateFileA, # DLL function name (given)
                        [:pointer, :uint, :uint, :int, :uint, :uint, :int], :pointer # specify C param / return value types
        #获取磁盘数据API
        attach_function :deviceIoControl, # method name  (your choice)
                        :DeviceIoControl, # DLL function name (given)
                        [:pointer, :uint, :int, :uint, :pointer, :uint, :pointer, :int], :int # specify C param / return value types
        ffi_lib 'iphlpapi'
        #获取网络数据API
        attach_function :getIfTable, # method name  (your choice)
                        :GetIfTable, # DLL function name (given)
                        [:pointer, :pointer, :int], :uint # specify C param / return value types
        attach_function :getAdaptersAddresses, # method name  (your choice)
                        :GetAdaptersAddresses, # DLL function name (given)
                        [:uint, :uint, :int, :pointer, :pointer], :uint # specify C param / return value types


    end
end