#encoding:utf-8
require 'pp'

module MarkdownPP
	DirectivePattern = /\#\{&([:=.?]+)(.*?)\}/
	DirectiveHandlers = Hash[*%w|~ translator_added = alternative ? undecided := may_change .. unfinished < tag_begin > tag_end|]
	MayChange = {}
	Undecided = []
	Unfinished = []
	Blank = ''
	
	module_function
	def scan_pp_directives(lines)
		lines.each_with_index do |line,lineno|
			for directive, params in line.scan DirectivePattern
				if directive == ':=' and not params.nil?
					english, value = params.split ','
					MayChange[english.strip] = value unless value.nil?
				elsif directive == '?'
					Undecided << [lineno, line, params]
				elsif directive == '..'
					Unfinished << [lineno, line]
				end
			end
		end
	end

	def sub_pp_directives(lines)
		lines.map do |line|
			line = line.gsub(DirectivePattern) do
				method = DirectiveHandlers[$1]
				method.nil? ? Blank : self.send(method.to_sym,*$2.split(','))
			end
			line.gsub(/\#\{(.*?)\}/) do
				MayChange[$1]
			end
		end
	end

	def parse(text)
		scan_pp_directives text
		sub_pp_directives text
	end

	def may_change(english, value = nil)
		MayChange[english]
	end

	def undecided(english, worst_choice = nil)
		worst_choice || Blank
	end

	def unfinished(why = nil)
		"[Unfinished，#{why}]"
	end

	def translator_added(*sentence)
		"(#{sentence})"
	end

	def alternative(alt)
		"(#{alt})"
	end

	def tag_begin(tag)
		"<#{tag}>"
	end

	def tag_end(tag)
		"</#{tag}>"
	end

	def self.method_missing(m,p)
		Blank
	end
end

 MarkdownPP.parse(File.readlines("#{File.realpath(ARGV.first)}"))