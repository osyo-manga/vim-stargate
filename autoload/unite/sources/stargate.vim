scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! unite#sources#stargate#define()
	return s:source
endfunction


let s:source = {
\	"name" : "stargate",
\	"max_candidates" : 200,
\	"default_action" : "insert",
\	"action_table" : {
\		"insert" : {
\			"is_selectable" : 1,
\		},
\	},
\	"hooks" : {},
\}


function! s:source.action_table.insert.func(candidates)
	for candidate in a:candidates
		call stargate#include(candidate.word)
	endfor
endfunction


function! s:source.hooks.on_init(args, context)
	let filetype = getbufvar(unite#get_current_unite().prev_bufnr, "&filetype")
	let a:context.source__stargate_dirs = stargate#get_include_paths(filetype)
endfunction

function! s:source.change_candidates(args, context) "{{{
	let filetype = getbufvar(unite#get_current_unite().prev_bufnr, "&filetype")
	let candidates = stargate#get_include_files(a:context.input, filetype, a:context.source__stargate_dirs)
	return map(candidates, "{
\		'word' : v:val.word . (v:val.isdirectory ? '/'  : ''),
\		'source__include_file' : v:val.word,
\		'action__path' : v:val.path,
\		'action__directory' : v:val.isdirectory ? v:val.path : fnamemodify(v:val.path, ':h'),
\		'kind' : v:val.isdirectory ? 'directory' : 'file'
\	}")
endfunction




let &cpo = s:save_cpo
unlet s:save_cpo
