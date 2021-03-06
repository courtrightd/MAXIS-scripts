''GATHERING STATS===========================================================================================
name_of_script = "ACTIONS - DEU-MATCH CLEARED CC.vbs"
start_time = timer
STATS_counter = 1
STATS_manualtime = 300
STATS_denominatinon = "C"
'END OF STATS BLOCK===========================================================================================
'run_locally = TRUE
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
'Example: CALL changelog_update("01/01/2000", "The script has been updated to fix a typo on the initial dialog.", "Jane Public, Oak County")
CALL changelog_update("08/17/2018", "Updated coding which reads active programs.", "Ilse Ferris, Hennepin County")
CALL changelog_update("07/23/2018", "Updated script to correct version and added case note to email for HC matches and CCOL.", "MiKayla Handley, Hennepin County")
CALL changelog_update("01/02/2018", "Corrected IEVS match error due to new year.", "MiKayla Handley, Hennepin County")
CALL changelog_update("12/27/2017", "Updated to handle clearing the match when the date is over 45 days.", "MiKayla Handley, Hennepin County")
CALL changelog_update("12/14/2017", "Updated to fix claim entering and case note header.", "MiKayla Handley, Hennepin County")
CALL changelog_update("11/14/2017", "Initial version.", "MiKayla Handley, Hennepin County")
'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================
'Fun with dates! --Creating variables for the rolling 12 calendar months
'current month -1
CM_minus_1_mo =  right("0" &          	 DatePart("m",           DateAdd("m", -1, date)            ), 2)
CM_minus_1_yr =  right(                  DatePart("yyyy",        DateAdd("m", -1, date)            ), 2)
'current month -2'
CM_minus_2_mo =  right("0" &             DatePart("m",           DateAdd("m", -2, date)            ), 2)
CM_minus_2_yr =  right(                  DatePart("yyyy",        DateAdd("m", -2, date)            ), 2)
'current month -3'
CM_minus_3_mo =  right("0" &             DatePart("m",           DateAdd("m", -3, date)            ), 2)
CM_minus_3_yr =  right(                  DatePart("yyyy",        DateAdd("m", -3, date)            ), 2)
'current month -4'
CM_minus_4_mo =  right("0" &             DatePart("m",           DateAdd("m", -4, date)            ), 2)
CM_minus_4_yr =  right(                  DatePart("yyyy",        DateAdd("m", -4, date)            ), 2)
'current month -5'
CM_minus_5_mo =  right("0" &             DatePart("m",           DateAdd("m", -5, date)            ), 2)
CM_minus_5_yr =  right(                  DatePart("yyyy",        DateAdd("m", -5, date)            ), 2)
'current month -6'
CM_minus_6_mo =  right("0" &             DatePart("m",           DateAdd("m", -6, date)            ), 2)
CM_minus_6_yr =  right(                  DatePart("yyyy",        DateAdd("m", -6, date)            ), 2)
'current month -7'
CM_minus_7_mo =  right("0" &             DatePart("m",           DateAdd("m", -7, date)            ), 2)
CM_minus_7_yr =  right(                  DatePart("yyyy",        DateAdd("m", -7, date)            ), 2)
'current month -8'
CM_minus_8_mo =  right("0" &             DatePart("m",           DateAdd("m", -8, date)            ), 2)
CM_minus_8_yr =  right(                  DatePart("yyyy",        DateAdd("m", -8, date)            ), 2)
'current month -9'
CM_minus_9_mo =  right("0" &             DatePart("m",           DateAdd("m", -9, date)            ), 2)
CM_minus_9_yr =  right(                  DatePart("yyyy",        DateAdd("m", -9, date)            ), 2)
'current month -10'
CM_minus_10_mo =  right("0" &            DatePart("m",           DateAdd("m", -10, date)           ), 2)
CM_minus_10_yr =  right(                 DatePart("yyyy",        DateAdd("m", -10, date)           ), 2)
'current month -11'
CM_minus_11_mo =  right("0" &            DatePart("m",           DateAdd("m", -11, date)           ), 2)
CM_minus_11_yr =  right(                 DatePart("yyyy",        DateAdd("m", -11, date)           ), 2)

