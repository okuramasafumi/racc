#
# DO NOT MODIFY!!!!
# This file was automatically generated by Racc 2.0.0.dev
# (codename: Mecha Oishii) from Racc grammar file "machete.y".
#

require 'racc/parser.rb'
module Machete
  class Parser < Racc::Parser

module_eval(<<'...end machete.y/module_eval...', 'machete.y', 175)

include Matchers

class SyntaxError < StandardError; end

def parse(input)
  @input = input
  @pos = 0

  do_parse
end

private

def integer_value(value)
  if value =~ /^0[bB]/
    value[2..-1].to_i(2)
  elsif value =~ /^0[oO]/
    value[2..-1].to_i(8)
  elsif value =~ /^0[dD]/
    value[2..-1].to_i(10)
  elsif value =~ /^0[xX]/
    value[2..-1].to_i(16)
  elsif value =~ /^0/
    value.to_i(8)
  else
    value.to_i
  end
end

def symbol_value(value)
  value[1..-1].to_sym
end

def string_value(value)
  quote = value[0..0]
  if quote == "'"
    value[1..-2].gsub("\\\\", "\\").gsub("\\'", "'")
  elsif quote == '"'
    value[1..-2].
      gsub("\\\\", "\\").
      gsub('\\"', '"').
      gsub("\\n", "\n").
      gsub("\\t", "\t").
      gsub("\\r", "\r").
      gsub("\\f", "\f").
      gsub("\\v", "\v").
      gsub("\\a", "\a").
      gsub("\\e", "\e").
      gsub("\\b", "\b").
      gsub("\\s", "\s").
      gsub(/\\([0-7]{1,3})/) { $1.to_i(8).chr }.
      gsub(/\\x([0-9a-fA-F]{1,2})/) { $1.to_i(16).chr }
  else
    raise "Unknown quote: #{quote.inspect}."
  end
end

REGEXP_OPTIONS = {
  'i' => Regexp::IGNORECASE,
  'm' => Regexp::MULTILINE,
  'x' => Regexp::EXTENDED
}

def regexp_value(value)
  /\A\/(.*)\/([imx]*)\z/ =~ value
  pattern, options = $1, $2

  Regexp.new(pattern, options.chars.map { |ch| REGEXP_OPTIONS[ch] }.inject(:|))
end

# "^" needs to be here because if it were among operators recognized by
# METHOD_NAME, "^=" would be recognized as two tokens.
SIMPLE_TOKENS = [
  "|",
  "<",
  ">",
  ",",
  "=",
  "^=",
  "^",
  "$=",
  "[",
  "]",
  "*=",
  "*",
  "+",
  "?",
  "{",
  "}"
]

