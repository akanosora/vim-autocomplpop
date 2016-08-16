"=============================================================================
" Copyright (c) 2007-2009 Takeshi NISHIDA
" Copyright (c) 2016      Zhen-Huan Hu
"
" GetLatestVimScripts: 1879 1 :AutoInstall: AutoComplPop
"=============================================================================
" LOAD GUARD {{{1

if exists('g:loaded_acp')
  finish
elseif v:version < 702
  echoerr 'AutoComplPop does not support this version of vim (' . v:version . ').'
  finish
endif
let g:loaded_acp = 1

" }}}1
"=============================================================================
" FUNCTION: {{{1

"
function s:DefineVariableDefault(name, default)
  if !exists(a:name)
    let {a:name} = a:default
  endif
endfunction

"
function s:MakeDefaultBehavior()
  let behavs = {
        \   '*'      : [],
        \   'ruby'   : [],
        \   'python' : [],
        \   'perl'   : [],
        \   'xml'    : [],
        \   'html'   : [],
        \   'xhtml'  : [],
        \   'css'    : [],
        \ }
  "---------------------------------------------------------------------------
  if !empty(g:acp_user_defined_completion_func) &&
        \ !empty(g:acp_user_defined_meets)
    for key in keys(behavs)
      call add(behavs[key], {
            \   'command'      : "\<C-x>\<C-u>",
            \   'completefunc' : g:acp_user_defined_completion_func,
            \   'meets'        : g:acp_user_defined_meets,
            \   'repeat'       : 0,
            \ })
    endfor
  endif
  "---------------------------------------------------------------------------
  for key in keys(behavs)
    call add(behavs[key], {
          \   'command'      : "\<C-x>\<C-u>",
          \   'completefunc' : 's:CompleteForSnipmate',
          \   'meets'        : 's:MeetsForSnipmate',
          \   'closefunc'    : 's:OnPopupCloseForSnipmate',
          \   'repeat'       : 0,
          \ })
  endfor
  "---------------------------------------------------------------------------
  for key in keys(behavs)
    call add(behavs[key], {
          \   'command' : g:acp_keyword_command,
          \   'meets'   : 's:MeetsForKeyword',
          \   'repeat'  : 0,
          \ })
  endfor
  "---------------------------------------------------------------------------
  for key in keys(behavs)
    call add(behavs[key], {
          \   'command' : "\<C-x>\<C-f>",
          \   'meets'   : 's:MeetsForFile',
          \   'repeat'  : 1,
          \ })
  endfor
  "---------------------------------------------------------------------------
  call add(behavs.ruby, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForRubyOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.python, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForPythonOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.perl, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForPerlOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.xml, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForXmlOmni',
        \   'repeat'  : 1,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.html, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForHtmlOmni',
        \   'repeat'  : 1,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.xhtml, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForHtmlOmni',
        \   'repeat'  : 1,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.css, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 's:MeetsForCssOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  return behavs
endfunction

" }}}1
"=============================================================================
" INITIALIZATION {{{1

"-----------------------------------------------------------------------------
call s:DefineVariableDefault('g:acp_enable_at_startup', 1)
call s:DefineVariableDefault('g:acp_mapping_driven', 0)
call s:DefineVariableDefault('g:acp_ignorecase_option', 1)
call s:DefineVariableDefault('g:acp_complete_option', '.,w,b,k')
call s:DefineVariableDefault('g:acp_completeopt_preview', 0)
call s:DefineVariableDefault('g:acp_user_defined_completion_func', '')
call s:DefineVariableDefault('g:acp_user_defined_meets', '')
call s:DefineVariableDefault('g:acp_snipmate_length', -1)
call s:DefineVariableDefault('g:acp_keyword_command', "\<C-n>")
call s:DefineVariableDefault('g:acp_keyword_length', 3)
call s:DefineVariableDefault('g:acp_ignore_keywords', [])
call s:DefineVariableDefault('g:acp_file_length', 0)
call s:DefineVariableDefault('g:acp_ruby_omni_method_length', 0)
call s:DefineVariableDefault('g:acp_ruby_omni_symbol_length', 1)
call s:DefineVariableDefault('g:acp_python_omni_length', 0)
call s:DefineVariableDefault('g:acp_perl_omni_length', -1)
call s:DefineVariableDefault('g:acp_xml_omni_length', 0)
call s:DefineVariableDefault('g:acp_html_omni_length', 0)
call s:DefineVariableDefault('g:acp_css_omni_property_length', 1)
call s:DefineVariableDefault('g:acp_css_omni_value_length', 0)
call s:DefineVariableDefault('g:acp_behavior', {})
"-----------------------------------------------------------------------------
call extend(g:acp_behavior, s:MakeDefaultBehavior(), 'keep')
"-----------------------------------------------------------------------------
command! -bar -narg=0 AcpEnable  call acp#enable()
command! -bar -narg=0 AcpDisable call acp#disable()
command! -bar -narg=0 AcpLock    call acp#lock()
command! -bar -narg=0 AcpUnlock  call acp#unlock()
"-----------------------------------------------------------------------------
" legacy commands
command! -bar -narg=0 AutoComplPopEnable  AcpEnable
command! -bar -narg=0 AutoComplPopDisable AcpDisable
command! -bar -narg=0 AutoComplPopLock    AcpLock
command! -bar -narg=0 AutoComplPopUnlock  AcpUnlock
"-----------------------------------------------------------------------------
if g:acp_enable_at_startup
  AcpEnable
endif
"-----------------------------------------------------------------------------

" }}}1
"=============================================================================
" vim: set fdm=marker:
