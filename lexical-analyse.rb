# encoding: UTF-8
require 'lexeme'

def take_info_from_file(file)
  local = File.join('C:','dev', 'src')
  labels = {
    :CONSOLE_LOG=>'Saidas para console em codigo final.',
    :COMMENTS=>'Codigo comentado',
    :SUFIX_FILE_TEST=>'Nome do arquivo comecando com letra maiuscula e/ou nao tem sufixo _test.',
    :TODO=>'TODO',
    :FIXME=>'FIXME',
    :REWIRE=>'Arquivo chamado nao existe',
    :VAR=>'Require nao usado'
  }

  lexer = Lexeme.define do
    token :CONSOLE_LOG => /console.log/
    token :TODO => /TODO/
    token :FIXME => /FIXME/
    #token :VAR => /var.*;/
    token :VAR => /var .* =/
    token :REWIRE => /rewire\(.*\)/
    #token :COMMENTS => /\*.*\*/
    #token :COMMENTS => /\/\*.*\*\//
    token :COMMENTS => /\/\*(\*(?!\/)|[^*])*\*\//
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

  file_already_exists = []
  tokens.each do |t|
     
    if file.include?('_test') and !File.basename(file, '.js').include?('_test')
      log = "#{file.sub(local, '')};#{labels[:SUFIX_FILE_TEST]};" 
      unless file_already_exists.include? log
        File.open("./analise.csv", 'a'){|file| 
          file.write("\n")
          file.write(log) 
        }
        file_already_exists << log
      end
    end  
    # VAR: require nao usado
    if t
      if [:VAR].include? t.name
        nme_var = t.value.split('var').last.split('=').first
        count = 0
        File.readlines(file).each do |line|
          if line.split(/\W+/).map(&:strip).include?(nme_var.strip) and
            (not line.strip.start_with?('//') or not line.strip.start_with?('/*'))
            count += 1 
          end
        end
        if count == 1
          log = "#{file.sub(local, '')};#{labels[t.name]};#{t.value}" 
          File.open("./analise.csv", 'a'){|file| 
            file.write("\n")
            file.write(log) 
          }
        end
      end
      if [:REWIRE].include? t.name
        nme_file_rewire = t.value.split('rewire(').last.split(')')
        if not File.exists?(File.join(file,nme_file_rewire))
          log = "#{file.sub(local, '')};#{labels[t.name]};#{t.value}" 
          File.open("./analise.csv", 'a'){|file| 
            file.write("\n")
            file.write(log) 
          }
        end
      end      
      if [:CONSOLE_LOG, :TODO, :FIXME].include? t.name
        log = "#{file.sub(local, '')};#{labels[t.name]};#{t.value}" 
        File.open("./analise.csv", 'a'){|file| 
          file.write("\n")
          file.write(log) 
        }
      end
      if [:COMMENTS].include? t.name
        if ['/*global', '/*jslint'].detect{|i| t.value.include?(i)}.nil?
          log = "#{file.sub(local, '')};#{labels[t.name]};#{t.value}" 
          File.open("./analise.csv", 'a'){|file| 
            file.write("\n")
            file.write(log) 
          }
        end
      end      
    end
  end
end

#File.delete('analise.csv')
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