COMPLEX_TOKENS = [
  [:NIL,   /^nil/],
  [:TRUE,  /^true/],
  [:FALSE, /^false/],
  # INTEGER needs to be before METHOD_NAME, otherwise e.g. "+1" would be
  # recognized as two tokens.
  [
    :INTEGER,
    /^
      [+-]?                               # sign
      (
        0[bB][01]+(_[01]+)*               # binary (prefixed)
        |
        0[oO][0-7]+(_[0-7]+)*             # octal (prefixed)
        |
        0[dD]\d+(_\d+)*                   # decimal (prefixed)
        |
        0[xX][0-9a-fA-F]+(_[0-9a-fA-F]+)* # hexadecimal (prefixed)
        |
        0[0-7]*(_[0-7]+)*                 # octal (unprefixed)
        |
        [1-9]\d*(_\d+)*                   # decimal (unprefixed)
      )
    /x
  ],
  [
    :SYMBOL,
    /^
      :
      (
        # class name
        [A-Z][a-zA-Z0-9_]*
        |
        # regular method name
        [a-z_][a-zA-Z0-9_]*[?!=]?
        |
        # instance variable name
        @[a-zA-Z_][a-zA-Z0-9_]*
        |
        # class variable name
        @@[a-zA-Z_][a-zA-Z0-9_]*
        |
        # operator (sorted by length, then alphabetically)
        (<=>|===|\[\]=|\*\*|\+@|-@|<<|<=|==|=~|>=|>>|\[\]|[%&*+\-\/<>^`|~])
      )
    /x
  ],
  [
    :STRING,
    /^
      (
        '                 # sinqle-quoted string
          (
            \\[\\']           # escape
            |
            [^']              # regular character
          )*
        '
        |
        "                 # double-quoted string
          (
            \\                # escape
            (
              [\\"ntrfvaebs]    # one-character escape
              |
              [0-7]{1,3}        # octal number escape
              |
              x[0-9a-fA-F]{1,2} # hexadecimal number escape
            )
            |
            [^"]              # regular character
          )*
        "
      )
    /x
  ],
  [
    :REGEXP,
    /^
      \/
        (
          \\                                          # escape
          (
            [\\\/ntrfvaebs\(\)\[\]\{\}\-\.\?\*\+\|\^\$] # one-character escape
            |
            [0-7]{2,3}                                  # octal number escape
            |
            x[0-9a-fA-F]{1,2}                           # hexadecimal number escape
          )
          |
          [^\/]                                       # regular character
        )*
      \/
      [imx]*
    /x
  ],
  # ANY, EVEN and ODD need to be before METHOD_NAME, otherwise they would be
  # recognized as method names.
  [:ANY,  /^any/],
  [:EVEN, /^even/],
  [:ODD,  /^odd/],
  # We exclude "*", "+", "<", ">", "^" and "|" from method names since they are
  # lexed as simple tokens. This is because they have also other meanings in
  # Machette patterns beside Ruby method names.
  [
    :METHOD_NAME,
    /^
      (
        # regular name
        [a-z_][a-zA-Z0-9_]*[?!=]?
        |
        # operator (sorted by length, then alphabetically)
        (<=>|===|\[\]=|\*\*|\+@|-@|<<|<=|==|=~|>=|>>|\[\]|[%&\-\/`~])
      )
    /x
  ],
  [:CLASS_NAME, /^[A-Z][a-zA-Z0-9_]*/]
]

def next_token
  skip_whitespace

  return false if remaining_input.empty?

  # Complex tokens need to be before simple tokens, otherwise e.g. "<<" would be
  # recognized as two tokens.

  COMPLEX_TOKENS.each do |type, regexp|
    if remaining_input =~ regexp
      @pos += $&.length
      return [type, $&]
    end
  end

  SIMPLE_TOKENS.each do |token|
    if remaining_input[0...token.length] == token
      @pos += token.length
      return [token, token]
    end
  end

  raise SyntaxError, "Unexpected character: #{remaining_input[0..0].inspect}."
end

def skip_whitespace
  if remaining_input =~ /\A^[ \t\r\n]+/
    @pos += $&.length
  end
end

def remaining_input
  @input[@pos..-1]
end

def on_error(error_token_id, error_value, value_stack)
  raise SyntaxError, "Unexpected token: #{error_value.inspect}."
end
...end machete.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
75, 19, 9, 10, 11, 12, 13, 14, 15, 16, 66, 67, 68, 7, 24, 
9, 10, 11, 12, 13, 14, 15, 16, 17, 74, 8, 7, 47, 9, 10, 
11, 12, 13, 14, 15, 16, 48, 18, 8, 7, 71, 9, 10, 11, 12, 
13, 14, 15, 16, 72, 70, 8, 7, 73, 9, 10, 11, 12, 13, 14, 
15, 16, 69, 18, 8, 7, 30, 31, 32, 51, 52, 53, 54, 33, 34, 
35, 29, 8, 41, 38, 39, 76, 30, 31, 32, 77, 36, 37, 40, 33, 
34, 35, 29, nil, 41, 38, 39, 18, 49, 50, 62, 63, 36, 37, 40, 
43, 44, 55, 64, 65, 45, 46, 57, 58, nil, nil, nil, nil, nil, 56]

