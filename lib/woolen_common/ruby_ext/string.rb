# -*- encoding : utf-8 -*-
require 'iconv' if RUBY_VERSION.to_f < 1.9
class String # :nodoc: all

    if defined?(Encoding) && ''.respond_to?(:encode)
        def encoding_aware?
            true
        end
    else
        def encoding_aware?
            false
        end
    end

    #判断是否为utf8
    def utf8?
        if String.method_defined?(:encode)
            return true if self.force_encoding("UTF-8").valid_encoding?
            return false
        else
            unpack('U*') rescue return false
            return true
        end
    end

    #TODO：参数功能目前没有用
    def to_utf8(enc='GBK')
        if self.respond_to?(:encode)
            return self if utf8?
            self.encode('UTF-8', enc)
        else
            require 'iconv' if RUBY_VERSION.to_f < 1.9
            return self if utf8?
            begin
                Iconv.iconv('UTF-8', enc, self).at(0).to_s
            rescue
                self
            end
        end
    end

    #TODO：参数功能目前没有用
    def to_gbk(enc='UTF-8')
        if self.respond_to?(:encode)
            return self unless utf8?
            self.encode('GBK', enc)
        else
            return self unless utf8?
            require 'iconv' if RUBY_VERSION.to_f < 1.9
            begin
                Iconv.iconv('GBK', enc, self).at(0).to_s
            rescue
                self
            end
        end
    end

    def to_gb2312(enc = 'UTF-8')
        # require 'iconv'
        # Iconv.iconv('GB2312','UTF-8',self).at(0).to_s
        if self.respond_to?(:encode)
            self.encode('GB2312', enc)
        else
            begin
                self.unpack("U*")
                require 'iconv' if RUBY_VERSION.to_f < 1.9
                Iconv.iconv('GB2312', enc, self).at(0).to_s
            rescue ::ArgumentError
                self
            end
        end
    end

    def to_arr()
        self.split('&') #暂时未考虑&在\之后的问题,fix this bug
    end

    def __camelize(first_letter_in_uppercase=true)
        if first_letter_in_uppercase
            self.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
        else
            self.to_s[0].chr.downcase + camelize(self)[1..-1]
        end
    end

    alias camelize __camelize

    def __underscore
        word = self.to_s.dup
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
    end

    alias underscore __underscore

end

class << nil
    def to_utf8
        ''
    end
end


if $0 == __FILE__
    #  require 'string'
    puts "中文123中文".to_gbk.dump
    puts "中文123中文".to_gb2312.dump
    puts File.join("中文abc/abc", "中文").to_gbk.dump
    puts File.join("中文abc/abc", "中文").to_gb2312.dump
    puts 'ab_c'.camelize
end
