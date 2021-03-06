module Splib
    LIBS = [:Array,
            :CodeReloader,
            :Constants,
            :Conversions,
            :Exec,
            :Float,
            :HumanIdealRandomIterator,
            :Monitor,
            :PriorityQueue,
            :Sleep,
            :UrlShorteners
           ]
    # args:: name of library to load
    # Loads the given library. Currently available:
    # :CodeReloader
    # :Constants
    # :Conversions
    # :Exec
    # :HumanIdealRandomIterator
    # :PriorityQueue
    # :UrlShorteners
    # :all
    def self.load(*args)
        if args.include?(:all)
            LIBS.each do |lib|
                require File.join(File.dirname(__FILE__), 'splib', lib.to_s)
            end
        else
            args.each do |lib|
                raise NameError.new("Unknown library name: #{lib}") unless LIBS.include?(lib)
                require File.join(File.dirname(__FILE__), 'splib', lib.to_s)
            end
        end
    end
end