name_of_script = "ACTIONS-PARIS-MATCH-CLAIM-ENTERED.vbs"
start_time = timer
STATS_counter = 1              'sets the stats counter at one
STATS_manualtime = 300         'manual run time in seconds
STATS_denomination = "C"      'C is for each case
'END OF stats block=========================================================================================================

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_loCALLy = FALSE or run_loCALLy = "" THEN	   'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF use_master_branch = TRUE THEN			   'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		ELSE											'Everyone ELSE should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/RELEASE/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		END IF
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

CALL changelog_update("12/27/2017", "Updates made to correct error.", "MiKayla Handley, Hennepin County")
CALL changelog_update("12/11/2017", "Initial version.", "MiKayla Handley, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================


function DEU_password_check(end_script)
'--- This function checks to ensure the user is in a MAXIS panel
'~~~~~ end_script: If end_script = TRUE the script will end. If end_script = FALSE, the user will be given the option to cancel the script, or manually navigate to a MAXIS screen.
	'===== Keywords: MAXIS, production, script_end_procedure
	Do
		EMReadScreen MAXIS_check, 5, 1, 39
		If MAXIS_check <> "MAXIS"  and MAXIS_check <> "AXIS " then
			If end_script = True then
				script_end_procedure("You do not appear to be in MAXIS. You may be passworded out. Please check your MAXIS screen and try again.")
			Else
				warning_box = MsgBox("You do not appear to be in MAXIS. You may be passworded out. Please check your MAXIS screen and try again, or press ""cancel"" to exit the script.", vbOKCancel)
				If warning_box = vbCancel then stopscript
			End if
		End if
	Loop until MAXIS_check = "MAXIS" or MAXIS_check = "AXIS "
end function

'---------------------------------------------------------------------The dialog
	'Connecting to MAXIS
	EMConnect ""
	BeginDialog PARIS_match_claim_dialog, 0, 0, 361, 245, "Overpayment Claim Entered"
		EditBox 55, 5, 35, 15, MAXIS_case_number
		EditBox 150, 5, 45, 15, discovery_date
		EditBox 240, 5, 20, 15, memb_number
	  EditBox 330, 5, 20, 15, OT_resp_memb
		DropListBox 55, 25, 40, 15, "Select:"+chr(9)+"YES"+chr(9)+"NO", fraud_referral
		DropListBox 150, 25, 50, 15, "Select:"+chr(9)+"BEER"+chr(9)+"UBEN"+chr(9)+"WAGE", IEVS_type
		DropListBox 295, 25, 55, 15, "Select:"+chr(9)+"1"+chr(9)+"2"+chr(9)+"3"+chr(9)+"4"+chr(9)+"YEAR"+chr(9)+"LAST YEAR"+chr(9)+"OTHER", select_quarter
		DropListBox 50, 65, 50, 15, "Select:"+chr(9)+"DW"+chr(9)+"FS"+chr(9)+"FG"+chr(9)+"HC"+chr(9)+"GA"+chr(9)+"GR"+chr(9)+"MF"+chr(9)+"MS", OP_program
	  EditBox 130, 65, 30, 15, OP_from
	  EditBox 180, 65, 30, 15, OP_to
	  EditBox 245, 65, 35, 15, Claim_number
	  EditBox 305, 65, 45, 15, Claim_amount
	  DropListBox 50, 85, 50, 15, "Select:"+chr(9)+"DW"+chr(9)+"FS"+chr(9)+"FG"+chr(9)+"HC"+chr(9)+"GA"+chr(9)+"GR"+chr(9)+"MF"+chr(9)+"MS", OP_program_II
	  EditBox 130, 85, 30, 15, OP_from_II
	  EditBox 180, 85, 30, 15, OP_to_II
	  EditBox 245, 85, 35, 15, Claim_number_II
	  EditBox 305, 85, 45, 15, Claim_amount_II
	  DropListBox 50, 105, 50, 15, "Select:"+chr(9)+"DW"+chr(9)+"FS"+chr(9)+"FG"+chr(9)+"HC"+chr(9)+"GA"+chr(9)+"GR"+chr(9)+"MF"+chr(9)+"MS", OP_program_III
	  EditBox 130, 105, 30, 15, OP_from_III
	  EditBox 180, 105, 30, 15, OP_to_III
	  EditBox 245, 105, 35, 15, Claim_number_III
	  EditBox 305, 105, 45, 15, Claim_amount_III
	  EditBox 70, 140, 160, 15, EVF_used
		EditBox 305, 140, 50, 15, income_rcvd_date
		EditBox 70, 160, 285, 15, Reason_OP
		DropListBox 105, 180, 40, 15, "Select:"+chr(9)+"YES"+chr(9)+"NO", EI_allowed_dropdown
		DropListBox 200, 180, 40, 15, "Select:"+chr(9)+"YES"+chr(9)+"NO", collectible_dropdown
	  DropListBox 270, 180, 85, 15, "Select:"+chr(9)+"HH No Info"+chr(9)+"HH Incorrect Or Incompl"+chr(9)+"HH Not Timely Inform"+chr(9)+"Estimate Wrong Inadv"+chr(9)+"No HRF"+chr(9)+"Benefits Rcd Pend App"+chr(9)+"Replacement Bene Used" +chr(9)+"Prog Pol Prevents Chg" +chr(9)+"EBT- Representment" +chr(9)+"IEVS - BEER"+chr(9)+"IEVS - BENDEX" +chr(9)+"IEVS - UNVI"+chr(9)+"IEVS - SDX"+chr(9)+"IEVS - WAGE"+chr(9)+"IEVS - UBEN"+chr(9)+"PARIS Inter-state Match"+chr(9)+"Agency: Delay   Action"+chr(9)+"Agency: Issue Comp Error"+chr(9)+"Agency: Dup Issuance"+chr(9)+"Agency:$50 Pass-Thru"+chr(9)+"GRH Vndr: No Info"+chr(9)+"GRH Vndr: Incomplete"+chr(9)+"GRH Vndr: Not Timely"+chr(9)+"GRH Vndr: Client Left Faci"+chr(9)+"99 Other", collectible_reason_dropdown
		EditBox 70, 160, 285, 15, Reason_OP
		EditBox 95, 200, 60, 15, HC_resp_memb
	  EditBox 290, 200, 65, 15, Fed_HC_AMT
	  ButtonGroup ButtonPressed
	      OkButton 260, 225, 45, 15
	      CancelButton 310, 225, 45, 15
	  Text 5, 10, 50, 10, "Case Number: "
	  Text 95, 10, 55, 10, "Discovery Date: "
	  Text 245, 30, 45, 10, "Match Period:"
	  Text 5, 30, 50, 10, "Fraud referral:"
	  Text 105, 30, 40, 10, "IEVS Type:"
	  Text 205, 10, 30, 10, "MEMB #:"
	  Text 270, 10, 60, 10, "Other resp. memb:"
	  GroupBox 10, 45, 345, 90, "Overpayment Information"
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
	  Text 15, 110, 30, 10, "Program:"
	  Text 105, 110, 20, 10, "From:"
	  Text 165, 110, 10, 10, "To:"
	  Text 215, 110, 25, 10, "Claim #"
	  Text 285, 110, 20, 10, "AMT:"
	  Text 150, 185, 40, 10, "Collectible?"
	  Text 240, 185, 30, 10, "Reason:"
	  Text 5, 145, 60, 10, "Income verif used:"
	  Text 05, 205, 90, 10, "HC responsible members:"
	  Text 200, 205, 85, 10, "Total Federal HC amount:"
	  Text 15, 165, 50, 10, "Reason for OP:"
	  Text 240, 145, 60, 10, "Date income rcvd: "
	  Text 5, 185, 100, 10, "E. Income disregard allowed?"
		Text 180, 55, 30, 10, "(MM/YY)"
	  Text 130, 55, 30, 10, "(MM/YY)"
	EndDialog


	Do
		err_msg = ""
		dialog PARIS_match_claim_dialog
		IF buttonpressed = 0 then stopscript
		IF MAXIS_case_number = "" or IsNumeric(MAXIS_case_number) = False or len(MAXIS_case_number) > 8 then err_msg = err_msg & vbnewline & "* Enter a valid case number."
		IF select_quarter = "Select:" THEN err_msg = err_msg & vbnewline & "* You must select a match period entry."
		IF fraud_referral = "Select:" THEN err_msg = err_msg & vbnewline & "* You must select a fraud referral entry."
		IF IEVS_type = "Select:" THEN err_msg = err_msg & vbnewline & "* You must select a match type entry."
		IF EI_allowed_dropdown = "Select:" THEN err_msg = err_msg & vbnewline & "* Please advise if Earned Income disregard was allowed."
		IF income_rcvd_date = "" THEN err_msg = err_msg & vbnewline & "* Please advise of date income was received."
		IF OP_program = "Select:" THEN err_msg = err_msg & vbnewline & "* You must have an overpayment entry."
		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine		'error message including instruction on what needs to be fixed from each mandatory field if incorrect
	LOOP UNTIL err_msg = ""
	CALL DEU_password_check(False)

	EMReadscreen dail_check, 4, 2, 48
	IF dail_check = "DAIL" THEN
		EMSendKey "t"
	  transmit
	  EMReadScreen DAIL_message, 4, 6, 6 'read the DAIL msg'
	  IF DAIL_message <> "PARI" THEN script_end_procedure("This is not a Paris match. Please select a Paris match, and run the script again.")
	  EMReadScreen MAXIS_case_number, 8, 5, 73
	  MAXIS_case_number= TRIM(MAXIS_case_number)
	  'Navigating deeper into the match interface
	  CALL write_value_and_transmit("I", 6, 3)   'navigates to INFC
	  CALL write_value_and_transmit("INTM", 20, 71)   'navigates to INTM
	  EMReadScreen error_msg, 2, 24, 2
	  error_msg = TRIM(error_msg)
	  IF error_msg <> "" THEN script_end_procedure("An error occurred in INFC, please process manually.")'-------option to read from REPT need to checking for error msg'

	ELSE
		CALL MAXIS_case_number_finder (MAXIS_case_number)
		memb_number = "01"
		date_recieved = date & ""
	  Row = 8
	  DO
	  	EMReadScreen Status, 2, row, 73 'DO loop to check status of case before we go into insm'
	  	IF Status <> "UR" THEN
	  		row = row + 1
	      ELSE
	  		EXIT DO
	  	END IF
	  LOOP UNTIL trim(Status) = "" or row = 19

	  CALL write_value_and_transmit("X", row, 3) 'navigating to insm'
	  'Ensuring that the client has not already had a difference notice sent
	  EMReadScreen notice_sent, 1, 8, 73
	  EMReadScreen sent_date, 8, 9, 73
	  If trim(sent_date) <> "" then sent_date= replace(sent_date, " ", "/")
	  '--------------------------------------------------------------------Client name
	  'Reading client name and splitting out the 1st name
	  EMReadScreen Client_Name, 26, 5, 27
	  'Formatting the client name for the spreadsheet
	  client_name = trim(client_name)                         'trimming the client name
	  IF instr(client_name, ",") THEN    						'Most cases have both last name and 1st name. This separatesthe two names
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
	  '----------------------------------------------------------------------Minnesota active programs
	  EMReadScreen MN_Active_Programs, 15, 6, 59
	  MN_active_programs = Trim(MN_active_programs)
	  MN_active_programs = Trim(MN_active_programs)
	  MN_active_programs = replace(MN_active_programs, " ", ", ")

	  'Month of the PARIS match
	  EMReadScreen Match_Month, 2, 6, 27
	  Match_month = replace(Match_Month, " ", "/")
	  EMReadScreen Match_year, 2, 6, 30
	  Match_year = replace(Match_year, " ", "/")

	  '--------------------------------------------------------------------PARIS match state & active programs-this will handle more than one state
	  DIM state_array()
	  ReDIM state_array(5, 0)
	  add_state = 0

	  Const row_num			= 1
	  Const state_name		= 2
	  Const match_case_num 	= 3
	  Const contact_info		= 4
	  Const progs 			= 5

	  row = 13
	  DO
	  	EMReadScreen state, 2, row, 3
	  	IF trim(state) = "" THEN
	  		EXIT DO
	  	ELSE
	  		'-------------------------------------------------------------------Case number for match state (if exists)
	  		EMReadScreen Match_State_Case_Number, 13, row, 9
	  		Match_State_Case_Number = trim(Match_State_Case_Number)
	  		IF Match_State_Case_Number = "" THEN Match_State_Case_Number = "N/A"
	  		Redim Preserve state_array(5, 	add_state)
	  		state_array(row_num, 			add_state) = row
	  		state_array(state_name, 		add_state) = state
	  		state_array(match_case_num, 	add_state) = Match_State_Case_Number
	  		add_state = add_state + 1
	  		END IF
	  	row = row + 3
	  	IF row = 19 THEN
	  		PF8
	  		EMReadScreen last_page_check, 21, 24, 2
	  		last_page_check = trim(last_page_check)
	  		IF last_page_check = "" THEN MsgBox "It appears there are 3 or more matches on this case, please process additional cases manually. The script will process the first two states."
	  	END IF
	  LOOP UNTIL last_page_check = "THIS IS THE LAST PAGE"

	  For item = 0 to Ubound(state_array, 2)
	  	row = state_array(row_num, item)
	      Match_Active_Programs = "" 'sometimes blanking over information will clear the value of the variable'
	      DO
	      	EMReadScreen Match_Prog, 22, row, 60
	      	Match_Prog = TRIM(Match_Prog)
	  		IF Match_Prog = "FOOD SUPPORT" THEN  Match_Prog = "FS"
	  		IF Match_Prog = "HEALTH CARE" THEN Match_Prog = "HC"
	      	IF Match_Prog <> "" THEN Match_Active_Programs = Match_Active_Programs & Match_Prog & ", "
	  		row = row + 1
	      LOOP UNTIL Match_Prog = "" or row = 19

	  	'-------------------------------------------------------------------trims excess spaces of Match_Active_Programs
	  	Match_Active_Programs = trim(Match_Active_Programs)
	  	'takes the last comma off of Match_Active_Programs when autofilled into dialog if more more than one app date is found and additional app is selected
	  	IF right(Match_Active_Programs, 1) = "," THEN Match_Active_Programs = left(Match_Active_Programs, len(Match_Active_Programs) - 1)
	  	state_array(progs, item) = Match_Active_Programs

	  	row = state_array(row_num, item)		're-establish the value of row to read phone and fax info
	  	Match_contact_info = ""
	  	phone_number = ""
	  	fax_number = ""

	  	'-------------------------------------------------------------------PARIS match contact information
	  	EMReadScreen Phone_Number, 23, row, 22
	  	Phone_Number = TRIM(Phone_Number)
	  	If Phone_Number = "Phone: (     )" then
	  		Phone_Number = ""
	  	Else
	  		EMReadScreen Phone_Number_ext, 8, row, 51
	  		Phone_Number_ext = trim(Phone_Number_ext)
	  		If Phone_Number_ext <> "" then Phone_Number = Phone_Number & " Ext: " & Phone_Number_ext
	  	End if
	  	'-------------------------------------------------------------------reading and cleaning up the fax number if it exists
	  	EMReadScreen fax_check, 8, row + 1, 37
	  	fax_check = trim(fax_check)
	  	If fax_check <> "" then
	  		EMReadScreen fax_number, 21, row + 1, 24
	  		fax_number = TRIM(fax_number)
	  	End if

	  	If fax_number = "Fax: (     )" then fax_number = ""
	  	Match_contact_info = phone_number & " " & fax_number
	  	state_array(contact_info, item) = Match_contact_info





	  start_a_blank_CASE_NOTE
	  CALL write_variable_in_CASE_NOTE ("-----" & Match_month &"/" & Match_year & " PARIS MATCH " & "(" & first_name &  ") OVERPAYMENT CLAIM ENTERED-----")
	  CALL write_bullet_and_variable_in_CASE_NOTE("Client Name", Client_Name)
	  CALL write_bullet_and_variable_in_CASE_NOTE("MN Active Programs", MN_active_programs)
	  'formatting for multiple states
	  FOR item = 0 to Ubound(state_array, 2)
	  	CALL write_variable_in_CASE_NOTE("----- Match State: " & state_array(state_name, item) & " -----")
	  	CALL write_bullet_and_variable_in_CASE_NOTE("Match State Active Programs", state_array(progs, item))
	  	CALL write_bullet_and_variable_in_CASE_NOTE("Match State Contact Info", state_array(contact_info, item))
	  NEXT
	  Call write_variable_in_CASE_NOTE("----- ----- ----- ----- -----")
	  Call write_variable_in_CASE_NOTE(other_programs & programs & " Overpayment " & OP_1 & " through " & OP_to_1 & " Claim # " & Claim_1 & " Amt $" & AMT_1)
	  IF OP_2 <> "" then Call write_variable_in_case_note(other_programs & " Overpayment " & OP_2 & " through  " & OP_to_2 & " Claim # " & Claim_2 & "  Amt $" & AMT_2)
	  IF OP_3 <> "" then Call write_variable_in_case_note(other_programs & " Overpayment " & OP_3 & " through  " & OP_to_3 & " Claim # " & Claim_3 & "  Amt $" & AMT_3)
	  IF OP_4 <> "" then Call write_variable_in_case_note(other_programs & " Overpayment " & OP_4 & " through  " & OP_to_4 & " Claim # " & Claim_4 & "  Amt $" & AMT_4)
	  IF EI_checkbox = CHECKED THEN CALL write_variable_in_case_note("* Earned Income Disregard Allowed")
	  IF instr(Active_Programs, "HC") then
	  	Call write_bullet_and_variable_in_CASE_NOTE("HC responsible members", HC_resp_memb)
	  	Call write_bullet_and_variable_in_CASE_NOTE("Total federal Health Care amount", Fed_HC_AMT)
	  	Call write_variable_in_CASE_NOTE("---Emailed HSPHD Accounts Receivable for the medical overpayment(s)")
	  END IF
	  CALL write_bullet_and_variable_in_case_note("Fraud referral made", fraud_referral)
	  CALL write_bullet_and_variable_in_case_note("Reason that claim is collectible or not", collectible_reason)
	  CALL write_bullet_and_variable_in_case_note("Other responsible member(s)", OT_resp_memb)
	  CALL write_bullet_and_variable_in_case_note("Reason for overpayment", Reason_OP)
	  CALL write_variable_in_CASE_NOTE("----- ----- ----- ----- -----")
	  CALL write_bullet_and_variable_in_CASE_NOTE("Client accessing benefits in other state", bene_other_state)
	  CALL write_bullet_and_variable_in_CASE_NOTE("Contacted other state", Contact_other_state)
	  IF fraud_referral = "YES" THEN CALL write_variable_in_CASE_NOTE("Fraud Referral Made")
	  CALL write_bullet_and_variable_in_CASE_NOTE("Other notes", other_notes)
	  CALL write_variable_in_CASE_NOTE("----- ----- ----- ----- -----")
	  CALL write_variable_in_CASE_NOTE ("DEBT ESTABLISHMENT UNIT 612-348-4290 EXT 1-1-1")