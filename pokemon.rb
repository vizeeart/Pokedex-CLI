#!/usr/bin/env ruby
# encoding: UTF-8

__author__ = "vizee art"

require 'json'
require 'net/http'

class Pokedex
  BASE_URL = 'https://pokeapi.co/api/v2/'
  LAST_POKEMON_FILE = 'last_pokemon.json'
  LANGUAGE_FILE = 'language.json'

  def initialize
    @pokemon_list = []
    @data_cache = {}
    @total_pokedex = 0
    @language = 'en'
    load_language
    load_last_pokemon
  end

  def start
    puts language_text('welcome_message')
    fetch_total_pokedex

    loop do
      puts "\n#{language_text('menu_title')}:"
      puts "1. #{language_text('menu_search_by_name')}"
      puts "2. #{language_text('menu_search_by_number')}"
      puts "3. #{language_text('menu_last_pokemon')}"
      puts "4. #{language_text('menu_pokemon_vs_pokemon')}"
      puts "5. #{language_text('menu_change_language')}"
      puts "6. #{language_text('menu_exit')}"

      print "#{language_text('menu_choice')}: "
      choice = gets.chomp.to_i

      case choice
      when 1
        search_pokemon_by_name
      when 2
        search_pokemon_by_number
      when 3
        show_last_pokemon
      when 4
        pokemon_vs_pokemon
      when 5
        change_language
      when 6
        puts language_text('saving_data_message')
        save_last_pokemon_to_file unless @pokemon_list.empty?
        save_language
        puts language_text('exit_message')
        break
      else
        puts language_text('invalid_choice_message')
      end
    end
  end

  private

  def fetch_total_pokedex
    uri = URI("#{BASE_URL}pokemon")
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    @total_pokedex = data['count']
  end

  def search_pokemon_by_name
    print "#{language_text('search_by_name_message')}: "
    input_name = gets.chomp.downcase

    pokemon_data = get_pokemon_data(input_name)
    if pokemon_data
      display_pokemon_info(pokemon_data)
    else
      puts language_text('pokemon_not_found_message', name: input_name.capitalize)
    end
  end

  def search_pokemon_by_number
    print "#{language_text('search_by_number_message', count: @total_pokedex)}: "
    pokemon_number = gets.chomp.to_i

    if pokemon_number.between?(1, @total_pokedex)
      pokemon_data = get_pokemon_data(pokemon_number)
      display_pokemon_info(pokemon_data) if pokemon_data
    else
      puts language_text('invalid_number_message')
    end
  end

  def show_last_pokemon
    if @pokemon_list.empty?
      puts language_text('no_data_message')
    else
      puts "#{language_text('last_pokemon_message')}:"
      display_pokemon_info(@pokemon_list.last)
    end
  end

  def save_last_pokemon_to_file
    last_pokemon = @pokemon_list.last
    File.open(LAST_POKEMON_FILE, 'w') { |file| file.write(last_pokemon.to_json) }
    puts language_text('last_pokemon_saved_message', filename: LAST_POKEMON_FILE)
  end
  
  def get_pokemon_data(identifier)
    return @data_cache[identifier] if @data_cache[identifier]

    uri = URI("#{BASE_URL}pokemon/#{identifier}")
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    @data_cache[identifier] = data
  end

  def display_pokemon_info(pokemon_data)
    puts "\n#{language_text('name')}: #{pokemon_data['name'].capitalize}"
    puts "#{language_text('id')}: #{pokemon_data['id']}"
    puts "#{language_text('height')}: #{pokemon_data['height']}"
    puts "#{language_text('weight')}: #{pokemon_data['weight']}"
    puts "#{language_text('type')}: #{pokemon_data['types'].map { |type| type['type']['name'].capitalize }.join(', ')}"
    puts "#{language_text('statistics')}:"
    pokemon_data['stats'].each do |stat|
      stat_name = stat['stat']['name'].capitalize
      base_stat = stat['base_stat']
      puts " - #{stat_name}: #{base_stat}"
    end

    @pokemon_list << pokemon_data
  end

  def load_last_pokemon
    if File.exist?(LAST_POKEMON_FILE)
      data = JSON.parse(File.read(LAST_POKEMON_FILE))
      @pokemon_list << data if data.is_a?(Hash)
    end
  end

  def save_last_pokemon_to_file
    last_pokemon = @pokemon_list.last
    File.open(LAST_POKEMON_FILE, 'w') { |file| file.write(last_pokemon.to_json) }
    puts language_text('last_pokemon_saved_message', filename: LAST_POKEMON_FILE)
  end

  def pokemon_vs_pokemon
    puts "#{language_text('pokemon_vs_pokemon_message')}:"

    puts "#{language_text('pokemon1_message')}:"
    first_pokemon_input = gets.chomp.downcase
    first_pokemon_data = get_pokemon_data(first_pokemon_input)

    unless first_pokemon_data
      puts language_text('pokemon_not_found_message', name: first_pokemon_input.capitalize)
      return
    end

    puts "#{language_text('pokemon2_message')}:"
    second_pokemon_input = gets.chomp.downcase
    second_pokemon_data = get_pokemon_data(second_pokemon_input)

    unless second_pokemon_data
      puts language_text('pokemon_not_found_message', name: second_pokemon_input.capitalize)
      return
    end

    puts "\n#{language_text('comparison_message')}:"
    compare_pokemon_stats(first_pokemon_data, second_pokemon_data)
  end

  def compare_pokemon_stats(pokemon1, pokemon2)
    stats1 = pokemon1['stats'].sum { |stat| stat['base_stat'] }
    stats2 = pokemon2['stats'].sum { |stat| stat['base_stat'] }

    puts "#{language_text('pokemon_name_stats', name: pokemon1['name'].capitalize, stats: stats1)}"
    puts "#{language_text('pokemon_name_stats', name: pokemon2['name'].capitalize, stats: stats2)}"

    if stats1 > stats2
      puts language_text('pokemon1_win_message', name: pokemon1['name'].capitalize)
    elsif stats1 < stats2
      puts language_text('pokemon2_win_message', name: pokemon2['name'].capitalize)
    else
      puts language_text('draw_message')
    end
  end

  def load_language
    if File.exist?(LANGUAGE_FILE)
      language_data = JSON.parse(File.read(LANGUAGE_FILE))
      @language = language_data['language']
    else
      set_default_language
    end
  end

  def save_language
    language_data = { 'language' => @language }
    File.open(LANGUAGE_FILE, 'w') { |file| file.write(language_data.to_json) }
    puts language_text('language_saved_message', language: language_text('language_name'))
  end

  def set_default_language
    puts "Pilih bahasa (Choose language):"
    puts "1. English"
    puts "2. Indonesia"
    print "Your choice: "
    language_choice = gets.chomp.to_i

    case language_choice
    when 1
      @language = 'en'
    when 2
      @language = 'id'
    else
      puts "Invalid choice. Default language set to English."
      @language = 'en'
    end
  end

  def change_language
    puts "Change Language:"
    puts "1. English"
    puts "2. Indonesia"
    print "Your choice: "
    language_choice = gets.chomp.to_i

    case language_choice
    when 1
      @language = 'en'
      puts language_text('language_changed_message', language: language_text('language_name'))
    when 2
      @language = 'id'
      puts language_text('language_changed_message', language: language_text('language_name'))
    else
      puts "Invalid choice. Language remains unchanged."
    end
  end

  def language_text(key, options = {})
    language_data = JSON.parse(File.read("lang/#{@language}.json"))
    text = language_data[key]
    options.each { |key, value| text.gsub!("{#{key}}", value.to_s) }  # Konversi value ke String
    text
  end
end

# Inisialisasi dan jalankan Pokedex CLI
pokedex = Pokedex.new
pokedex.start
