class ClassFromVariationRange
  attr_reader :a_border, :b_border, :frequency, :relative_frequency
  attr_accessor :empirical_func
  def initialize(a_border, b_border, variation_range, data_arr)
    @a_border = a_border
    @b_border = b_border
    @frequency = find_frequency(variation_range)
    @relative_frequency = (@frequency.to_f / data_arr.length)
    @empirical_func = nil
  end

  def find_frequency(variation_range)
    if b_border != variation_range[-1].value.to_f
      return count_frequency(variation_range)
    else
      return count_last_frequency(variation_range)
    end
  end


  def count_frequency(variation_range)
    count = 0
    variation_range.each do |x|
      if (a_border...b_border).include?(x.value.to_f)
        count += x.frequency
      end
    end
    count
  end

  def count_last_frequency(variation_range)
    count = 0
    variation_range.each do |x|
      if (a_border..b_border).include?(x.value.to_f)
        count += x.frequency
      end
    end
    count
  end

  def include_x?(x)
    (a_border...b_border).include?(x.value.to_f)
  end

  def include_last_x?(x)
    (a_border..b_border).include?(x.value.to_f)
  end
end