'Establishing value of variables for the rolling 12 months
current_month = CM_mo & "/" & CM_yr
current_month_minus_one = CM_minus_1_mo & "/" & CM_minus_1_yr
current_month_minus_two = CM_minus_2_mo & "/" & CM_minus_2_yr
current_month_minus_three = CM_minus_3_mo & "/" & CM_minus_3_yr
current_month_minus_four = CM_minus_4_mo & "/" & CM_minus_4_yr
current_month_minus_five = CM_minus_5_mo & "/" & CM_minus_5_yr
current_month_minus_six = CM_minus_6_mo & "/" & CM_minus_6_yr
current_month_minus_seven = CM_minus_7_mo & "/" & CM_minus_7_yr
current_month_minus_eight = CM_minus_8_mo & "/" & CM_minus_8_yr
current_month_minus_nine = CM_minus_9_mo & "/" & CM_minus_9_yr
current_month_minus_ten = CM_minus_10_mo & "/" & CM_minus_10_yr
current_month_minus_eleven = CM_minus_11_mo & "/" & CM_minus_11_yr

'---------------------------------------------------------------------THE SCRIPT
EMConnect ""

MAXIS_footer_month = CM_mo
MAXIS_footer_year = CM_yr
'----------------------------------------------------------------------------------------------------DAIL
EMReadscreen dail_check, 4, 4, 14 'changed from DAIL to view to ensure we are in DAIL/DAIL'
IF dail_check = "View" THEN
    EMReadScreen IEVS_type, 4, 6, 6 'read the DAIL msg'
    EMSendKey "t"
	'msgbox IEVS_type
    IF IEVS_type = "WAGE" or IEVS_type = "BEER" or IEVS_type = "UBEN" THEN
    	match_found = TRUE
    ELSE
    	script_end_procedure("This is not an supported match currently. Please select a WAGE match DAIL, and run the script again.")
    END IF
	IF match_found = TRUE THEN
    	EMReadScreen MAXIS_case_number, 8, 5, 73
		MAXIS_case_number= TRIM(MAXIS_case_number)
		 '----------------------------------------------------------------------------------------------------IEVP
		'Navigating deeper into the match interface
		CALL write_value_and_transmit("I", 6, 3)   		'navigates to INFC
		CALL write_value_and_transmit("IEVP", 20, 71)   'navigates to IEVP
		TRANSMIT
	    EMReadScreen err_msg, 7, 24, 2
	    IF err_msg = "NO IEVS" THEN script_end_procedure("An error occurred in IEVP, please process manually.")'checking for error msg'
	END IF
ElseIF dail_check <> "View" THEN
    CALL MAXIS_case_number_finder (MAXIS_case_number)
    MEMB_number = "01"
    BeginDialog case_number_dialog, 0, 0, 131, 65, "Case Number to clear match"
      EditBox 60, 5, 65, 15, MAXIS_case_number
      EditBox 60, 25, 30, 15, MEMB_number
      ButtonGroup ButtonPressed
        OkButton 20, 45, 50, 15
        CancelButton 75, 45, 50, 15
      Text 5, 30, 55, 10, "MEMB Number:"
      Text 5, 10, 50, 10, "Case Number:"
    EndDialog
    DO
    	DO
    		err_msg = ""
    		Dialog case_number_dialog
    		IF ButtonPressed = 0 THEN StopScript
      		If MAXIS_case_number = "" or IsNumeric(MAXIS_case_number) = False or len(MAXIS_case_number) > 8 then err_msg = err_msg & vbNewLine & "* Enter a valid case number."
      		If IsNumeric(MEMB_number) = False or len(MEMB_number) <> 2 then err_msg = err_msg & vbNewLine & "* Enter a valid 2 digit member number."
    		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
    	LOOP UNTIL err_msg = ""
    	CALL check_for_password(are_we_passworded_out)
    LOOP UNTIL are_we_passworded_out = false
    CALL navigate_to_MAXIS_screen("STAT", "MEMB")
    EMwritescreen MEMB_number, 20, 76
    TRANSMIT
    EMReadscreen SSN_number_read, 11, 7, 42
    SSN_number_read = replace(SSN_number_read, " ", "")
	CALL navigate_to_MAXIS_screen("INFC" , "____")
	CALL write_value_and_transmit("IEVP", 20, 71)
	CALL write_value_and_transmit(SSN_number_read, 3, 63)
