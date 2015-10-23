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

import fgl browser

schema pool_doctors

type customer_type record like customer.*
define m_customer_rec customer_type  

define w ui.window
define f ui.form



private function exception()
    whenever any error call serious_error
end function



---- Control ----
function view_customer(l_cm_code)
define l_cm_code like customer.cm_code

define l_ok boolean
define l_err_text string

    let m_customer_rec.cm_code = l_cm_code
    call db_select() returning l_ok, l_err_text
    if l_ok then
        open window customer_grid with form "customer_grid"
        let w= ui.Window.getCurrent()
        let f= w.getForm()
        call ui_view()
        close window customer_grid
    else
        call show_error(l_err_text, true)
    end if
    return l_ok, l_err_text
end function






---- User Interface ----
private function ui_view()
define result string

define l_front_end string
define l_url string

    display by name m_customer_rec.cm_code, m_customer_rec.cm_name, m_customer_rec.cm_email, m_customer_rec.cm_phone
    display sfmt("%1\n%2\n%3\n%4",  m_customer_rec.cm_addr1, m_customer_rec.cm_addr2, m_customer_rec.cm_addr3, m_customer_rec.cm_addr4) to cm_address

    menu "" 
        on action cancel
            exit menu

        on action call
            let result = 0
            try
                call ui.interface.frontcall("standard","launchUrl",[sfmt("telprompt:%1", m_customer_rec.cm_phone)],[result])
            catch
                let result = 1
            end try
            if result > 0 then
                call show_error("Unable to call", true)
            end if
            
        on action sms
            try
                call ui.interface.frontcall("mobile","composeSMS",[m_customer_rec.cm_phone,""],result)
            catch
                call show_error("Unable to SMS", true)
            end try
            
        on action email
            try
                call ui.interface.frontcall("mobile","composeMail",[m_customer_rec.cm_email,"",""],result)
            catch
                call show_error("Unable to email", true)
            end try

        on action map
            let l_url = sfmt("http://maps.google.com/maps?q=%1,%2",m_customer_rec.cm_lat, m_customer_rec.cm_lon)
            call browser.browser(m_customer_rec.cm_name, l_url)
    end menu
end function



---- Database ----
private function db_select()
    
    select * 
    into m_customer_rec.*
    from customer 
    where customer.cm_code = m_customer_rec.cm_code

    if status=notfound then
        return false, "Customer record could not be found"
    end if
    return true, ""
end function