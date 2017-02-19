local capi = { luakit = luakit }

local editor = {}

-- Can't yet handle files with special characters in their name
editor.edit = function (file, line)
	local subs = {
		term = globals.term or os.getenv("TERMINAL") or "xterm",
		editor = globals.editor or os.getenv("EDITOR") or "vim",
		file = file,
		line = line and " +" .. tostring(line) or "",
	}
	local cmd_tmpl = "{term} -e '{editor} {file}{line}'"
	local cmd = string.gsub(cmd_tmpl, "{(%w+)}", subs)
	capi.luakit.spawn(cmd)
end

return editor
