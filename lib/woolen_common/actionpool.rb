require 'rubygems'
begin
    require 'fastthread'
rescue LoadError
    # we don't care if it's available
    # just load it if it's around
end
require "#{File.join(File.dirname(__FILE__), 'splib')}"
Splib.load :Array, :Monitor
require "#{File.join(File.dirname(__FILE__),'actionpool', 'pool')}"