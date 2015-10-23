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

import com
import util

import fgl lib_job_header
import fgl lib_customer

schema pool_doctors

define m_count record
    customer integer,
    product integer,
    job_get integer,
    job_put integer,
    job_deleted integer
end record

constant rep string =  "01" -- replace with unique identifier for device?



private function exception()
    whenever any error call serious_error
end function



function execute()
define l_ok boolean
define l_err_text string

    if not test_connected() then
        return false, "Must be connected to internet"
    end if

    initialize m_count.* to null
    let l_ok = true
    if l_ok then
        call refresh_product() returning l_ok, l_err_text
    end if
    if l_ok then 
        call refresh_customer() returning l_ok, l_err_text
    end if
    if l_ok then
        call refresh_job_header() returning l_ok, l_err_text
    end if
    if l_ok then
        call send_jobs() returning l_ok, l_err_text
    end if
    if l_ok then
        call delete_old_jobs() returning l_ok, l_err_text
    end if
    if l_ok then
        let l_err_text = sfmt("%1 new jobs loaded\n%2 product records refreshed\n %3 customer records refresh\n%4 completed jobs uploaded\n%5 old jobs deleted", m_count.job_get, m_count.product, m_count.customer, m_count.job_put, m_count.job_deleted)
    end if
    return l_ok, l_err_text
end function



function create_random_job()
define l_ok boolean
define l_err_text string

define l_url string

define req com.HttpRequest
define resp com.HttpResponse

define s string

    if not test_connected() then
        return false, "Must be connected to internet"
    end if

    #let l_url = "https://demo.4js.com/gas/ws/r/pool_doctors/service/createRandomJob"
    let l_url = "http://bj.bluejs.com/bj/ws/r/bj/pool_doctors_server/createRandomJob"

    let req = com.HttpRequest.create(l_url)
    
    call req.setHeader("Content-Type","application/JSON")
    call req.setMethod("POST")

    call req.doTextRequest(rep using "&&")

    let resp = req.getResponse()
   
    if resp.getStatusCode() = 200 then
        let s = resp.getTextResponse()
        let l_ok = true
        let l_err_text = sfmt("New job created %1", s)
    else
        let l_ok = false
        let l_err_text = "Error creating job\n", resp.getStatusDescription()
    end if
    return l_ok, l_err_text
end function



private function refresh_customer()
define l_url string

define req com.HttpRequest
define resp com.HttpResponse

define j util.JSONObject
define s string

define j_resp record
    count float,
    results dynamic array of record
        cm_addr1 string,
        cm_addr2 string,
        cm_addr3 string,
        cm_addr4 string,
        cm_code string,
        cm_email string,
        cm_lat float,
        cm_lon float,
        cm_name string,
        cm_phone string,
        cm_postcode string,
        cm_rep string
    end record
end record
define i integer
define l_customer_rec record like customer.*

    #let l_url = "https://demo.4js.com/gas/ws/r/pool_doctors/service/getCustomers"
    let l_url = "http://bj.bluejs.com/bj/ws/r/bj/pool_doctors_server/getCustomers"

    let req = com.HttpRequest.create(l_url)
    call req.doRequest()

    let resp = req.getResponse()
    if resp.getStatusCode() = 200 then
        #ok
    else
        return false, resp.getStatusDescription()
    end if
        
    let s = resp.getTextResponse()
    let j = util.JSONObject.parse(s)
    --display util.json.proposetype(s)
    call j.toFGL(j_resp)

    begin work
    try
        delete from customer where 1=1
        for i = 1 to j_resp.results.getLength()
            let l_customer_rec.cm_addr1 = j_resp.results[i].cm_addr1
            let l_customer_rec.cm_addr2 = j_resp.results[i].cm_addr2
            let l_customer_rec.cm_addr3 = j_resp.results[i].cm_addr3
            let l_customer_rec.cm_addr4 = j_resp.results[i].cm_addr4
            let l_customer_rec.cm_code = j_resp.results[i].cm_code
            let l_customer_rec.cm_email = j_resp.results[i].cm_email
            let l_customer_rec.cm_lat= j_resp.results[i].cm_lat
            let l_customer_rec.cm_lon = j_resp.results[i].cm_lon
            let l_customer_rec.cm_name = j_resp.results[i].cm_name
            let l_customer_rec.cm_phone = j_resp.results[i].cm_phone
            let l_customer_rec.cm_postcode = j_resp.results[i].cm_postcode
            let l_customer_rec.cm_rep = j_resp.results[i].cm_rep
       
            insert into customer values(l_customer_rec.*)
        end for
        let m_count.customer = j_resp.results.getLength()
    catch
        rollback work
        return false, sqlca.sqlerrm
    end try
    commit work
    return true, ""
