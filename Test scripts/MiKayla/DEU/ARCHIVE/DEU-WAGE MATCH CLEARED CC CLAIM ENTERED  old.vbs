'GATHERING STATS===========================================================================================
name_of_script = "DEU-ACTION-WAGE MATCH CLEARED.vbs"
start_time = timer
STATS_counter = 1
STATS_manualtime = 180
STATS_denominatinon = "C"
'END OF STATS BLOCK===========================================================================================

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
		FuncLib_URL = "C:\BZS-FuncLib\MASTER FUNCTIONS LIBRARY.vbs"
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

CALL changelog_update("06/06/2017", "Initial version.", "MiKayla Handley, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

EMConnect ""
CALL MAXIS_case_number_finder (MAXIS_case_number)
memb_number = "01"
OP_Date = date & ""

BeginDialog CC_Cleared_dialog, 0, 0, 281, 245, "Cleared CC-Claim Entered"
  EditBox 65, 5, 60, 15, MAXIS_case_number
  DropListBox 210, 5, 55, 15, "Select One:"+chr(9)+"1"+chr(9)+"2"+chr(9)+"3"+chr(9)+"4"+chr(9)+"YEAR", select_quarter
  EditBox 35, 35, 35, 15, OP_1
  EditBox 90, 35, 35, 15, OP_to_1
  EditBox 160, 35, 35, 15, Claim_1
  EditBox 220, 35, 45, 15, AMT_1
  EditBox 35, 55, 35, 15, OP_2
  EditBox 90, 55, 35, 15, OP_to_2
  EditBox 160, 55, 35, 15, Claim_2
  EditBox 220, 55, 45, 15, Amt_2
  EditBox 35, 75, 35, 15, OP_3
  EditBox 90, 75, 35, 15, OP_to_3
  EditBox 160, 75, 35, 15, Claim_3
  EditBox 220, 75, 45, 15, AMT_3
  EditBox 35, 95, 35, 15, OP_4
  EditBox 90, 95, 35, 15, OP_to_4
  EditBox 160, 95, 35, 15, Claim_4
  EditBox 220, 95, 45, 15, AMT_4
  DropListBox 70, 120, 60, 15, "Select One:"+chr(9)+"YES"+chr(9)+"NO", fraud_referral
  DropListBox 70, 140, 60, 15, "Select One:"+chr(9)+"YES"+chr(9)+"NO", colectible_dropdown
  EditBox 70, 160, 70, 15, collectible_reason
  EditBox 70, 180, 70, 15, EVF_date
  EditBox 230, 140, 45, 15, OT_resp_memb
  EditBox 230, 160, 45, 15, Fed_HC_AMT
  EditBox 230, 180, 45, 15, HC_resp_memb
  EditBox 60, 205, 215, 15, Reason_OP
  CheckBox 155, 125, 120, 10, "Earned Income disregard allowed", EI_checkbox
  Text 10, 10, 50, 10, "Case Number: "
  Text 160, 10, 45, 10, "Match Period:"
  GroupBox 5, 25, 270, 90, "Overpayment Information"
  Text 10, 40, 25, 10, "From:"
  Text 75, 40, 10, 10, "To:"
  Text 130, 40, 25, 10, "Claim #"
  Text 200, 40, 20, 10, "AMT:"
  Text 10, 60, 20, 10, "From:"
  Text 75, 60, 10, 10, "To:"
  Text 130, 60, 25, 10, "Claim #"
  Text 200, 60, 20, 10, "AMT:"
  Text 10, 80, 20, 10, "From:"
  Text 75, 80, 10, 10, "To:"
  Text 130, 80, 25, 10, "Claim #"
  Text 200, 80, 20, 10, "AMT:"
  Text 10, 100, 20, 10, "From:"
  Text 75, 100, 10, 10, "To:"
  Text 130, 100, 25, 10, "Claim #"
  Text 200, 100, 20, 10, "AMT:"
  Text 15, 125, 50, 10, "Fraud referral:"
  Text 25, 145, 40, 10, "Collectible?"
  Text 5, 165, 65, 10, "Collectible Reason:"
  Text 5, 185, 60, 10, "Income verif used:"
  Text 160, 145, 65, 10, "HC resp. members:"
  Text 160, 165, 65, 10, "Total FED HC AMT:"
  Text 160, 185, 60, 10, "Other resp. memb:"
  Text 5, 210, 50, 10, "Reason for OP: "
  ButtonGroup ButtonPressed
    OkButton 180, 225, 45, 15
    CancelButton 230, 225, 45, 15
EndDialog



Do
	Do
		err_msg = ""
		dialog CC_Cleared_dialog
		IF buttonpressed = 0 then stopscript 
		IF MAXIS_case_number = "" or IsNumeric(MAXIS_case_number) = False or len(MAXIS_case_number) > 8 then err_msg = err_msg & vbnewline & "* Enter a valid case number."
        If (Cleared_status = "CC - Claim Entered" AND instr(programs, "HC") or instr(programs, "Medical Assistance")) then err_msg = err_msg & vbNewLine & "* System does not allow HC or MA cases to be cleared with the code 'CC - Claim Entered'."
		IF OP_1 = false then err_msg = err_msg & vbnewline & "* You must have an overpayment entry."
		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine		'error message including instruction on what needs to be fixed from each mandatory field if incorrect
	LOOP UNTIL err_msg = ""									'loops until all errors are resolved
	CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
Loop until are_we_passworded_out = false					'loops until user passwords back in

'----------------------------------------------------------------------------------------------------Creating the quarter
CM_minus_6_yr =  right(DatePart("yyyy", DateAdd("m", -6, date)), 2)

'------------------------------------------------------------------------------------------------------Defaulting the quarters 
IF select_quarter = "1" THEN
    IEVS_period = "01-" & CM_yr & "/03-" & CM_yr
ELSEIF select_quarter = "2" THEN
    IEVS_period = "04-" & CM_yr & "/06-" & CM_yr
ELSEIF select_quarter = "3" THEN
    IEVS_period = "07-" & CM_yr & "/09-" & CM_yr
ELSEIF select_quarter = "4" THEN
    IEVS_period = "10-" & CM_minus_6_yr & "/12-" & CM_minus_6_yr
END IF

'----------------------------------------------------------------------------------------------------IEVS
CALL navigate_to_MAXIS_screen("STAT", "MEMB")
EMwritescreen memb_number, 20, 76
transmit

EMReadscreen SSN_number_read, 11, 7, 42
SSN_number_read = replace(SSN_number_read, " ", "") 

CALL navigate_to_MAXIS_screen("INFC" , "____")  
CALL write_value_and_transmit("IEVP", 20, 71) 
CALL write_value_and_transmit(SSN_number_read, 3, 63) '

EMReadScreen edit_error, 2, 24, 2
edit_error = trim(edit_error)
IF edit_error <> "" then script_end_procedure("No IEVS matches and/ or could not access IEVP.")

Row = 7	
Do 
	EMReadScreen IEVS_match, 11, row, 47 
	If trim(IEVS_match) = "" THEN script_end_procedure("IEVS match for the selected period could not be found. The script will now end.")
	If IEVS_match = IEVS_period then 
		Exit do
	Else 
		row = row + 1
		'msgbox "row: " & row 
		If row = 17 then 
			PF8
			row = 7
		End if
	End if 
Loop until IEVS_period = select_quarter 

EMReadScreen multiple_match, 11, row + 1, 47 
If multiple_match = IEVS_period then 
	msgbox("More than one match exists for this time period. Determine the match you'd like to clear, and put your cursor in front of that match." & vbcr & "Press OK once match is determined.")
	EMSendKey "U"
	transmit
Else 
	CALL write_value_and_transmit("U", row, 3)   'navigates to IULA
End if 
'----------------------------------------------------------------------------------------------------IULA
'Entering the IEVS match & reading the difference notice to ensure this has been sent
'Reading potential errors for out-of-county cases
EMReadScreen OutOfCounty_error, 12, 24, 2
IF OutOfCounty_error = "MATCH IS NOT" then
	script_end_procedure("Out-of-county case. Cannot update.")
Else
	IF IEVS_type = "WAGE" then
		EMReadScreen quarter, 1, 8, 14
		EMReadScreen IEVS_year, 4, 8, 22
		If quarter <> select_quarter then script_end_procedure("Match period does not match the selected match period. The script will now end.")
	Elseif IEVS_type = "BEER" then
		EMReadScreen IEVS_year, 2, 8, 15
		IEVS_year = "20" & IEVS_year
	End if
End if 

'----------------------------------------------------------------------------------------------------Client name
EMReadScreen client_name, 35, 5, 24
'Formatting the client name for the spreadsheet
client_name = trim(client_name)                         'trimming the client name
if instr(client_name, ",") then    						'Most cases have both last name and 1st name. This seperates the two names
	length = len(client_name)                           'establishing the length of the variable
	position = InStr(client_name, ",")                  'sets the position at the deliminator (in this case the comma)
	last_name = Left(client_name, position-1)           'establishes client last name as being before the deliminator
	first_name = Right(client_name, length-position)    'establishes client first name as after before the deliminator
Else                                'In cases where the last name takes up the entire space, then the client name becomes the last name
	first_name = ""
	last_name = client_name
END IF
if instr(first_name, " ") then   						'If there is a middle initial in the first name, then it removes it
	length = len(first_name)                        	'trimming the 1st name
	position = InStr(first_name, " ")               	'establishing the length of the variable
	first_name = Left(first_name, position-1)       	'trims the middle initial off of the first name
End if

'----------------------------------------------------------------------------------------------------ACTIVE PROGRAMS
EMReadScreen Active_Programs, 13, 6, 68
Active_Programs = trim(Active_Programs)

programs = ""
IF instr(Active_Programs, "D") then programs = programs & "DWP, "
IF instr(Active_Programs, "F") then programs = programs & "Food Support, "
IF instr(Active_Programs, "H") then programs = programs & "Health Care, "
IF instr(Active_Programs, "M") then programs = programs & "Medical Assistance, "
IF instr(Active_Programs, "S") then programs = programs & "MFIP, "
'trims excess spaces of programs 
programs = trim(programs)
'takes the last comma off of programs when autofilled into dialog
If right(programs, 1) = "," THEN programs = left(programs, len(programs) - 1) 

'----------------------------------------------------------------------------------------------------Employer info & diff notice info
EMReadScreen source_income, 27, 8, 37
source_income = trim(source_income)

If instr(source_income, "AMT: $") then 
    length = len(source_income) 						  'establishing the length of the variable
    position = InStr(source_income, "AMT: $")    		      'sets the position at the deliminator  
    employer_name = Left(source_income, position)  'establishes employer as being before the deliminator
	Else 
	employer_name = source_income
End if 
MsgBox employer_name

EMReadScreen diff_notice, 1, 14, 37
EMReadScreen diff_date, 10, 14, 68
diff_date = trim(diff_date)
If diff_date <> "" then diff_date = replace(diff_date, " ", "/")

PF3		'exiting IULA, helps prevent errors when going to the case note

'-----------------------------------------------------------------------------------'for the case notes

IF select_quarter = "1" THEN
	IEVS_type = "WAGE"
    IEVS_period = "01-" & CM_yr & "/03-" & CM_yr
ELSEIF select_quarter = "2" THEN
	IEVS_type = "WAGE"
    IEVS_period = "04-" & CM_yr & "/06-" & CM_yr
ELSEIF select_quarter = "3" THEN
    IEVS_type = "WAGE"
	IEVS_period = "07-" & CM_yr & "/09-" & CM_yr
ELSEIF select_quarter = "4" THEN
	IEVS_type = "WAGE"
    IEVS_period = "10-" & CM_minus_6_yr & "/12-" & CM_minus_6_yr
ELSEIF select_quarter = "YEAR" THEN
	IEVS_type = "BEER"
	IEVS_period = right(DatePart("yyyy",DateAdd("yyyy", -1, date)), 2) 
END IF

msgbox IEVS_period

IF select_quarter = "YEAR" THEN IEVS_type = "BEER"

programs = ""
IF instr(Active_Programs, "D") then programs = programs & "DWP, "
IF instr(Active_Programs, "F") then programs = programs & "Food Support, "
IF instr(Active_Programs, "H") then programs = programs & "Health Care, "
IF instr(Active_Programs, "M") then programs = programs & "Medical Assistance, "
IF instr(Active_Programs, "S") then programs = programs & "MFIP, "
'trims excess spaces of programs 
programs = trim(programs)
'takes the last comma off of programs when autofilled into dialog
IF right(programs, 1) = "," THEN programs = left(programs, len(programs) - 1) 
If IEVS_type = "WAGE" then
	'Updated IEVS_period to write into case note
	If quarter = 1 then IEVS_quarter = "1ST"
	If quarter = 2 then IEVS_quarter = "2ND"
	If quarter = 3 then IEVS_quarter = "3RD"
	If quarter = 4 then IEVS_quarter = "4TH"
End if
IEVS_period = replace(IEVS_period, "/", " to ")
Due_date = dateadd("d", 10, date)	'defaults the due date for all verifications at 10 days requested for HEADER of casenote'
PF3 'back to the DAIL'

'-----------------------------------------------------------------------------------------CASENOTE
start_a_blank_CASE_NOTE
IF IEVS_type = "WAGE" THEN CALL write_variable_in_CASE_NOTE("-----" & IEVS_quarter & " QTR " & IEVS_year & " WAGE MATCH " & "(" & first_name &  ")" & "CLEARED CC-CLAIM ENTERED-----")
IF IEVS_type = "BEER" THEN CALL write_variable_in_CASE_NOTE("-----" & IEVS_year & " NON-WAGE MATCH (" & type_match & ") " & "(" & first_name &  ")" &  "CLEARED CC-CLAIM ENTERED-----")
CALL write_bullet_and_variable_in_CASE_NOTE("Period", IEVS_period)
CALL write_bullet_and_variable_in_CASE_NOTE("Active Programs", programs)
CALL write_bullet_and_variable_in_CASE_NOTE("Source of income", source_income)
Call write_variable_in_CASE_NOTE("----- ----- ----- ----- ----- ----- -----")
Call write_variable_in_CASE_NOTE(program_droplist & "Overpayment " & OP_1 & " through " & OP_to_1 & "  Claim # " & Claim_1 & "  Amt $" & AMT_1)
IF OP_2 <> "" then Call write_variable_in_case_note(program_droplist & "Overpayment " & OP_2 & " through  " & OP_to_2 & "  Claim # " & Claim_2 & "  Amt $" & AMT_2)
IF OP_3 <> "" then Call write_variable_in_case_note(program_droplist & "Overpayment " & OP_3 & " through  " & OP_to_3 & "  Claim # " & Claim_3 & "  Amt $" & AMT_3)
IF OP_4 <> "" then Call write_variable_in_case_note(program_droplist & "Overpayment " & OP_4 & " through  " & OP_to_4 & "  Claim # " & Claim_4 & "  Amt $" & AMT_4)
IF EI_checkbox = CHECKED THEN CALL write_variable_in_case_note("* Earned Income Disregard Allowed")
IF instr(program_droplist, "HC") then 
	Call write_bullet_and_variable_in_CASE_NOTE("HC responsible members", HC_resp_memb)
	Call write_bullet_and_variable_in_CASE_NOTE("Total federal Health Care amount", Fed_HC_AMT)
	Call write_variable_in_CASE_NOTE("---Emailed HSPHD Accounts Receivable for the medical overpayment(s)")
END IF
CALL write_bullet_and_variable_in_case_note("Income verification received", EVF_date)
CALL write_bullet_and_variable_in_case_note("Other responsible member(s)", OT_resp_memb)
CALL write_bullet_and_variable_in_case_note("Fraud referral made", fraud_referral)
CALL write_bullet_and_variable_in_case_note("Collectible claim", colectible_dropdown) 
CALL write_bullet_and_variable_in_case_note("Reason that claim is collectible or not", collectible_reason)   
CALL write_bullet_and_variable_in_case_note("Reason for overpayment", Reason_OP) 
CALL write_variable_in_CASE_NOTE("----- ----- ----- ----- ----- ----- -----")
CALL write_variable_in_CASE_NOTE("DEBT ESTABLISHMENT UNIT 612-348-4290 PROMPTS 1-1-1") 
IF instr(program_droplist, "HC") THEN CALL create_outlook_email("", "mikayla.handley@hennepin.us", "Claims entered for #" &  MAXIS_case_number, "Member #: " & memb_number & vbcr & "Date Overpayment Created: " & OP_Date & vbcr & "Programs: " & program_droplist & vbcr & "See case notes for further details.", "", False)