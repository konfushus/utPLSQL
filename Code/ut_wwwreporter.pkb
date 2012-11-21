CREATE OR REPLACE PACKAGE BODY utWWWreporter
IS

/************************************************************************
GNU General Public License for utPLSQL

Copyright (C) 2000-2003
Steven Feuerstein and the utPLSQL Project
(steven@stevenfeuerstein.com)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see license.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
************************************************************************
$Log: ut_htmlreporter.pkb,v $
Revision 1.2  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.1  2004/07/14 17:01:57  chrisrimmer
Added first version of pluggable reporter packages


************************************************************************/
type tVar2000 is table of varchar2(2000) index by binary_integer;

gn_nb number := 0;
gv_version varchar2(100) := 'iAS Web GUI for utPLSQL version 0.3';
gv_author varchar2(100) := '<a href="http://www.laclasse.com/">by Pierre-Gilles Levallois</a>';
gv_current_testing varchar2(2000) := '-';
gn_current_nb_failure number := 0;
gn_current_nb_success number := 0;
gn_total_fail number := 0;
gn_total_success number := 0;
tHtml tVar2000;

----------------------------------------------------------------------------
-- add to html table.
----------------------------------------------------------------------------
procedure addComment(pStr varchar2) is
begin
    tHtml(nvl(tHtml.last, 0) + 1) := pStr;
end addComment;

----------------------------------------------------------------------------
-- displays html in the report.
----------------------------------------------------------------------------
procedure displaySupplement is
    i number;
begin
  htp.p('<fieldset id="supplement"><legend>user comments & parameters</legend>');
    i := tHtml.first;
    while (i is not null) loop
        htp.p(tHtml(i));
        i := tHtml.next(i);
    end loop;
  htp.P('</fieldset>');
end displaySupplement;