end if
'----------------------------------------------------------------------------------------------------selecting the correct wage match
Row = 7
DO
	EMReadScreen IEVS_period, 11, row, 47
	IF trim(IEVS_period) = "" THEN script_end_procedure("A match for the selected period could not be found. The script will now end.")
	ievp_info_confirmation = MsgBox("Press YES to confirm this is the match you wish to act on." & vbNewLine & "For the next match, press NO." & vbNewLine & vbNewLine & _
	"   " & IEVS_period, vbYesNoCancel, "Please confirm this match")
	'msgbox IEVS_period
    IF ievp_info_confirmation = vbNo THEN
		row = row + 1
		'msgbox "row: " & row
		IF row = 17 THEN
			PF8
			row = 7
		END IF
	END IF
	IF ievp_info_confirmation = vbCancel THEN script_end_procedure ("The script has ended. The match has not been acted on.")
	IF ievp_info_confirmation = vbYes THEN 	EXIT DO
LOOP UNTIL ievp_info_confirmation = vbYes

''---------------------------------------------------------------------Reading potential errors for out-of-county cases
CALL write_value_and_transmit("U", row, 3)   'navigates to IULA
EMReadScreen OutOfCounty_error, 12, 24, 2
IF OutOfCounty_error = "MATCH IS NOT" then
	script_end_procedure("Out-of-county case. Cannot update.")
Else
	IF IEVS_type = "WAGE" then
		EMReadScreen casenote_quarter, 1, 8, 14
		EMReadScreen IEVS_year, 4, 8, 22
	ELSEIF IEVS_type = "UBEN" THEN
		EMReadScreen IEVS_month, 2, 5, 68
		EMReadScreen IEVS_year, 4, 8, 71
	ELSEIF IEVS_type = "BEER" THEN
		EMReadScreen IEVS_year, 2, 8, 15
		IEVS_year = "20" & IEVS_year
	END IF
END IF

EMReadScreen number_IEVS_type, 3, 7, 12 'read the DAIL msg'
IF number_IEVS_type = "A30" THEN IEVS_type = "BNDX"
IF number_IEVS_type = "A40" THEN IEVS_type = "SDXS/I"
IF number_IEVS_type = "A70" THEN IEVS_type = "BEER"
IF number_IEVS_type = "A80" THEN IEVS_type = "UNVI"
IF number_IEVS_type = "A60" THEN IEVS_type = "UBEN"
IF number_IEVS_type = "A50" or number_IEVS_type = "A51"  THEN IEVS_type = "WAGE"
'------------------------------------------setting up case note header'
IF IEVS_type = "BEER" THEN type_match = "B"
IF IEVS_type = "UBEN" THEN type_match = "U"
IF IEVS_type = "WAGE" THEN type_match = "U"
IF IEVS_type = "WAGE" THEN EMreadscreen casenote_quarter, 1, 8, 14

'--------------------------------------------------------------------Client name
EmReadScreen panel_name, 4, 02, 52
IF panel_name <> "IULA" THEN script_end_procedure("Script did not find IULA.")
EMReadScreen client_name, 35, 5, 24
client_name = trim(client_name)                         'trimming the client name
IF instr(client_name, ",") THEN    						'Most cases have both last name and 1st name. This separates the two names
	length = len(client_name)                           'establishing the length of the variable
	position = InStr(client_name, ",")                  'sets the position at the deliminator (in this case the comma)
	last_name = Left(client_name, position-1)           'establishes client last name as being before the deliminator
	first_name = Right(client_name, length-position)    'establishes client first name as after before the deliminator
