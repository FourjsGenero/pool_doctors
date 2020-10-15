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
IMPORT os

DEFINE m_been_here_before BOOLEAN
DEFINE m_test_mode BOOLEAN
DEFINE m_filename STRING

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL serious_error
END FUNCTION

FUNCTION start_errorlog(l_filename)
    DEFINE l_filename STRING
    LET m_filename = l_filename
    CALL startlog(l_filename)
END FUNCTION

FUNCTION clear_errorlog()
    DEFINE l_ok BOOLEAN
    DEFINE l_error_text STRING
    LET l_ok = os.Path.delete(m_filename)
    LET l_error_text = IIF(l_ok, "Errorlog deleted", "Unable to delete errorlog")
    CALL startlog(m_filename)
    RETURN l_ok, l_error_text
END FUNCTION

FUNCTION view_errorlog()
    DEFINE l_text TEXT

    LOCATE l_text IN FILE m_filename
    MENU "Error Log" ATTRIBUTES(STYLE = "dialog", COMMENT = l_text)
        ON ACTION accept
            EXIT MENU
    END MENU
END FUNCTION

FUNCTION test_mode(l_test_mode)
    DEFINE l_test_mode BOOLEAN
    LET m_test_mode = l_test_mode
END FUNCTION

FUNCTION serious_error()

    -- Prevent endless loop occuring
    IF m_been_here_before THEN
        EXIT PROGRAM 2
    END IF
    LET m_been_here_before = TRUE

    MENU "Error" ATTRIBUTES(STYLE = "dialog", COMMENT = "An unexpected error has occured")
        ON ACTION accept

        ON ACTION viewlog ATTRIBUTES(TEXT = "View log")
            CALL view_errorlog()
    END MENU

    IF m_test_mode THEN
        LET m_been_here_before = FALSE
    ELSE
        EXIT PROGRAM 1
    END IF
END FUNCTION
