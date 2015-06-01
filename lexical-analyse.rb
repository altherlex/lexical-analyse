# encoding: UTF-8

#http://stackoverflow.com/questions/348256/regular-expression-to-match-code-blocks-multiple-times
#/(\/{2}\@debug)(.|\s)*?(\/{2}\@end-debug).*/
require 'lexeme'

def take_info_from_file(file)
  local = File.join('C:','dev', 'src')
  labels = {
    :CONSOLE_LOG=>'Saidas para console em codigo final.',
    :COMMENTS=>'Codigo comentado'
  }

  lexer = Lexeme.define do
    token :CONSOLE_LOG => /console.log/
    # token :PLUS     => /^\+$/
    # token :MINUS    => /^\-$/
    # token :MULTI    => /^\*$/
    # token :DIV      => /^\/$/
    # token :NUMBER   => /^\d+\.?\d?$/
    # token :RESERVED => /^(fin|print|func|)$/
    # token :STRING   => /^".*"$/
    token :COMMENTS => /\*.*\*/
    token :STOP     =>   /\n/
    token :WORD       => /^*$/ 
  end

  tokens = []
  File.readlines(file).each do |line|
    tokens <<
      lexer.analyze do 
        from_string line
      end
  end
  tokens = *tokens.map{|i| i.first}

  tokens.each do |t|
    if t
      if [:COMMENTS, :CONSOLE_LOG].include? t.name
        begin
          log = "#{file.sub(local, '')};#{labels[t.name]};#{t.value}" 
          File.open("./analise.csv", 'a'){|file| 
            file.write("\n")
            file.write(log) 
          }
        rescue
        end
      end
    end
  end
end

api = ARGV[0] || 'api-proximos_pagamentos'
local = File.join('C:','dev', 'src')
files_to_load = {
    dir: [
      File.join(local, api, '_tests'),
      File.join(local, api, 'controller'),
      File.join(local, api, 'controller', 'resource'),
      File.join(local, api, 'controller', 'validation'),
      File.join(local, api, 'processor'),
      File.join(local, api, 'lib'),
      File.join(local, api, 'utils'),
      File.join(local, api, 'service')
    ],
    files:[
      File.join(local, api, 'controller', 'resource.js'),
      File.join(local, api, 'controller', 'validation.js')
    ]
  }

files_to_load[:dir].map!{|dir| Dir.glob( File.join(dir, '**', '*.js') ) }
files_to_load[:files].map!{|file| Dir.glob( File.join(file) )}
files_to_load = [*files_to_load[:dir], *files_to_load[:file]]
files_to_load.flatten.reject{ |e| File.directory? e }.each{|file| 
  take_info_from_file(file)
}
