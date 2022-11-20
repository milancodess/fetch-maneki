
CONFIG = ARGV.to_h do |argv|
	argv.split '=', 2
end

class String
	def column key
		<<~TXT.chomp.gsub /[\n\s]+/, ' '
			#{CONFIG['KEY_COLOR']}#{key} 
			#{CONFIG['VALUE_COLOR']}#{chomp}
		TXT
	end
end

ASCII_LINES = (
	File.read CONFIG['ASCII_FILE'] rescue <<~TXT
		   /_____\\
		    /, ,\\
		    )<> (
		   / / \\ \\
		__(\\|  _\\_)
		\\_/-___\\_/
	TXT
).split ?\n

File.write 'bin/mfetch', <<~TXT
#!/bin/sh
echo -e "\\
#{
	ASCII_LINES.map.with_index do |ascii_line, i|
		spacing = 12 - ascii_line.length
		CONFIG['ASCII_COLOR'] +
		(ascii_line.gsub ?\\, '\\\\\\\\\\\\\\') +
		' ' * spacing +
		case CONFIG["LINE_#{i}"]
		when 'user_at_host'
			"#{CONFIG['SPECIAL_COLOR']}$USER@`uname -n`"
		when 'kernel'
			<<~TXT.column 'krl'
				`uname -r`
			TXT
		when 'host'
			<<~TXT.column 'hst'
				`cat
					/sys/devices/virtual/dmi/id/product_{name,version}
					/sys/firmware/devicetree/base/model
					2>/dev/null | tr '\\n' ' '`
			TXT
		when 'uptime'
			<<~TXT.column 'upt'
				`uptime -p | cut -d' ' -f2-`
			TXT
		when 'battery'
			<<~TXT.column 'bat'
				`cat \\`find
					/sys/class/power_supply
					-name 'BAT*' -print -quit
					\\`/energy_{now,full}
					| tr '\\n' ' '
					| awk '{print $1/1000"k / " $2/1000"k"}'`
			TXT
		when 'memory'
			<<~TXT.column 'mem'
				`free -m | awk 'NR==2{print $3\"M / \"$2\"M\"}'`
			TXT
		when 'disk'
			<<~TXT.column 'dsk'
				`df -h --output=used,size /
				| awk 'FNR==2{print $1" / "$2}'`
			TXT
		when 'shell'
			<<~TXT.column 'shl'
				`basename $SHELL`
			TXT
		else
			''
		end
	end.join ?\n
}#{CONFIG['CLEAR_COLOR']}"
TXT