ELSEIF instr(first_name, " ") THEN   						'If there is a middle initial in the first name, THEN it removes it
	length = len(first_name)                        	'trimming the 1st name
	position = InStr(first_name, " ")               	'establishing the length of the variable
	first_name = Left(first_name, position-1)       	'trims the middle initial off of the first name
ELSE                                'In cases where the last name takes up the entire space, THEN the client name becomes the last name
	first_name = ""
	last_name = client_name
END IF
first_name = trim(first_name)
IF instr(first_name, " ") THEN   						'If there is a middle initial in the first name, THEN it removes it
	length = len(first_name)                        	'trimming the 1st name
	position = InStr(first_name, " ")               	'establishing the length of the variable
	first_name = Left(first_name, position-1)       	'trims the middle initial off of the first name
END IF

'----------------------------------------------------------------------------------------------------ACTIVE PROGRAMS
EMReadScreen Active_Programs, 13, 6, 68
Active_Programs = trim(Active_Programs)

programs = ""
IF instr(Active_Programs, "D") THEN programs = programs & "DWP, "
IF instr(Active_Programs, "F") THEN programs = programs & "Food Support, "
IF instr(Active_Programs, "H") THEN programs = programs & "Health Care, "
IF instr(Active_Programs, "M") THEN programs = programs & "Medical Assistance, "
IF instr(Active_Programs, "S") THEN programs = programs & "MFIP, "
'trims excess spaces of programs
programs = trim(programs)
'takes the last comma off of programs when autofilled into dialog
IF right(programs, 1) = "," THEN programs = left(programs, len(programs) - 1)
'----------------------------------------------------------------------------------------------------Employer info & difference notice info
EMReadScreen income_source, 75, 8, 37
income_source = trim(income_source)
length = len(income_source)		'establishing the length of the variable

IF instr(income_source, " AMOUNT: $") THEN
    position = InStr(income_source, " AMOUNT: $")    		      'sets the position at the deliminator
    income_source = Left(income_source, position)  'establishes employer as being before the deliminator
Elseif instr(income_source, " AMT: $") THEN 					  'establishing the length of the variable
    position = InStr(income_source, " AMT: $")    		      'sets the position at the deliminator
    income_source = Left(income_source, position)  'establishes employer as being before the deliminator
Else
    income_source = income_source	'catch all variable
END IF

discovery_date = date

BeginDialog overpayment_dialog, 0, 0, 361, 230, "Match Cleared CC Claim Entered"
EditBox 60, 5, 40, 15, MAXIS_case_number
EditBox 60, 25, 40, 15, discovery_date
DropListBox 160, 5, 40, 15, "Select:"+chr(9)+"YES"+chr(9)+"NO", fraud_referral
EditBox 140, 25, 20, 15, memb_number
EditBox 230, 25, 20, 15, OT_resp_memb
DropListBox 300, 5, 55, 15, "Select:"+chr(9)+"1"+chr(9)+"2"+chr(9)+"3"+chr(9)+"4"+chr(9)+"YEAR"+chr(9)+"LAST YEAR"+chr(9)+"OTHER", casenote_quarter
DropListBox 300, 25, 55, 15, "Select:"+chr(9)+"BNDX"+chr(9)+"SDXS"+chr(9)+"BEER"+chr(9)+"NONE"+chr(9)+"UNVI"+chr(9)+"UBEN"+chr(9)+"WAGE", IEVS_type
DropListBox 50, 65, 50, 15, "Select:"+chr(9)+"DW"+chr(9)+"FS"+chr(9)+"FG"+chr(9)+"GA"+chr(9)+"GR"+chr(9)+"MF"+chr(9)+"MS", OP_program
EditBox 130, 65, 30, 15, OP_from
EditBox 180, 65, 30, 15, OP_to
EditBox 245, 65, 35, 15, Claim_number
EditBox 305, 65, 45, 15, Claim_amount
DropListBox 50, 85, 50, 15, "Select:"+chr(9)+"DW"+chr(9)+"FS"+chr(9)+"FG"+chr(9)+"GA"+chr(9)+"GR"+chr(9)+"MF"+chr(9)+"MS", OP_program_II
EditBox 130, 85, 30, 15, OP_from_II
EditBox 180, 85, 30, 15, OP_to_II
EditBox 245, 85, 35, 15, Claim_number_II
EditBox 305, 85, 45, 15, Claim_amount_II
  EditBox 130, 105, 30, 15, HC_from
  EditBox 180, 105, 30, 15, HC_to
  EditBox 245, 105, 35, 15, HC_claim_number
  EditBox 305, 105, 45, 15, HC_claim_amount
