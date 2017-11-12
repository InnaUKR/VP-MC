require 'csv'
class DataController < ApplicationController
  require 'PrimaryStatAnalysisCount/PrimaryStatAnalysisCount'
  @@data = []
  @@variation_range = []
  @@saved_variation_range = []
  @@anomaly = []

  before_action :set_datum, only: [:show, :edit, :update]
  # GET /data
  # GET /data.json

  def index
    if @@data != []
      @data = @@data
      @variation_range = @@variation_range
      PrimaryStatAnalysisCount.set_empirical_func(@@variation_range, @data.length)
      # session[:variation_range] = @variation_range
      #@classes = PrimaryStatAnalysisCount.create_classes(@variation_range, @data)
    end
  end

  def import
    @@data = []
    CSV.parse(params[:file].read) do |row|
      @@data << row[0].to_f
    end
    @@variation_range = PrimaryStatAnalysisCount.create_variation_range(@@data)
    redirect_to data_path, notice: 'Файл успішно завантажено'
  end

  def classes
    if @@data != []
      @data = @@data

      @class_numb = PrimaryStatAnalysisCount.count_classes_number(@data)
      @user_class_number = params[:user_class_number]
      p @user_class_number= @user_class_number.to_i
      if @user_class_number == 0
        @user_class_number = @class_numb
      end
      p @user_class_number

      @classes = PrimaryStatAnalysisCount.create_classes(@@variation_range,
                                                         @data, @user_class_number)
      PrimaryStatAnalysisCount.set_empirical_func(@classes, @data.length)
      @borders_arr = make_border_arr(@user_class_number, @classes)

      @relative_frequency_arr = make_rel_frequency_arr(@classes)
      @emp_func_arr = made_emp_func_arr
      @emp_func_class_arr = made_emp_func_class_arr(@classes)

    end
  end

  def make_border_arr(class_numb, classes)
    borders_arr = []
    (0...class_numb).each do |i|
      borders_arr << classes[i].a_border
    end
    borders_arr << @classes[@classes.length-1].b_border
  end

  def make_rel_frequency_arr(classes)
    relative_frequency_arr = []
    classes.each { |cl| relative_frequency_arr << cl.relative_frequency }
    relative_frequency_arr
  end

  def made_emp_func_arr
    arr = []
    @@variation_range.each do |x|
      arr << [x.value, x.empirical_func]
    end
    arr
  end

  def made_emp_func_class_arr(classes)
    arr = []
    classes.each do |cl|
      arr << [[cl.a_border, cl.empirical_func], [cl.b_border, cl.empirical_func]]
    end
    arr
  end

  def characteristics
    n = @@variation_range.length

    #Average
    sum = 0
    @@variation_range.each{|x| sum += (x.value * x.frequency)}
    @average_value = sum / n

    #Median
    @median = find_median

    #Dispersion
    sum = 0
    @@variation_range.each{ |x| sum += (((x.value - @average_value)**2 )*x.frequency)}
    @dispersion_shifted = (1.0 / n ) * sum
    @dispersion = (1.0 / (n - 1)) * sum

    #Medium-square
    @medium_square_shifted = Math.sqrt(@dispersion_shifted)
    @medium_square = Math.sqrt(@dispersion)

    #Pearson variation coefficient
    sum = 0
    @@variation_range.each{ |x| sum += (((x.value - @average_value)**2 )*x.frequency)}
    @pearson_coefficient = @medium_square / @average_value

    #Asymmetry coefficient
    sum = 0
    @@variation_range.each{ |x| sum += (((x.value - @average_value)**3 )*x.frequency)}
    @asymmetry_coefficient_shifted = (1.0 / (n *(@medium_square_shifted**3))) * sum
    @asymmetry_coefficient = Math.sqrt(n * (n - 1.0)) / (n - 2.0) * @asymmetry_coefficient_shifted

    #Coefficient of excess
    sum = 0
    @@variation_range.each{ |x| sum += (((x.value - @average_value)**4 )*x.frequency)}
    @excess_coefficient_shifted  = (1.0 / (n * (@medium_square_shifted**4))) * sum
    @excess_coefficient = (((n**2) - 1.0).to_f / ((n - 2.0)*(n - 3.0))) * ((@excess_coefficient_shifted - 3.0) * (6.0 / (n - 1.0)))

    #Contraccess coefficient
    @contraccess_coefficient = 1.0 / Math.sqrt(@excess_coefficient_shifted)

    #
    @average_value_ = @medium_square / Math.sqrt(n)
    @medium_square_ = @medium_square / Math.sqrt(2.0 * n)
    @pearson_coefficient_ = @pearson_coefficient * (Math.sqrt((1.0 + 2.0 * (@pearson_coefficient**2)) / (2.0 * n)))
    @asymmetry_coefficient_ = Math.sqrt((6.0 *(n - 2.0)) / ((n + 1.0) * (n + 3.0)))
    @excess_coefficient_ = Math.sqrt((24.0 / n) * (1.0 - (225.0 / (15.0 * n +124.0))))
    @contraccess_coefficient_ = Math.sqrt(@excess_coefficient.magnitude / (29.0 * n)) * ((@excess_coefficient**2 )- 1).abs**(3.0 / 4.0)

    #
    rozp_Studenta = find_rozp_Studenta
    @average_value_H = @average_value - rozp_Studenta * @average_value_
    @average_value_B = @average_value + rozp_Studenta * @average_value_

    @medium_square_H = @medium_square - rozp_Studenta * @medium_square_
    @medium_square_B = @medium_square + rozp_Studenta * @medium_square_

    @pearson_coefficient_H = @pearson_coefficient - rozp_Studenta * @pearson_coefficient_
    @pearson_coefficient_B = @pearson_coefficient + rozp_Studenta * @pearson_coefficient_

    @asymmetry_coefficient_H = @asymmetry_coefficient - rozp_Studenta * @asymmetry_coefficient_
    @asymmetry_coefficient_B = @asymmetry_coefficient + rozp_Studenta * @asymmetry_coefficient_

    @excess_coefficient_H = @excess_coefficient - rozp_Studenta * @excess_coefficient_
    @excess_coefficient_B = @excess_coefficient + rozp_Studenta * @excess_coefficient_

    @contraccess_coefficient_H = @contraccess_coefficient - rozp_Studenta * @contraccess_coefficient_
    @contraccess_coefficient_B = @contraccess_coefficient + rozp_Studenta * @contraccess_coefficient_

  #
    t1 = 2.0 + 0.2 * Math.log10(0.04 * n)
    t2 = (19.0 * (@excess_coefficient + 2)**(1.0/2.0) + 1)**(1.0/2.0)
    @a,@b = find_border(@asymmetry_coefficient, @average_value, t1, t2, @medium_square)
    @@anomaly = find_anomaly(@a ,@b)
    @anomaly = @@anomaly
  end

  def delete_anomaly(anomaly)
    @@saved_variation_range = @@variation_range
    anomaly.each do |x|
      @@variation_range.delete_at(@@variation_range.index(x))
    end
  end

  def find_border(a, x, t1, t2, s)
    a,b=0,0
    if (-0.2..0.2).include?(a)
      a = x - t1 * s
      b = x + t2 * s
    elsif a < -0.2
      a = x - t2 * s
      b = x + t1 * s
    elsif a < 0.2
      a = x - t1 * s
      b = x + t2 * s
    end
    return [a, b]
  end

  def find_anomaly(a, b)
    anomaly = []
    @@variation_range.each do |x|
      if (x.value<=a) || (x.value>=b)
        anomaly << x
      end
    end
    anomaly
  end

  def difference_in_degree(average, degree)
    sum = 0
    @@variation_range.each { |x| sum += ((x.value - average)**degree) * x.frequency}
    return sum
  end

  def find_median
    n = @@data.length
    @data = @@data.sort
    if (n % 2).zero?
        (@data[(n / 2) - 1] + @data[(n / 2)]) / 2.0
    else
        @data[(n / 2).to_i]
    end
  end

  def find_rozp_Studenta
    case @@data.length - 1
      when 24
        2.06
      when 69
        2.0
      else
        1.96
    end 
    


  end

  # GET /data/1
  # GET /data/1.json
  def show
  end

  # GET /data/new
  def new
    @datum = Datum.new
  end

  # GET /data/1/edit
  def edit
  end

  # POST /data
  # POST /data.json
  def create
    @datum = Datum.new(datum_params)

    respond_to do |format|
      if @datum.save
        format.html { redirect_to @datum, notice: 'Datum was successfully created.' }
        format.json { render :show, status: :created, location: @datum }
      else
        format.html { render :new }
        format.json { render json: @datum.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /data/1
  # PATCH/PUT /data/1.json
  def update
    respond_to do |format|
      if @datum.update(datum_params)
        format.html { redirect_to @datum, notice: 'Datum was successfully updated.' }
        format.json { render :show, status: :ok, location: @datum }
      else
        format.html { render :edit }
        format.json { render json: @datum.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /data/1
  # DELETE /data/1.json
  def destroy
    @@saved_variation_range = @@variation_range
    @@anomaly.each do |x|
      @@variation_range.delete_at(@@variation_range.index(x))
      end
    redirect_to data_path, notice: 'Аномалії успішно видалено'
  end

  helper_method :step_beck
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datum
      @datum = Datum.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def datum_params
      params.fetch(:datum, {})
    end
end
