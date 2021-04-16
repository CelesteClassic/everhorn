local filedialog = {}

local ffi = require("ffi")
local Comdlg32 = ffi.load("Comdlg32")

ffi.cdef [[
	typedef struct {
		unsigned long	lStructSize;
		void*			hwndOwner;
		void*			hInstance;
		const char*	lpstrFilter;
		char*		lpstrCustomFilter;
		unsigned long	nMaxCustFilter;
		unsigned long	nFilterIndex;
		char*		lpstrFile;
		unsigned long	nMaxFile;
		char*		lpstrFileTitle;
		unsigned long 	nMaxFileTitle;
		const char*	lpstrInitialDir;
		const char*	lpstrTitle;
		unsigned long 	flags;
		unsigned short	nFileOffset;
		unsigned short	nFileExtension;
		const char*	lpstrDefExt;
		unsigned long	lCustData;
		void*			lpfnHook;
		const char*	lpTemplateName;
		void*			pvReserved;
		unsigned long	dwReserved;
		unsigned long	flagsEx;
	} OPENFILENAMEA;

	int GetOpenFileNameA(OPENFILENAMEA *lpofn);
	int GetSaveFileNameA(OPENFILENAMEA *lpofn);
]]

function filedialog.open(filter)
	local ofnptr = ffi.new("OPENFILENAMEA[1]")
	local ofn = ofnptr[0]

	ofn.lStructSize = ffi.sizeof("OPENFILENAMEA")
	ofn.hwndOwner = nil
	
	ofn.lpstrFile = ffi.new("char[32768]")
	ofn.nMaxFile = 32767

	ofn.nFilterIndex = 1
	ofn.lpstrFilter = filter or "*.ahm, *.p8\0*.ahm;*.p8\0"
	
	ofn.lpstrTitle = nil
	ofn.lpstrInitialDir = nil
	
	ofn.flags = 0x1800
	
	if Comdlg32.GetOpenFileNameA(ofnptr) > 0 then
		return ffi.string(ofn.lpstrFile)
	end
end

function filedialog.save()
	local ofnptr = ffi.new("OPENFILENAMEA[1]")
	local ofn = ofnptr[0]

	ofn.lStructSize = ffi.sizeof("OPENFILENAMEA")
	ofn.hwndOwner = nil
	
	ofn.lpstrFile = ffi.new("char[32768]")
	ofn.nMaxFile = 32767

	ofn.nFilterIndex = 1
	ofn.lpstrFilter = "*.ahm\0*.ahm\0"
	ofn.lpstrDefExt = "map"
	
	ofn.lpstrTitle = "Save"
	ofn.lpstrInitialDir = nil
	
	ofn.flags = 0x0802
	
	if Comdlg32.GetSaveFileNameA(ofnptr) > 0 then
		return ffi.string(ofn.lpstrFile)
	end
end

return filedialog
