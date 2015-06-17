# -*- encoding : utf-8 -*-
require 'drb'
module DRb
  class DRbObject
    undef :type rescue nil
  end
end
