scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:exts = {
\	"c" : ["", "h"],
\	"cpp" : ["", "h", "hpp", "hxx"],
\	"ruby" : ["", "rb"],
\}

function! stargate#get_file_exts(filetype)
	return get(s:exts, a:filetype, [])
endfunction


let s:format = {
\	"_" : "%s",
\	"include_square_parentheses" : "#include <%s>",
\	"include_double_quotation"   : '#include "%s"',
\	"require_single_quotation"   : "require '%s'",
\	"load_single_quotation"      : "load '%s'",
\	"import " : "import %s",
\}

let g:stargate#include_format = extend(s:format, get(g:, "stargate#include_format", {}))


let s:default_format = {
\	"c"      : "include_square_parentheses",
\	"cpp"    : "include_square_parentheses",
\	"ruby"   : "require_single_quotation",
\	"python" : "import",
\}

let g:stargate#include_default_format = extend(s:default_format, get(g:, "stargate#include_default_format", {}))

function! stargate#get_include_format(filetype)
	return get(g:stargate#include_format, get(g:stargate#include_default_format, a:filetype, "_"), "%s")
endfunction


" let s:include_dirs = {
" \	"c" : [],
" \	"cpp" : [],
" \}
let g:stargate#include_paths = get(g:, "stargate#include_paths", {})

function! stargate#get_include_paths(filetype)
	return get(g:stargate#include_paths, a:filetype, []) + split(&path, '[,;]')
endfunction


function! s:echoerr(expr)
	echohl Error
	echo a:expr
	echohl NONE
endfunction


function! s:to_slashpath(path)
	return substitute(a:path, '\\', '/', 'g')
endfunction


function! s:glob(expr, dir)
	let cwd = getcwd()
	let result = []
	try
		execute "lcd" fnameescape(a:dir)
		return map(map(split(glob(a:expr), '\n'), 's:to_slashpath(v:val)'), '{
\			"word" : v:val,
\			"path" : a:dir . "/" . v:val,
\			"isdirectory" : isdirectory(v:val)
\		}')
	finally
		execute "lcd" fnameescape(cwd)
	endtry
endfunction


function! s:get_include_paths(keyword, filetype, paths)
	let paths = a:paths
	let exts = stargate#get_file_exts(a:filetype)
	let bufdir = s:to_slashpath(fnamemodify(expand("%d"), ':p:h'))
	let glob = a:keyword !~ '\*$' ? a:keyword . "*" : a:keyword

	let dirs = filter(map(copy(paths), 'v:val == "." ? bufdir : v:val'), 'isdirectory(v:val)')
	let candidates = eval(join(map(dirs, "s:glob(glob, v:val)"), '+'))
	let result = filter(candidates, 'empty(fnamemodify(v:val.word, ":e")) || index(exts, fnamemodify(v:val.word, ":e")) >= 0')
" 	PP candidates
	return result
endfunction


function! stargate#get_include_files(...)
	let keyword  = get(a:, 1, "")
	let filetype = get(a:, 2, &filetype)
	let paths    = get(a:, 3, stargate#get_include_paths(&filetype))
	return s:get_include_paths(keyword, filetype, paths)
endfunction


function! s:include(file, format)
	let lnum = search(&l:include, 'bnW')
	if lnum == 0
		" 一番上から最初の空白行の位置
		let lnum = get(filter(map(getline(1, "."), 'v:val =~ ''^$'' ? v:key : -1'), 'v:val != -1'), 0, 1)
	endif
	let file = substitute(a:file, '\\', '/', 'g')
	let format = a:format
	call append(lnum, printf(format, file))
endfunction


function! stargate#include(file, ...)
	if a:0 >= 1
		let format = a:1
	else
		let format = stargate#get_include_format(&filetype)
	endif
	return s:include(a:file, format)
endfunction


function! s:uniq(list)
	let result = {}
	for _ in a:list
		let result[_] = 0
	endfor
	return keys(result)
endfunction

function! stargate#command_complete(arglead, ...)
	return s:uniq(map(stargate#get_include_files(a:arglead, &filetype, stargate#get_include_paths(&filetype)), 'v:val.word'))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