racc_action_check = [
70, 7, 0, 0, 0, 0, 0, 0, 0, 0, 54, 54, 54, 0, 17, 
8, 8, 8, 8, 8, 8, 8, 8, 1, 70, 0, 8, 21, 18, 18, 
18, 18, 18, 18, 18, 18, 22, 1, 8, 18, 56, 48, 48, 48, 48, 
48, 48, 48, 48, 57, 55, 18, 48, 58, 51, 51, 51, 51, 51, 51, 
51, 51, 55, 61, 48, 51, 19, 19, 19, 28, 28, 28, 28, 19, 19, 
19, 19, 51, 19, 19, 19, 71, 50, 50, 50, 75, 19, 19, 19, 50, 
50, 50, 50, nil, 50, 50, 50, 20, 26, 26, 52, 52, 50, 50, 50, 
20, 20, 46, 53, 53, 20, 20, 46, 46, nil, nil, nil, nil, nil, 46]

racc_action_pointer = [0, 23, nil, nil, nil, nil, nil, -
14, 13, nil, nil, nil, nil, nil, nil, nil, nil, 14, 26, 64, 83, 1, 
19, nil, nil, nil, 82, nil, 51, nil, nil, nil, nil, nil, nil, nil, nil, 
nil, nil, nil, nil, nil, nil, nil, nil, nil, 102, nil, 39, nil, 80, 52, 
94, 102, 4, 33, 35, 20, 24, nil, nil, 49, nil, nil, nil, nil, nil, 
nil, nil, nil, -5, 52, nil, nil, nil, 56, nil, nil]

racc_action_default = [-56, -56, -1, -3, -4, -5, -6, -7, -33, -48, -49, -50, -51, -52, -53, -54, -55, -56, -56, -56, -37, -56, -34, -35, 78, -2, -56, -9, -56, -19, -20, -21, -22, -23, -24, -25, -26, -27, -28, -29, -30, -31, -38, -39, -40, -41, -56, -32, -56, -8, -56, -56, -56, -56, -56, -56, -56, -56, -56, -36, -10, -11, -12, -15, -13, -16, -14, -17, -18, -42, -56, -56, -46, -47, -43, -56, -44, -45]

racc_goto_table = [
1, 23, 27, 25, 26, 21, 22, 42, nil, nil, nil, nil, nil, nil, nil, 
nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 
nil, nil, nil, 60, nil, nil, nil, nil, nil, nil, nil, 59, nil, nil, nil, 
nil, nil, nil, nil, nil, nil, 61]

racc_goto_check = [
1, 12, 8, 2, 7, 10, 11, 13, nil, nil, nil, nil, nil, nil, nil, 
nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 
nil, nil, nil, 8, nil, nil, nil, nil, nil, nil, nil, 12, nil, nil, nil, 
nil, nil, nil, nil, nil, nil, 1]

racc_goto_pointer = [nil, 0, -15, nil, nil, nil, nil, -15, -17, nil, -3, -2, -7, -13]

racc_goto_default = [nil, 20, 2, 3, 4, 5, 6, nil, nil, 28, nil, nil, nil, nil]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 31, :_reduce_none,
  3, 31, :_reduce_2,
  1, 32, :_reduce_none,
  1, 32, :_reduce_none,
  1, 32, :_reduce_none,
  1, 32, :_reduce_none,
  1, 33, :_reduce_7,
  4, 33, :_reduce_8,
  1, 37, :_reduce_none,
  3, 37, :_reduce_10,
  3, 38, :_reduce_11,
  3, 38, :_reduce_12,
  3, 38, :_reduce_13,
  3, 38, :_reduce_14,
  3, 38, :_reduce_15,
  3, 38, :_reduce_16,
  3, 38, :_reduce_17,
  3, 38, :_reduce_18,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  1, 39, :_reduce_none,
  3, 34, :_reduce_32,
  0, 40, :_reduce_33,
  1, 40, :_reduce_none,
  1, 41, :_reduce_35,
  3, 41, :_reduce_36,
  1, 42, :_reduce_none,
  2, 42, :_reduce_38,
  1, 43, :_reduce_39,
  1, 43, :_reduce_40,
  1, 43, :_reduce_41,
  3, 43, :_reduce_42,
  4, 43, :_reduce_43,
  4, 43, :_reduce_44,
  5, 43, :_reduce_45,
  3, 43, :_reduce_46,
  3, 43, :_reduce_47,
  1, 35, :_reduce_48,
  1, 35, :_reduce_49,
  1, 35, :_reduce_50,
  1, 35, :_reduce_51,
  1, 35, :_reduce_52,
  1, 35, :_reduce_53,
  1, 35, :_reduce_54,
  1, 36, :_reduce_55 ]

