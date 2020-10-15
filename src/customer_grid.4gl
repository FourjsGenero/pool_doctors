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
IMPORT FGL lib_ui

IMPORT FGL lib_settings

IMPORT FGL browser

IMPORT FGL customer_reading

SCHEMA pool_doctors

TYPE customer_type RECORD LIKE customer.*
DEFINE m_customer_rec customer_type

DEFINE w ui.window
DEFINE f ui.form

PRIVATE FUNCTION exception()
    WHENEVER ANY ERROR CALL lib_error.serious_error
END FUNCTION

---- Control ----
FUNCTION view_customer(l_cm_code)
    DEFINE l_cm_code LIKE customer.cm_code

    DEFINE l_ok BOOLEAN
    DEFINE l_err_text STRING

    LET m_customer_rec.cm_code = l_cm_code
    CALL db_select() RETURNING l_ok, l_err_text
    IF l_ok THEN
        OPEN WINDOW customer_grid WITH FORM "customer_grid"
        LET w = ui.Window.getCurrent()
        LET f = w.getForm()
        CALL ui_view()
        CLOSE WINDOW customer_grid
    ELSE
        CALL lib_ui.show_error(l_err_text, TRUE)
    END IF
    RETURN l_ok, l_err_text
END FUNCTION

---- User Interface ----
PRIVATE FUNCTION ui_view()
    DEFINE result STRING

    DEFINE l_url STRING

    DISPLAY BY NAME m_customer_rec.cm_code, m_customer_rec.cm_name, m_customer_rec.cm_email, m_customer_rec.cm_phone
    DISPLAY SFMT("%1\n%2\n%3\n%4",
            m_customer_rec.cm_addr1, m_customer_rec.cm_addr2, m_customer_rec.cm_addr3, m_customer_rec.cm_addr4)
        TO cm_address

    MENU ""
        BEFORE MENU
            CALL dialog.setActionActive("map", lib_settings.js_map > 0)
        ON ACTION cancel
            EXIT MENU

        ON ACTION readings
            CALL customer_reading.show(m_customer_rec.cm_code, m_customer_rec.cm_name)

        ON ACTION call
            LET result = 0
            TRY
                CALL ui.interface.frontcall("standard", "launchUrl", [SFMT("telprompt:%1", m_customer_rec.cm_phone)], [result])
            CATCH
                LET result = 1
            END TRY
            IF result > 0 THEN
                CALL lib_ui.show_error("Unable to call", TRUE)
            END IF

        ON ACTION sms
            TRY
                CALL ui.interface.frontcall("mobile", "composeSMS", [m_customer_rec.cm_phone, ""], result)
            CATCH
                CALL lib_ui.show_error("Unable to SMS", TRUE)
            END TRY

        ON ACTION email
            TRY
                CALL ui.interface.frontcall("mobile", "composeMail", [m_customer_rec.cm_email, "", ""], result)
            CATCH
                TRY
                    CALL ui.interface.frontcall("standard", "launchUrl", [SFMT("mailto:%1", m_customer_rec.cm_email)], [])
                CATCH
                    CALL lib_ui.show_error("Unable to email", TRUE)
                END TRY
            END TRY

        ON ACTION map
            -- There are many different ways to launch a map tool...

            CASE lib_settings.js_map
                WHEN 1
                    LET l_url = SFMT("geo:q=%1,%2", m_customer_rec.cm_lat, m_customer_rec.cm_lon)
                    CALL ui.interface.frontCall("standard", "launchUrl", l_url, [])
                WHEN 2
                    LET l_url = SFMT("https://www.google.com/maps/@%1,%2,12z", m_customer_rec.cm_lat, m_customer_rec.cm_lon)
                    CALL ui.interface.frontCall("standard", "launchUrl", l_url, [])
                WHEN 3
                    LET l_url = SFMT("comgooglemapsurl://maps.google.com/?q=@%1,%2", m_customer_rec.cm_lat, m_customer_rec.cm_lon)
                    CALL ui.interface.frontCall("standard", "launchUrl", l_url, [])
                OTHERWISE
                    CALL lib_ui.not_implemented_dialog()
            END CASE
    END MENU
END FUNCTION

---- Database ----
PRIVATE FUNCTION db_select()

    SELECT * INTO m_customer_rec.* FROM customer WHERE customer.cm_code = m_customer_rec.cm_code

    IF status = NOTFOUND THEN
        RETURN FALSE, "Customer record could not be found"
    END IF
    RETURN TRUE, ""
END FUNCTION
