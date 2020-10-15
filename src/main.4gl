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

IMPORT FGL home

MAIN
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT NO WRAP

    CALL lib_error.start_errorlog("pool_doctors.log")
    WHENEVER ANY ERROR CALL lib_error.serious_error

    CALL ui.Interface.setText("Pool Doctors")
    CALL ui.Interface.setImage("splash_320x480") -- Not logo_transparent as hard to see in chromeBar

    CALL ui.Interface.loadStyles("pool_doctors")
    CALL ui.Interface.loadActionDefaults("pool_doctors")

    CALL init_database()

    CALL lib_settings.populate()
    CLOSE WINDOW screen
    CALL home.execute()

END MAIN

PRIVATE FUNCTION init_database()
    DEFINE l_database_exists BOOLEAN
    DEFINE ch base.channel

    -- First attempt to connect to database.
    -- If this successed we know the database exists
    LET l_database_exists = TRUE
    TRY
        CONNECT TO "pool_doctors"
    CATCH
        LET l_database_exists = FALSE
    END TRY

    IF l_database_exists THEN
        -- Database exists.
        -- In later versions of app, upgrade database here

        -- We are done and can carry on with app
        RETURN
    END IF

    -- If get to there, there is no database, need to create it
    -- Warning if in development mode
    IF NOT base.Application.isMobile() THEN
        IF NOT lib_ui.confirm_dialog("About to create database.  Are you sure?") THEN
            CALL errorlog("User cancelled database creation")
            EXIT PROGRAM 1
        END IF
    END IF

    -- Database doesn't exist so we need to create a new empty database file
    -- Should use FGL_GETRESOURCE(dbi.database.pool_doctors.source) here instead
    -- of hard-coded filename
    TRY
        LET ch = base.Channel.create()
        CALL ch.openFile("pool_doctors.db", "w")
        CALL ch.close()
    CATCH
        CALL errorlog("Unable to create empty database")
        EXIT PROGRAM 1
    END TRY

    -- Connect to new empty database
    TRY
        CONNECT TO "pool_doctors"
    CATCH
        -- Something has gone wrong
        CALL errorlog("Unable to connect to empty database")
        EXIT PROGRAM 1
    END TRY

    -- Create Database
    EXECUTE IMMEDIATE "create table customer (
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
    EXECUTE IMMEDIATE "create table job_detail (
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
    EXECUTE IMMEDIATE "create table job_header (
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
    EXECUTE IMMEDIATE "create table job_note (
        jn_code char(10),
        jn_idx integer,
        jn_note varchar(10000),
        jn_when datetime year to minute,
        constraint sqlite_autoindex_job_note_1 primary key(jn_code, jn_idx),
        constraint fk_job_note_job_header_1 foreign key(jn_code)
            references job_header(jh_code))"
    EXECUTE IMMEDIATE "create table job_photo (
        jp_code char(10) not null,
        jp_idx integer not null,
        jp_photo varchar(160),
        jp_when datetime year to minute,
        jp_lat decimal(11,5),
        jp_lon decimal(11,5),
        jp_text varchar(10000),
        constraint sqlite_autoindex_job_photo_1 primary key(jp_code, jp_idx),
        constraint fk_job_photo_job_header_1 foreign key(jp_code)
            references job_header(jh_code))"
    EXECUTE IMMEDIATE "create table job_timesheet (
        jt_code char(10) not null,
        jt_idx integer not null,
        jt_start datetime year to minute,
        jt_finish datetime year to minute,
        jt_charge_code_id char(2),
        jt_text varchar(10000),
        constraint sqlite_autoindex_job_timesheet_1 primary key(jt_code, jt_idx),
        constraint fk_job_timesheet_job_header_1 foreign key(jt_code)
            references job_header(jh_code))"
    EXECUTE IMMEDIATE "create table product (
        pr_code char(10) not null,
        pr_desc varchar(255) not null,
        pr_barcode varchar(30),
        constraint sqlite_autoindex_product_1 primary key(pr_code))"
    EXECUTE IMMEDIATE "create table job_settings (
        js_url char(40),
        js_group char(40),
        js_map smallint)"

    EXECUTE IMMEDIATE "create unique index idx_customer_pk on customer(cm_code)"
    EXECUTE IMMEDIATE "create index idx_customer_name on customer(cm_name)"
    EXECUTE IMMEDIATE "create unique index idx_job_detail_pk on job_detail(jd_code, jd_line)"
    EXECUTE IMMEDIATE "create index idx_job_detail_product on job_detail(jd_product)"
    EXECUTE IMMEDIATE "create unique index idx_job_header_pk on job_header(jh_code)"
    EXECUTE IMMEDIATE "create index idx_job_header_customer on job_header(jh_customer)"
    EXECUTE IMMEDIATE "create unique index idx_job_note_pk on job_note(jn_code, jn_idx)"
    EXECUTE IMMEDIATE "create unique index idx_job_photo_pk on job_photo(jp_code, jp_idx)"
    EXECUTE IMMEDIATE "create unique index idx_job_timesheet_pk on job_timesheet(jt_code, jt_idx)"
    EXECUTE IMMEDIATE "create unique index idx_product_pk on product(pr_code)"
    EXECUTE IMMEDIATE "create index idx_product_name on product(pr_desc)"

    -- insert initial data if required
    #insert into job_settings(js_url, js_group) values("https://demo.4js.com/gas","pool_doctors_server")
    INSERT INTO job_settings(js_url, js_group, js_map) VALUES("https://demo.4js.com/gas", "pool_doctors_server", 1)

END FUNCTION
