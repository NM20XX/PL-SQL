/*******************************************************************************
Program Name   : REPLACE_STRING
Description    : This procedure will replace a pattern in a file with new value.
Input          : p_upd_from   --pattern to remove/replace
                 p_upd_to     --pattern to replace with
                 p_filename_i --input file name
                 p_filename_o --output file name
                 p_update_beginning --(DEFAULT 'N')

Output         : p_filename_o
                 log_p_filename_i --log file to list the rows that have changed

*******************************************************************************/
PROCEDURE REPLACE_STRING(
 p_upd_from   IN VARCHAR2, 
 p_upd_to     IN VARCHAR2,
 p_filename_i IN VARCHAR2,
 p_filename_o IN VARCHAR2, 
 p_update_beginning IN VARCHAR2 DEFAULT 'N'
 )
 
AS
  lv_file_i     UTL_FILE.FILE_TYPE; -- input file
  lv_file_o     UTL_FILE.FILE_TYPE; -- output file
  lv_file_log   UTL_FILE.FILE_TYPE; -- log file to list the rows that have changed
  lv_idx        PLS_INTEGER := 0;   -- to check if the pattern exist in the middle of the line
  lv_idx_begin  PLS_INTEGER := 0;   -- to check if the pattern exist at the beginning of the line
  lv_line_orig  VARCHAR2(1000);     -- original line
  lv_line_upd   VARCHAR2(1000);     -- updated line
  lv_line_l     VARCHAR2(1000);
  lv_line_r     VARCHAR2(1000);
  lv_len_line   NUMBER;
  lv_len_str    NUMBER;
  lv_upd_b_from VARCHAR2(300);      --pattern at the beginning of the line
  lv_upd_b_to   VARCHAR2(300);      --pattern to replace with at the beginning
  lv_upd_e_from VARCHAR2(300);      --pattern at the end of the line
  lv_upd_e_to   VARCHAR2(300);      --pattern to replace with at the end
  lv_i          PLS_INTEGER := 0;   --total lines processed
  lv_upd_cnt    PLS_INTEGER := 0;   --lines updated
  lv_upd        VARCHAR2(1) := 'N';

BEGIN
  lv_file_i   := UTL_FILE.FOPEN('OUT',p_filename_i,'R'); --Reading the input file
  lv_file_o   := UTL_FILE.FOPEN('OUT',p_filename_o,'W');
  lv_file_log := UTL_FILE.FOPEN('OUT','log_'||p_filename_i,'W');
  --Removing delimiter for the begin and end of the string
  lv_upd_b_from := SUBSTR(p_upd_from,2);
  lv_upd_b_to   := SUBSTR(p_upd_to,2);
  lv_upd_e_from := SUBSTR(p_upd_from,1,(LENGTH(p_upd_from)-1));
  lv_upd_e_to   := SUBSTR(p_upd_to,1,(LENGTH(p_upd_to)-1));
  lv_len_str    := (LENGTH(p_upd_from)-2); --Removing both the delimiter

  UTL_FILE.PUT_LINE(lv_file_log, 'Below lines have been changed:');

  --This loop will read the from the input file and update when required
  LOOP
  BEGIN
    UTL_FILE.GET_LINE(lv_file_i, lv_line_orig);
    lv_i := lv_i+1;
    lv_idx := INSTR(lv_line_orig,p_upd_from);
    lv_idx_begin := INSTR(lv_line_orig,lv_upd_b_from);
    lv_line_upd  :=lv_line_orig;
    lv_upd := 'N';

    --Beginning of the line
    IF lv_idx_begin = 1 THEN
      IF p_update_beginning = 'N' THEN
        UTL_FILE.PUT_LINE(lv_file_log,'ERROR: Pattern at the beginning; NO ACTION taken: '''||lv_line_orig||'''');
      ELSE
        lv_line_r  :=SUBSTR(lv_line_upd,(LENGTH(lv_upd_b_from)+1)); --right part of the string
        lv_line_upd:=lv_upd_b_to||lv_line_r; --concat
        lv_upd :='Y';
      END IF;
    END IF;

    --Middle of the line
    IF lv_idx>0 THEN
      lv_line_upd := REPLACE(lv_line_upd, p_upd_from, p_upd_to);
      --2nd time check in case the pattern exists in consecutive fields which is not been updated in the first REPLACE operation(Ex: $.$.$)
      lv_line_upd := REPLACE(lv_line_upd, p_upd_from, p_upd_to);
      lv_upd :='Y';
    END IF;

    --End of the line (Ex:'IN2|02|.')
    lv_len_line := LENGTH(lv_line_upd);
    lv_line_r := SUBSTR(lv_line_upd,(lv_len_line-lv_len_str));

    IF lv_line_r = lv_upd_e_from THEN --the pattern exist at the end of the line
      lv_line_l  :=SUBSTR(lv_line_upd,1,(lv_len_line-lv_len_str-1)); --left part of the string
      lv_line_upd:=lv_line_l;
      lv_upd :='Y';
    END IF;

    --Write to the output file
    UTL_FILE.PUT_LINE(lv_file_o,lv_line_upd);

    --Write to the log file
    IF lv_upd = 'Y' THEN
      lv_upd_cnt:= lv_upd_cnt + 1; --increase update count
      UTL_FILE.PUT_LINE(lv_file_log,lv_line_orig);
    END IF;

  EXCEPTION WHEN NO_DATA_FOUND THEN --Input file reach the end
    UTL_FILE.FCLOSE(lv_file_i);
    EXIT;
  END;
  END LOOP;

  IF UTL_FILE.IS_OPEN(lv_file_i) THEN UTL_FILE.FCLOSE(lv_file_i); END IF; --Close input file
  UTL_FILE.FCLOSE(lv_file_o); --Close output file

  UTL_FILE.PUT_LINE(lv_file_log,'Total count of lines processed: '||lv_i);
  UTL_FILE.PUT_LINE(lv_file_log,'Count of lines updated succesfully: '||lv_upd_cnt);
  UTL_FILE.PUT_LINE(lv_file_log,'Program,REPLACE_STRING ('||p_upd_from||', '||p_upd_to||', '||p_filename_i||', '||p_filename_o||', '||p_update_beginning||')');
  UTL_FILE.FCLOSE(lv_file_log);

END REPLACE_STRING;