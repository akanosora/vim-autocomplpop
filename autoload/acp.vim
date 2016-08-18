"=============================================================================
" Copyright (c) 2007-2009 Takeshi NISHIDA
" Copyright (c) 2016      Zhen-Huan Hu
"
"=============================================================================
" LOAD GUARD {{{1

if exists('g:loaded_autoload_acp') || v:version < 702
  finish
endif
let g:loaded_autoload_acp = 1

" }}}1
"=============================================================================
" GLOBAL FUNCTIONS: {{{1

" To enable auto-popup
function acp#enable()
  call acp#disable()

  augroup AcpGlobalAutoCommand
    autocmd!
    autocmd InsertEnter * unlet! s:pos_last s:last_uncompletable
    autocmd InsertLeave * call s:FinishPopup(1)
  augroup END

  if g:acp_mapping_driven
    " Use key mappings to trigger the popup menu
    call s:MapForMappingDriven()
  else
    " Otherwise trigger the popup menu 
    " after the cursor was moved in Insert mode
    autocmd AcpGlobalAutoCommand CursorMovedI * call s:FeedPopup()
  endif

  " Trigger the popup menu
  " when switching to Insert mode
  nnoremap <silent> i i<C-r>=<SID>FeedPopup()<CR>
  nnoremap <silent> a a<C-r>=<SID>FeedPopup()<CR>
  nnoremap <silent> R R<C-r>=<SID>FeedPopup()<CR>
endfunction

" To disable auto-popup
function acp#disable()
  call s:UnMapForMappingDriven()
  augroup AcpGlobalAutoCommand
    autocmd!
  augroup END
  nnoremap i <Nop> | nunmap i
  nnoremap a <Nop> | nunmap a
  nnoremap R <Nop> | nunmap R
endfunction

" To suspend auto-popup temporarily
function acp#lock()
  let s:lock_count += 1
endfunction

" To resume auto-popup from suspension
function acp#unlock()
  let s:lock_count -= 1
  if s:lock_count < 0
    let s:lock_count = 0
    throw "AutoComplPop: Not locked"
  endif
endfunction

" }}}1
"=============================================================================
" LOCAL FUNCTIONS: {{{1

" Default completion funciton for snipMate
function s:CompleteFuncForSnipmate(findstart, base)
  if a:findstart
    let s:snip_completion_pos = len(matchstr(s:GetCurrentText(), '.*\U'))
    return s:snip_completion_pos
  endif
  let base_len = len(a:base)
  let items = filter(GetSnipsInCurrentScope(),
        \            'strpart(v:key, 0, base_len) ==? a:base')
  return map(sort(items(items)), 's:MakeSnipmateItem(v:val[0], v:val[1])')
endfunction

" Default 'meets' function for snipMate
" to decide whether to attempt completion
function s:MeetsForSnipmate(context)
  if g:acp_snipmate_length < 0
    return 0
  endif
  let matches = matchlist(a:context, '\(^\|\s\|\<\)\(\u\{' .
        \                            g:acp_snipmate_length . ',}\)$')
  return !empty(matches) && !empty(s:GetMatchingSnipItems(matches[2]))
endfunction

" Default 'OnPopupClose' function for snipMate
function s:OnPopupCloseForSnipmate()
  let word = s:GetCurrentText()[s:snip_completion_pos :]
  for trigger in keys(GetSnipsInCurrentScope())
    if word ==# trigger
      call feedkeys("\<C-r>=TriggerSnippet()\<CR>", "n")
      return 0
    endif
  endfor
  return 1
endfunction

" Default 'meets' function for anything that is a keyword
" to decide whether to attempt completion
function s:MeetsForKeyword(context)
  if g:acp_keyword_length < 0
    return 0
  endif
  let matches = matchlist(a:context, '\(\k\{' . g:acp_keyword_length . ',}\)$')
  if empty(matches)
    return 0
  endif
  for ignore in g:acp_ignore_keywords
    if stridx(ignore, matches[1]) == 0
      " Do not attempt completion
      " if the start of the match occurs in 'ignore'
      return 0
    endif
  endfor
  return 1
endfunction

" Default 'meets' function for file names
" to decide whether to attempt completion
function s:MeetsForFile(context)
  if g:acp_file_length < 0
    return 0
  endif
  if has('win32') || has('win64')
    let separator = '[/\\]'
  else
    let separator = '\/'
  endif
  if a:context !~ '\f' . separator . '\f\{' . g:acp_file_length . ',}$'
    return 0
  endif
  return a:context !~ '[*/\\][/\\]\f*$\|[^[:print:]]\f*$'
