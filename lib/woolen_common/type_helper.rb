# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'logger')}"
module WoolenCommon
    class TypeHelper
        class << self
            include WoolenCommon::ToolLogger
            def to_signed(number, bits)
                mask = (1 << (bits - 1))
                (number & ~mask) - (number & mask)
            end

            def to_unsigned(number, bits)
                mask_high = (1 << (bits - 1))
                mask_low = 0
                (bits-1).times do |step_bit|
                    mask_low += (1 << (step_bit))
                end
                high = number & mask_high
                low = number & mask_low
                #debug "to unsigned #{high},#{low}"
                high + low
            end

            def get_high_bit_num(number,all_bits,high_start_bits)
                bits_mask = 0
                (high_start_bits..all_bits-1).each do |step_bit|
                    bits_mask += (1 << (step_bit))
                end
                number & bits_mask
            end


            def get_low_bit_num(number,hight_start_bits)
                bits_mask = 0
                (0..hight_start_bits-1).each do |step_bit|
                    bits_mask += (1 << (step_bit))
                end
                number & bits_mask
            end
        end
    end
end
