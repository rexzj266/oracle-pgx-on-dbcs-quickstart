-- Drop HR Objects
-- https://livesql.oracle.com/apex/livesql/file/content_GWKN7QJBHHC8F1RJTEB47AFOY.html

-- Copyright

begin
   dbms_output.put_line('Copyright (c) 2018, Oracle and/or its affiliates.  All rights reserved.  ');
   dbms_output.put_line('Permission is hereby granted, free of charge, to any person obtaining ');
   dbms_output.put_line('a copy of this software and associated documentation files (the ');
   dbms_output.put_line('"Software"), to deal in the Software without restriction, including ');
   dbms_output.put_line('without limitation the rights to use, copy, modify, merge, publish, ');
   dbms_output.put_line('distribute, sublicense, and/or sell copies of the Software, and to ');
   dbms_output.put_line('permit persons to whom the Software is furnished to do so, subject to ');
   dbms_output.put_line('the following conditions: ');
   dbms_output.put_line(' ');
   dbms_output.put_line('The above copyright notice and this permission notice shall be ');
   dbms_output.put_line('included in all copies or substantial portions of the Software. ');
   dbms_output.put_line(' ');
   dbms_output.put_line('THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, ');
   dbms_output.put_line('EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF ');
   dbms_output.put_line('MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND ');
   dbms_output.put_line('NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE ');
   dbms_output.put_line('LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION ');
   dbms_output.put_line('OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION ');
   dbms_output.put_line('WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. ');
end;
/

DROP PROCEDURE add_job_history
/

DROP PROCEDURE secure_dml
/

DROP VIEW emp_details_view
/

DROP SEQUENCE departments_seq
/

DROP SEQUENCE employees_seq
/

DROP SEQUENCE locations_seq
/

DROP TABLE regions CASCADE CONSTRAINTS
/

DROP TABLE departments CASCADE CONSTRAINTS
/

DROP TABLE locations CASCADE CONSTRAINTS
/

DROP TABLE jobs CASCADE CONSTRAINTS
/

DROP TABLE job_history CASCADE CONSTRAINTS
/

DROP TABLE employees CASCADE CONSTRAINTS
/

DROP TABLE countries CASCADE CONSTRAINTS
/


DROP VIEW works_as CASCADE CONSTRAINTS;
DROP VIEW works_at CASCADE CONSTRAINTS;
DROP VIEW managed_by CASCADE CONSTRAINTS;