EditBox 190, 125, 20, 15, HC_resp_memb
EditBox 305, 125, 45, 15, Fed_HC_AMT
EditBox 70, 150, 160, 15, income_source
CheckBox 235, 155, 120, 10, "Earned Income Disregard Allowed", EI_checkbox
EditBox 70, 170, 160, 15, EVF_used
EditBox 310, 170, 45, 15, income_rcvd_date
EditBox 70, 190, 285, 15, Reason_OP
ButtonGroup ButtonPressed
  OkButton 260, 210, 45, 15
  CancelButton 310, 210, 45, 15
Text 5, 10, 50, 10, "Case Number: "
Text 250, 10, 45, 10, "Match Period:"
Text 5, 30, 55, 10, "Discovery Date: "
Text 105, 10, 50, 10, "Fraud Referral:"
Text 260, 30, 40, 10, "IEVS Type:"
Text 105, 30, 30, 10, "Memb #:"
Text 170, 30, 60, 10, "Ot Resp. Memb #:"
GroupBox 5, 45, 350, 100, "Overpayment Information"
Text 15, 70, 30, 10, "Program:"
Text 105, 70, 20, 10, "From:"
Text 165, 70, 10, 10, "To:"
Text 215, 70, 25, 10, "Claim #"
Text 285, 70, 20, 10, "AMT:"
Text 15, 90, 30, 10, "Program:"
Text 105, 90, 20, 10, "From:"
Text 165, 90, 10, 10, "To:"
Text 215, 90, 25, 10, "Claim #"
Text 285, 90, 20, 10, "AMT:"
Text 15, 110, 70, 10, "HC Program(s) Only:"
Text 105, 110, 20, 10, "From:"
Text 165, 110, 10, 10, "To:"
Text 215, 110, 25, 10, "Claim #"
Text 285, 110, 20, 10, "AMT:"
Text 15, 155, 50, 10, "Income Source:"
Text 5, 175, 65, 10, "Income Verif Used:"
Text 90, 130, 100, 10, "Health Care Resp. Memb(s) #:"
Text 230, 130, 75, 10, "Total Federal HC AMT:"
Text 25, 195, 40, 10, "OP Reason:"
Text 245, 175, 65, 10, "Date Income Rcvd: "
Text 130, 55, 30, 10, "(MM/YY)"
Text 180, 55, 30, 10, "(MM/YY)"
EndDialog

Do
    Do
    	err_msg = ""
    	dialog overpayment_dialog
    	cancel_confirmation
    	IF MAXIS_case_number = "" or IsNumeric(MAXIS_case_number) = False or len(MAXIS_case_number) > 8 then err_msg = err_msg & vbnewline & "* Enter a valid case number."
    	IF casenote_quarter = "Select:" THEN err_msg = err_msg & vbnewline & "* You must select a match period entry."
    	IF fraud_referral = "Select:" THEN err_msg = err_msg & vbnewline & "* You must select a fraud referral entry."
    	IF trim(Reason_OP) = "" or len(Reason_OP) < 5 THEN err_msg = err_msg & vbnewline & "* You must enter a reason for the overpayment please provide as much detail as possible (min 5)."
    	IF OP_program = "Select:"THEN err_msg = err_msg & vbNewLine &  "* Please enter the program for the overpayment."
    	IF OP_program_II <> "Select:" THEN
    		IF OP_from_II = "" THEN err_msg = err_msg & vbNewLine &  "* Please enter the month and year overpayment occurred."
    		IF Claim_number_II = "" THEN err_msg = err_msg & vbNewLine &  "* Please enter the claim number."
    		IF Claim_amount_II = "" THEN err_msg = err_msg & vbNewLine &  "* Please enter the amount of claim."
    	END IF
    	IF HC_claim_number <> "" THEN
    		IF HC_from = "" THEN err_msg = err_msg & vbNewLine &  "* Please enter the month and year overpayment started."
    		IF HC_to = "" THEN err_msg = err_msg & vbNewLine &  "* Please enter the month and year overpayment ended."
    		IF HC_claim_amount = "" THEN err_msg = err_msg & vbNewLine &  "* Please enter the amount of claim."
    	END IF
    	IF IEVS_type = "Select:" THEN err_msg = err_msg & vbnewline & "* You must select a match type entry."
    	IF EVF_used = "" then err_msg = err_msg & vbNewLine & "* Please enter verication used for the income recieved. If no verification was received enter N/A."
    	IF isdate(income_rcvd_date) = False or income_rcvd_date = "" then err_msg = err_msg & vbNewLine & "* Please enter a valid date for the income recieved."
    	IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine		'error message including instruction on what needs to be fixed from each mandatory field if incorrect
    LOOP UNTIL err_msg = ""
    CALL check_for_password_without_transmit(are_we_passworded_out)
