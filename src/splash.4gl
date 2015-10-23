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

import fgl job_sync
import fgl job_header_list



private function exception()
    whenever any error call serious_error
end function



function execute()
    open window splash with form "splash"    
    call splash()
    close window splash
end function




private function splash()
define splash string
define l_ok boolean
define l_err_text string
define l_result string

define l_outdata, l_outextras string

    call ui.interface.frontcall("webcomponent","call",["formonly.splash","setById","root",splash_html()],l_result)

    input by name splash attributes(unbuffered, without defaults=true, cancel=false, accept=false)
        before input
            -- set to false before deployment
            call dialog.setActionActive("settings", true)
        
        on action splash
            call job_header_list.list()

        on action settings
            menu "" attributes(style="popup")
                on action random attributes(text="Create Random Job")
                    -- simulate the creation of a new job
                    call job_sync.create_random_job() returning l_ok, l_err_text
                    if l_ok then
                        call show_message(l_err_text,true)
                    else
                        call show_error(l_err_text, true)
                    end if
                on action delete_all attributes(text= "Delete ALL Job Data")
                    call delete_database() returning l_ok, l_err_text
                    if l_ok then
                        call show_message(l_err_text,true)
                    else
                        call show_error(l_err_text, true)
                    end if
                on action force_error attributes(text= "Force Error")  -- used to test error handling
                    display 1/0        -- this will make program stop with error
                on action cancel
                    exit menu
            end menu
                
        on action refresh 
            call job_sync.execute() returning l_ok, l_err_text
            if l_ok then
                call show_message("Sync Result\n"||l_err_text,true)
            else
                call show_error("Sync Result\n"||l_err_text,true)
            end if

        on action help 
           #call browser.browser("Help","https://demo.4js.com/gas/help.htm")
           call browser.browser("Help","http://bj.bluejs.com/pool_doctors/help.html")
           -- this could use a PDF but the PDF is slow to load when it contains images
           -- could also consider embedding PDF inside application
            #call browser.browser("help","https://demo.4js.com/gas/help.pdf")
            
        on action video
            call browser.browser("Intro","https://www.youtube.com/watch?v=dM9rKLB7_2o")

        on action about
            call show_message(about_text(), true)
            
    end input
    if int_flag then
        let int_flag = 0
    end if
end function



private function delete_database()
    if confirm_dialog("Are you sure you want to delete ALL job data?") then
        begin work
        try 
            delete from job_detail where 1=1
            delete from job_note where 1=1
            delete from job_photo where 1=1
            delete from job_timesheet where 1=1
            delete from job_header where 1=1
        catch
            rollback work
            return false, "Unable to delete job data"
        end try
        commit work
        return true, "ALL job data deleted"
    else
        return false, "Deletion of all job data cancelled"
    end if
end function



private function splash_html()
    -- considerchanging image for different devices
    return "<div style=\"position: absolute; left: 0%; top: 0%; height: 100%; width: 100% \"><img src=\"splash_iphone5.jpg\" height=\"100%\" width=\"100%\"  onclick=\"execAction('splash','')\" /></div>"
end function



private function about_text()
define sb base.StringBuffer

    let sb = base.StringBuffer.create()
    call sb.append("This application was produced by Blue J Software Pty Ltd (www.bluejs.com)")
    call sb.append("\n\n")
    call sb.append("It is intended to illustrate a working application using Genero Mobile.")
    call sb.append("\n\n")
    call sb.append("For a modified derivative of this application to meet your requirements, or any other Genero Mobile consultancy or development, please contact us at sales@bluejs.com")
    return sb.toString()
end function