endfunction

" Default 'meets' function for Ruby
" to decide whether to attempt completion
function s:MeetsForRubyOmni(context)
  if has('ruby') && g:acp_ruby_omni_method_length >= 0 &&
        \ a:context =~ '[^. \t]\(\.\|::\)\k\{' .
        \              g:acp_ruby_omni_method_length . ',}$'
    return 1
  endif
  if has('ruby') && g:acp_ruby_omni_symbol_length >= 0 &&
        \ a:context =~ '\(^\|[^:]\):\k\{' .
        \              g:acp_ruby_omni_symbol_length . ',}$'
    return 1
  endif
  return 0
endfunction

" Default 'meets' function for Python
" to decide whether to attempt completion
function s:MeetsForPythonOmni(context)
  return has('python') && g:acp_python_omni_length >= 0 &&
        \ a:context =~ '\k\.\k\{' . g:acp_python_omni_length . ',}$'
endfunction

" Default 'meets' function for Perl
" to decide whether to attempt completion
function s:MeetsForPerlOmni(context)
  return has('perl') && g:acp_perl_omni_length >= 0 &&
        \ a:context =~ '\w->\k\{' . g:acp_perl_omni_length . ',}$'
endfunction

" Default 'meets' function for Xml
" to decide whether to attempt completion
function s:MeetsForXmlOmni(context)
  return g:acp_xml_omni_length >= 0 &&
        \ a:context =~ '\(<\|<\/\|<[^>]\+ \|<[^>]\+=\"\)\k\{' .
        \              g:acp_xml_omni_length . ',}$'
endfunction

" Default 'meets' function for Html
" to decide whether to attempt completion
function s:MeetsForHtmlOmni(context)
  return g:acp_html_omni_length >= 0 &&
        \ a:context =~ '\(<\|<\/\|<[^>]\+ \|<[^>]\+=\"\)\k\{' .
        \              g:acp_html_omni_length . ',}$'
endfunction

" Default 'meets' function for JavaScript
" to decide whether to attempt completion
function s:MeetsForJavaScriptOmni(context)
  return g:acp_javascript_omni_length >= 0 &&
        \ a:context =~ '\k\{' .
        \              g:acp_javascript_omni_length . ',}$'
endfunction

" Default 'meets' function for Css
" to decide whether to attempt completion
function s:MeetsForCssOmni(context)
  if g:acp_css_omni_property_length >= 0 &&
        \ a:context =~ '\(^\s\|[;{]\)\s*\k\{' .
        \              g:acp_css_omni_property_length . ',}$'
    return 1
  endif
  if g:acp_css_omni_value_length >= 0 &&
        \ a:context =~ '[:@!]\s*\k\{' .
        \              g:acp_css_omni_value_length . ',}$'
    return 1
  endif
  return 0
endfunction

" Map keys to s:FeedPopup()
function s:MapForMappingDriven()
  call s:UnMapForMappingDriven()
  let s:mapping_driven_keys = [
        \ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
        \ 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
        \ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        \ 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        \ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        \ '-', '_', '~', '^', '.', ',', ':', '!', '#', '=', '%', '$', '@', '<', '>', '/', '\',
        \ '<Space>', '<C-h>', '<BS>', ]
  for key in s:mapping_driven_keys
    execute printf('inoremap <silent> %s %s<C-r>=<SID>FeedPopup()<CR>',
          \        key, key)
  endfor
endfunction

" Unmap keys
function s:UnMapForMappingDriven()
  if !exists('s:mapping_driven_keys')
    return
  endif
  for key in s:mapping_driven_keys
    execute 'iunmap' key
  endfor
  unlet s:mapping_driven_keys
endfunction

" Set variable with temporary value
function s:SetTempOption(group, name, value)
  if !exists('s:orig_map[a:group]')
    let s:orig_map[a:group] = {}
  endif
  if !exists('s:orig_map[a:group][a:name]')
    let s:orig_map[a:group][a:name] = eval(a:name)
  endif
  execute 'let' a:name '= a:value'
endfunction

" Restore original value to variable and clean up
function s:RestoreTempOptions(group)
  if !exists('s:orig_map[a:group]')
    return
  endif
  for [name, value] in items(s:orig_map[a:group])
    execute 'let' name '= value'
    unlet value " to avoid E706
  endfor
  unlet s:orig_map[a:group]
endfunction

" Retrieve contents at current line before cursor
function s:GetCurrentText()
  return strpart(getline('.'), 0, col('.') - 1)
