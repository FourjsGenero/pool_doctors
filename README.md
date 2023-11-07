# pool_doctors

The Pool Doctors GeneroMobile demo application.  This is intended to be used in conjunction with the https://github.com/FourjsGenero/pool_doctors_server repository that will contain the back end database and web services that support the mobile application.

## Introduction

This program was first written to coincide with the initial release of Genero Mobile.  Its aim was to show a Genero application working in a mobile environment (iOS or Android) and to incorporate as many GeneroMobile features as possible as well as being something a Genero developer would recognise.  It is NOT a fully fledged production ready application, it is missing a lot of business rules that you would expect to see in such an application, this is a deliberate design decision so that the new code syntax was not hidden too much,  for instance there is no logic preventing two or more devices updating the same rows of data.

The application is called Pool Doctors as that was an example of a technician/courier driver role that was a scenario we dreamt up that meet the Design Brief.  Hopefully after running the app you can visualise that by substituting in different data for the customer and product tables, this app could equally have been called Fridge Doctor, TV Doctor, Car Doctor etc.

## Design Brief

Application used by an employee at a remote site

Use small device to record performance of service and/or delivery of goods

The application should be generic and applicable to ...
* Technician – record work performed
* Courier Driver – proof of delivery

Use as many device features as possible
* Camera
* Barcode Reader
* GPS + Map
* Phone/SMS/Email
* Signature Capture
* Database + Synchronization via Web Services
* 4gl syntax including INPUT+Grid, INPUT+Web Component, DISPLAY ARRAY+Table or ScrollGrid, MENU, MENU STYLE="dialog"
* Include a number of different widgets including DATEEDIT, COMBOBOX, CHECKBOX to demonstrate the use of Native widgets.

## Business Process

The basic business process of the application is
* customer makes contact with head office and requests some work to be done, a job is created
* job is assigned to technician
* technician uses sync process (Web Services) on device to get the jobs that have been allocated to them
* they use device to make contact (phone, email and/ot text) with the customer and navigate to the site
* use the device to record the work done
* use the device to record the labour involved
* use the device to document the work done with photos
* use the device to document the work done with notes
* use the device to get the customer to sign off on the job
* technician uses sync process on device (Web Services) to get the job data uplaoded to the central server. 


    (Small change to update language associated with repository)

