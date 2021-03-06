require_relative './station'
require_relative './journey'
require_relative './fare_calculator'
require_relative './journeylog'

class Oystercard
  attr_reader :balance
  attr_reader :current_journey
  attr_reader :journey_history

  DEFAULT_CAPACITY = 90
  MINIMUM_FAIR = 1

  ERROR_MESSAGES = {
    exceeded_limit: 'The amount you are trying to top_up is above limit = 90 GBR',
    minimum_fair: 'Minimum amount to start a journey is 1 GBR'
  }.freeze

  def initialize(balance = 0, journey_history = JourneyLog.new, current_journey = nil, fare_calculator = FareCalculator.new)
    @balance = balance
    @journey_history = journey_history
    @current_journey = current_journey
    @fare_calculator = fare_calculator
  end

  def top_up(amount)
    raise ERROR_MESSAGES[:exceeded_limit] if limit_reached?(amount)
    @balance += amount
    @balance
  end

  def touch_in(station)
    unless @current_journey.nil?
      amount = @fare_calculator.calculator(@current_journey)
      deduct(amount)
    end
    initialize_journey(station)
  end

  def touch_out(station)
    if @current_journey.nil?
      @current_journey = Journey.new
      amount = @fare_calculator.calculator(@current_journey)
      deduct(amount)
    else
      @current_journey.exit_station = station
      @journey_history.update_last_journey(@current_journey)
      amount = @fare_calculator.calculator(@current_journey)
      deduct(amount)
      @current_journey = nil
      in_journey?
    end
  end

  def in_journey?
    !@current_journey.nil?
  end

  private

  def initialize_journey(station)
    raise ERROR_MESSAGES[:minimum_fair] unless has_minimum?
    station.pass
    @current_journey = Journey.new
    @current_journey.entry_station = station
    @journey_history.add_journey(@current_journey)
    in_journey?
  end

  def limit_reached?(amount)
    @balance + amount > DEFAULT_CAPACITY
  end

  def has_minimum?
    @balance >= MINIMUM_FAIR
  end

  def deduct(amount)
    @balance -= amount
    @balance
  end
end