endfunction

" Retrieve contents at current line after cursor
function s:GetPostText()
  return strpart(getline('.'), col('.') - 1)
endfunction

" Retrieve current word at cursor
" At a non-keyword character, return empty string
function s:GetCurrentWord()
  return matchstr(s:GetCurrentText(), '\k*$')
endfunction

" Check if the buffer is modified
function s:IsModifiedSinceLastCall()
  if exists('s:pos_last')
    let pos_prev     = s:pos_last
    let n_lines_prev = s:n_lines_last
    let text_prev    = s:text_last
  endif
  let s:pos_last     = getpos('.')
  let s:n_lines_last = line('$')
  let s:text_last    = getline('.')
  if !exists('pos_prev')
    return 1
  elseif pos_prev[1] != s:pos_last[1] || n_lines_prev != s:n_lines_last
    return (pos_prev[1] - s:pos_last[1] == n_lines_prev - s:n_lines_last)
  elseif text_prev ==# s:text_last
    return 0
  elseif pos_prev[2] > s:pos_last[2]
    return 1
  elseif has('gui_running') && has('multi_byte')
    " NOTE: auto-popup causes a strange behavior when IME/XIM is working
    return pos_prev[2] + 1 == s:pos_last[2]
  endif
  return pos_prev[2] != s:pos_last[2]
endfunction

" Make current behavior set s:current_behavs
" Return 1 if a new behavior set is created, 0 if otherwise
function s:MakeCurrentBehaviorSet()
  if exists('s:current_behavs[s:behav_idx].repeat')
        \ && s:current_behavs[s:behav_idx].repeat
    let s:current_behavs = [ s:current_behavs[s:behav_idx] ]
  elseif s:IsModifiedSinceLastCall()
    " Make a behavior set only if the buffer has been modified since last call
    let s:current_behavs = copy(exists('g:acp_behavior[&filetype]')
          \ ? g:acp_behavior[&filetype]
          \ : g:acp_behavior['*'])
  else
    " No need to create a behavior set if the buffer is unchanged
    call s:ClearCurrentBehaviorSet()
    return 0
  endif
  let s:behav_idx = 0
  let word = s:GetCurrentWord()
  if word ==# ''
    " Clear s:last_uncompletable at a non-keyword character
    unlet! s:last_uncompletable
  endif
  call filter(s:current_behavs, 'call(v:val.meets, [word])')
  return !empty(s:current_behavs)
endfunction

" Clear current behavior set s:current_behavs
function s:ClearCurrentBehaviorSet()
  let s:current_behavs = []
endfunction

" Feed keys to popup menu
function s:FeedPopup()
  " CursorMovedI event will not be triggered while the popup menu is visible
  " It will be triggered once popup menu has disappeared (aka: end of a word)
  if s:lock_count > 0 || pumvisible() || &paste
    return ''
  elseif exists('s:current_behavs[s:behav_idx].closef')
    if !call(s:current_behavs[s:behav_idx].closef, [])
      " Fallback to s:FinishPopup if not successful
      call s:FinishPopup(1)
    endif
    return ''
  elseif s:MakeCurrentBehaviorSet()
    " Improve the response by not to attempt another completion
    " after a word found with no completion candidate at the last attempt
    if exists('s:last_uncompletable') &&
          \ stridx(s:GetCurrentWord(), s:last_uncompletable.word) == 0 &&
          \ map(copy(s:current_behavs), 'v:val.command') ==# s:last_uncompletable.commands
      call s:FinishPopup(0)
      return ''
    else
      " In case of words divided by symbols (e.g.: 'for(int', 'ab=cd') while a
      " popup menu is visible, another popup is not possible without pressing <C-e>
      " or trying to popup at least once
      " First completion behavior is doubled to circumvent this
      call insert(s:current_behavs, s:current_behavs[0])
      " Set temporary options before attempting to popup menu
      call s:SetTempOption(s:L_0, '&complete', g:acp_complete_option)
      call s:SetTempOption(s:L_0, '&completeopt', 'menuone' . (g:acp_completeopt_preview ? ',preview' : ''))
      call s:SetTempOption(s:L_0, '&completefunc', (exists('s:current_behavs[0].completefunc') ? s:current_behavs[0].completefunc : eval('&completefunc')))
      call s:SetTempOption(s:L_0, '&ignorecase', g:acp_ignorecase_option)
      call s:SetTempOption(s:L_0, '&spell', 0)
      " If autocmd driven, set 'lazyredraw' to avoid flickering,
      " If key mapping driven, set 'nolazyredraw' to make the popup menu visible
      call s:SetTempOption(s:L_0, '&lazyredraw', !g:acp_mapping_driven)
      " Unlike other options, &textwidth must be restored after each final <C-e>
      call s:SetTempOption(s:L_1, '&textwidth', 0)
      call feedkeys(printf("%s\<C-r>=%sOnPopup()\<CR>", s:current_behavs[0].command, s:PREFIX_SID), 'n')
      return ''
    endif
  else
    call s:FinishPopup(1)
    return ''
  endif
