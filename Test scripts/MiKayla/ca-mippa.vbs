'===========================================================================================STATS
name_of_script = "CA - MIPPA.vbs"
start_time = timer
STATS_counter = 1
STATS_manualtime = 200
STATS_denominatinon = "C"
'===========================================================================================END OF STATS BLOCK

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

' ===========================================================================================================CHANGELOG BLOCK
'Starts by defining a changelog array
changelog = array()

'INSERT ACTUAL CHANGES HERE, WITH PARAMETERS DATE, DESCRIPTION, AND SCRIPTWRITER. **ENSURE THE MOST RECENT CHANGE GOES ON TOP!!**
'Example: call changelog_update("01/01/2000", "The script has been updated to fix a typo on the initial dialog.", "Jane Public, Oak County")
call changelog_update("11/06/2017", "Updates to handle when there are multiple PMI associated with the same client.", "MiKayla Handley, Hennepin County")
call changelog_update("10/10/2017", "Updates to correct dialog box error message and ensure the correct case number pulls through the whole script.", "MiKayla Handley, Hennepin County")
call changelog_update("10/10/2017", "Updates to correct action when case noting and updating REPT/MLAR.", "MiKayla Handley, Hennepin County")
call changelog_update("09/29/2017", "Updates to correct action if HC is already pending.", "MiKayla Handley, Hennepin County")
call changelog_update("08/21/2017", "Initial version.", "MiKayla Handley, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'=======================================================================================================END CHANGELOG BLOCK

'---------------------------------------------------------------script

EMConnect ""
'Navigates to MIPPA Lis Application-Medicare Improvement for Patients and Providers (MIPPA)
CALL navigate_to_MAXIS_screen("REPT", "MLAR")
EMReadscreen error_check, 5, 24, 02
IF error_check <> "" THEN script_end_procedure("You are not on a MIPPA message. This script will stop.")
row = 11 'this part should be a for next?' can we jsut do a cursor read for now?
EMReadscreen msg_check, 1, row, 03
IF msg_check <> "_" THEN script_end_procedure("You are not on a MIPPA message. This script will stop.")

DO
	EMReadScreen MLAR_maxis_name, 21, row, 5
	MLAR_maxis_name = TRIM(MLAR_maxis_name)
	    MLAR_info_confirmation = MsgBox("Press YES to confirm this is the MIPAA you wish to clear." & vbNewLine & "For the next match, press NO." & vbNewLine & vbNewLine & _
		"   " & MLAR_maxis_name, vbYesNoCancel, "Please confirm this match")
			IF MLAR_info_confirmation = vbNo THEN
				row = row + 1
				'msgbox "row: " & row
				IF row = 19 THEN
					PF8
					row = 7
				END IF
			END IF
			IF MLAR_info_confirmation = vbCancel THEN script_end_procedure ("The script has ended. The match has not been acted on.")
			IF MLAR_info_confirmation = vbYes THEN 	EXIT DO
LOOP UNTIL MLAR_info_confirmation = vbYes

EMwritescreen "X", row, 03 'this will take us to REPT/MLAD'
TRANSMIT
	'navigates to MLAD
EMReadScreen MLAD_maxis_name, 22, 6, 20
MLAD_maxis_name = TRIM(MLAD_maxis_name)
EMReadScreen MLAD_SSN_number, 11, 7, 20
MLAD_SSN_number = trim(MLAD_SSN_number)
EMReadScreen SSN_first, 3, 7, 20
EMReadScreen SSN_mid, 2, 7, 24
EMReadScreen SSN_last, 4, 7, 27
EMReadScreen appl_date, 8, 11, 20
appl_date = replace(appl_date, " ", "/")
'----------------------------------------------------------------------used for the dialog to appl
EMReadScreen birth_date, 8, 8, 20
birth_date = replace(birth_date, " ", "/")
EMReadScreen medi_number, 10, 10, 20
EMReadScreen rcvd_date, 8, 12, 20
rcvd_date = replace(rcvd_date, " ", "/")
EMReadScreen gender_ask, 1, 9, 20
EMReadScreen MLAR_addr_street, 19, 9, 56
EMReadScreen MLAR_addr_streetII, 19, 8, 56
EMReadScreen MLAR_addr_city, 22, 12, 56
EMReadScreen MLAR_addr_state, 2, 13, 56
EMReadScreen MLAR_addr_zip, 5, 13, 65
EMReadScreen addr_county, 22, 14, 56
EMReadScreen MLAR_addr_phone, 12, 15, 56
EMReadScreen appl_status, 2, 4, 20 'this is not used anywhere else in the script'
'--------------------------------------------------------------------navigates to PERS and writing SSN'
PF2
EMwritescreen SSN_first, 14, 36
EMwritescreen SSN_mid, 14, 40
EMwritescreen SSN_last, 14, 43
TRANSMIT

EMReadScreen error_msg, 18, 24, 2
error_msg = trim(error_msg)
IF error_msg = "SSN DOES NOT EXIST" THEN script_end_procedure ("Unable to find person in SSN search." & vbNewLine & "Please do a PERS search using the client's name." & vbNewLine & "Case may need to be APPLd.")
'Right here we want to write for the first and last name_of_script pull this from match cleared






'This will take us to certain places based on PERS search'

EMReadscreen current_panel_check, 4, 2, 51
IF current_panel_check = "PERS" THEN script_end_procedure ("Please search by person name and run script again.")
'IF current_panel_check <> "DSPL" THEN script_end_procedure("Unable to access DSPL screen. Please review your case, and process manually if necessary.")
'If there are more than one match for a case the script will take you to MTCH'
Row = 8
IF current_panel_check = "MTCH" THEN
	DO
		EMReadScreen PMI_number, 7, row, 71
		IF trim(PMI_number) = "" THEN script_end_procedure("A PMI could not be found. The script will now end.")
		PERS_check = MsgBox("Multiple matches found. Ensure duplicate PMIs have been reported, APPL using oldest PMI." & vbNewLine & "Press YES to confirm this is the PERS match you wish to act on." & vbNewLine & "For the next PERS match, press NO." & vbNewLine & vbNewLine & _
		"   " & PMI_number, vbYesNoCancel, "Please confirm this PERS match")
		If PERS_check = vbYes THEN
			EMWriteScreen "x", row, 5
			TRANSMIT
			EMReadscreen current_panel_check, 4, 2, 51
			IF current_panel_check = "DSPL" THEN
			 	EXIT DO
			ELSE
				msgbox("Unable to access DSPL screen. Please review your case, and process manually if necessary.")
				EXIT DO
			END IF
		END IF
		IF PERS_check = vbNo THEN
			row = row + 1
			msgbox "row: " & row
			IF row = 16 THEN
				PF8
				row = 8
			END IF
		END IF
		IF PERS_check = vbCancel THEN script_end_procedure ("The script has ended. The match has not been acted on.")
	LOOP UNTIL PERS_check = vbYes
'ELSE
END IF
'msgbox "Where am I this should be DSPL if there is a match"
IF current_panel_check = "DSPL" THEN
	EMwritescreen "HC", 07, 22 'drilling down for accuracy '
	TRANSMIT
	EMReadScreen error_msg, 23, 24, 2
	error_msg = trim(error_msg)
	IF error_msg = "NO RECORDS EXIST FOR HC" THEN
		EMwritescreen "MA", 07, 22
		TRANSMIT
	END IF
	IF MAXIS_case_number = "" THEN
		EMwritescreen "  ", 07, 22
		TRANSMIT
		EMReadScreen MAXIS_case_number, 8, row, 06 'not sure about this part'
		EMReadscreen case_status, 4, row, 35
		EMReadScreen case_status, 4, row, 53
	END IF
    '-------------------------------------------------------------------checking for an active case
	row = 10
    DO
		EMReadScreen MAXIS_case_number, 8, row, 06
    	'second loop to ensure we are acting on the correct case number'
		msgbox "Where am I again"
	  	MLAR_case_number_check = MsgBox("Multiple case matches found. Ensure duplicate PMIs have been reported, APPL or update using Current or Pending case." & vbNewLine & "Press YES to confirm this is the case you wish to act on." & vbNewLine & "For the next case, press NO." & vbNewLine & vbNewLine & _
    	"   " & MAXIS_case_number, vbYesNoCancel, "Please confirm this case.")
    	IF MLAR_case_number_check = vbYes THEN
    		EMWriteScreen "x", row, 5
    		TRANSMIT
		END IF
    	If MLAR_case_number_check = vbNo THEN
    		row = row + 1
    		msgbox "row: " & row
			IF row = 19 THEN
				PF8
				row = 7
			END IF
    	END IF
		IF MLAR_case_number_check = vbCancel THEN script_end_procedure ("The script has ended. The case has not been acted on.")
	LOOP UNTIL MLAR_case_number_check = vbYes

    IF case_status = "CURRENT" THEN
    	EMReadScreen appl_date, 8, row, 25
    	APPL_box = MsgBox("This information is read from REPT/MLAR:" & vbcr & MLAD_maxis_name & vbcr & appl_date & vbcr & maxis_name & vbcr & birth_date & vbcr & gender_ask & vbcr & MLAR_addr_street & MLAR_addr_street & MLAR_addr_city & MLAR_addr_state & "" & MLAR_addr_zip & vbcr & MLAR_addr_phone & vbcr & "APPL case and click OK if you wish to continue running the script and CANCEL if you want to exit." & vbcr & "HCRE must be updated when adding HC", vbOKCancel)
    	IF APPL_box = vbCancel then script_end_procedure("The script has ended. Please review the REPT/MLAR as you indicated that you wish to exit the script")
    ELSEIF case_status = "PEND" THEN
    	EMReadScreen pend_date, 5, row, 47
    	PEND_box = MsgBox("This information is read from REPT/MLAR:" & vbcr & MLAD_maxis_name & vbcr & appl_date & vbcr & maxis_name & vbcr & birth_date & vbcr & gender_ask & vbcr & MLAR_addr_street & MLAR_addr_street & MLAR_addr_city & MLAR_addr_state & "" & MLAR_addr_zip & vbcr & MLAR_addr_phone & vbcr & "APPL case and click OK if you wish to continue running the script and CANCEL if you want to exit." & vbcr & "HCRE must be updated when adding HC", vbOKCancel)
    	IF PEND_box = vbCancel then script_end_procedure("The script has ended. Please review the REPT/MLAR as you indicated that you wish to exit the script")
    ELSEIF case_status = "CAF " THEN
    	MsgBox "Please ensure case is in a PEND II status"
    	EMReadScreen end_date, 5, row, 53
    END IF
    'Call navigate_to_MAXIS_screen("CASE", "CURR")

    IF case_status = "CURRENT" or case_status = "PEND" THEN
        Call navigate_to_MAXIS_screen("STAT", "ADDR")
        EMReadscreen current_panel_check, 4, 2, 44
        IF current_panel_check = "ADDR" THEN 'Reading and cleaning up Residence address
            EMReadScreen addr_line_1, 22, 6, 43
            EMReadScreen addr_line_2, 22, 7, 43
            EMReadScreen city, 15, 8, 43
            EMReadScreen State, 2, 8, 66
            EMReadScreen Zip_code, 5, 9, 43
            addr_line_1 = replace(addr_line_1, "_", "")
            addr_line_2 = replace(addr_line_2, "_", "")
            city = replace(city, "_", "")
            State = replace(State, "_", "")
            Zip_code = replace(Zip_code, "_", "")
            'Reading homeless code
            EMReadScreen homeless_code, 1, 10, 43
            'Reading and cleaning up mailing address
            EMReadScreen mailing_addr_line_1, 22, 13, 43
            EMReadScreen mailing_addr_line_2, 22, 14, 43
            EMReadScreen mailing_city, 15, 15, 43
            EMReadScreen mailing_State, 2, 16, 43
            EMReadScreen mailing_Zip_code, 5, 16, 52
            mailing_addr_line_1 = replace(mailing_addr_line_1, "_", "")
            mailing_addr_line_2 = replace(mailing_addr_line_2, "_", "")
            mailing_city = replace(mailing_city, "_", "")
            mailing_State = replace(mailing_State, "_", "")
            mailing_Zip_code = replace(mailing_Zip_code, "_", "")
        END IF
	END IF
	IF current_panel_check <> "ADDR" THEN MsgBox(current_panel_check)
END IF
'------------------------------------------------------------------------------------------------dialog
BeginDialog MIPPA_active_dialog, 0, 0, 376, 175, "MIPAA"
  EditBox 55, 5, 35, 15, MAXIS_case_number
  ButtonGroup ButtonPressed
    PushButton 100, 5, 50, 15, "Geocoder", Geo_coder_button
  CheckBox 175, 25, 160, 10, "Check if case does not need to be transferred", transfer_case_checkbox
  EditBox 55, 25, 20, 15, spec_xfer_worker
  DropListBox 255, 5, 115, 15, "Select One:"+chr(9)+"YES-Update MLAD"+chr(9)+"NO-APPL(Known to MAXIS)"+chr(9)+"NO-APPL(Not known to MAXIS)"+chr(9)+"NO-ADD A PROGRAM", select_answer
  ButtonGroup ButtonPressed
    OkButton 275, 45, 45, 15
    CancelButton 325, 45, 45, 15
  Text 175, 10, 75, 10, "Active on Health Care?"
  Text 15, 30, 40, 10, "Transfer to:"
  Text 5, 10, 50, 10, "Case Number:"
  Text 80, 30, 60, 10, " (last 3 digit of X#)"
  Text 15, 75, 190, 10, "Case Name: " & MLAD_maxis_name
  Text 15, 100, 110, 10, "APPL date: " & appl_date
  Text 15, 110, 80, 10, "DOB: " & birth_date
  Text 170, 140, 100, 10, "Phone: " & MLAR_addr_phone
  Text 15, 130, 110, 10, "Received Date: " & rcvd_date
  Text 15, 120, 120, 10, "MEDI Number: " &  medi_number
  Text 15, 90, 120, 10, "SSN: " & MLAD_SSN_number
  Text 15, 140, 110, 10, "Gender Marker: " & gender_ask
  Text 170, 90, 195, 10, "Addr: " & MLAR_addr_street & MLAR_addr_streetII
  Text 170, 110, 90, 10, "State: " & MLAR_addr_state
  Text 170, 100, 195, 10, "City: " &  MLAR_addr_city
  Text 170, 120, 110, 10, "Zip: " & MLAR_addr_zip
  Text 15, 150, 110, 10, "Status: " & appl_status
  Text 170, 130, 110, 10, "County: " & addr_county
  GroupBox 5, 60, 365, 110, "MLAR Information"
EndDialog

'--------------------------------------------------------------------------------------------------script
Do
	Do
		err_msg = ""
		dialog MIPPA_active_dialog
		cancel_confirmation
		IF select_answer = "Select One:" THEN err_msg = err_msg & vbnewline & "* Select at least one option."
		IF transfer_case_checkbox = CHECKED and spec_xfer_worker <> "" THEN err_msg = err_msg & vbnewline & "* Only check if the case does NOT need to be transferred."
		IF transfer_case_checkbox = UNCHECKED and spec_xfer_worker = "" THEN err_msg = err_msg & vbnewline & "* You must advise of basket to transfer to (last 3 digits of worker number)."
		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine		'error message including instruction on what needs to be fixed from each mandatory field if incorrect
	LOOP UNTIL err_msg = ""
	CALL check_for_password(are_we_passworded_out)
LOOP UNTIL are_we_passworded_out = false

'-------------------------------------------------------------------------------------Transfers the case to the assigned worker if this was selected in the second dialog box
'Determining if a case will be transferred or not. All cases will be transferred except addendum app types. THIS IS NOT CORRECT AND NEEDS TO BE DISCUSSED WITH QI
IF transfer_case_checkbox = CHECKED THEN
	transfer_case = FALSE
ELSE
    CALL navigate_to_MAXIS_screen ("SPEC", "XFER")
    EMWriteScreen "x", 7, 16
    TRANSMIT
    PF9
    EMWriteScreen "X127" & spec_xfer_worker, 18, 61
    TRANSMIT
    EMReadScreen worker_check, 9, 24, 2

    IF worker_check = "SERVICING" THEN
    	action_completed = False
    	PF10
    END IF

    EMReadScreen transfer_confirmation, 16, 24, 2
    IF transfer_confirmation = "CASE XFER'D FROM" then
    	action_completed = True
    Else
    	action_completed = False
    End if
END IF

'----------------------------------------------------------------------------------case note

start_a_blank_case_note
IF select_answer = "YES-Update MLAD" THEN
	CALL write_variable_in_CASE_NOTE("~ MIPAA received via REPT/MLAR on " & rcvd_date & " ~")
	CALL write_variable_in_CASE_NOTE("* Please review the MIPPA record and case information for consistency and follow-up with any inconsistent information, as appropriate.")
ELSE CALL write_variable_in_CASE_NOTE ("~ HC PENDED - MIPAA received via REPT/MLAR on " & appl_date & " ~")
    IF select_answer = "NO-APPL(Known to MAXIS)" THEN
    	CALL write_variable_in_CASE_NOTE("* APPL'd case using the MIPPA record and case information applicant is known to MAXIS by SSN or name search.")
    	CALL write_variable_in_CASE_NOTE ("* Pended on: " & date)
		CALL write_variable_in_CASE_NOTE ("* Application mailed using automated system per DHS: " & rcvd_date)
    ELSEIF select_answer = "NO-APPL(Not known to MAXIS)" THEN
    	CALL write_variable_in_CASE_NOTE("* APPL'd case using the MIPPA record and case information applicant is not known to MAXIS by SSN or name search.")
    	CALL write_variable_in_CASE_NOTE ("* Pended on: " & date)
		CALL write_variable_in_CASE_NOTE ("* Application mailed using automated system per DHS: " & rcvd_date)
    ELSEIF select_answer = "NO-ADD A PROGRAM" THEN
    	CALL write_variable_in_CASE_NOTE("* APPL'd case using the MIPPA record and case information applicant is known to MAXIS and may be active on other programs.")
		CALL write_variable_in_CASE_NOTE ("* Application mailed using automated system per DHS: " & rcvd_date)
    	CALL write_variable_in_CASE_NOTE ("* HC Ended on: " & end_date)
	END IF
END IF
CALL write_variable_in_case_NOTE ("* Requesting: HC")
CALL write_variable_in_CASE_NOTE ("* REPT/MLAR APPL Date: " & appl_date)
IF transfer_case = TRUE THEN CALL write_variable_in_CASE_NOTE ("* Case transferred to basket " & spec_xfer_worker & ".")
CALL write_variable_in_CASE_NOTE ("* MIPPA rcvd and acted on per: TE 02.07.459")
CALL write_variable_in_CASE_NOTE ("---")
CALL write_variable_in_CASE_NOTE (worker_signature)

'------------------------------------------------------------------------Naviagetes to REPT/MLAR'

'Navigates back to MIPPA to clear the match
CALL navigate_to_MAXIS_screen("REPT", "MLAR")
row = 11 'this part should be a for next?' can we jsut do a cursor read for now?
EMReadscreen msg_check, 1, row, 03
IF msg_check <> "_" THEN script_end_procedure("You are not on a MIPPA message. This script will stop.")
DO
	EMReadScreen MLAR_maxis_name, 21, row, 5
	MLAR_maxis_name = TRIM(MLAR_maxis_name)
	    END_info_confirmation = MsgBox("Press YES to confirm this is the MIPAA you wish to clear." & vbNewLine & "For the next match, press NO." & vbNewLine & vbNewLine & _
		"   " & MLAR_maxis_name, vbYesNoCancel, "Please confirm this match")
			IF END_info_confirmation = vbNo THEN
				row = row + 1
				'msgbox "row: " & row
				IF row = 19 THEN
					PF8
					row = 7
				END IF
			END IF
			IF END_info_confirmation = vbCancel THEN script_end_procedure ("The script has ended. The match has not been acted on.")
			IF END_info_confirmation = vbYes THEN 	EXIT DO
LOOP UNTIL END_info_confirmation = vbYes

EMwritescreen "X", row, 03
TRANSMIT
PF9

IF select_answer = "YES-Update MLAD" or select_answer = "NO-ADD A PROGRAM" THEN
	EMwritescreen "AP", 4, 20
	TRANSMIT
	PF3
	PF3
    EMWriteScreen MAXIS_case_number, 18, 43
	CALL navigate_to_MAXIS_screen("DAIL", "WRIT")
	CALL create_MAXIS_friendly_date(date, 0, 5, 18)
	CALL write_variable_in_TIKL("~ A MIPPA record was recieved please check case information for consistency and follow-up with any inconsistent information, as appropriate.")
	TRANSMIT
	PF3
ELSE
	EMwritescreen "PN", 4, 20
	TRANSMIT
	PF3
	PF3
    EMWriteScreen MAXIS_case_number, 18, 43
	CALL navigate_to_MAXIS_screen("DAIL", "WRIT")
	CALL create_MAXIS_friendly_date(date, 0, 5, 18)
	CALL write_variable_in_TIKL("~ Please review the MIPPA record and case information for consistency and follow-up with any inconsistent information, as appropriate.")
	TRANSMIT
	PF3
END IF

'to help check on app rcvd'
'Function create_outlook_email(email_recip, email_recip_CC, email_subject, email_body, email_attachment, send_email)
'CALL create_outlook_email("pahoua.vang@hennepin.us;", "", maxis_name & maxis_case_number & " MIPPA case need Application sent EOM.", "", "", TRUE)
msgbox "where am i ending?"
script_end_procedure("MIPPA CASE NOTE HAS BEEN UPDATED. PLEASE ENSURE THE CASE IS CLEARED on REPT/MLAR.")