racc_reduce_n = 56

racc_shift_n = 78

racc_token_table = {
  false => 0,
  :error => 1,
  :NIL => 2,
  :TRUE => 3,
  :FALSE => 4,
  :INTEGER => 5,
  :SYMBOL => 6,
  :STRING => 7,
  :REGEXP => 8,
  :ANY => 9,
  :EVEN => 10,
  :ODD => 11,
  :METHOD_NAME => 12,
  :CLASS_NAME => 13,
  "|" => 14,
  "<" => 15,
  ">" => 16,
  "," => 17,
  "=" => 18,
  "^=" => 19,
  "$=" => 20,
  "*=" => 21,
  "*" => 22,
  "+" => 23,
  "^" => 24,
  "[" => 25,
  "]" => 26,
  "?" => 27,
  "{" => 28,
  "}" => 29 }

racc_nt_base = 30

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "NIL",
  "TRUE",
  "FALSE",
  "INTEGER",
  "SYMBOL",
  "STRING",
  "REGEXP",
  "ANY",
  "EVEN",
  "ODD",
  "METHOD_NAME",
  "CLASS_NAME",
  "\"|\"",
  "\"<\"",
  "\">\"",
  "\",\"",
  "\"=\"",
  "\"^=\"",
  "\"$=\"",
  "\"*=\"",
  "\"*\"",
  "\"+\"",
  "\"^\"",
  "\"[\"",
  "\"]\"",
  "\"?\"",
  "\"{\"",
  "\"}\"",
  "$start",
  "expression",
  "primary",
  "node",
  "array",
  "literal",
  "any",
  "attrs",
  "attr",
  "method_name",
  "items_opt",
  "items",
  "item",
  "quantifier" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

# reduce 1 omitted

module_eval(<<'.,.,', 'machete.y', 44)
  def _reduce_2(val, _values, result)
                   result = if val[0].is_a?(ChoiceMatcher)
                 ChoiceMatcher.new(val[0].alternatives << val[2])
               else
                 ChoiceMatcher.new([val[0], val[2]])
               end
             
    result
  end
.,.,

# reduce 3 omitted

# reduce 4 omitted

# reduce 5 omitted

# reduce 6 omitted

module_eval(<<'.,.,', 'machete.y', 57)
  def _reduce_7(val, _values, result)
             result = NodeMatcher.new(val[0].to_sym)
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 60)
  def _reduce_8(val, _values, result)
             result = NodeMatcher.new(val[0].to_sym, val[2])
       
    result
  end
.,.,

# reduce 9 omitted

