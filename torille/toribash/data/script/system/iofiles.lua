-- Files I/O manager

FILES_MODE_READONLY = 'r'
FILES_MODE_WRITE = 'w+'
FILES_MODE_APPEND = 'a'
FILES_MODE_READWRITE = 'r+'

do
	Files = {}
	Files.__index = Files
	
	function Files:new(path, mode)
		if (not path) then
			return false
		end
		local mode = mode or FILES_MODE_READONLY
		
		local File = {}
		setmetatable(File, self)
		
		File.mode = mode
		
		local isroot = path:match("%.%.%/") and 1 or nil
		File.isroot = isroot
		
		local path = path:gsub("%.%.%/", "")
		File.path = path
		
		if (not File:isDownloading()) then
			File.data = io.open(path, mode, isroot)
			return File
		end
		
		return File
	end
	
	function Files:reopen(mode)
		self:close()
		local mode = mode or self.mode
		if (not self:isDownloading()) then
			self.data = io.open(self.path, mode, self.isroot)
		end
	end
	
	function Files:readAll()
		if (not self.data) then
			return false
		end
		local filedata = self.data:read("*all")
		
		-- Remove all CRs
		filedata = filedata:gsub("\r", "")
		
		local lines = {}
		-- Replace lines() with gmatch to ensure we only read LF newlines
		for ln in filedata:gmatch("[^\n]*\n") do
			table.insert(lines, ln)
		end
		if (#lines == 0 and filedata:len() > 0) then
			return { filedata }
		end
		return lines
	end
	
	function Files:writeLine(line)
		local line = line:find("\n$") and line or (line .. "\n")
		self.data:write(line)
	end
	
	function Files:isDownloading()
		for i,v in pairs(get_downloads()) do
			if (v:match(strEsc(self.path:gsub("%.%a+$", "")) .. "%.%a+$")) then
				return true
			end
		end
		return false
	end
	
	function Files:close()
		if (self.data) then
			self.data:close()
		end
	end
end