----------------------------------------------------------------------------
-- displayPercentage : displays percentage total of successed tests
----------------------------------------------------------------------------
procedure displayPercentage is
begin
    htp.p('<script>
    var pct = "'||to_char(round(100* gn_total_success / (gn_total_success + gn_total_fail), 2))||'% passed.";
    o = document.getElementById("totalpct");
    o.innerHTML=pct;
    </script>');
exception
when others then
    htp.p(sqlerrm);
end;
----------------------------------------------------------------------------
-- header of the html page.
----------------------------------------------------------------------------
procedure header is
begin
    htp.p('<div id="head"><span id="version">'||gv_version||'</span>&nbsp;<span id="author">'||gv_author||'</span></div>');
end header;

----------------------------------------------------------------------------
-- Show the config for a user
----------------------------------------------------------------------------
PROCEDURE showconfig (username_in IN VARCHAR2 := NULL)
   IS
     lv_user varchar2(50) := utconfig.tester;
   BEGIN
   /*
      --Get the configuration
      rec := utconfig.config (v_user);
      --Now show it
      pl ('=============================================================');
      pl ('utPLSQL Configuration for ' || v_user);
      pl ('   Directory: ' || rec.DIRECTORY);
      pl ('   Autcompile? ' || rec.autocompile);
      pl ('   Manual test registration? ' || rec.registertest);
      pl ('   Prefix = ' || rec.prefix);
      pl ('   Default reporter     = ' || rec.reporter);
	  pl ('   ----- File Output settings:');
      pl ('   Output directory: ' || rec.filedir);
      pl ('   User prefix     = ' || rec.fileuserprefix);
      pl ('   Include progname? ' || rec.fileincprogname);
      pl ('   Date format     = ' || rec.filedateformat);
      pl ('   File extension  = ' || rec.fileextension);
      pl ('   ----- End File Output settings');
      pl ('=============================================================');
	  */
	   htp.p('<div id="conf">');
	   htp.p('<h5 class="title">&nbsp;&#155;&nbsp;Configuration for '||lv_user||'</h5>');
	   htp.p('<ul>');
	   htp.p('<li>Directory : ' || utconfig.dir||'</li>');
	   htp.p('<li>Autcompile ? ' || utplsql.bool2vc(utconfig.autocompiling)||'</li>');
	   htp.p('<li>Manual test registration ? ' || utplsql.bool2vc(utconfig.registeringtest)||'</li>');
	   htp.p('<li>Prefix =  ' || utconfig.userprefix||'</li>');
	   htp.p('<li>Default reporter = ' || utconfig.getreporter||'</li>');
	   htp.p('<li>Showing failure only ? ' || utplsql.bool2vc(utconfig.showingfailuresonly)||'</li>');
	   htp.p('</ul>');
	   htp.p('</div>');
   END showconfig;

--------------------------------------------------------------------------------
-- css : put your own values for css 
--------------------------------------------------------------------------------
procedure css is
begin
  htp.p('<style>
		  body, table, tr, td {margin: 0; padding: 0;font-family: Verdana,Arial,Helvetica,sans-serif;font-size: 11px;text-decoration: none;color: black;}
		  #container{margin:3px;}
          #totalpct {font-size:13px;margin-left:20px;}
		  .coulfond {background-color: #cfcfbc;}					  
		  .warn, .title {color:orange;font-weight:bold;}
		  .ok {color:green;font-weight:bold;}
		  .ko {color:red;font-weight:bold;}
		  table#tabData1 {border:1px solid black; clear:both;}
          table#tabData1 tr td {padding:1px;}
		  .nb{font-size:6px; text-align:right;vertical-align:top;}
          .status, .counttest {vertical-align:top;}
		  .Pair {background-color: #E9e9e7;}
		  .Impair {background-color: #F5FCC5;}
          .counttest {text-align:right;border-top:1px dotted #C0C0C0;}
		  #foot, #head, .head {background-color:#666666; color:white; height:16px; text-align:center;padding-top:2px;}
		  #version{font-weight:bold}
		  #author, #author a {color:lightblue;}
		  #conf {width:40%;float:right;border:1px solid orange;margin:5px 0px 5px 0px;}
          fieldset {width:55%;}
          fieldset * {padding-left:20px;}
          fieldset legend {padding-left:5px;font-weight:bold;}
		</style>
		');
end css;
--------------------------------------------------------------------------------
-- open : opening web page 
--------------------------------------------------------------------------------
   PROCEDURE open
   IS
   BEGIN
      htp.p('<html><head><title>test results</title>');
	  css;
	  htp.p('</head><body class="coulfond"><center>
		  		  <table width="960" border="0" cellpadding="0" cellspacing="0">
                     <tr>
					   <td style="background-color:white;">
					     <div id="container"><form>');
	  header;
	  showconfig;
   END open;

--------------------------------------------------------------------------------
-- close : closing web page 
--------------------------------------------------------------------------------
   PROCEDURE close
   IS
   BEGIN
	 htp.p('<div id="foot"><span>'||to_char(sysdate, 'Day DD Month - HH24:MI:SS')||'</span></div>');
	 htp.p('</form></div></td></tr></table></body></html>');
   END close;

--------------------------------------------------------------------------------
-- pl : printing a string 
--------------------------------------------------------------------------------
   PROCEDURE pl (str VARCHAR2)
   IS
   BEGIN
     htp.p(replace(str, chr(10), '<br/>')||'<br/>');
   END pl;

--------------------------------------------------------------------------------
-- pl_success : printing "Success" flag 
--------------------------------------------------------------------------------
   PROCEDURE pl_success
   IS
   BEGIN
     htp.p('<span class="ok">Success</span>');
   END pl_success;

--------------------------------------------------------------------------------
-- pl_failure : printing "FAILURE" flag 
--------------------------------------------------------------------------------
   PROCEDURE pl_failure
   IS
   BEGIN
     htp.p('<span class="ko">FAILURE</span>');
   END pl_failure;

--------------------------------------------------------------------------------
-- before_results : printing some stuff before printing results 
--------------------------------------------------------------------------------
   PROCEDURE before_results(run_id IN utr_outcome.run_id%TYPE)
   IS
   BEGIN
      utWWWreporter.open;
      htp.p('<h1>'|| utplsql.currpkg || ': ');
      IF utresult.success (run_id) THEN
        pl_success;
      ELSE
        pl_failure;
      END IF;
      htp.p('<span id="totalpct"></span>');
      htp.P('</h1>');
      displaySupplement();
      htp.p('<br/>Results:<br/>');
      htp.p('<table id="tabData1" name="tabData1">');
      htp.p('<tr><th>#</th><th>Status</th><th>Description</th><th>% Success</th></tr>');

   END before_results;
  
--------------------------------------------------------------------------------
-- counttests : printing in a of tests after each tested function or proc. 
--------------------------------------------------------------------------------
procedure counttests is
begin
    htp.p('<tr>');
    -- this is the end of a program testing.
    htp.p('<td colspan="4" class="counttest">'||
    to_char(round(100* gn_current_nb_success / (gn_current_nb_success + gn_current_nb_failure), 2))||
    '%</td>');
    htp.p('</tr>');
    gn_total_fail := gn_total_fail + gn_current_nb_failure;
    gn_total_success := gn_total_success + gn_current_nb_success;
end;
 
--------------------------------------------------------------------------------
-- smartTitle : printing in a smart way the name of the tested proc. or Func. 
--------------------------------------------------------------------------------
   procedure smartTitle is
	  new_testing varchar2(2000);
   begin
	 new_testing := substr(utreport.outcome.description, 1, instr(utreport.outcome.description, ':')-1);
	 if ( new_testing != gv_current_testing ) then
        -- the first time, no testcount...
        if ( gv_current_testing != '-' ) then
            countTests();
        end if; 
        gv_current_testing := new_testing;
        gn_current_nb_failure := 0;
        gn_current_nb_success := 0;
        -- New program testing
        htp.p('<tr>');
            htp.p('<td colspan="4"><span class="title"><b>&nbsp;&#155;&nbsp;Testing program "'||new_testing||'"...</b></span></td>');
        htp.P('</tr>');
	 end if;
   end smartTitle;

--------------------------------------------------------------------------------
-- smartDesc : returning a smart printing of an failure or success description. 
--------------------------------------------------------------------------------
   function smartDesc(pdesc varchar2) return varchar2 is
      my_desc varchar2(4000) := substr(pdesc, instr(pdesc, ':')+1, length(pdesc));
	  i number := 1;
	  tag varchar2(20);
	  lb_tag_opened boolean := false;
	  offset number;
   begin
     while i < length(my_desc) loop
	   if (substr(my_desc,i,1) = '"') then
	     if (lb_tag_opened) then
		   tag := '</b>';
		   offset := - 1;
		   lb_tag_opened := false;
	       my_desc := substr(my_desc,1,i + offset) || tag || substr(my_desc,i, length(my_desc));
		   i := i + length(tag);
		 else
		   tag := '<b>';
		   lb_tag_opened := true;
		   offset := 1;
	       my_desc := substr(my_desc,1,i) || tag || substr(my_desc,i + offset, length(my_desc));
		 end if;
	   end if;
	   i := i + 1;
	 end loop;
	 
     return my_desc;
   end smartDesc;

--------------------------------------------------------------------------------
-- show_failure : printing details of a failure 
--------------------------------------------------------------------------------
   PROCEDURE show_failure
   IS
   BEGIN
     smartTitle;     
	 htp.p('<tr><td class="nb">'||gn_nb||'</td><td>');
     pl_failure;
     htp.p('</td><td>' || smartDesc(utreport.outcome.description) || '</td></tr>');
   END show_failure;

--------------------------------------------------------------------------------
-- show_result : printing results
--------------------------------------------------------------------------------
   PROCEDURE show_result
   IS
     odd_even varchar2(100);
   BEGIN
     if ( MOD(gn_nb, 2) = 1) then
	   odd_even := 'impair';
	 else
	   odd_even := 'pair';
	 end if;
	 
	 smartTitle;
	 
     htp.p ('<tr class="'||odd_even||'"><td class="nb">'||gn_nb||'</td><td class="status">');

     IF utreport.outcome.status = 'SUCCESS' THEN
       pl_success;
       gn_current_nb_success := gn_current_nb_success + 1;
     ELSE
       pl_failure;
       gn_current_nb_failure := gn_current_nb_failure + 1;
     END IF;
	 
     htp.p('</td><td>' || smartDesc(utreport.outcome.description) || '</td></tr>');
	 gn_nb := gn_nb + 1;
   END show_result;

--------------------------------------------------------------------------------
-- after_results : printing some stuff after results are printed
--------------------------------------------------------------------------------
   procedure after_results(run_id in utr_outcome.run_id%type)
   is
   begin
     counttests();
     htp.p('</table>');
     displayPercentage();
   end after_results;

--------------------------------------------------------------------------------
-- before_errors : printing some stuff before printing errors 
--------------------------------------------------------------------------------
   PROCEDURE before_errors(run_id IN utr_error.run_id%TYPE)
   IS
   
     cursor c_err is
	 select e.errlevel, e.errcode, e.description 
	 from utr_error e;
	 lr_err c_err%rowtype;
	
   BEGIN
     htp.p('<br/>Errors:<br/><table id="tabData1">');
     htp.p('<tr><th>Error Level</th><th>Error Code</th><th>Description</th></tr>');
	 
	     open c_err;
         loop
            fetch c_err into lr_err;
            exit when c_err%notfound;
			htp.p('<tr><td>'||lr_err.errlevel||'</td><td>'||lr_err.errcode||'</td><td>'||lr_err.description||'</td></tr>');
         end loop;
         close c_err;
      
   END before_errors;

--------------------------------------------------------------------------------
-- show_error : printing errors
--------------------------------------------------------------------------------
   PROCEDURE show_error
   IS
   BEGIN
    utreport.pl ('<tr><td>' || utreport.error.errlevel ||
         '</td><td>' || utreport.error.errcode ||
         '</td><td>' || utreport.error.errtext || '</td></tr>');
   END show_error;

--------------------------------------------------------------------------------
-- after_errors : printing some stuff after errors are printed
--------------------------------------------------------------------------------
   PROCEDURE after_errors(run_id IN utr_error.run_id%TYPE)
   IS
   BEGIN
     htp.p('</table>');
--	 utWWWreporter.close;
   END after_errors;

END utWWWreporter;
/
