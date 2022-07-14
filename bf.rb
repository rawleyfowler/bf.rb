#!/usr/bin/ruby

# Brainfuck interpreter in Ruby by Rawley Fowler
# Licensed under the GNU General Public License v3.0
module BFInterpreter
  class Tape
    def initialize(n = 30000)
      @values = Array.new(n, 0)
      @ptr = 0
    end

    def set x
      check_val_and_throw
      values[ptr] = x
    end

    def get
      check_val_and_throw
      values[ptr]
    end

    def incr_ptr
      ptr += 1
      ptr = 255 if ptr > 255
    end

    def decr_ptr
      ptr -= 1
      ptr = 0 if ptr < 0
    end

    def incr_val
      values[ptr] += 1
    end

    def decr_val
      values[ptr] -= 1
    end

    def check_val_and_throw
      if ptr < 0 || ptr > values.count - 1
        raise StandardError "Attempting to index value outside tap of length: #{@values.count} with index #{ptr}"
      end
    end

    private
    attr_reader :values, :ptr
  end

  class Interpreter
    class << self
      def find_loop_endings str
        bracket_pairs = {}

        last_bracket = str.length

        t = 0
        i = 0
        while i < str.length do
          if str[i] == "["
            t += 1
            j = i+1
            while j < str.length
              if str[j] == "["
                t += 1
              elsif str[j] == "]"
                t -= 1
                if t == 0
                  bracket_pairs[i] = j
                  break
                end
              end
              j += 1
            end
          end
          i += 1 
        end
        bracket_pairs
      end
    end

    def initialize
      @tape = Tape.new
    end

    def interpret_string(str)
      s = str.gsub(/[^><+-\.,\[\]]/, '')
      
      in_loop = false
      loop_begin = -1
      loop_end = -1

      bracket_pairs = Interpreter.find_loop_endings s
      
      i = 0
      while i < s.length
        c = s[i]

        if c == "["
          if i == s.length - 1 || bracket_pairs[i] == nil
            puts "Invalid loop at position #{i}"
            exit 1
          end
          
          loop_begin = i + 1
          loop_end = bracket_pairs[i] - 1
          i = bracket_pairs[i] + 1
          in_loop = true

          while in_loop do
            self.interpret_string(s[loop_begin..loop_end])

            if tape.get == 0
              c = s[i]
              # Break out back to normal iteration
              in_loop = false
            end
          end
        end
      
        handle_char c
        i += 1
      end
    end
    
    def interpret_file(path)
      data = File.open(path).read
      interpret_string data
    end

    private
    attr_reader :tape
    
    def handle_char c
      case c
      when ">"
        @tape.incr_ptr
      when "<"
        @tape.decr_ptr
      when "+"
        @tape.incr_val
      when "-"
        @tape.decr_val
      when "."
        print @tape.get.chr
      when ","
        @tape.set(gets.ord)
      end
    end
    
  end
end

def usage
  puts "bf.rb BrainF**k compiler written in Ruby."
  puts "To run: './bf.rb [BF CODE]' or 'ruby bf.rb -f [FILE]'"
  puts ""
  puts "FLAGS:"
  puts "-f FILE\t\tProvide a given file to the interpreter."
  puts "-h \t\t\tShow this message."
  puts ""
  exit 1
end

if ARGV.count == 1 && ARGV[0] == "-h"
  usage
end

if ARGV.count < 1 || ARGV.count > 2
  usage
end

interpreter = BFInterpreter::Interpreter.new

if ARGV.count == 2 && ARGV[0] == "-f"
  interpreter.interpret_file ARGV[1]
end

if ARGV.count == 1
  interpreter.interpret_string ARGV[0]
end
