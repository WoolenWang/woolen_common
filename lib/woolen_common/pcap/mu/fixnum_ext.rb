# -*- encoding : utf-8 -*-
if RUBY_VERSION == '1.8.6'
    class Fixnum
        def ord
            self
        end
    end
end