end function



private function refresh_product()
define l_url string

define req com.HttpRequest
define resp com.HttpResponse

define j util.JSONObject
define s string

define j_resp record
    count float,
    results dynamic array of record
        pr_barcode string,
        pr_code string,
        pr_name string
    end record
end record
define i integer
define l_product_rec record like product.*

    #let l_url = "https://demo.4js.com/gas/ws/r/pool_doctors/service/getProducts"
    let l_url = "http://bj.bluejs.com/bj/ws/r/bj/pool_doctors_server/getProducts"

    let req = com.HttpRequest.create(l_url)
    call req.doRequest()
    let resp = req.getResponse()
    if resp.getStatusCode() = 200 then
        #ok
    else
        return false, resp.getStatusDescription()
    end if
    
    let s = resp.getTextResponse()
    #display util.json.proposetype(s)
    let j = util.JSONObject.parse(s)
    call j.toFGL(j_resp)
    begin work
    try
        delete from product where 1=1
        for i = 1 to j_resp.results.getLength()
            let l_product_rec.pr_barcode = j_resp.results[i].pr_barcode
            let l_product_rec.pr_code = j_resp.results[i].pr_code
            let l_product_rec.pr_desc = j_resp.results[i].pr_name
            insert into product values (l_product_rec.*)
        end for
        let m_count.product = j_resp.results.getLength()
    catch
        rollback work
        return false, sqlca.sqlerrm
    end try
    commit work
    return true, ""
end function



private function refresh_job_header()
define l_url string

define req com.HttpRequest
define resp com.HttpResponse

define j util.JSONObject
define s string

define j_resp record
    count float,
    results dynamic array of record
        jh_address1 string,
        jh_address2 string,
        jh_address3 string,
        jh_address4 string,
        jh_code string,
        jh_contact string,
        jh_customer string,
        jh_date_created string,
        jh_date_signed string,
        jh_phone string,
        jh_signature string,
        jh_status string,
        jh_task_notes string
    end record
end record
define i integer
define l_job_header_rec record like job_header.*

    let m_count.job_get = 0

    -- This gets jobs for customers with repcode = 01
    #let l_url = "https://demo.4js.com/gas/ws/r/pool_doctors/service/getJobsForRep"
    let l_url = "http://bj.bluejs.com/bj/ws/r/bj/pool_doctors_server/getJobsForRep"
    
    let req = com.HttpRequest.create(l_url)
    call req.setHeader("Content-Type","application/JSON")
    call req.setMethod("POST")
    call req.doTextRequest(rep using "&&")

    let resp = req.getResponse()

    if resp.getStatusCode() = 200 then
        #ok
    else
        return false, resp.getStatusDescription()
    end if
    
    let s = resp.getTextResponse()
   
    --display util.json.proposetype(s)
    let j = util.JSONObject.parse(s)
    call j.toFGL(j_resp)
    begin work
    try
        for i = 1 to j_resp.results.getLength()
            initialize l_job_header_rec.* to null
            -- only load job if it isn't in our system, and doesn't belong to rep
            let l_job_header_rec.jh_code = j_resp.results[i].jh_code
       
            if  lib_job_header.exists(l_job_header_rec.jh_code) then
                -- job is in database already
                continue for
            end if

            if j_resp.results[i].jh_status = "X" then
                -- job is complete
                continue for
            end if
        
            let l_job_header_rec.jh_customer = j_resp.results[i].jh_customer
            let l_job_header_rec.jh_address1 = j_resp.results[i].jh_address1
            let l_job_header_rec.jh_address2 = j_resp.results[i].jh_address2
            let l_job_header_rec.jh_address3 = j_resp.results[i].jh_address3
            let l_job_header_rec.jh_address4 = j_resp.results[i].jh_address4
            let l_job_header_rec.jh_contact = j_resp.results[i].jh_contact
            let l_job_header_rec.jh_date_created = j_resp.results[i].jh_date_created.subString(1,16)
            let l_job_header_rec.jh_phone = j_resp.results[i].jh_phone
            let l_job_header_rec.jh_status = j_resp.results[i].jh_status
            let l_job_header_rec.jh_task_notes = j_resp.results[i].jh_task_notes

            let m_count.job_get = m_count.job_get + 1
            insert into job_header values (l_job_header_rec.*)
        end for
    catch
        rollback work
        return false, ""
    end try
    commit work
    return true, ""
end function



private function send_jobs()
define l_ok boolean
define l_err_text string

define l_url string

define req com.HttpRequest
define resp com.HttpResponse

-- case of record/field names important for FGL to JSON process 
define j_send record
        Customer string,
        JobLines dynamic array of record
            jd_code string,
            jd_line float,
            jd_product string,
            jd_qty float,
            jd_status string
        end record,
        Notes dynamic array of record
            jn_code string,
            jn_idx float,
            jn_note string,
            jn_when string
        end record,
        Photos dynamic array of record
            jp_code string,
            jp_idx float,
            jp_lat float,
            jp_lon float,
            jp_photo string,
            jp_image byte,
            jp_when string
        end record,
        TimeSheets dynamic array of record
            jt_charge_code_id string,
            jt_code string,
            jt_finish string,
            jt_idx float,
            jt_start string,
            jt_text string
        end record,
        cm_rep string,
        jh_address1 string,
        jh_address2 string,
        jh_address3 string,
        jh_address4 string,
        jh_code string,
        jh_contact string,
        jh_customer string,
        jh_date_created string,
        jh_date_signed string,
        jh_name_signed string,
        jh_phone string,
        jh_signature string,
        jh_status string,
        jh_task_notes string
end record

define l_sql string

define l_job_header record like job_header.*
define l_job_detail record like job_detail.*
define l_job_note record like job_note.*
define l_job_photo record like job_photo.*
define l_job_timesheet record like job_timesheet.*   
define i integer


    #let l_url = "https://demo.4js.com/gas/ws/r/pool_doctors/service/putJob"
    let l_url = "http://bj.bluejs.com/bj/ws/r/bj/pool_doctors_server/putJob"

    let l_sql = "select * from job_header where jh_status = 'X'"
    prepare job_header_text from l_sql
    declare job_header_curs cursor for job_header_text

    let l_sql = "select * from job_detail where jd_code= ? order by jd_line"
    prepare job_detail_text from l_sql
    declare job_detail_curs cursor for job_detail_text

    let l_sql = "select * from job_note where jn_code= ? order by jn_idx"
    prepare job_note_text from l_sql
    declare job_note_curs cursor for job_note_text

    let l_sql = "select * from job_photo where jp_code= ? order by jp_idx"
    prepare job_photo_text from l_sql
    declare job_photo_curs cursor for job_photo_text

    let l_sql = "select * from job_timesheet where jt_code= ? order by jt_idx"
    prepare job_timesheet_text from l_sql
    declare job_timesheet_curs cursor for job_timesheet_text

    let m_count.job_put = 0
    let l_ok = true

    foreach job_header_curs into l_job_header.*
        let req = com.HttpRequest.create(l_url)
        
        call req.setHeader("Content-Type","application/JSON")
        call req.setMethod("POST")
        call req.setTimeOut(60)

        call req.setVersion("1.0") -- added this as available in GM 1.1 and allows fastcgi

        initialize j_send.* to null
        let j_send.cm_rep = rep
        let j_send.jh_address1 = l_job_header.jh_address1
        let j_send.jh_address2 = l_job_header.jh_address2
        let j_send.jh_address3 = l_job_header.jh_address3
        let j_send.jh_address4 = l_job_header.jh_address4
        let j_send.jh_code = l_job_header.jh_code
        let j_send.jh_contact = l_job_header.jh_contact
        let j_send.jh_customer = l_job_header.jh_customer
        let j_send.jh_date_created = l_job_header.jh_date_created
        let j_send.jh_date_signed = l_job_header.jh_date_signed
        let j_send.jh_name_signed = l_job_header.jh_name_signed
        let j_send.jh_phone = l_job_header.jh_phone
        let j_send.jh_signature = l_job_header.jh_signature
        let j_send.jh_status = l_job_header.jh_status
        let j_send.jh_task_notes = l_job_header.jh_task_notes

        let i = 0
        foreach job_detail_curs using l_job_header.jh_code into l_job_detail.*
            let i = i + 1
            let j_send.joblines[i].jd_code = l_job_detail.jd_code
            let j_send.joblines[i].jd_line = l_job_detail.jd_line
            let j_send.joblines[i].jd_product = l_job_detail.jd_product
            let j_send.joblines[i].jd_qty = l_job_detail.jd_qty
            let j_send.joblines[i].jd_status = l_job_detail.jd_status
        end foreach

        let i = 0
        foreach job_note_curs using l_job_header.jh_code into l_job_note.*
            let i = i + 1
            let j_send.notes[i].jn_code = l_job_note.jn_code
            let j_send.notes[i].jn_idx = l_job_note.jn_idx
            let j_send.notes[i].jn_note = l_job_note.jn_note
            let j_send.notes[i].jn_when = l_job_note.jn_when
        end foreach

        let i = 0
        locate l_job_photo.jp_photo_data in file "photo.tmp"
        foreach job_photo_curs using l_job_header.jh_code into l_job_photo.*
            let i = i + 1
            let j_send.photos[i].jp_code = l_job_photo.jp_code
            let j_send.photos[i].jp_idx = l_job_photo.jp_idx
            let j_send.photos[i].jp_lat = l_job_photo.jp_lat            
            let j_send.photos[i].jp_lon = l_job_photo.jp_lon
            let j_send.photos[i].jp_photo = l_job_photo.jp_photo
            let j_send.photos[i].jp_when = l_job_photo.jp_when
            locate j_send.photos[i].jp_image in memory
            call j_send.photos[i].jp_image.readfile("photo.tmp")
        end foreach

        let i = 0
        
        foreach job_timesheet_curs using l_job_header.jh_code into l_job_timesheet.*
            let i =i + 1
            let j_send.timesheets[i].jt_code = l_job_timesheet.jt_code
            let j_send.timesheets[i].jt_idx = l_job_timesheet.jt_idx
            let j_send.timesheets[i].jt_start = l_job_timesheet.jt_start
            let j_send.timesheets[i].jt_finish = l_job_timesheet.jt_finish
            let j_send.timesheets[i].jt_charge_code_id = l_job_timesheet.jt_charge_code_id
            let j_send.timesheets[i].jt_text = l_job_timesheet.jt_text
        end foreach

        call req.doTextRequest(util.JSON.stringify(j_send))
      
        let resp = req.getResponse()
   
        if resp.getStatusCode() = 200 then
            let l_ok = true
            let m_count.job_put = m_count.job_put + 1
        else
            let l_ok = false
            let l_err_text = "Error syncing Job:", l_job_header.jh_code, " ", resp.getStatusCode(), " ", resp.getStatusDescription()
            exit foreach
        end if
    end foreach
    if not l_ok then
        return false, l_err_text
    end if
    return true, ""