Loop Until are_we_passworded_out = false
	'----------------------------------------------------------------------------------------------------RESOLVING THE MATCH
' EMReadScreen confirm_income_source, 75, 8, 37
' confirm_income_source = trim(confirm_income_source)
' IF confirm_income_source <> income_source THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & income_source & vbNewLine

EmReadScreen panel_name, 4, 02, 52
IF panel_name <> "IULA" THEN
    EmReadScreen back_panel_name, 4, 2, 52
    If back_panel_name <> "IEVP" Then
        CALL back_to_SELF
        CALL navigate_to_MAXIS_screen("INFC" , "____")
        CALL write_value_and_transmit("IEVP", 20, 71)
        CALL write_value_and_transmit(SSN_number_read, 3, 63)
    End If
    CALL write_value_and_transmit("U", row, 3)   'navigates to IULA
End If

EMWriteScreen "030", 12, 46

col = 57
Do
    EMReadscreen action_header, 4, 11, col

    If action_header <> "    " Then
        If action_header = "ACTH" Then
            EMWriteScreen "BE", 12, col+1
        Else
            EMWriteScreen "CC", 12, col+1
        End If
    End If

    col = col + 6
Loop until action_header = "    "

' IF programs = "Health Care" THEN
' 	' EMWriteScreen "BE", row + 1, col + 1
'     EMWriteScreen "BE", 12, 58
' ELSE
' 	' EMWriteScreen "CC", row + 1, col + 1
'     EMWriteScreen "CC", 12, 58
' END IF

TRANSMIT
'----------------------------------------------------------------------------------------writing the note on IULB
'EmReadScreen panel_name, 4, 02, 52
'IF panel_name = "IULB" THEN msgbox "Script did not find IULB."

Call clear_line_of_text(8, 6)

EMReadScreen err_msg, 11, 24, 2
err_msg = trim(err_msg)
IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
If err_msg = "ACTION CODE" THEN script_end_procedure(err_msg & vbNewLine & "Please ensure you are selecting the correct code for resolve. PF10 to ensure the match can be resolved using the script.")'checking for error msg'
EMWriteScreen "Claim entered. See Case Note. ", 8, 6
Call clear_line_of_text(17, 9)
IF OP_program <> "HC" THEN  EMWriteScreen Claim_number, 17, 9
'need to check about adding for mutli claims'
'msgbox "did the notes input?"
TRANSMIT 'this will take us back to IEVP main menu'

EmReadScreen panel_name, 4, 02, 52
IF panel_name <> "IEVP" THEN 'msgbox "Script did not find IEVP."
    CALL back_to_SELF
    CALL navigate_to_MAXIS_screen("INFC" , "____")
    CALL write_value_and_transmit("IEVP", 20, 71)
    CALL write_value_and_transmit(SSN_number_read, 3, 63)
