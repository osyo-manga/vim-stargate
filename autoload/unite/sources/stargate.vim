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
\		"narrowing_word" : {
\			"is_selectable" : 0,
\			"is_quit" : 0,
\		},
\	},
\	"hooks" : {},
\}


function! s:source.action_table.insert.func(candidates)
	for candidate in a:candidates
		call stargate#include(candidate.word)
	endfor
endfunction


function! s:make_candidates(context)
	let filetype = getbufvar(unite#get_current_unite().prev_bufnr, "&filetype")
	let candidates = stargate#get_include_files(a:context.input, filetype, a:context.source__stargate_dirs)
	return [a:context.input, map(candidates, "{
\		'word' : v:val.word . (v:val.isdirectory ? '/'  : ''),
\		'source__include_file' : v:val.word,
\		'action__path' : v:val.path,
\		'action__directory' : v:val.isdirectory ? v:val.path : fnamemodify(v:val.path, ':h'),
\		'kind' : v:val.isdirectory ? 'directory' : 'file'
\	}")]
endfunction

let s:candidates_cache = []
function! s:source.hooks.on_init(args, context)
	let filetype = getbufvar(unite#get_current_unite().prev_bufnr, "&filetype")
	let a:context.source__stargate_dirs = stargate#get_include_paths(filetype)
	let s:candidates_cache = s:make_candidates(a:context)
endfunction


function! s:source.action_table.narrowing_word.func(candidate)
	let candidate = unite#helper#get_current_candidate()
	call unite#mappings#narrowing(has_key(candidate, 'action__word')
\		? candidate.action__word
\		: candidate.word)
endfunction


function! s:source.change_candidates(args, context)
	let input = a:context.input
	if input =~ '/$' || len(a:context.input) <= len(s:candidates_cache[0])
		let s:candidates_cache = s:make_candidates(a:context)
	endif
	return s:candidates_cache[1]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
