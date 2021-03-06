'Required for statistical purposes==========================================================================================
name_of_script = "ADMIN - FSET SANCTIONS.vbs"
start_time = timer
STATS_counter = 1                     	'sets the stats counter at one
STATS_manualtime = 120                	'manual run time in seconds
STATS_denomination = "C"       		'M is for each MEMBER
'END OF stats block=========================================================================================================

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN	   'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF use_master_branch = TRUE THEN			   'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/Hennepin-County/MAXIS-scripts/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else											'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/Hennepin-County/MAXIS-scripts/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		End if
		SET req = CreateObject("Msxml2.XMLHttp.6.0")				'Creates an object to get a FuncLib_URL
		req.open "GET", FuncLib_URL, FALSE							'Attempts to open the FuncLib_URL
		req.send													'Sends request
		IF req.Status = 200 THEN									'200 means great success
			Set fso = CreateObject("Scripting.FileSystemObject")	'Creates an FSO
			Execute req.responseText								'Executes the script code
		ELSE														'Error message
			critical_error_msgbox = MsgBox ("Something has gone wrong. The Functions Library code stored on GitHub was not able to be reached." & vbNewLine & vbNewLine &_
                                            "FuncLib URL: " & FuncLib_URL & vbNewLine & vbNewLine &_
                                            "The script has stopped. Please check your Internet connection. Consult a scripts administrator with any questions.", _
                                            vbOKonly + vbCritical, "BlueZone Scripts Critical Error")
            StopScript
		END IF
	ELSE
		FuncLib_URL = "C:\MAXIS-scripts\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================

'CHANGELOG BLOCK ===========================================================================================================
'Starts by defining a changelog array
changelog = array()

