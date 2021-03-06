'LOADING GLOBAL VARIABLES--------------------------------------------------------------------
Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
Set fso_command = run_another_script_fso.OpenTextFile("Q:\Blue Zone Scripts\Public assistance script files\Script Files\SETTINGS - GLOBAL VARIABLES.vbs")
text_from_the_other_script = fso_command.ReadAll
fso_command.Close
Execute text_from_the_other_script

'STATS GATHERING----------------------------------------------------------------------------------------------------
name_of_script = "ANOKA - ACTIONS - SPECIAL ENROLLMENT"
start_time = timer

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

'SCRIPT----------------------------------------------------------------------------------------------------

EMConnect "A" 'Forces worker to use S1 session fo the script

contract_code = "MA 12"
enrollment_date = "05/01/17"

do
	attn
	EMReadScreen MMIS_A_check, 7, 15, 15
	IF MMIS_A_check = "RUNNING" then
	EMSendKey "10" 'to 10
	transmit
	Else
	attn
	EMConnect "B"
	attn
	EMReadScreen MMIS_B_check, 7, 15, 15
	If MMIS_B_check <> "RUNNING" then
		script_end_procedure("MMIS does not appear to be running. This script will now stop.")
	Else
		EMSendKey "10"
		transmit
	End if
	End if
	EMFocus 'Bringing window focus to the second screen if needed.

	'Sending MMIS back to the beginning screen and checking for a password prompt
	Do
	PF6
	EMReadScreen password_prompt, 38, 2, 23
	IF password_prompt = "ACF2/CICS PASSWORD VERIFICATION PROMPT" then StopScript
	EMReadScreen session_start, 18, 1, 7
	Loop until session_start = "SESSION TERMINATED"

	'Getting back in to MMIS and transmitting past the warning screen (workers should already have accepted the warning screen when they logged themself into MMIS the first time!)
	EMWriteScreen "mw00", 1, 2
	transmit
	transmit

	'The following will select the correct version of MMIS. First it looks for C302, then EK01, then C402.
	row = 1
	col = 1
	EMSearch "C302", row, col
	If row <> 0 then
	If row <> 1 then 'It has to do this in case the worker only has one option (as many LTC and OSA workers don't have the option to decide between MAXIS and MCRE case access). The MMIS screen will show the text, but it's in the first row in these instances.
		EMWriteScreen "x", row, 4
		transmit
	End if
	Else 'Some staff may only have EK01 (MMIS MCRE). The script will allow workers to use that if applicable.
	row = 1
	col = 1
	EMSearch "EK01", row, col
	If row <> 0 then
		If row <> 1 then
		EMWriteScreen "x", row, 4
		transmit
		End if
	Else 'Some OSAs have C402 (limited access). This will search for that.
		row = 1
		col = 1
		EMSearch "C402", row, col
		If row <> 0 then
		If row <> 1 then
			EMWriteScreen "x", row, 4
			transmit
		End if
		Else 'Some OSAs have EKIQ (limited MCRE access). This will search for that.
		row = 1
		col = 1
		EMSearch "EKIQ", row, col
		If row <> 0 then
			If row <> 1 then
			EMWriteScreen "x", row, 4
			transmit
			End if
		Else
			script_end_procedure("C402, C302, EKIQ, or EK01 not found. Your access to MMIS may be limited. Contact your script Alpha user if you have questions about using this script.")
		End if
		End if
	End if
	End if

	'Now it finds the recipient file application feature and selects it.
	row = 1
	col = 1
	EMSearch "RECIPIENT FILE APPLICATION", row, col
	EMWriteScreen "x", row, col - 3
	transmit
	PMI_number = ""
	IF retain_provider_check <> 1 THEN health_plan = "Select one..."

	'do the dialog here
	Do
		err_msg = ""
	    BeginDialog dialog1, 0, 0, 211, 95, "Enrollment Information"
	      EditBox 55, 10, 80, 15, PMI_number
	      DropListBox 55, 30, 100, 15, "Select one..."+chr(9)+"Blue Plus"+chr(9)+"Health Partners"+chr(9)+"UCare", Health_plan
	      ButtonGroup ButtonPressed
	      	OkButton 100, 75, 50, 15
	      	CancelButton 155, 75, 50, 15
	      Text 10, 15, 45, 10, "PMI Number:"
	      Text 10, 35, 45, 10, "Health Plan:"
	      CheckBox 10, 50, 195, 10, "Check here to retain this provider for the next script run.", retain_provider_check
	    EndDialog
		Dialog
		cancel_confirmation
		If Health_plan = "Select one..." THEN err_msg = err_msg & vbCr & "Please select Health care plan."
		If err_msg <> "" then MsgBox err_msg
	Loop until err_msg = ""
	'accounting for leaving out 0s on PMI_number
	Do
	If len(PMI_number) < 8 then PMI_number = "0" & PMI_number
	Loop until len(PMI_number) = 8

	'health plans
	If health_plan = "Health Partners" then health_plan_code = "A585713900"
	If health_plan = "UCare" then health_plan_code = "A565813600"
	If health_plan = "Blue Plus" then health_plan_code = "A065813800"

	Contract_code_part_one = left(contract_code, 2)
	Contract_code_part_two = right(contract_code, 2)

	'Now we are in RKEY, and it navigates into the case, transmits, and makes sure we've moved to the next screen.
	EMWriteScreen "c", 2, 19
	EMWriteScreen PMI_number, 4, 19
	transmit
	EMReadscreen RSUM_check, 4, 1, 51   'changed this to RSUM
	If RSUM_check <> "RSUM" then script_end_procedure("The listed PMI number was not found. Check your PMI number and try again.")
	'not needed? 10/29/15
	'Now it gets to RELG for member 01 of this case.
	'EMWriteScreen "rcin", 1, 8
	'transmit
	'EMWriteScreen "x", 11, 2
	'check Rpol to see if there is other insurance available, if so worker processes manually
	EMWriteScreen "rpol", 1, 8
	transmit
	'making sure script got to right panel
	EMReadScreen RPOL_check, 4, 1, 52
	If RPOL_check <> "RPOL" then script_end_procedure("The script was unable to navigate to RPOL process manually if needed.")
	EMreadscreen policy_number, 1, 7, 8
	if policy_number <> " " then
		EMReadScreen rpol_policy_end_date, 8, 7, 65
		IF rpol_policy_end_date = "99/99/99" THEN
			msgbox "This case has spans on RPOL. Please evaluate manually at this time."
			pf6
			stopscript
		END IF
	end if
	EMWriteScreen "rpph", 1, 8
	transmit
	'making sure script got to right panel
	EMReadScreen RPPH_check, 4, 1, 52
	If RPPH_check <> "RPPH" then script_end_procedure("The script was unable to navigate to RPPH process manually if needed.")
	'Grabs client's name
	EMreadscreen client_first_name, 13, 3, 20
	client_first_name  = replace(client_first_name, " ", "")
	EMreadscreen client_last_name, 18, 3, 2
	client_last_name  = replace(client_last_name, " ", "")
	'hard coded for this situation, this ends current span
	enrollment_span_end = DateAdd("D", -1, enrollment_date)
	CALL write_date(enrollment_span_end, "MM/DD/YY", 13, 14)
	'writes disenrollment reason
	' for this script, the disenrollment code = "HP"
	' for this script, the enrollment code = "HP" as well

	' we need to add additional code to enter an enrollment code

	change_reason = "HP"
	EMWriteScreen change_reason, 13, 75
	'resets to bottom of the span list.
	pf11
	'Checks for exclusion code, if not blank then it stops script.
	EMReadscreen XCL_code, 2, 6, 2
	If XCL_code <> "* " then
		EMReadScreen XCL_code_end_date, 8, 6, 18
		IF XCL_code_end_date = "99/99/99" THEN script_end_procedure("There is an active exclusion code. Please process manually.")
		IF datediff("d", date, XCL_code_end_date) >= 0 THEN script_end_procedure("There is an exclusion code that hasn't ended as of today. Please process manually.")
	END IF
	'enter enrollment date
	EMsetcursor 13, 5
	EMSendKey enrollment_date
	'enter managed care plan code
	EMsetcursor 13, 23
	EMSendKey Health_plan_code
	'enter contract code
	EMSetcursor 13, 34
	EMSendkey contract_code_part_one
	EMsetcursor 13, 37
	EMSendkey contract_code_part_two
	'enter change reason
	EMsetcursor 13, 71
	EMsendkey change_reason
	'Asks worker to make sure the script has entered into the right case and cancels out to RKEY if worker hits cancel to no save anything.

	DO
		PMI_correct = MsgBox ("Please verify that the PMI and client are correct and click OK. If the PMI was entered incorrectly hit cancel and start the script again.", vbOKCancel)

		IF PMI_correct = vbCancel THEN
			double_check_cancel = MsgBox ("Are you sure you want to cancel the script? Press YES to cancel. Press NO to return to the script.", vbYesNo)
			IF double_check_cancel = vbNo THEN script_end_procedure("Script cancelled")
		END IF
	LOOP UNTIL PMI_correct = vbOK

	'Heading to REFM
	EMWriteScreen "refm", 1, 8
	transmit
	'making sure script got to right panel
	EMReadScreen REFM_check, 4, 1, 52
	If REFM_check <> "REFM" then script_end_procedure("The script was unable to navigate to REFM process manually if needed.")
	'checks for edit after hitting transmit
	Emreadscreen edit_check, 1, 24, 2
	If edit_check <> " " then script_end_procedure("There is an edit on this action. Please review the edit and proceed manually.")
	EMReadScreen clinic_exists, 21, 19, 4
	If clinic_exists <> "                     " then script_end_procedure("PMI has a selected clinic code. Please review and proceed manually.")
	'form rec'd
	EMsetcursor 10, 16
	EMSendkey "n"

	' Commenting out code...not needed for this process
	''other insurance y/n
	'EMsetcursor 11, 18
	'EMsendkey insurance_yn
	''preg y/n
	'EMsetcursor 12, 19
	'EMsendkey pregnant_yn
	''interpreter y/n
	'EMsetcursor 13, 29
	'EMsendkey interpreter_yn
	''interpreter type
	'if interpreter_type <> "" then
	'	EMsetcursor 13, 52
	'	EMsendKey interpreter_type
	'end if
	''medical clinic code
	'EMsetcursor 19, 4
	'EMsendkey Medical_clinic_code
	''dental clinic code if applicable
	'EMsetcursor 19, 24
	'EMsendkey Dental_clinic_code
	''foster care y/n
	'EMsetcursor 21, 15
	'EMsendkey foster_care_yn
	'Asks worker to make sure the script has entered the correct information and cancels out to RKEY if worker hits cancel to no save anything.

	'BeginDialog correct_REFM_check, 0, 0, 191, 105, "REFM check"
	'  ButtonGroup ButtonPressed
	'    OkButton 35, 75, 50, 15
	'    CancelButton 95, 75, 50, 15
	'  Text 25, 15, 130, 35, "Please verify that the information entered is correct then click OK. If the information was entered incorrectly hit cancel and start the script again. "
	'EndDialog
	'
	'Dialog correct_REFM_check
	'cancel_confirmation
	transmit
	'checks for edit after hitting transmit
	Emreadscreen edit_check, 1, 24, 2
	If edit_check <> " " then script_end_procedure("There is an edit on this action. Please review the edit and proceed manually.")



	'Save and casenote
	pf3
	EMWriteScreen "c", 2, 19
	transmit
	pf4
	pf11
	EMSendkey "***SPECIAL ENROLLMENT CHANGE FOR 05/01/17***  CHANGED " & Client_first_name & " " & client_last_name & " to " & health_plan & " " & Enrollment_date & " " & worker_signature

	case_note_check = MsgBox("Please double check that the case note was created for " & client_first_name & " " & client_last_name & " and press OK to continue to Cancel to stop the script.", vbOKCancel)
	IF case_note_check = vbCancel THEN stopscript

	pf3
	pf3

	do_again = MsgBox ("The script has finished running for this client. Do you want to process another Special Enrollment form?", vbYesNo)
	IF do_again = vbNo THEN EXIT DO
LOOP

script_end_procedure("Success")
