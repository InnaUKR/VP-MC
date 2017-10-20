class Variant
  attr_reader :value, :frequency, :relative_frequency
  attr_accessor :empirical_func
  def initialize(value, data_arr)
    @value = value
    @frequency = data_arr.count(@value)
    @relative_frequency = (@frequency.to_f / data_arr.length)
    @empirical_func = nil
  end

end