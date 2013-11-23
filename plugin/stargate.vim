scriptencoding utf-8
if exists('g:loaded_stargate')
  finish
endif
let g:loaded_stargate = 1

let s:save_cpo = &cpo
set cpo&vim


command! -nargs=1 -complete=customlist,stargate#command_complete
\	StargateInclude call stargate#include(<f-args>, stargate#get_include_format(&filetype))


let &cpo = s:save_cpo
unlet s:save_cpo