End If
'------------------------------------------------------------------back on the IEVP menu, making sure that the match cleared
'msgbox panel_name
EMReadScreen days_pending, 5, row, 72
days_pending = trim(days_pending)
atch_cleared = TRUE
IF IsNumeric(days_pending) = TRUE THEN match_cleared = FALSE

If match_cleared = FALSE Then
    confirm_cleared = MsgBox ("The script cannot identify that this match has cleared." & vbNewLine & vbNewLine & "Review IEVP and find the match that is being cleared with this run." &vbNewLine & " ** HAS THE MATCH BEEN CLEARED? **", vbQuestion + vbYesNo, "Confirm Match Cleared")

    if confirm_cleared = vbYes Then match_cleared = TRUE
End If
If match_cleared = FALSE Then script_end_procedure("This match did not appear to clear. Please check case, and try again.")

' 	match_cleared = FALSE
' 	script_end_procedure("This match did not appear to clear. Please check case, and try again.")
' ELSE
' 	match_cleared = TRUE
' END IF

IF IEVS_type = "WAGE" THEN
	IF casenote_quarter = 1 THEN IEVS_quarter = "1ST"
	IF casenote_quarter = 2 THEN IEVS_quarter = "2ND"
 	IF casenote_quarter = 3 THEN IEVS_quarter = "3RD"
 	IF casenote_quarter = 4 THEN IEVS_quarter = "4TH"
END IF
IEVS_period = replace(IEVS_period, "/", " to ")
Due_date = dateadd("d", 10, date)	'defaults the due date for all verifications at 10 days requested for HEADER of casenote'
PF3 'back to the DAIL'
PF3
'Going to the MISC panel to add claim referral tracking information
Call navigate_to_MAXIS_screen ("STAT", "MISC")
Row = 6

EmReadScreen panel_number, 1, 02, 78
If panel_number = "0" then
	EMWriteScreen "NN", 20,79
	TRANSMIT
ELSE
	Do
		'Checking to see if the MISC panel is empty, if not it will find a new line'
		EmReadScreen MISC_description, 25, row, 30
		MISC_description = replace(MISC_description, "_", "")
		If trim(MISC_description) = "" then
			PF9
			EXIT DO
		Else
			row = row + 1
		End if
	Loop Until row = 17
	If row = 17 then MsgBox("There is not a blank field in the MISC panel. Please delete a line(s), and run script again or update manually.")
End if
'writing in the action taken and date to the MISC panel
EMWriteScreen "Claim Determination", Row, 30
EMWriteScreen date, Row, 66
PF3
start_a_blank_CASE_NOTE
Call write_variable_in_case_note("-----Claim Referral Tracking-----")
Call write_bullet_and_variable_in_case_note("Program(s)", programs)
Call write_bullet_and_variable_in_case_note("Action Date", date)
Call write_variable_in_case_note("* Entries for these potential claims must be retained until further notice.")
Call write_variable_in_case_note("-----")
Call write_variable_in_case_note(worker_signature)
  '    ----------------------------------------------------------------the case match CLEARED note
start_a_blank_CASE_NOTE
IF IEVS_type = "WAGE" THEN CALL write_variable_in_CASE_NOTE("-----" & IEVS_quarter & " QTR " & IEVS_year & " WAGE MATCH"  & "(" & first_name & ") CLEARED CC-CLAIM ENTERED-----")
IF IEVS_type = "BEER" THEN CALL write_variable_in_CASE_NOTE("-----" & IEVS_year & " NON-WAGE MATCH(" & type_match & ") " & "(" & first_name & ") CLEARED CC-CLAIM ENTERED-----")
IF IEVS_type = "UBEN" THEN CALL write_variable_in_CASE_NOTE("-----" & IEVS_month & " NON-WAGE MATCH(" & type_match & ") " & "(" & first_name & ") CLEARED CC-CLAIM ENTERED-----")
CALL write_bullet_and_variable_in_CASE_NOTE("Discovery date", discovery_date)
CALL write_bullet_and_variable_in_CASE_NOTE("Period", IEVS_period)
CALL write_bullet_and_variable_in_CASE_NOTE("Active Programs", programs)
CALL write_bullet_and_variable_in_CASE_NOTE("Source of income", income_source)
Call write_variable_in_CASE_NOTE("----- ----- -----")
Call write_variable_in_CASE_NOTE(OP_program & " Overpayment " & OP_from & " through " & OP_to & " Claim # " & Claim_number & " Amt $" & Claim_amount)
IF OP_program_II <> "Select:" then
	Call write_variable_in_CASE_NOTE(OP_program_II & " Overpayment " & OP_from_II & " through " & OP_to_II & " Claim # " & Claim_number_II & " Amt $" & Claim_amount_II)
	Call write_variable_in_CASE_NOTE("----- ----- -----")
