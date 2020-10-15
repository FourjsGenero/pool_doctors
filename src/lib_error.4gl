#
#       (c) Copyright 2014, Blue J Software - www.bluejs.com
#
#       MIT License (http://www.opensource.org/licenses/mit-license.php)
#
#       Permission is hereby granted, free of charge, to any person
#       obtaining a copy of this software and associated documentation
#       files (the "Software"), to deal in the Software without restriction,
#       including without limitation the rights to use, copy, modify, merge,
#       publish, distribute, sublicense, and/or sell copies of the Software,
#       and to permit persons to whom the Software is furnished to do so,
#       subject to the following conditions:
#
#       The above copyright notice and this permission notice shall be
#       included in all copies or substantial portions of the Software.
#
#       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#       EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#       OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#       NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
#       BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
#       ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#       CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#       THE SOFTWARE.

# no import fgl here, this module needs to be as foolproof as possible
import os

define m_been_here_before boolean
define m_test_mode boolean
define m_filename string



private function exception()
    whenever any error call serious_error
end function



function start_errorlog(l_filename)
define l_filename string
    let m_filename = l_filename
    call startlog(l_filename)
end function



function clear_errorlog()
define l_ok boolean
define l_error_text string
    let l_ok = os.Path.delete(m_filename) 
    let l_error_text = iif(l_ok, "Errorlog deleted", "Unable to delete errorlog")
    call startlog(m_filename)
    return l_ok, l_error_text
end function



function view_errorlog()
define l_text text

    locate l_text in file m_filename   
    menu "Error Log" attributes(style="dialog", comment=l_text)
        on action accept
            exit menu
    end menu
end function


function test_mode(l_test_mode)
define l_test_mode boolean
    let m_test_mode = l_test_mode
end function



function serious_error()

    -- Prevent endless loop occuring
    if m_been_here_before then
        exit program 2
    end if
    let m_been_here_before = true
    
    menu "Error" attributes(style="dialog", comment="An unexpected error has occured")
        on action accept
            
        on action viewlog attributes(text="View log")
            call view_errorlog()                        
    end menu

    if m_test_mode then
        let m_been_here_before = false
    else
        exit program 1
    end if
end function