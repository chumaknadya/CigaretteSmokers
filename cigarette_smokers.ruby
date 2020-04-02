#!/usr/bin/env ruby

require 'thread'

class CigaretteSmoker
  INGREDIENTS = ['TOBACCO', 'PAPER', 'MATCHES']
  ROUNDS_COUNTER = 3
  SLEEP_TIME = 3

  def initialize(rounds = ROUNDS_COUNTER)
    @rounds = rounds
    @semaphore = Mutex.new
    @cond_mutex = ConditionVariable.new
    @available_ingredients = Array.new(INGREDIENTS.count, false)
    @smoker_threads = Array.new
    initialize_threads
  end

  def initialize_threads
    @smoker_threads << Thread.new { Thread.current[:name]  = "with Tobacco"; smoker_routine(INGREDIENTS.index('PAPER'),
                                                                                            INGREDIENTS.index('MATCHES')) }
    @smoker_threads << Thread.new { Thread.current[:name]  = "with Paper"; smoker_routine(INGREDIENTS.index('TOBACCO'),
                                                                                          INGREDIENTS.index('MATCHES')) }
    @smoker_threads << Thread.new { Thread.current[:name]  = "with Matches"; smoker_routine(INGREDIENTS.index('TOBACCO'),
                                                                                            INGREDIENTS.index('PAPER')) }
    @agent_thread = Thread.new { agent_routine }
  end

  def agent_routine
    @rounds.times do
      @semaphore.synchronize {
        random_ingredients = generate_random_ingredients
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "Ingredients #{INGREDIENTS[random_ingredients[0]]} and #{INGREDIENTS[random_ingredients[1]]} on the table"

        @available_ingredients[random_ingredients[0]] = true
        @available_ingredients[random_ingredients[1]] = true

        @cond_mutex.broadcast
        @cond_mutex.wait(@semaphore)
      }
    end
  end

  def smoker_routine(needed_ingredient1, needed_ingredient2)
    current_name = Thread.current[:name]
    while true
      @semaphore.synchronize do
        until @available_ingredients[needed_ingredient1] && @available_ingredients[needed_ingredient2]
          @cond_mutex.wait(@semaphore)
        end

        break if @terminate
        @available_ingredients[needed_ingredient1] = false
        @available_ingredients[needed_ingredient2] = false

        puts "Smoker #{current_name} rolls cigarette"
        puts "Smoker #{current_name} started smoking"
        tabacco_smoking
        puts "Smoker #{current_name} ended smoking"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        @cond_mutex.signal
      end
    end
  end

  def tabacco_smoking
    puts 'Smoke! Smoke! Smoke!'
    sleep(SLEEP_TIME)
  end

  def wait_for_completion
    @agent_thread.join
    @semaphore.synchronize {
      @terminate = true
      @available_ingredients.fill(true)
      @cond_mutex.broadcast
    }
  end

  private

  def generate_random_ingredients
    item1 = rand(1..100) % INGREDIENTS.count
    item2 = rand(1..100) % INGREDIENTS.count
    item2 = (item2 + 1) % INGREDIENTS.count if item1 == item2
    return item1, item2
  end
end

smoker = CigaretteSmoker.new
smoker.wait_for_completion
