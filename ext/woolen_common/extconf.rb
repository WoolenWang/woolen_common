#!/usr/bin/env ruby

CC = RbConfig::CONFIG['CC']
if CC =~ /clang/
  RbConfig::MAKEFILE_CONFIG['try_header'] = :try_cpp
  RbConfig::CONFIG['CPP'] = "#{CC} -E"
elsif RbConfig::CONFIG['arch'] =~ /mswin32|mingw/
  RbConfig::MAKEFILE_CONFIG['try_header'] = :try_cpp
  RbConfig::CONFIG['CPP'] = "#{CC} /P"
end

require "mkmf"
extention_name = 'woolen_common'

if $warnflags
  $warnflags.slice!('-Wdeclaration-after-statement')
  $warnflags.slice!('-Wimplicit-function-declaration')
end

# Quick fix for 1.8.7
$CFLAGS << " -I#{File.dirname(__FILE__)}/ext/woolen_common"
$CPPFLAGS << " -I#{File.dirname(__FILE__)}/ext/woolen_common"

# Create Makefile
create_makefile('woolen_common')

