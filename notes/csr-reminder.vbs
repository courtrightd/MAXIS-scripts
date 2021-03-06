'Required for statistical purposes==========================================================================================
name_of_script = "NOTES - CSR REMINDER.vbs"
start_time = timer
STATS_counter = 1               'sets the stats counter at one
STATS_manualtime = 120          'manual run time in seconds
STATS_denomination = "C"        'C is for each case
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
call changelog_update("04/24/2018", "Initial version.", "MiKayla Handley, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'THE SCRIPT--------------------------------------------------------------------------------------------------
'CONNECTING TO MAXIS & GRABBING THE CASE NUMBER
EMConnect ""
CALL MAXIS_case_number_finder(MAXIS_case_number)

'--------------------------------------------------------------------------------------------------DIALOG
BeginDialog csr_contact_dialog, 0, 0, 351, 170, "CSR Reminder call"
  EditBox 275, 5, 65, 15, phone_number
  ComboBox 100, 30, 75, 15, "Select one..."+chr(9)+"Client (M01)"+chr(9)+"Other HH Member"+chr(9)+"AREP"+chr(9)+"SWKR", who_contacted
  ComboBox 255, 30, 85, 15, "Select one..."+chr(9)+"spoke to client"+chr(9)+"left a voicemail"+chr(9)+"unable to reach client", result_call
  CheckBox 275, 45, 65, 10, "Used Interpreter", used_interpreter_checkbox
  EditBox 65, 70, 275, 15, verifs_needed
  EditBox 65, 90, 275, 15, other_notes
  CheckBox 10, 120, 255, 10, "Check here if the phone numbers on file need to be corrected. ", number_check
  CheckBox 10, 135, 255, 10, "Check here if you want to TIKL out for this case after the case note is done.", TIKL_check
  EditBox 75, 150, 155, 15, worker_signature
  ButtonGroup ButtonPressed
    OkButton 235, 150, 50, 15
    CancelButton 290, 150, 50, 15
  EditBox 55, 5, 55, 15, MAXIS_case_number
  EditBox 145, 5, 65, 15, when_contact_was_made
  GroupBox 5, 55, 340, 60, "Additional information:"
  Text 10, 75, 50, 10, "Verifs needed: "
  Text 15, 95, 45, 10, "Other notes:"
  Text 120, 10, 20, 10, "Date:"
  Text 5, 10, 50, 10, "Case number: "
  Text 25, 35, 70, 10, "Who was contacted?:"
  Text 220, 10, 50, 10, "Phone number: "
  Text 10, 155, 60, 10, "Worker signature:"
  Text 190, 35, 60, 10, "Result of the call:"
EndDialog

'updates the "when contact was made" variable to show the current date & time
when_contact_was_made = date & ", " & time

Do 
    DO
        err_msg = ""
    	Dialog csr_contact_dialog
    	cancel_confirmation
        If trim(MAXIS_case_number) = "" or IsNumeric(MAXIS_case_number) = False or len(MAXIS_case_number) > 8 then err_msg = err_msg & vbNewLine & "* Enter a valid case number."
    	If trim(when_contact_was_made) = "" then err_msg = err_msg & vbNewLine & "* Enter the contact date and time."
        If trim(phone_number) = "" then err_msg = err_msg & vbNewLine & "* Enter the contact phone number."
        If (who_contacted = "Select one..." or result_call = "Select one...") then err_msg = err_msg & vbNewLine & "* Enter all contact type information."
        If trim(worker_signature) = "" then err_msg = err_msg & vbNewLine & "* Sign your case note."
        IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
    LOOP UNTIL err_msg = ""
    call check_for_password(are_we_passworded_out)  'Adding functionality for MAXIS v.6 Passworded Out issue'
LOOP UNTIL are_we_passworded_out = false

'checking for an active MAXIS session
Call check_for_MAXIS(False)

'THE CASE NOTE----------------------------------------------------------------------------------------------------
start_a_blank_case_note
CALL write_variable_in_CASE_NOTE("CSR reminder call to " & who_contacted & ", " & result_call)
If Used_interpreter_checkbox = checked THEN
	CALL write_variable_in_CASE_NOTE("* Contact was made: " & when_contact_was_made & " w/ interpreter")
Else
	CALL write_bullet_and_variable_in_CASE_NOTE("Contact was made", when_contact_was_made)
End if
CALL write_bullet_and_variable_in_CASE_NOTE("Phone number", phone_number)
CALL write_bullet_and_variable_in_CASE_NOTE("Verifs Needed", verifs_needed)
CALL write_bullet_and_variable_in_CASE_NOTE("Other notes", other_notes)
IF number_check = checked THEN CALL write_variable_in_CASE_NOTE("* Follow-up is needed to get correct phone numbers.")
CALL write_variable_in_CASE_NOTE("---")
CALL write_variable_in_CASE_NOTE(worker_signature)

'TIKLING
IF TIKL_check = checked THEN
	MsgBox "The script will now navigate to a TIKL."
	CALL navigate_to_MAXIS_screen("dail", "writ")
END IF

script_end_procedure("Your CSR reminder call is complete. The result of the call is: " & result_call)