endfunction

" Generate contents for s:FeedPopup()
" Keep it as a local function to avoid users accidentally calling it directly
function s:OnPopup()
  if pumvisible()
    " When a popup menu appears
    inoremap <silent> <expr> <C-h> <SID>OnBS()
    inoremap <silent> <expr> <BS>  <SID>OnBS()
    if g:acp_select_first_item
      " To restore the original text and select the first match
      return (s:current_behavs[s:behav_idx].command =~# "\<C-p>" ? "\<C-n>\<Up>"
            \                                                    : "\<C-p>\<Down>")
    else
      " To restore the original text
      return (s:current_behavs[s:behav_idx].command =~# "\<C-p>" ? "\<C-n>"
            \                                                    : "\<C-p>")
    endif
  elseif s:behav_idx < len(s:current_behavs) - 1
    " When popup menu impossible for the current completion behavior,
    " attempt the next behavior if available
    let s:behav_idx += 1
    " Need to update &completefunc each time before a new behavior is tried
    call s:SetTempOption(s:L_0, '&completefunc',
          \ (exists('s:current_behavs[s:behav_idx].completefunc') ? s:current_behavs[s:behav_idx].completefunc : eval('&completefunc')))
    return printf("\<C-e>%s\<C-r>=%sOnPopup()\<CR>", s:current_behavs[s:behav_idx].command, s:PREFIX_SID)
  else
    " After all attempts have failed
    let s:last_uncompletable = {
          \   'word': s:GetCurrentWord(),
          \   'commands': map(copy(s:current_behavs), 'v:val.command')[1:],
          \ }
    call s:FinishPopup(0)
    return "\<C-e>"
  endif
endfunction

" Cleaning function after popup
function s:FinishPopup(level)
  if a:level >= 0
    call s:ClearCurrentBehaviorSet()
    call s:RestoreTempOptions(s:L_0)
    inoremap <C-h> <Nop> | iunmap <C-h>
    inoremap <BS>  <Nop> | iunmap <BS>
  endif
  if a:level >= 1
    call s:RestoreTempOptions(s:L_1)
  endif
endfunction

"
function s:OnBS()
  " Use "matchstr" instead of "strpart" to handle multi-byte characters
  if call(s:current_behavs[s:behav_idx].meets,
        \ [matchstr(s:GetCurrentText(), '.*.\@=')])
    return "\<BS>"
  endif
  return "\<C-e>\<BS>"
endfunction

"
function s:MakeSnipmateItem(key, snip)
  if type(a:snip) == type([])
    let descriptions = map(copy(a:snip), 'v:val[0]')
    let formatted_snip = '[MULTI] ' . join(descriptions, ', ')
  else
    let formatted_snip = substitute(a:snip, '\(\n\|\s\)\+', ' ', 'g')
  endif
  return  {
        \   'word': a:key,
        \   'menu': strpart(formatted_snip, 0, 80),
        \ }
endfunction

"
function s:GetMatchingSnipItems(base)
  let key = a:base . "\n"
  if !exists('s:snip_items[key]')
    let s:snip_items[key] = items(GetSnipsInCurrentScope())
    call filter(s:snip_items[key], 'strpart(v:val[0], 0, len(a:base)) ==? a:base')
    call map(s:snip_items[key], 's:MakeSnipmateItem(v:val[0], v:val[1])')
  endif
  return s:snip_items[key]
endfunction

function s:GetSidPrefix()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" }}}1
"=============================================================================
" INITIALIZATION {{{1

"-----------------------------------------------------------------------------
let s:PREFIX_SID = s:GetSidPrefix()
delfunction s:GetSidPrefix
let s:L_0 = 0
let s:L_1 = 1
"-----------------------------------------------------------------------------
let s:lock_count = 0
let s:current_behavs = []
let s:behav_idx = 0
let s:orig_map = {}
let s:snip_items = {}

" }}}1
"=============================================================================
" vim: set fdm=marker:
