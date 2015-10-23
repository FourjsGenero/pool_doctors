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

import fgl splash

main
    options field order form
    options input no wrap 
    
    call start_errorlog("pool_doctors.log")
    whenever any error call serious_error
    
    call ui.Interface.setText("Pool Doctors")
    call ui.Interface.setImage("logo_transparent")
    
    call ui.Interface.loadStyles("pool_doctors")
    case frontend() 
        when "GMA"   call ui.Interface.loadActionDefaults("pool_doctors_android")
        when "GMI"   call ui.Interface.loadActionDefaults("pool_doctors_ios")
        otherwise    call ui.Interface.loadActionDefaults("pool_doctors")
    end case
    
    call init_database()

    call splash.execute()

end main



private function init_database()
define l_database_exists boolean
define ch base.channel

    -- First attempt to connect to database.
    -- If this successed we know the database exists
    LET l_database_exists = true
    try
        connect to "pool_doctors"
    catch
        let l_database_exists = false
    end try

    
    if l_database_exists then
        -- Database exists.
        -- In later versions of app, upgrade database here

        -- We are done and can carry on with app
        return
    end if

    -- If get to there, there is no database, need to create it
    -- Warning if in development mode
    if not base.Application.isMobile() then
        if not confirm_dialog("About to create database.  Are you sure?") then
            call errorlog("User cancelled database creation")
            exit program 1
        end if
    end if

    -- Database doesn't exist so we need to create a new empty database file
    -- Should use FGL_GETRESOURCE(dbi.database.pool_doctors.source) here instead
    -- of hard-coded filename
    try
        let ch = base.Channel.create()
        call ch.openFile("pool_doctors.db","w")
        call ch.close()
    catch
        call errorlog("Unable to create empty database")
        exit program 1
    end try

    -- Connect to new empty database
    try
        connect to "pool_doctors"
    catch
        -- Something has gone wrong
        call errorlog("Unable to connect to empty database")
        exit program 1
    end try

    -- Create Database
    execute immediate "create table customer (
        cm_code char(10) not null,
        cm_name varchar(255) not null,
        cm_email varchar(30),
        cm_phone varchar(20),
        cm_addr1 varchar(40),
        cm_addr2 varchar(40),
        cm_addr3 varchar(40),
        cm_addr4 varchar(40),
        cm_lat decimal(11,5),
        cm_lon decimal(11,5),
        cm_postcode char(10),
        cm_rep char(2),
        constraint sqlite_autoindex_customer_1 primary key(cm_code))"
    execute immediate "create table job_detail (
        jd_code char(10) not null,
        jd_line integer not null,
        jd_product char(10),
        jd_qty decimal(11,2),
        jd_status char(1),
        constraint sqlite_autoindex_job_detail_1 primary key(jd_code, jd_line),
        constraint fk_job_detail_job_header_1 foreign key(jd_code)
            references job_header(jh_code),
        constraint fk_job_detail_product_2 foreign key(jd_product)
            references product(pr_code))"
    execute immediate "create table job_header (
        jh_code char(10) not null,
        jh_customer char(10),
        jh_date_created datetime year to minute,
        jh_status char(1),
        jh_address1 varchar(40),
        jh_address2 varchar(40),
        jh_address3 varchar(40),
        jh_address4 varchar(40),
        jh_contact varchar(40),
        jh_phone varchar(20),
        jh_task_notes varchar(200),
        jh_signature varchar(10000),
        jh_date_signed datetime year to minute,
        jh_name_signed varchar(40),
        constraint sqlite_autoindex_job_header_1 primary key(jh_code),
        constraint fk_job_header_customer_1 foreign key(jh_customer)
            references customer(cm_code))"
    execute immediate "create table job_note (
        jn_code char(10),
        jn_idx integer,
        jn_note varchar(10000),
        jn_when datetime year to minute,
        constraint sqlite_autoindex_job_note_1 primary key(jn_code, jn_idx),
        constraint fk_job_note_job_header_1 foreign key(jn_code)
            references job_header(jh_code))"
    execute immediate "create table job_photo (
        jp_code char(10) not null,
        jp_idx integer not null,
        jp_photo varchar(160),
        jp_when datetime year to minute,
        jp_lat decimal(11,5),
        jp_lon decimal(11,5),
        jp_photo_data byte,
        jp_text varchar(10000),
        constraint sqlite_autoindex_job_photo_1 primary key(jp_code, jp_idx),
        constraint fk_job_photo_job_header_1 foreign key(jp_code)
            references job_header(jh_code))"
    execute immediate "create table job_timesheet (
        jt_code char(10) not null,
        jt_idx integer not null,
        jt_start datetime year to minute,
        jt_finish datetime year to minute,
        jt_charge_code_id char(2),
        jt_text varchar(10000),
        constraint sqlite_autoindex_job_timesheet_1 primary key(jt_code, jt_idx),
        constraint fk_job_timesheet_job_header_1 foreign key(jt_code)
            references job_header(jh_code))"
    execute immediate "create table product (
        pr_code char(10) not null,
        pr_desc varchar(255) not null,
        pr_barcode varchar(30),
        constraint sqlite_autoindex_product_1 primary key(pr_code))"

    execute immediate "create unique index idx_customer_pk on customer(cm_code)"
    execute immediate "create index idx_customer_name on customer(cm_name)"
    execute immediate "create unique index idx_job_detail_pk on job_detail(jd_code, jd_line)"
    execute immediate "create index idx_job_detail_product on job_detail(jd_product)"
    execute immediate "create unique index idx_job_header_pk on job_header(jh_code)"
    execute immediate "create index idx_job_header_customer on job_header(jh_customer)"
    execute immediate "create unique index idx_job_note_pk on job_note(jn_code, jn_idx)"
    execute immediate "create unique index idx_job_photo_pk on job_photo(jp_code, jp_idx)"
    execute immediate "create unique index idx_job_timesheet_pk on job_timesheet(jt_code, jt_idx)"
    execute immediate "create unique index idx_product_pk on product(pr_code)"
    execute immediate "create index idx_product_name on product(pr_desc)"

    -- insert initial data if required
end function