'INSERT ACTUAL CHANGES HERE, WITH PARAMETERS DATE, DESCRIPTION, AND SCRIPTWRITER. **ENSURE THE MOST RECENT CHANGE GOES ON TOP!!**
'Example: call changelog_update("01/01/2000", "The script has been updated to fix a typo on the initial dialog.", "Jane Public, Oak County")
CALL changelog_update("10/22/2018", "Changed output about orientation letters from a YES/NO to the date of the orientation on the letter.", "Ilse Ferris, Hennepin County")
CALL changelog_update("09/17/2018", "Add extra handling for case noting sanctions for more than one HH member.", "Ilse Ferris, Hennepin County")
CALL changelog_update("09/12/2018", "Auto approval functionality complete. Added comments and removed testing code.", "Ilse Ferris, Hennepin County")
CALL changelog_update("06/09/2018", "Made several updates to support using a single master sanction list while processing. Also added text to case note if the case has been identified as potentially homeless for unfit for employment expansion exemption.", "Ilse Ferris, Hennepin County")
CALL changelog_update("05/21/2018", "Added additional handling for when a WCOM exists in the add WCOM option.", "Ilse Ferris, Hennepin County")
CALL changelog_update("05/19/2018", "Added searching for LETR dates when don't match the orientation date.", "Ilse Ferris, Hennepin County")
CALL changelog_update("05/10/2018", "Streamlined text in worker comments based on feedback provided by DHS.", "Ilse Ferris, Hennepin County")
call changelog_update("05/07/2018", "Initial version.", "Ilse Ferris, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'----------------------------------------------------------------------------------------------------Custom Functions
Function HCRE_panel_bypass() 
	'handling for cases that do not have a completed HCRE panel
	PF3		'exits PROG to prommpt HCRE if HCRE insn't complete
	Do
		EMReadscreen HCRE_panel_check, 4, 2, 50
		If HCRE_panel_check = "HCRE" then
			PF10	'exists edit mode in cases where HCRE isn't complete for a member
			PF3
		END IF
	Loop until HCRE_panel_check <> "HCRE"
End Function

'----------------------------------------------------------------------------------------------------DIALOG
'The dialog is defined in the loop as it can change as buttons are pressed 
BeginDialog info_dialog, 0, 0, 256, 125, "SNAP ABAWD (FSET) Sanction"
  ButtonGroup ButtonPressed
    PushButton 200, 40, 50, 15, "Browse...", select_a_file_button
  DropListBox 170, 85, 80, 15, "Select one..."+chr(9)+"Review sanctions"+chr(9)+"Sanction cases", sanction_option
  ButtonGroup ButtonPressed
    OkButton 150, 105, 50, 15
    CancelButton 200, 105, 50, 15
  EditBox 15, 40, 180, 15, file_selection_path
  EditBox 65, 105, 80, 15, worker_signature
  Text 90, 90, 80, 10, "Select the script option:"
  Text 15, 60, 230, 15, "Select the Excel file that contains your information by selecting the 'Browse' button, and finding the file."
  Text 20, 20, 225, 15, "This script should be used members have been identified by SNAP E and T as ready for sanction."
  Text 5, 110, 55, 10, "Worker sigature:"
  GroupBox 10, 5, 245, 75, "Using this script:"
EndDialog

BeginDialog excel_row_dialog, 0, 0, 126, 50, "Select the excel row to start"
  EditBox 75, 5, 40, 15, excel_row_to_start
  ButtonGroup ButtonPressed
    OkButton 10, 25, 50, 15
    CancelButton 65, 25, 50, 15
  Text 10, 10, 60, 10, "Excel row to start:"
EndDialog

'----------------------------------------------------------------------------------------------------The script
'CONNECTS TO BlueZone
EMConnect ""

'dialog and dialog DO...Loop	
Do
    'Initial Dialog to determine the excel file to use, column with case numbers, and which process should be run
    'Show initial dialog
    Do
        err_msg = ""
    	Dialog info_dialog
    	If ButtonPressed = cancel then stopscript
    	If ButtonPressed = select_a_file_button then call file_selection_system_dialog(file_selection_path, ".xlsx")
        If sanction_option = "Select one..." then err_msg = err_msg & vbNewLine & "* Select a sanction option."
        If worker_signature = "" then err_msg = err_msg & vbNewLine & "* Sign your case note."
		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
    Loop until err_msg = ""
    If objExcel = "" Then call excel_open(file_selection_path, True, True, ObjExcel, objWorkbook)  'opens the selected excel file'
    
    'Allows user to select which excel row to start at. Allows for updating cases as you go or sorting. 
    Do 
        dialog excel_row_dialog
        If ButtonPressed = cancel then stopscript
        If IsNumeric(excel_row_to_start) = false then msgbox "Enter a numeric excel row to start the script."
    Loop until IsNumeric(excel_row_to_start) = True
    CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
Loop until are_we_passworded_out = false					'loops until user passwords back in

back_to_SELF
excel_row = excel_row_to_start      'starting at user selected excel row 

'Creating variables for the excel columns as this project has not yet finished evolving. 
date_col        = 5
status_col      = 6
wreg_col        = 7
months_col      = 8
referral_col    = 9
orient_col      = 10
notice_col      = 11
sanction_col    = 12
notes_col       = 13

'----------------------------------------------------------------------------------------------------Actually imposing the sanction
If sanction_option = "Review sanctions" then 
    objExcel.Cells(1, 5).Value = "Agency notified date"
    objExcel.Cells(1, 6).Value = "SNAP Status"
    objExcel.Cells(1, 7).Value = "ABAWD/FSET"
    objExcel.Cells(1, 8).Value = "ABAWD Months Used"
    objExcel.Cells(1, 9).Value = "Referral Date"
    objExcel.Cells(1, 10).Value = "Orient Date"
    objExcel.Cells(1, 11).Value = "Orient LETR Date"
    objExcel.Cells(1, 12).Value = "Sanction?"
    objExcel.Cells(1, 13).Value = "BULK Notes"
    
    FOR i = 1 to 13 	'formatting the cells'
        objExcel.Cells(1, i).Font.Bold = True		'bold font'
        ObjExcel.columns(i).NumberFormat = "@" 		'formatting as text
        objExcel.Columns(i).AutoFit()				'sizing the columns'
    NEXT
    
    ObjExcel.columns(5).NumberFormat = "mm/dd/yyyy" 'Formatting the 'Agency notified date' as a date 
    
    Do 
        sanction_notes = ""
        referral_date = ""
        abawd_counted_months = ""
        abawd_counted_months = ""
        sanction_case = ""
        found_member = ""
        
        PMI_number = ObjExcel.Cells(excel_row, 1).Value
        PMI_number = trim(PMI_number)
        MAXIS_case_number = ObjExcel.Cells(excel_row, 2).Value
        MAXIS_case_number = trim(MAXIS_case_number)
        If MAXIS_case_number = "" then exit do
        
        MAXIS_footer_month = CM_mo	'establishing footer month/year as the current month 
        MAXIS_footer_year = CM_yr 
        Call MAXIS_footer_month_confirmation	'ensuring we are in the correct footer month/year
    
        Call navigate_to_MAXIS_screen("STAT", "PROG")
    	EMReadScreen PRIV_check, 4, 24, 14					'if case is a priv case then it gets added to priv case list
    	If PRIV_check = "PRIV" then
            sanction_notes = sanction_notes & "PRIV case."
            found_member = False 
    	Else
            EmReadscreen county_code, 4, 21, 21             'identifying cases that are out of county. 
            IF county_code <> UCase(worker_county_code) then 
                sanction_notes = sanction_notes & " Out-of-county case."
                found_member = False 
            End if 
        End if 
        
        If found_member <> False then 
            EmReadscreen SNAP_actv, 4, 10, 74               'identifying cases that are inactive vs active 
            ObjExcel.Cells(excel_row, status_col).Value = SNAP_actv
            If SNAP_actv = "ACTV" then 
            else 
                sanction_notes = sanction_notes & " SNAP not active."
            End if
        
            Call HCRE_panel_bypass  'function to ensure we get past HCRE panel 
        
            Call navigate_to_MAXIS_screen ("STAT", "MEMB")  'Finding the member number for the PMI provided by E & T
            member_number = ""
            Do 
                EMReadscreen memb_PMI, 8, 4, 46
                memb_PMI = trim(memb_PMI)
                If memb_PMI = PMI_number then
                    EMReadscreen member_number, 2, 4, 33
                    found_member = True 
                    exit do
                Else 
                    transmit
                END IF
                EMReadScreen MEMB_error, 5, 24, 2
            Loop until MEMB_error = "ENTER"
            
            If member_number = "" then 
                sanction_notes = sanction_notes & " Unable to find HH member on case."
                found_member = False 
            End if 
        End if 
            
        If found_member = True then 
    	    call navigate_to_MAXIS_screen("STAT", "WREG")          'Gathering WREG coding 
            Call write_value_and_transmit(member_number, 20, 76)
            
    	    EMReadScreen FSET_code, 2, 8, 50
    	    EMReadScreen ABAWD_code, 2, 13, 50
            wreg_codes = FSET_code & "/" & ABAWD_code
    	    ObjExcel.Cells(excel_row, wreg_col).Value = wreg_codes
            
            '----------------------------------------------------------------------------------------------------Reading the amount of counted months 
            EMReadScreen wreg_total, 1, 2, 78
            IF wreg_total <> "0" THEN
            	EmWriteScreen "x", 13, 57		'Pulls up the WREG tracker'
            	transmit
            	EMREADScreen tracking_record_check, 15, 4, 40  		'adds cases to the rejection list if the ABAWD tracking record cannot be accessed.
            	If tracking_record_check <> "Tracking Record" then
    	       		sanction_notes = sanction_notes & " Cannot access the ABAWD tracking record. Review and process manually."
            	ELSE
            		bene_mo_col = (15 + (4*cint(MAXIS_footer_month)))		'col to search starts at 15, increased by 4 for each footer month
            		bene_yr_row = 10
            		abawd_counted_months = 0					'delclares the variables values at 0
            		month_count = 0
            		DO
            			'establishing variables for specific ABAWD counted month dates
            			If bene_mo_col = "19" then counted_date_month = "01"
            			If bene_mo_col = "23" then counted_date_month = "02"
            			If bene_mo_col = "27" then counted_date_month = "03"
            			If bene_mo_col = "31" then counted_date_month = "04"
            			If bene_mo_col = "35" then counted_date_month = "05"
            			If bene_mo_col = "39" then counted_date_month = "06"
            			If bene_mo_col = "43" then counted_date_month = "07"
            			If bene_mo_col = "47" then counted_date_month = "08"
            			If bene_mo_col = "51" then counted_date_month = "09"
            			If bene_mo_col = "55" then counted_date_month = "10"
            			If bene_mo_col = "59" then counted_date_month = "11"
            			If bene_mo_col = "63" then counted_date_month = "12"
            			'counted date year: this is found on rows 7-10. Row 11 is current year plus one, so this will be exclude this list.
            			If bene_yr_row = "10" then counted_date_year = right(DatePart("yyyy", date), 2)
            			If bene_yr_row = "9"  then counted_date_year = right(DatePart("yyyy", DateAdd("yyyy", -1, date)), 2)
            			If bene_yr_row = "8"  then counted_date_year = right(DatePart("yyyy", DateAdd("yyyy", -2, date)), 2)
            			If bene_yr_row = "7"  then counted_date_year = right(DatePart("yyyy", DateAdd("yyyy", -3, date)), 2)
            			abawd_counted_months_string = counted_date_month & "/" & counted_date_year

            			'reading to see if a month is counted month or not
            			EMReadScreen is_counted_month, 1, bene_yr_row, bene_mo_col

            			'counting and checking for counted ABAWD months
            			IF is_counted_month = "X" or is_counted_month = "M" THEN
            				EMReadScreen counted_date_year, 2, bene_yr_row, 14			                    'reading counted year date
            				abawd_counted_months_string = counted_date_month & "/" & counted_date_year
            				abawd_info_list = abawd_info_list & ", " & abawd_counted_months_string			'adding variable to list to add to array
            				abawd_counted_months = abawd_counted_months + 1				                    'incremeting counted months
            			END IF

            			'declaring & splitting the abawd months array
            			If left(abawd_info_list, 1) = "," then abawd_info_list = right(abawd_info_list, len(abawd_info_list) - 1)
            			counted_months_array = Split(abawd_info_list, ",")

            			bene_mo_col = bene_mo_col - 4		're-establishing serach once the end of the row is reached
            			IF bene_mo_col = 15 THEN
            				bene_yr_row = bene_yr_row - 1
            				bene_mo_col = 63
            			END IF
            			month_count = month_count + 1
            		LOOP until month_count = 36
            	    PF3
            	End if
    	       	ObjExcel.Cells(excel_row, months_col).Value = abawd_counted_months     'total of counted months 
    	       END If
        End if 
        
        If found_member = True then  
            Call navigate_to_MAXIS_screen("INFC", "WORK")       'Gathering referral information 
            EmReadscreen no_referral, 2, 24, 2
            If no_referral = "NO" then 
                sanction_notes = sanction_notes & " No referral in WF1M for this case."
            Else 
                row = 7
                Do 
                    EMReadscreen work_memb, 2, row, 3
                    If work_memb = member_number then 
                        EmReadscreen referral_date, 8, row, 72
                        referral_date = trim(referral_date)
                        EmReadscreen appt_date, 8, row, 59
                        
                        If referral_date <> "" then referral_date = replace(referral_date, " ", "/")    'cleaning up the referral date & appt date 
                        If appt_date <> "__ __ __" then 
                            appt_date = replace(appt_date, " ", "/")
                        Else 
                            appt_date = ""
                        End if 
                        ObjExcel.Cells(excel_row, referral_col).Value = referral_date
                        ObjExcel.Cells(excel_row, orient_col).Value = appt_date
                        found_member = True
                        exit do 
                    Else 
                        row = row + 1       'checking for non - memb 01 cases 
                    End if 
                Loop until trim(work_memb) = ""
                If found_member <> true then sanction_notes = sanction_notes & " Unable to find referral for member in INFC."
            End if 
        End if 
        
        If found_member = True then
            orient_date_LETR = ""
            Call navigate_to_MAXIS_screen("SPEC", "WCOM")
            row = 7
            notice_sent = False     'Defauliting notice sent to false (as this would likely be manually reviewed.)
            DO
            	EMReadscreen notice_type, 16, row, 30          'SPEC/LETR Letter at Hennepin County is generally the FSET letter 
                If notice_type = "SPEC/LETR Letter" then 
                    EmReadscreen FS_notice, 2, row, 26          'Confirms the letter is for SNAP receipients. 
                    If FS_notice = "FS" or FS_notice = "  " then 
                        Call write_value_and_transmit ("x", row, 13)
                        PF8
                        PF8                                      'twice to get to the date of the orientation 
                        EmReadscreen orient_date_LETR, 10, 2, 8     'Reads the orienation date on the letter  
                        If isDate(orient_date_LETR) = False then 
                            sanction_case = FALSE
                            PF3
                            orient_date_LETR = ""
                        Else 
                            Call ONLY_create_MAXIS_friendly_date(orient_date_LETR) 'reformats the date 
                            If orient_date_LETR = appt_date then 
                                notice_sent = True                                  'Confirms the date on the notice is the orientation date    
                                sanction_case = TRUE
                                exit do 
                            ELSE
                                sanction_notes = sanction_notes & " Referral date does not match date on letter."    'ohterwise the information is output to be reviewed manually 
                                notice_sent = True          'case is still identified in the Excel output as a member who was given a notice 
                                sanction_case = FALSE       'but not identified as sanctioned. This will be done in the manual review. 
                                PF3
                                exit do 
                            End if 
                        End if 
                    else 
                        sanction_case = False               'Continues to default to FALSE 
                    End if 
                elseif trim(notice_type) = "" then 
                    PF7         'navigating to the previous footer month/year if no notices are found
                    row = 7     'resetting the row to start as 7.
                else  
                    sanction_case = false                   'Continues to default to FALSE 
                End if 
                If sanction_case = False then row = row + 1
                EmReadscreen no_notices, 10, 24, 2 
            Loop until no_notices = "NO NOTICES"
            
            ObjExcel.Cells(excel_row, notice_col).Value = orient_date_LETR
        
            If sanction_case = true then 
                If wreg_codes = "30/06" or wreg_codes = "30/08" or wreg_codes = "30/10" or wreg_codes = "30/11" then 
                    ObjExcel.Cells(excel_row, sanction_col).Value = "Yes"       'Entering the sanction as a YES, mandatory FSET participants
                Else 
                    ObjExcel.Cells(excel_row, sanction_col).Value = "No"         'Entering the sanction as a NO, non-mandatory FSET participants      
                End if  
            End if 
        End if     

        ObjExcel.Cells(excel_row, notes_col).Value = sanction_notes         'Entering the sanction     
    	STATS_counter = STATS_counter + 1                                  'Incrementing the stats counter 
        excel_row = excel_row + 1
    Loop until ObjExcel.Cells(excel_row, 2).Value = ""
End if 

'----------------------------------------------------------------------------------------------------SANCTION CASES option
If sanction_option = "Sanction cases" then 
    excel_row = excel_row_to_start          'starting at user selected excel row 
    Do 
        sanction_notes = ""
        sanction_code = ""
        
        PMI_number = ObjExcel.Cells(excel_row, 1).Value
        PMI_number = trim(PMI_number)
        MAXIS_case_number = ObjExcel.Cells(excel_row, 2).Value
        MAXIS_case_number = trim(MAXIS_case_number)
        
        sanction_code = objExcel.cells(excel_row, sanction_col).Value
        sanction_code = Trim(Ucase(sanction_code))
        agency_informed_sanction = ObjExcel.Cells(excel_row, date_col).Value
        agency_informed_sanction = trim(agency_informed_sanction)
        sanction_notes = ObjExcel.Cells(excel_row, notes_col).Value
        
        If MAXIS_case_number = "" then exit do     'applying sanctions for cases that are marked as YES 
        If sanction_code = "YES" then
            Call MAXIS_background_check         'Ensuring case is out of background 
            MAXIS_footer_month = CM_mo	         'Establishing the current month for CASE/PERS info 
            MAXIS_footer_year = CM_yr 
            call MAXIS_footer_month_confirmation	'ensuring we are in the correct footer month/year
            
            Call navigate_to_MAXIS_screen("CASE", "PERS")
            row = 10
            Do
            	EMReadScreen person_PMI, 8, row, 34
                person_PMI = trim(person_PMI)
            	IF person_PMI = "" then exit do
            	IF PMI_number = person_PMI then 
                    EMReadScreen FS_status, 1, row, 54      'Reading the SNAP status for the current month for the FSET member 
            		If FS_status = "A" then 
                        sanction_case = True 
                        EMReadScreen member_number, 2, row, 3               'gathers member number
                        exit do 
                    Else 
                        sanction_case = False 
                        sanction_notes = sanction_notes & "Member is not active on SNAP. "  'Case will not be sanctioned 
                        exit do 
                    End if 
            	Else
            		row = row + 3			'information is 3 rows apart. Will read for the next member. 
            		If row = 19 then
            			PF8  
            			row = 10					'changes MAXIS row if more than one page exists
            		END if
            	END if
            	EMReadScreen last_PERS_page, 21, 24, 2
            LOOP until last_PERS_page = "THIS IS THE LAST PAGE"
    
            IF sanction_case = True then 
                MAXIS_footer_month = CM_plus_1_mo	'establishing footer month/year as next month to make the updates to the case
                MAXIS_footer_year = CM_plus_1_yr 
                call MAXIS_footer_month_confirmation	'ensuring we are in the correct footer month/year
                
                Call navigate_to_MAXIS_screen("STAT", "WREG")
                EMWriteScreen member_number, 20, 76
                transmit
                'checking to make sure that WREG is updating for the correct member
                EMReadScreen WREG_MEMB_check, 6, 24, 2
                IF WREG_MEMB_check = "REFERE" OR WREG_MEMB_check = "MEMBER" THEN 
                    sanction_case = False
                    sanction_notes = sanction_notes & "Member # is not valid on WREG. "
                else  
                    'Ensuring that cases are mandatory FSET (ABAWD code "30")
                    EMReadScreen ABAWD_status, 2, 13, 50
                    If ABAWD_status = "10" or ABAWD_status = "08" or ABAWD_status = "06" or ABAWD_status = "11" or ABAWD_status = "13" then 
                        sanction_case = True
                    Else 
                        sanction_case = False
                        sanction_notes = sanction_notes & "Member is not coded as a Mandatory FSET on WREG. "       'Will not sanction cases that are no longer coded as mandatory FSET, while still bypassing banked months cases 
                    End if 
                End if 
            End if 
    
            If sanction_case = True then 
                EmReadscreen wreg_sanction_code, 2,  8, 50      'Reading sanction code 
                If wreg_sanction_code = "02" then
                    EmReadscreen sanction_month, 2, 10, 50      'reading sanction month 
                    IF sanction_month = MAXIS_footer_month then 
                        Update_wreg = False                     'these cases have already been updated with the sanction. Prevents running through background unnecessarily. Good for caess that had stat errors, but have now been updated. 
                    else 
                        update_wreg = true                      'Cases that still need to be updated for the current month, but may have already have a sanction set, but not applied. 
                    End if 
                else 
                    update_wreg = True                          'If case is not sanction code 02, case will be updated. 
                End if 
                
                If update_wreg = true then 
                    PF9                                                 'Putting into edit mode to update case. 
                    EMReadscreen PWE_check, 1, 6, 68                    'who is the PWE?
                    'updating WREG to reflect sanction 
                    EMWriteScreen "02", 8, 50							'Enters sanction FSET code of "02"
                    EMWriteScreen MAXIS_footer_month, 10, 50			'sanction begin month
                    EMWriteScreen MAXIS_footer_year, 10, 56			    'sanction begin year
                    EMWriteScreen "01", 11, 50	                        'sanction # 
                    EMWriteScreen "01", 12, 50		                    'reason for sanction. This adds information to the notice. - If sanction is more than reason 01, then this will be processed indivdually.
                    EMWriteScreen "_", 8, 80							'blanks out Defer FSET/No funds field 
                    PF3
                End if 
                
                '>>>>>>>>>>ADDR panel information to determine if case should get additional information about 'unfit for employment' in the case note.
                CALL navigate_to_MAXIS_screen("STAT", "ADDR")
                EMReadScreen homeless_code, 1, 10, 43
                EmReadscreen addr_line_01, 16, 6, 43
                IF homeless_code = "Y" or addr_line_01 = "GENERAL DELIVERY" THEN possible_homeless = True 
                
                '----------------------------------------------------------------------------------------------------The Case note
                Call navigate_to_MAXIS_screen("CASE", "NOTE")
                EmReadscreen first_casenote, 40, 5, 25                  'Reading 1st case note. 
                If instr(first_casenote, "SNAP sanction imposed") then 
                    EmReadscreen sanction_member, 2, 5, 58
                    If sanction_member = member_number then 
                        create_casenote = False                             'if duplicate exists, then a new case note will not be created. Preventing duplicdte case notes. 
                    Else 
                        create_casenote = True      'case note exists for another HH member, not the current member 
                    End if 
                Else 
                    create_casenote = True 
                End if 
                        
                If create_casenote = True then 
                    PF9     'edit mode (not Edna Mode)
                    Call write_variable_in_CASE_NOTE("--SNAP sanction imposed for MEMB " & member_number & " for " & MAXIS_footer_month & "/" & MAXIS_footer_year & "--")
                    If PWE_check = "Y" THEN Call write_variable_in_CASE_NOTE("* Entire household is sanctioned. Member is the PWE.")
                    If PWE_check = "N" THEN Call write_variable_in_CASE_NOTE("* Only the HH MEMB is sanctioned. Member is NOT the PWE.")
                    Call write_bullet_and_variable_in_CASE_NOTE("Date agency was notified of sanction", agency_informed_sanction)
                    Call write_variable_in_CASE_NOTE("* Client does not appear to meet Good Cause criteria.")
                    If possible_homeless = True then 
                        Call write_variable_in_CASE_NOTE("---")
                        Call write_variable_in_CASE_NOTE("Client may meet an ABAWD exemption.")
                        Call write_variable_in_CASE_NOTE("Per CM 11.24: A person is unfit for employment if he or she is currently homeless. Homeless specifically defined for this purpose as:")
                        Call write_variable_in_CASE_NOTE("1. Lacking a fixed and regular nighttime residence, including temporary housing situations AND")
                        Call write_variable_in_CASE_NOTE("2. Lacking access to work-related necessities (i.e. shower or laundry facilities, etc.).")
                    else 
                        Call write_variable_in_CASE_NOTE("* Client does not appear to meet any ABAWD exemptions.")
                    End if 
                    Call write_variable_in_CASE_NOTE("---")
                    Call write_variable_in_CASE_NOTE("* Number/occurrence of sanction: 1st")
                    Call write_variable_in_CASE_NOTE("* Reason for sanction: Failed to attend orientation.") 
                    Call write_variable_in_CASE_NOTE("* Added Good Cause/failure to comply information to the notice.")
                    Call write_variable_in_CASE_NOTE("---")
                    Call write_variable_in_CASE_NOTE(worker_signature)
                    PF3
                End if 
                
                Call MAXIS_background_check             'clearing background to make the approval 
                '----------------------------------------------------------------------------------------------------Approval of sanction case 
                Call navigate_to_MAXIS_screen("ELIG", "FS  ")
                EMReadScreen is_case_approved, 10, 3, 3     'at FSPR screen 
                IF is_case_approved <> "UNAPPROVED" THEN
                    EmReadscreen STAT_edits, 10, 24, 2      'reading for inhibiting stat edits. These will be cleared manually since most of these cases have more than one issue.  
                    If STAT_edits = "STAT EDITS" then 
                        sanction_notes = sanction_notes & " Case has STAT edits. Resolve and approve manually."     'inhibiting stat edits found 
                        sanction_case = false 
                    else 
                        sanction_notes = sanction_notes & " No approved results found. Review/approve manually."    'If new results haven't been triggered for whatever reason 
                        sanction_case = false
                    End if 
                Else 
                    Row = 7         'member 01 starts at row 7 
                    Do 
                        EmReadscreen elig_memb, 2, row, 10      'reading member numbers to select the correct member 
                        If elig_memb = member_number then 
                            Call write_value_and_transmit("X", row, 5)      'found them!
                            sanction_case = True
                            exit do 
                        else 
                            row = row + 1           'will check for next member
                            sanction_case = False 
                        End if 
                    Loop until trim(elig_memb) = ""    'blank space means the list of members is complete 
                    
                    If sanction_case = false then 
                        sanction_notes = sanction_notes & " Unable to find memb " & member_number & " in ELIG results."
                    else 
                        EmReadscreen wreg_test, 6, 14, 54   'Reading person test results 
                        If wreg_test = "FAILED" then 
                            sanction_case = true 
                        else 
                            sanction_notes = sanction_notes & " Not failing elig and/or wreg test. Review/approve manually."    'ensuring cases are failing for the correct reason. 
                            sanction_case = false 
                        end if 
                        transmit 'to exit person test
                    End if 
                End if 
                
                If sanction_case = True then 
                    approval_confirm = ""  'resetting variable
                    Call write_value_and_transmit("FSSM", 19, 70)
                    Call write_value_and_transmit("APP", 19, 70)    'approving the SNAP results - So exciting! 
                    transmit                                         'past approval pop up
                    Call navigate_to_MAXIS_screen("ELIG", "FSPR")   
                    EmReadscreen approval_confirm, 8, 3, 3          'confirming the approval took 
                    If approval_confirm = "APPROVED" then 
                        sanction_case = True
                        sanction_notes = "" & "Sanction imposed."   'labeling the case as sanctioned 
                    Else 
                        sanction_case = False 
                        sanction_notes = sanction_notes & " Approval not confirmed. Review/approve manually."   'Catching cases tha tmay not have been approved. 
                    End if 
                End if     
            End if 
        End if 
        ObjExcel.Cells(Excel_row, notes_col).Value = sanction_notes     'Adding sanction notes to spreadsheet  
        excel_row = excel_row + 1     
    Loop until ObjExcel.Cells(excel_row, 2).Value = ""  'End of list 
    
    '----------------------------------------------------------------------------------------------------ADDING WCOM     
    excel_row = excel_row_to_start     'starting at user selected excel row 
    Do 
        sanction_notes = ""
        sanction_code = ""
    
        MAXIS_case_number = ObjExcel.Cells(excel_row, 2).Value
        MAXIS_case_number = trim(MAXIS_case_number)
        
        sanction_code = objExcel.cells(excel_row, sanction_col).Value
        sanction_code = Trim(Ucase(sanction_code))
        agency_informed_sanction = ObjExcel.Cells(excel_row, date_col).Value
        agency_informed_sanction = trim(agency_informed_sanction)
        sanction_notes = ObjExcel.Cells(excel_row, notes_col).Value
    
        If MAXIS_case_number = "" then exit do          'adding WCOM for cases that are marked as YES 
        If sanction_code = "YES" then  
            If instr(sanction_notes, "Sanction imposed") then 
                'case has been approved as being sanctioned 
                CALL navigate_to_MAXIS_screen("SPEC", "WCOM")   
                'Searching for waiting SNAP notice
                wcom_row = 6
                Do
                    wcom_row = wcom_row + 1
                    Emreadscreen program_type, 2, wcom_row, 26      'Looking for FS 
                    Emreadscreen print_status, 7, wcom_row, 71      'Looing for waiting notice results 
                    If program_type = "FS" then
                        If print_status = "Waiting" then
                            Call write_value_and_transmit("x", wcom_row, 13)    'selecting the FS/Waiting notice 
                            PF9
                            Emreadscreen fs_wcom_exists, 3, 3, 15
                            If fs_wcom_exists <> "   " then 
                                sanction_notes = sanction_notes & "WCOM already exists on the notice."  'does not add additional WCOM's if worker comments 
                                PF3
                                PF3
                                fs_wcom_writen = true  'WCOM exists 
                            Else
                                fs_wcom_writen = true  'WCOM exists 
                                'This will write if the notice is for SNAP only. This is not required. Information required should be sent by E & T.
                                CALL write_variable_in_SPEC_MEMO("******************************************************")
                                CALL write_variable_in_SPEC_MEMO("What to do next:")
                                CALL write_variable_in_SPEC_MEMO("* You must meet the SNAP Employment and Training rules by the end of the month. If you want to meet the rules, contact your team at 612-596-1300, or your SNAP Employment and Training provider at 612-596-7411.")
                                CALL write_variable_in_SPEC_MEMO("* You can tell us why you did not meet the rules. If you had a good reason for not meeting the SNAP Employment and Training rules, contact your SNAP Employment and Training provider right away.")
                                CALL write_variable_in_SPEC_MEMO("******************************************************")
                                PF4     'saving notice 
                                PF3     'exiting specific notice 
                            End if
                        End If
                    End If
                    If fs_wcom_writen = true then Exit Do   
                    If wcom_row = 17 then
                        PF8         'moved to next footer month/year if cannot find 
                        Emreadscreen spec_edit_check, 6, 24, 2
                        wcom_row = 6
                    end if
                    If spec_edit_check = "NOTICE" THEN no_fs_waiting = true
                Loop until spec_edit_check = "NOTICE"
                 
                If fs_wcom_writen <> True then sanction_notes = sanction_notes & " No waiting FS notice found. WCOM not added."
            End if 
            ObjExcel.Cells(Excel_row, notes_col).Value = sanction_notes  'Adding sanction notes
        End if 
        excel_row = excel_row + 1     
    Loop until ObjExcel.Cells(excel_row, 2).Value = ""  'loops until the end 
End if 

'End of the script clean up and closure
FOR i = 1 to 13 	'formatting the cells'
    objExcel.Columns(i).AutoFit()				'sizing the columns'
NEXT

STATS_counter = STATS_counter - 1 'since we start with 1
script_end_procedure("Success! Your list is complete. Please review the list for work that still may be required.")