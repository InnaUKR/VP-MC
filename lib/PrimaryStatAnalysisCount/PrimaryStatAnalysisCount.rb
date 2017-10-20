module PrimaryStatAnalysisCount
  require 'PrimaryStatAnalysisCount/Variant'
  require 'PrimaryStatAnalysisCount/ClassFromVariationRange'
  def self.create_variation_range(data)
    data_arr = data.sort
    uniq_data = data_arr.uniq
    variation_range = []
    uniq_data.each { |ud| variation_range << Variant.new(ud, data_arr) }
    variation_range
  end

  def self.create_classes(variation_range, data_arr, class_number)
    #classes_number = count_classes_number(data_arr).round
    borders = count_classes_border(variation_range, class_number)
    classes_arr = []
    (1..class_number).each do |i|
      classes_arr << ClassFromVariationRange.new(borders[i - 1], borders[i], variation_range, data_arr)
    end
    classes_arr
  end

  def self.count_classes_number(data_arr)
    vr_leng = data_arr.length # N
    if vr_leng < 100
      if (vr_leng % 2).zero?
        return (Math.sqrt(vr_leng) - 1).round
      else
        return (Math.sqrt(vr_leng)).round
      end

    else
      if (vr_leng % 2).zero?
        return (vr_leng**(1.0 / 3.0) - 1).round
      else
        return (vr_leng**(1.0 / 3.0)).round
      end
    end
  end

  def self.count_classes_width(variation_range, classes_number)
    (variation_range.last.value.to_f - variation_range.first.value.to_f) / classes_number
  end

  def self.count_classes_border(variation_range, classes_number)
    width = count_classes_width(variation_range, classes_number)
    border_arr = []
    (1..(classes_number + 1)).each do |i|
      border_arr << variation_range[0].value.to_f + (i - 1) * width
    end
    border_arr
  end

  def self.set_empirical_func(collection, coll_group_number)
    sum = 0
    collection.each do |x|
      sum += x.frequency
      x.empirical_func = sum / coll_group_number.to_f
    end
  end

end