end function



private function delete_old_jobs()
define l_sql string
define l_jh_code like job_header.jh_code

define l_cutoff_date like job_header.jh_date_signed
define l_days_to_keep_str string
define l_days_to_keep interval day to day

    -- delete jobs that are more than 7 days old and have been synced
    -- generate interval variable of 7 days and delete form current date
    let l_days_to_keep_str = "7"
    let l_days_to_keep  = l_days_to_keep_str

    let l_cutoff_date = current year to minute
    let l_cutoff_date = l_cutoff_date - l_days_to_keep

    let l_sql = "select jh_code from job_header where jh_status = 'X' and jh_date_signed <= ? "
    let m_count.job_deleted = 0
  
    begin work
    try
        prepare delete_old_jobs_text from l_sql
        declare delete_old_jobs_curs cursor for delete_old_jobs_text
        foreach delete_old_jobs_curs using l_cutoff_date into l_jh_code
            delete from job_detail where jd_code = l_jh_code
            delete from job_note where jn_code = l_jh_code
            delete from job_photo where jp_code = l_jh_code
            delete from job_timesheet where jt_code = l_jh_code
            delete from job_header where jh_code = l_jh_code
            let m_count.job_deleted = m_count.job_deleted + 1
        end foreach
    catch
        rollback work
        let m_count.job_deleted = 0
        return false, sqlca.sqlerrm
    end try
    commit work
    return true, ""
end function



private function test_connected()
define l_ipaddress string

    if not base.Application.isMobile() then
        return true
    end if
    call ui.interface.frontCall("standard","feinfo","ip", l_ipaddress)
    
    -- TODO: This line is required due to bug that prevented the refresh icon appearing
    -- Having this line makes the refresh icon appear
    CALL ui.Interface.refresh()  
    
    if l_ipaddress.getLength() > 0 then
        return true
    end if
    return false
end function