END IF

IF HC_claim_number <> "" THEN
	Call write_variable_in_CASE_NOTE("HC OVERPAYMENT CLAIM ENTERED" & " (" & first_name & ") " & HC_from & " through " & HC_to)
	Call write_variable_in_CASE_NOTE("* HC Claim # " & HC_claim_number & " Amt $" & HC_Claim_amount)
	Call write_bullet_and_variable_in_CASE_NOTE("Health Care responsible members", HC_resp_memb)
	Call write_bullet_and_variable_in_CASE_NOTE("Total Federal Health Care amount", Fed_HC_AMT)
	CALL write_bullet_and_variable_in_CASE_NOTE("Discovery date", discovery_date)
	CALL write_bullet_and_variable_in_CASE_NOTE("Source of income", income_source)
	Call write_variable_in_CASE_NOTE("Emailed HSPHD Accounts Receivable for the medical overpayment(s)")
	Call write_variable_in_CASE_NOTE("----- ----- -----")
END IF
IF EI_checkbox = CHECKED THEN CALL write_variable_in_case_note("* Earned Income Disregard Allowed")
IF EI_checkbox = UNCHECKED THEN CALL write_variable_in_case_note("* Earned Income Disregard Not Allowed")
CALL write_bullet_and_variable_in_case_note("Fraud referral made", fraud_referral)
CALL write_bullet_and_variable_in_case_note("Income verification received", EVF_used)
CALL write_bullet_and_variable_in_case_note("Date verification received", income_rcvd_date)
CALL write_bullet_and_variable_in_case_note("Reason for overpayment", Reason_OP)
CALL write_bullet_and_variable_in_case_note("Other responsible member(s)", OT_resp_memb)
CALL write_variable_in_CASE_NOTE("----- ----- ----- ----- ----- ----- -----")
CALL write_variable_in_CASE_NOTE("DEBT ESTABLISHMENT UNIT 612-348-4290 PROMPTS 1-1-1")
PF3 'to save casenote'
IF HC_claim_number <> "" THEN
	EmWriteScreen "x", 5, 3
	Transmit
	note_row = 4			'Beginning of the case notes
	Do 						'Read each line
		EMReadScreen note_line, 76, note_row, 3
       	note_line = trim(note_line)
		If trim(note_line) = "" Then Exit Do		'Any blank line indicates the end of the case note because there can be no blank lines in a note
		message_array = message_array & note_line & vbcr		'putting the lines together
		note_row = note_row + 1
		If note_row = 18 then 									'End of a single page of the case note
		EMReadScreen next_page, 7, note_row, 3
		If next_page = "More: +" Then 						'This indicates there is another page of the case note
			PF8												'goes to the next line and resets the row to read'\
			note_row = 4
				End If
			End If
	Loop until next_page = "More:  " OR next_page = "       "	'No more pages
	'Function create_outlook_email(email_recip, email_recip_CC, email_subject, email_body, email_attachment, send_email)
CALL create_outlook_email("HSPH.FIN.Unit.AR.Spaulding@hennepin.us", "","Claims entered for #" &  MAXIS_case_number & " Member # " & memb_number & " Date Overpayment Created: " & discovery_date & "HC Claim # " & HC_claim_number, "CASE NOTE" & vbcr & message_array,"", False)
END IF

script_end_procedure("Overpayment case note entered please review case note to ensure accuracy and copy case note to CCOL.")
