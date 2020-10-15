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

IMPORT FGL lib_error

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

-- Standard dialog to display messages.  Set second parameter to true to
-- force acknowledgement
FUNCTION show_message(l_message_text, l_acknowledge)
    DEFINE l_message_text STRING
    DEFINE l_acknowledge BOOLEAN

    IF l_acknowledge THEN
        IF l_message_text.getlength() > 0 THEN
            MENU "Info" ATTRIBUTES(STYLE = "dialog", COMMENT = l_message_text, IMAGE = "fa-info")
                ON ACTION accept
                    EXIT MENU
            END MENU
        END IF
    ELSE
        MESSAGE l_message_text
        CALL ui.Interface.refresh() -- force display to current window
    END IF
END FUNCTION

-- Standard dialog to display errors.  Set second parameter to true to
-- force acknowledgement
FUNCTION show_error(l_error_text, l_acknowledge)
    DEFINE l_error_text STRING
    DEFINE l_acknowledge BOOLEAN

    IF l_acknowledge THEN
        IF l_error_text.getlength() > 0 THEN
            MENU "Error" ATTRIBUTES(STYLE = "dialog", COMMENT = l_error_text, IMAGE = "fa-stop")
                ON ACTION accept
                    EXIT MENU
            END MENU
        END IF
    ELSE
        ERROR l_error_text
        CALL ui.interface.refresh() -- force display to current window
    END IF
END FUNCTION

FUNCTION not_implemented_dialog()
    CALL show_message("This has not yet been implemented", TRUE)
END FUNCTION

FUNCTION confirm_dialog(l_text)
    DEFINE l_text STRING
    DEFINE l_ok BOOLEAN

    -- yes, no dialog with default answer = no, i.e. user has to
    -- explicitly choose yes to do something destructive

    LET l_ok = FALSE
    MENU "Warning" ATTRIBUTES(STYLE = "dialog", COMMENT = l_text, IMAGE = "fa-warning")
        COMMAND "No"
            LET l_ok = FALSE
        COMMAND "Yes"
            LET l_ok = TRUE
    END MENU
    RETURN l_ok
END FUNCTION

FUNCTION confirm_cancel_dialog()
    RETURN confirm_dialog("Are you sure you want to cancel?  You will lose your changes")
END FUNCTION
