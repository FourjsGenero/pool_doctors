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

schema "pool_doctors"

type product_type record like product.*

define m_product_arr dynamic array of product_type 
define m_arr dynamic array of record
    major string,
    minor string,
    img string
end record

define w ui.window
define f ui.form

define m_toggle string
define m_filter string
define m_orderby string



private function exception()
    whenever any error call serious_error
end function



function select()
define l_pr_code like product.pr_code

define l_ok boolean
define l_err_text string

    let m_toggle = nvl(m_toggle,"pr_code")
    
    open window product_list with form "product_list" attributes(type=popup)#style="dialog")
    let w= ui.window.getcurrent()
    let f = w.getform()
    call f.loadtoolbar("pool_doctors_list")

    call db_populate() returning l_ok, l_err_text
    if l_ok then
        call ui_populate()
        let l_pr_code = ui_list()
    else
        call show_error(l_err_text, true)
    end if
    
    close window product_list
    
    return l_pr_code
end function



private function ui_populate()
define i integer

    call m_arr.clear()
    for i = 1 to m_product_arr.getLength()
        call ui_populate_row(i)
    end for
end function



private function ui_populate_row(l_row)
define l_row integer

    case m_toggle
         when "pr_code"
            let m_arr[l_row].major = m_product_arr[l_row].pr_code clipped
            let m_arr[l_row].minor = m_product_arr[l_row].pr_desc clipped
            let m_arr[l_row].img = ""
        when "pr_desc"
            let m_arr[l_row].major = m_product_arr[l_row].pr_desc clipped
            let m_arr[l_row].minor = m_product_arr[l_row].pr_code clipped
            let m_arr[l_row].img = ""
     end case
end function



private function ui_list()
define l_ok boolean
define l_err_text string

define l_popup_value_select boolean

    display array m_arr to scr.* attributes(unbuffered,  accessorytype=checkmark, doubleclick=accept)

        on action toggle
            let l_popup_value_select = true
            menu "Display Detail" attributes(style="popup")
                on action pr_code attributes(text="Code")
                    let m_toggle = "pr_code"
                on action pr_desc attributes(text="Description")
                    let m_toggle = "pr_desc"
                on action cancel
                    let l_popup_value_select = false
            end menu
            if l_popup_value_select then
                call ui_populate()
            end if

        on action order
            let l_popup_value_select = true
            menu "Order" attributes(style="popup")
                on action pr_code attributes(text="Code")
                    let m_orderby = "pr_code"
                on action pr_desc attributes(text="Description")
                    let m_orderby = "pr_desc"
                on action cancel
                    let l_popup_value_select = false
            end menu
            if l_popup_value_select then
                call db_populate() returning l_ok, l_err_text
                if l_ok then
                    call ui_populate()
                else
                    call show_error(l_err_text, true)
                end if
            end if
            
    end display
    if int_flag then
        let int_flag = 0
        return null
    else
        return m_product_arr[arr_curr()].pr_code
    end if
end function



private function db_populate()
define l_sql string
define l_rec product_type

    try
        call m_product_arr.clear()
        let l_sql = "select * from product"
        if m_filter.getLength() > 0 then
            let l_sql = l_sql, " where ", m_filter
        end if
        if m_orderby.getlength() > 0 then
            let l_sql = l_sql, " order by ", m_orderby
        end if
        declare product_list_curs cursor from l_sql
        foreach product_list_curs into l_rec.*
            let m_product_arr[m_product_arr.getLength()+1].* = l_rec.*
        end foreach
    catch
        return false, sqlca.sqlerrm
    end try
    return true, ""
end function