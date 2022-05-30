let g:sessions_dir = "~/.vim/sessions/"

function! ListSessions(A,L,P) abort
    return system('ls ' . g:sessions_dir)
endfunction

function! HandleSession(action, filename, check=1) abort
    " cd g:sessions_dir
    let _cwd = getcwd()
    exec 'cd ' . g:sessions_dir

    " prevent path traversal
    let filename = fnamemodify(a:filename, ':t')
    " append .vim extension if not provided
    if fnamemodify(filename, ':e') !=? 'vim'
        let filename .= '.vim'
    endif

    if a:action ==? 'save'
        " confirm overwrite if saving session that exist, bypass for autosave
        if a:check && filereadable(filename)
            if confirm('Session "' . filename . '" already exists. Overwrite?'
                        \, "&Yes\n&No") != 1
                redraw | echom 'Save aborted.'
                return
            endif
        endif
        exec 'mksession! ' . g:sessions_dir . filename
        redraw | echom 'Saved session "' . filename . '"'
    elseif a:action ==? 'restore'
        if filereadable(filename)
            exec 'source ' . g:sessions_dir . filename
            redraw | echom 'Restored session "' . filename . '"'
        else
            echohl ErrorMsg
            redraw | echo 'Session does not exist, unable to restore!'
            echohl None
        endif
    elseif a:action ==? 'delete'
        if delete(filename) == 0
            redraw | echom 'Deleted session "' . filename . '"'
            " unset v:this_session if deleted so we don't trigger autosave
            if fnamemodify(v:this_session, ':t') ==? filename
                let v:this_session = ''
            endif
        else
            echohl ErrorMsg
            redraw | echom 'Session does not exist, unable to delete!'
            echohl None
        endif
    endif

    " cd -
    exec 'cd ' . _cwd
endfunction 

function! AutosaveOnQuit() abort
    if len(v:this_session) > 0
        let filename = fnamemodify(v:this_session, ':t')
        call HandleSession('save', filename, 0)
    endif
endfunction

autocmd VimLeave * call AutosaveOnQuit()

command! -complete=custom,ListSessions -nargs=1 SaveSession
    \ call HandleSession('save', <f-args>) 

command! -complete=custom,ListSessions -nargs=1 RestoreSession
    \ call HandleSession('restore', <f-args>)

command! -complete=custom,ListSessions -nargs=1 DeleteSession
    \ call HandleSession('delete', <f-args>)

