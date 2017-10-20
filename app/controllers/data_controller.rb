require 'csv'
class DataController < ApplicationController
  require 'PrimaryStatAnalysisCount/PrimaryStatAnalysisCount'
  @@data = []
  @@variation_range = []

  before_action :set_datum, only: [:show, :edit, :update, :destroy]
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

      @classes = PrimaryStatAnalysisCount.create_classes(@@variation_range,
                                                         @data, @class_numb)
      PrimaryStatAnalysisCount.set_empirical_func(@classes, @data.length)
      @borders_arr = make_border_arr(@class_numb, @classes)

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
    sum = 0
    n = @@variation_range.length
    @@variation_range.each { |x| sum += x.value }
    @average_value = sum / n
    #MSD - medium_square_deviation
    @average_value_MSD = Math.sqrt((1.0 / (n - 1.0)) *
                                       difference_in_degree(@average_value, 2))

    @mediana = find_mediana(n)
    
    a = (1.0 / (n * @average_value_MSD**3)) *
        difference_in_degree(@average_value, 3)
    @asymmetry_coef = Math.sqrt(n * (n - 1.0)) / (n - 2.0) * a
    
    e = 1.0 / (n * @average_value_MSD**4) *
        difference_in_degree(@average_value, 4)
    @excess_coef = ((n**2 - 1) / ((n - 2) * (n - 3))) * ((e - 3.0) + 6 / (n - 1))
    @counterexcess_coef = 1.0 / Math.sqrt(e.abs)
    @variation_coef = @average_value_MSD / @average_value
  end

  def difference_in_degree(average, degree)
    sum = 0
    @@variation_range.each { |x| sum += (x.value - average)**degree }
    return sum
  end

  def find_mediana(n)
    if (n % 2).zero?
        (@@variation_range[(n / 2) - 1].value + @@variation_range[(n / 2)].value) / 2.0
    else
        @@variation_range[(n / 2) - 1].value
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
    @datum.destroy
    respond_to do |format|
      format.html { redirect_to data_url, notice: 'Datum was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

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
