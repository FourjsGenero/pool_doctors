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
 
private function exception()
    whenever any error call serious_error
end function



-- Return the frontend, GMI or GMA
function frontend()
define l_frontend string
    call ui.Interface.frontCall("standard","feinfo","fename",l_frontend)
    return l_frontend
end function



-- Standard dialog to display messages.  Set second parameter to true to
-- force acknowledgement
function show_message(l_message_text, l_acknowledge) 
define l_message_text string
define l_acknowledge boolean

    if l_acknowledge then
        if l_message_text.getlength() > 0 then
            #call fgl_winmessage("Info", l_message_text,"info")
            menu "Info" attributes(style="dialog", comment=l_message_text)
               on action accept
                  exit menu
            end menu
        end if
    else
        message l_message_text
        call ui.Interface.refresh() -- force display to current window
    end if
end function



-- Standard dialog to display errors.  Set second parameter to true to
-- force acknowledgement
function show_error(l_error_text, l_acknowledge)
define l_error_text string
define l_acknowledge boolean

    if l_acknowledge then
        if l_error_text.getlength() > 0 then
            call fgl_winmessage("Error", l_error_text,"stop")
        end if
    else
        error l_error_text
        call ui.interface.refresh() -- force display to current window
    end if
end function



function not_implemented_dialog()
    call show_message("This has not yet been implemented",true)
end function



function confirm_dialog(l_text)
define l_text string

    -- yes, no dialog with default answer = no, i.e. user has to
    -- explicitly choose yes to do something destructive
    return fgl_winquestion("Warning", l_text,"no","no|yes","",0) == "yes"
end function
    



function confirm_cancel_dialog()
    return confirm_dialog("Are you sure you want to cancel?  You will lose your changes")
end function