module_eval(<<'.,.,', 'machete.y', 64)
  def _reduce_10(val, _values, result)
     result = val[0].merge(val[2]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 66)
  def _reduce_11(val, _values, result)
     result = { val[0].to_sym => val[2] } 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 68)
  def _reduce_12(val, _values, result)
             result = {
           val[0].to_sym => SymbolRegexpMatcher.new(
             Regexp.new("^" + Regexp.escape(symbol_value(val[2]).to_s))
           )
         }
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 75)
  def _reduce_13(val, _values, result)
             result = {
           val[0].to_sym => SymbolRegexpMatcher.new(
             Regexp.new(Regexp.escape(symbol_value(val[2]).to_s) + "$")
           )
         }
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 82)
  def _reduce_14(val, _values, result)
             result = {
           val[0].to_sym => SymbolRegexpMatcher.new(
             Regexp.new(Regexp.escape(symbol_value(val[2]).to_s))
           )
         }
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 89)
  def _reduce_15(val, _values, result)
             result = {
           val[0].to_sym => StringRegexpMatcher.new(
             Regexp.new("^" + Regexp.escape(string_value(val[2])))
           )
         }
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 96)
  def _reduce_16(val, _values, result)
             result = {
           val[0].to_sym => StringRegexpMatcher.new(
             Regexp.new(Regexp.escape(string_value(val[2])) + "$")
           )
         }
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 103)
  def _reduce_17(val, _values, result)
             result = {
           val[0].to_sym => StringRegexpMatcher.new(
             Regexp.new(Regexp.escape(string_value(val[2])))
           )
         }
       
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 110)
  def _reduce_18(val, _values, result)
             result = {
           val[0].to_sym => IndifferentRegexpMatcher.new(
             Regexp.new(regexp_value(val[2]))
           )
         }
       
    result
  end
.,.,

# reduce 19 omitted

# reduce 20 omitted

# reduce 21 omitted

# reduce 22 omitted

# reduce 23 omitted

# reduce 24 omitted

# reduce 25 omitted

# reduce 26 omitted

# reduce 27 omitted

# reduce 28 omitted

# reduce 29 omitted

# reduce 30 omitted

# reduce 31 omitted

module_eval(<<'.,.,', 'machete.y', 134)
  def _reduce_32(val, _values, result)
     result = ArrayMatcher.new(val[1]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 136)
  def _reduce_33(val, _values, result)
     result = [] 
    result
  end
.,.,

# reduce 34 omitted

module_eval(<<'.,.,', 'machete.y', 139)
  def _reduce_35(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 140)
  def _reduce_36(val, _values, result)
     result = val[0] << val[2] 
    result
  end
.,.,

# reduce 37 omitted

module_eval(<<'.,.,', 'machete.y', 143)
  def _reduce_38(val, _values, result)
     result = Quantifier.new(val[0], *val[1]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 145)
  def _reduce_39(val, _values, result)
     result = [0, nil, 1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 146)
  def _reduce_40(val, _values, result)
     result = [1, nil, 1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 147)
  def _reduce_41(val, _values, result)
     result = [0, 1, 1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 149)
  def _reduce_42(val, _values, result)
                 result = [integer_value(val[1]), integer_value(val[1]), 1]
           
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 152)
  def _reduce_43(val, _values, result)
                 result = [integer_value(val[1]), nil, 1]
           
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 155)
  def _reduce_44(val, _values, result)
                 result = [0, integer_value(val[2]), 1]
           
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 158)
  def _reduce_45(val, _values, result)
                 result = [integer_value(val[1]), integer_value(val[3]), 1]
           
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 160)
  def _reduce_46(val, _values, result)
     result = [0, nil, 2] 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 161)
  def _reduce_47(val, _values, result)
     result = [1, nil, 2] 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 163)
  def _reduce_48(val, _values, result)
     result = LiteralMatcher.new(nil) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 164)
  def _reduce_49(val, _values, result)
     result = LiteralMatcher.new(true) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 165)
  def _reduce_50(val, _values, result)
     result = LiteralMatcher.new(false) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 166)
  def _reduce_51(val, _values, result)
     result = LiteralMatcher.new(integer_value(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 167)
  def _reduce_52(val, _values, result)
     result = LiteralMatcher.new(symbol_value(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 168)
  def _reduce_53(val, _values, result)
     result = LiteralMatcher.new(string_value(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 169)
  def _reduce_54(val, _values, result)
     result = LiteralMatcher.new(regexp_value(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'machete.y', 171)
  def _reduce_55(val, _values, result)
     result = AnyMatcher.new 
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

  end   # class Parser
  end   # module Machete
