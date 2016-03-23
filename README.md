# Canvas-Demo-Site-Generator
This script has been built to help provision demo sites in Canvas LMS
It will complete the following tasks for you
1) Complete SIS Import from folder of CSVs (users, courses, sections, accounts, enrollments)
2) Import demo user avatars based on CSV file
3) Create a new account level role called "principal"
4) Make the user with the sis_user_id "Principal" that role
5) Import example course content 
6) Switch on New UI
7) Switch on Commons

In order to make this script work you will need to have an Admin level token for the Canvas enviroment you are importing into
