'GATHERING STATS----------------------------------------------------------------------------------------------------
name_of_script = "NOTICES - SELECT WCOM.vbs"
start_time = timer
STATS_counter = 1                          'sets the stats counter at one
STATS_manualtime = 90                               'manual run time in seconds
STATS_denomination = "C"       'C is for each CASE
'END OF stats block==============================================================================================

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN	   'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF use_master_branch = TRUE THEN			   'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else											'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/RELEASE/MASTER%20FUNCTIONS%20LIBRARY.vbs"
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
call changelog_update("03/13/2018", "Initial version.", "Casey Love, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'FUNCTION===================================================================================================================
'Function created to list of all the notices in either WCOM or MEMO - with information
'IDEA - Create_List_Of_Notices function may need to be updated for this particular script
Function Create_List_Of_Notices
    'This function is fairly specific at this time to work when being called within the loop of a dynamic dialog.
    'The array filled will be used to list the notices in the dialog. (Array and constants are defined in the script - outside of the function)
	Erase NOTICES_ARRAY            'Clear the array at the beginning of the function because this can be re called on a loop for dialog display
	no_notices = FALSE             'setting this at the beginning - this will be turned to TRUE if nothing is found in on the specified panel
	If notice_panel = "WCOM" Then      'if the dialog inputs 'WCOM' then the function will go to WCOM
		wcom_row = 7                   'setting initial variables
		array_counter = 0
		Do
			ReDim Preserve NOTICES_ARRAY(3, array_counter)       'resizing the array
			EMReadScreen notice_date, 8,  wcom_row, 16           'getting all the detail from each notice information
			EMReadScreen notice_prog, 2,  wcom_row, 26
			EMReadScreen notice_info, 31, wcom_row, 30
			EMReadScreen notice_stat, 8,  wcom_row, 71

			notice_date = trim(notice_date)                      'Formatting the notice information
			notice_prog = trim(notice_prog)
			notice_info = trim(notice_info)
			notice_stat = trim(notice_stat)

			If array_counter = 0 AND notice_date = "" Then no_notices = TRUE     'This resets the notices boolean to indicate the notice type and month/year have no waiting notices

			NOTICES_ARRAY(selected,    array_counter) = unchecked                'Adding the notice information to the array
			NOTICES_ARRAY(information, array_counter) = notice_info & " - " & notice_prog & " - " & notice_date & " - Status: " & notice_stat
			NOTICES_ARRAY(MAXIS_row,   array_counter) = wcom_row

			array_counter = array_counter + 1            'incrementing the counter and row
			wcom_row = wcom_row + 1

			EMReadScreen next_notice, 4, wcom_row, 30    'looking to see if another notice exists - loop will exit if no other notices are on the panel
			next_notice = trim(next_notice)

		Loop until next_notice = ""
	End If

	If notice_panel = "MEMO" Then       'if the dialog inputs 'MEMO' then the function will go to MEMO
		memo_row = 7                    'setting initial variables
		array_counter = 0
		Do
			ReDim Preserve NOTICES_ARRAY(3, array_counter)       'resizing the array
			EMReadScreen notice_date, 8,  memo_row, 19           'getting all the detail from each notice information
			EMReadScreen notice_info, 31, memo_row, 29
			EMReadScreen notice_stat, 8,  memo_row, 67

			notice_date = trim(notice_date)                      'Formatting the notice information
			notice_info = trim(notice_info)
			notice_stat = trim(notice_stat)

			If array_counter = 0 AND notice_date = "" Then no_notices = TRUE     'This resets the notices boolean to indicate the notice type and month/year have no waiting notices

			NOTICES_ARRAY(selected,    array_counter) = unchecked                'Adding the notice information to the arra
			NOTICES_ARRAY(information, array_counter) = notice_info & " - " & notice_date & " - Status: " & notice_stat
			NOTICES_ARRAY(MAXIS_row,   array_counter) = memo_row

			array_counter = array_counter + 1            'incrementing the counter and row
			memo_row = memo_row + 1

			EMReadScreen next_notice, 4, memo_row, 30    'looking to see if another notice exists - loop will exit if no other notices are on the panel
			next_notice = trim(next_notice)

		Loop until next_notice = ""
	End If
End Function

'Function to add verbiage to an array that will be used to write to a WCOM
'This function is used so that we can correctly asses the length of the message to write in to WCOM - this is vital for this script so that we don't miss out on WCOM verbiage
Function add_words_to_message(message_to_add)

    If trim(message_to_add) <> "" Then  'ensuring there is a value in the message to add
        message_array = split(message_to_add, " ")      'creating an array of all the words in the message

        'ERASE array_of_msg_lines
        ReDim array_of_msg_lines(0)         'blanks out this array each time because we don't want old messages to be duplicated

        message_line = ""                   'setting variables for a FOR...NEXT
        lines_in_msg = 0

        For each word in message_array          'This will look at each word in the message
            'MsgBox lines_in_msg
            If len(word) + len(message_line) > 59 Then              'there are only 59 characters available in each line
                ReDim Preserve array_of_msg_lines(lines_in_msg)     'increases the size of the array of lines in the message input
                array_of_msg_lines(lines_in_msg) = message_line     'adding the combined words to the array
                lines_in_msg = lines_in_msg + 1

                message_line = ""                                   'blanking out the combination of words for each line
            End If

            message_line = message_line & replace(word, ";", "") & " "      'Adding each word to the line

            IF right(word, 1) = ";" Then                                    'moving to a new line if ; is input
                ReDim Preserve array_of_msg_lines(lines_in_msg)
                array_of_msg_lines(lines_in_msg) = message_line
                lines_in_msg = lines_in_msg + 1

                message_line = ""
            End If
        Next

        ReDim Preserve array_of_msg_lines(lines_in_msg)         'adding the last line to the array of lines
        array_of_msg_lines(lines_in_msg) = message_line
        lines_in_msg = lines_in_msg + 1

        'MsgBox "End of WCOM Row: " & end_of_wcom_row & vbNewLine & "Lines Used:" & lines_in_msg
        'Adding a seperator if there is already a message in WCOM
        If UBound(WCOM_TO_WRITE_ARRAY) = 0 Then
            notice_line = 0
        Else
            notice_line = UBound(WCOM_TO_WRITE_ARRAY) + 1
            ReDim Preserve WCOM_TO_WRITE_ARRAY(notice_line)
            WCOM_TO_WRITE_ARRAY(notice_line) = "-      - - - - - - - - - - - - - - - - - - - -       -"
            notice_line = notice_line + 1
        End If

        'Here the lines for this message are added to the array that is storing all the messages in the script run as a worker can select multiple
        For each entry in array_of_msg_lines
            'MsgBox entry
            ReDim Preserve WCOM_TO_WRITE_ARRAY(notice_line)
            WCOM_TO_WRITE_ARRAY(notice_line) = trim(entry)
            notice_line = notice_line + 1
        Next

        end_of_wcom_row = end_of_wcom_row + lines_in_msg        'tracking how long the WCOM is already
    End If

End Function

'THE SCRIPT=====================================================================================================================
EMConnect ""            'Connect to BlueZone

Dim NOTICES_ARRAY()         'Creating an array to list all the notices displayed on the panel
ReDim NOTICES_ARRAY(3,0)

Const selected = 0          'Setting constants for easy readability of the array
Const information = 1
Const MAXIS_row = 2

Call check_for_MAXIS(False)     'Making sure that we are not passworded out

'Finds MAXIS case number
call MAXIS_case_number_finder(MAXIS_case_number)

EMReadScreen which_panel, 4, 2, 47          'Checking to see where the script is started from
If which_panel <> "WCOM" then               'If this is not on WCOM - and if the case number is known, the script will navigate to WCOM
    If MAXIS_case_number <> "" Then
        Call navigate_to_MAXIS_screen("SPEC", "WCOM")
	    notice_panel = "WCOM"
	    at_notices = True                  'This boolean tells the script if we are already at one of the notices page (for this script ONLY WCOM)
    Else
        at_notices = FALSE
    End If
Else
    at_notices = TRUE
    notice_panel = "WCOM"
End If


If at_notices = True then               'generating a list of notices if we are at WCOM - so the following dialog will not be empty if we start at WCOM

	EMReadScreen MAXIS_footer_month, 2, 3, 46
	EMReadScreen MAXIS_footer_year,  2, 3, 51

	Create_List_Of_Notices

End If

'This is the DO...LOOP for the dialog to select the WCOM to add information to
Do
	err_msg = ""       'resetting the err_msg variable at the beginning of each loop for handling of correct dialogs

    If NOTICES_ARRAY(0, 0) <> "" Then           'This is looking to see if there is information in the first element of the array (indicating the array has data)
        For notices_listed = 0 to UBound(NOTICES_ARRAY, 2)                                          'looking at all the notices
            EMReadScreen desc, 20, NOTICES_ARRAY(MAXIS_row, notices_listed), 30                     'reading the description of the notice
            if desc = "ELIG Approval Notice" Then                                                   'if the notice is an elig approval - this will check to see if the notice is waiting - these will be prechecked
                EMReadScreen print_status, 7, NOTICES_ARRAY(MAXIS_row, notices_listed), 71
                If print_status = "Waiting" Then NOTICES_ARRAY(selected, notices_listed) = checked
            End If
        Next
    End If

	dlg_y_pos = 65     'setting some lengths and positions
	dlg_length = 125 + (UBound(NOTICES_ARRAY, 2) * 20)

	BeginDialog find_notices_dialog, 0, 0, 205, dlg_length, "Notices to add WCOM"      'This is what the dialog will look like
	  Text 5, 10, 50, 10, "Case Number"
	  EditBox 65, 5, 50, 15, MAXIS_case_number
	  Text 5, 30, 120, 10, "In which month was the notice sent?"
	  EditBox 140, 25, 20, 15, MAXIS_footer_month
	  EditBox 165, 25, 20, 15, MAXIS_footer_year
	  ButtonGroup ButtonPressed
	    PushButton 60, 50, 50, 10, "Find Notices", find_notices_button
	  If no_notices = FALSE Then
		  For notices_listed = 0 to UBound(NOTICES_ARRAY, 2)
		  	CheckBox 10, dlg_y_pos, 185, 10, NOTICES_ARRAY(information, notices_listed), NOTICES_ARRAY(selected, notices_listed)
			dlg_y_pos = dlg_y_pos + 15
		  Next
	  Else
	  	  Text 10, dlg_y_pos, 185, 10, "**No Notices could be found here.**"
		  dlg_y_pos = dlg_y_pos + 15
	  End If
	  dlg_y_pos = dlg_y_pos + 5
	  EditBox 75, dlg_y_pos, 125, 15, worker_signature
	  dlg_y_pos = dlg_y_pos + 5
	  Text 5, dlg_y_pos, 60, 10, "Worker Signature:"
	  dlg_y_pos = dlg_y_pos + 15
	  ButtonGroup ButtonPressed
	    OkButton 100, dlg_y_pos, 50, 15
	    CancelButton 150, dlg_y_pos, 50, 15
	EndDialog

	Dialog find_notices_dialog         'display the dialog
	cancel_confirmation

	notice_selected = FALSE            'this boolean and loop will identify if no notice has been selected
	For notice_to_print = 0 to UBound(NOTICES_ARRAY, 2)
		If NOTICES_ARRAY(selected, notice_to_print) = checked Then notice_selected = TRUE
	Next

    'looking for errors in the dialog entry
	If MAXIS_case_number = "" Then err_msg = err_msg & vbNewLine & "- Enter a Case Number."
	If MAXIS_footer_month = "" or MAXIS_footer_year = "" Then err_msg = err_msg & vbNewLine & "- Enter footer month and year."
	If notice_selected = False Then err_msg = err_msg & vbNewLine & "- Select a notice to be copied to a Word Document."

    'If the button is pressed to find notices, the loop will not entry - but instead navigate to the WCOM for the specified case and month/year
	If ButtonPressed = find_notices_button then
		If MAXIS_case_number <> "" AND MAXIS_footer_month <> "" AND MAXIS_footer_year <> "" Then  'navigation only works with case number and footer month/year
			Call navigate_to_MAXIS_screen ("SPEC", notice_panel)            'for this script - this is always WCOM
			EMWriteScreen MAXIS_footer_month, 3, 46
			EMWriteScreen MAXIS_footer_year, 3, 51

			transmit
			Create_List_Of_Notices           'using the funcation to create a list of notices for the dialog
			err_msg = "LOOP"                 'this keeps the loop from exiting since err_msg will not be blank
		Else
			err_msg = err_msg & vbNewLine & "!!! Cannot read a list of notices without a case number entered, and footer month & year entered !!!"   'If case number or footer month/year are not specified - this will be the error
		End If
	End If

    'The error message will only display if it is not blank AND is not the one to keep the loop from exiting.
	If err_msg <> "" AND left(err_msg, 4) <> "LOOP" Then MsgBox "*** Please resolve to continue ***" & vbNewLine & err_msg

Loop Until err_msg = ""

'navigating to the panel for case case and footer month/year specified.
Call navigate_to_MAXIS_screen ("SPEC", notice_panel)

EMWriteScreen MAXIS_footer_month, 3, 46
EMWriteScreen MAXIS_footer_year, 3, 51

transmit

'setting these variables
'IDEA the WCOMs available will vary depending on the type of notice that was selected - since each program has different WCOM needs
SNAP_notice = FALSE
MFIP_notice = FALSE
GA_notice = FALSE
MSA_notice = FALSE

'This bit identifies which type of notice has been selected - so that in the future WCOMs listed in the next dialog can be adjusted based on the type of notice
For notices_listed = 0 to UBound(NOTICES_ARRAY, 2)
    If NOTICES_ARRAY(selected, notices_listed) = checked Then
        EMReadScreen notice_prog, 3, NOTICES_ARRAY(MAXIS_row, notices_listed), 25
        notice_prog = trim(notice_prog)
        If notice_prog = "FS" Then SNAP_notice = TRUE
        If notice_prog = "MF" Then MFIP_notice = TRUE
        If notice_prog = "GA" Then GA_notice = TRUE
        If notice_prog = "MS" Then MSA_notice = TRUE
    End If
Next

'DIALOG to select the WCOM to add
BeginDialog wcom_selection_dlg, 0, 0, 251, 240, "Select WCOM"
  CheckBox 15, 25, 190, 10, "WCOM for SNAP Duplicate Assistance in another state", duplicate_assistance_wcom_checkbox
  Text 10, 10, 95, 10, "Check the WCOM needed."
  CheckBox 15, 40, 145, 10, "WCOM for closing due to Returned Mail", returned_mail_wcom_checkbox
  CheckBox 15, 55, 155, 10, "WCOM for SNAP closed via PACT due to FPI", pact_fraud_wcom_checkbox
  CheckBox 15, 70, 130, 10, "WCOM for Temp disabled ABAWDs", temp_disa_abawd_wcom_checkbox
  CheckBox 15, 85, 85, 10, "WCOM for Client Death", client_death_wcom_checkbox
  CheckBox 15, 100, 125, 10, "WCOM for MFIP to SNAP transition", mfip_to_snap_wcom_checkbox
  CheckBox 15, 115, 215, 10, "WCOM for ABAWD with postponed WREG verifs for EXP SNAP", wreg_postponed_verif_wcom_checkbox
  CheckBox 15, 130, 160, 10, "WCOM for possible Banked Months available", banked_mos_avail_wcom_checkbox
  CheckBox 15, 145, 180, 10, "WCOM for Banked Months closing due to non-coop", banked_mos_non_coop_wcom_checkbox
  CheckBox 15, 160, 235, 10, "WCOM for Banked Months closing due to all available months used.", banked_mos_used_wcom_checkbox
  CheckBox 15, 175, 235, 10, "WCOM for ABAWD WREG coded for Child under 18", abawd_child_coded_wcom_checkbox
  CheckBox 15, 190, 205, 10, "WCOM for Failure to comply FSET - Good Cause Information", fset_fail_to_comply_wcom_checkbox
  CheckBox 15, 205, 150, 10, "WCOM for SNAP closed/denied with PACT", snap_pact_wcom_checkbox
  ButtonGroup ButtonPressed
    OkButton 140, 220, 50, 15
    CancelButton 195, 220, 50, 15
EndDialog

'Initial declaration of arrays
Dim array_of_msg_lines ()
Dim WCOM_TO_WRITE_ARRAY ()
'Eventually this checkbox dialog will be dynamic and the WCOMs available will be different based on the programs of the notices selected.
'THIS is a big loop that will be used to make sure the WCOM is not too long
Do      'Just made this  loop - this needs sever testing.
    big_err_msg = ""            'this error message is called something different because there are other err_msg variables that happen within this loop for each WCOM

    Dialog wcom_selection_dlg       'running the dialog to select which WCOMs are going to be added
    cancel_confirmation

    end_of_wcom_line = 0            'setting variables to asses length of WCOM
    end_of_wcom_row = 1

    'setting the arrays to blank for each loop - they will be refilled once the checkboxes are selected again
    ReDim array_of_msg_lines(0)
    ReDim WCOM_TO_WRITE_ARRAY (0)

    'Here there is an IF statement for each checkbox - each WCOM may have it's own dialog and the verbiage will be added to the array for the WCOM lines

    If duplicate_assistance_wcom_checkbox = checked Then        'Duplicate assistance in another state
        If dup_state = "" Then                                  'If this is blank the script will look for it on MEMI - but if we are looping and the worker has already filled it in, the script will let that value stand
            Call navigate_to_MAXIS_screen ("STAT", "MEMI")
            EMReadScreen dup_state, 2, 14, 78
        End If
        If dup_state = "__" Then dup_state = ""                 'formatting state to not have underscores

        If dup_month = "" Then dup_month = MAXIS_footer_month   'setting the month and year as a default
        If dup_year = "" Then dup_year = MAXIS_footer_year

        'code for the dialog for dup assistance (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 121, 90, "WCOM Details"
          EditBox 70, 20, 25, 15, dup_state
          EditBox 70, 40, 15, 15, dup_month
          EditBox 90, 40, 15, 15, dup_year
          ButtonGroup ButtonPressed
            OkButton 60, 65, 50, 15
          Text 5, 10, 110, 10, "Duplicate SNAP in another state"
          Text 5, 25, 50, 10, "Previous State:"
          Text 5, 45, 60, 10, "In (Month/Year)"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If dup_state = "" Then err_msg = err_msg & vbNewLine & "* Enter the state in which client already received SNAP."
            If dup_month = "" or dup_year = "" Then err_msg = err_msg & vbNewLine & "* Enter the month and year for which SNAP in MN is being denied due to receipt of benefits in another state."
            If err_msg <> "" Then MsgBox "Please resolve before continuing:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("You received SNAP benefits from the state of: " & dup_state & " during the month of " & dup_month & "/" & dup_year & ". You cannot recceive SNAP benefits from two states at the same time.")
    End If

    If returned_mail_wcom_checkbox = checked Then           'Returned Mail
        'code for the dialog for returned mail (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 126, 85, "WCOM Details"
          EditBox 75, 20, 45, 15, rm_sent_date
          EditBox 75, 40, 45, 15, rm_due_date
          ButtonGroup ButtonPressed
            OkButton 60, 65, 50, 15
          Text 5, 5, 110, 10, "Returned Mail"
          Text 5, 25, 65, 10, "Verif Request Sent:"
          Text 5, 45, 65, 10, "Verif Request Due:"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            if isdate(rm_sent_date) = False Then err_msg = err_msg & vbNewLine & "*Enter a valid date for when the request for address information was sent."
            if isdate(rm_due_date) = False Then err_msg = err_msg & vbNewLine & "*Enter a valid date for when the response for address information was due."
            if err_msg <> "" Then msgBox "Resolve to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("Your mail has been returned to our agency. On " & rm_sent_date & " you were sent a Request for you to contact this agency because of this returned mail. You did not contact this agency by " & rm_due_date & " so your SNAP case has been closed.")
    End If

    If pact_fraud_wcom_checkbox Then        'FPI findings indicate another person
        'code for the dialog for closing for fpi result (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 281, 85, "WCOM Details"
          EditBox 75, 20, 45, 15, new_hh_memb
          EditBox 215, 20, 60, 15, SNAP_close_date
          EditBox 75, 40, 200, 15, new_memb_verifs
          ButtonGroup ButtonPressed
            OkButton 225, 65, 50, 15
          Text 5, 5, 120, 10, "New HH Member Information Failed"
          Text 5, 25, 65, 10, "New person in HH:"
          Text 140, 25, 70, 10, "SNAP close eff date:"
          Text 5, 45, 65, 10, "Verifs requested:"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If new_hh_memb = "" Then err_msg = err_msg & vbNewLine & "*Enter the name of the person who has joined the household."
            If isdate(SNAP_close_date) = False Then err_msg = err_msg & vbNewLine & "*Enter a valid date on which SNAP will close."
            If new_memb_verifs = "" Then err_msg = err_msg & vbNewLine & "*Enter the verifications that were needed to add this person to the case." & vbNewLine & "If no verifications are required - this is not the correct WCOM to use."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("This agency received a request to add " & new_hh_memb & " but the information requested to add this person was not received. The information needed was: " & new_memb_verifs & ". This person and their income is mandatory to be provided and because this informaiton has not been provided, your SNAP case will be closed on " & SNAP_close_date & " ")
    End If

    If temp_disa_abawd_wcom_checkbox Then       'Verified temporary disa for ABAWD exemption
        'code for the dialog for temporary disa for ABAWD (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 131, 60, "WCOM Details"
          EditBox 105, 20, 20, 15, numb_disa_mos
          ButtonGroup ButtonPressed
            OkButton 75, 40, 50, 15
          Text 5, 5, 120, 10, "DISA indicated on form from Doctor"
          Text 0, 25, 105, 10, "Number of months of disability"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If numb_disa_mos = "" Then err_msg = err_msg & vbNewLine & "*Enter the number of months the disability is expected to last from the doctor's information."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("You are exempt from the ABAWD work provision because you are unable to work for " & numb_disa_mos & " months per your Doctor statement.")
    End If

    If client_death_wcom_checkbox Then      'Client death - NO WORKER INPUT NEEDED
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("This SNAP case has been closed because the only eligible unit member has died.")
    End If

    If mfip_to_snap_wcom_checkbox Then      'MFIP is closing and SNAP is opening
        'code for the dialog for MFIP closure reason when SNAP is reassessed (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 166, 80, "WCOM Details"
          EditBox 5, 40, 155, 15, MFIP_closing_reason
          ButtonGroup ButtonPressed
            OkButton 110, 60, 50, 15
          Text 5, 5, 155, 10, "MFIP is closing and SNAP has been assessed"
          Text 5, 25, 105, 10, "Why is MFIP closing:"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If MFIP_closing_reason = "" Then err_msg = err_msg & vbNewLine & "*List all reasons why SNAP is closing."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("You are no longer eligible for MFIP because " & MFIP_closing_reason & ".")
    End If

    If wreg_postponed_verif_wcom_checkbox Then      'XFS Postponed verifs are in WREG
        'code for the dialog for postponed verifs from WREG (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 281, 115, "WCOM Details"
          EditBox 60, 20, 135, 15, abawd_name
          EditBox 5, 55, 270, 15, wreg_verifs_needed
          EditBox 60, 75, 55, 15, wreg_verifs_due_date
          EditBox 60, 95, 55, 15, snap_closure_date
          ButtonGroup ButtonPressed
            OkButton 225, 95, 50, 15
          Text 5, 5, 185, 10, "Postponed Verification of WREG information/exemption"
          Text 5, 25, 50, 10, "Client Name:"
          Text 5, 40, 70, 10, "Verifications Needed:"
          Text 5, 80, 40, 10, "Verifs Due:"
          Text 5, 100, 50, 10, "SNAP Closure:"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If abawd_name = "" Then err_msg = err_msg & vbNewLine & "* Enter the name of the client that has used 3 ABAWD months."
            If wreg_verifs_needed = "" Then err_msg = err_msg & vbNewLine & "* List all WREG verifications needed."
            If isdate(wreg_verifs_due_date) = False Then err_msg = err_msg & vbNewLine & "* Enter a valid date for the date the verifications are due."
            If isdate(snap_closure_date) = False Then err_msg = err_msg & vbNewLine & "* Enter a valid date for the day SNAP will close if verifications are not received."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message(abawd_name & " has used their 3 entitled months of SNAP benefits as an Able Bodied Adult Without Dependents. Verification of " & wreg_verifs_needed & " has been postponed. You must turn in verification of " & wreg_verifs_needed & " by " & wreg_verifs_due_date & " to continue to be eligible for SNAP benefits. If you do not turn in the required verifications, your case will close on " & snap_closure_date & ".")
    End If

    If banked_mos_avail_wcom_checkbox Then      'ABAWD expired - Banked Months available - NO WORKER INPUT NEEDED
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("You have used all of your available ABAWD months. You may be eligible for SNAP banked months if you are cooperating with Employment Services. Please contact your financial worker if you have questions.")
    End If

    If banked_mos_non_coop_wcom_checkbox Then       'Banked Months closing due to FSET non-coop
        'code for the dialog for non-coop with banked months (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 201, 65, "WCOM Details"
          EditBox 60, 20, 135, 15, banked_abawd_name
          ButtonGroup ButtonPressed
            OkButton 145, 45, 50, 15
          Text 5, 5, 185, 10, "Client that failed Banked Months E&T requirement."
          Text 5, 25, 50, 10, "Client Name:"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If banked_abawd_name = "" Then err_msg = err_msg & vbNewLine & "* Enter the name of the client that has not cooperated with E&T."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("You have been receiving SNAP banked months. Your SNAP case is closing because " & banked_abawd_name & " did not meet the requirements of working with Employment and Training. If you feel you have Good Cause for not cooperating with this requirement please contact your financial worker before you SNAP clsoes. If your SNAP closes for not cooperating with Employment and Training you will not be eligible for future banked months. If you meet an exemption listed above AND all other eligibility factors you may be eligible for SNAP. If you have questions please contact your financial worker.")
    End If

    If banked_mos_used_wcom_checkbox Then       'Banked Months expired - NO WORKER INPUT NEEDED
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("You have been receiving SNAP banked months. Your SNAP is closing for using all available banked months. If you meet one of the exemptions listed above AND all ofther eligibility factors you may still be eligible for SNAP. Please contact your financial worker if you have questions.")
    End If

    If abawd_child_coded_wcom_checkbox Then         'ABAWD exemption for care of child
        'code for the dialog for ABAWD child exemption (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 201, 65, "WCOM Details"
          EditBox 60, 20, 135, 15, exempt_abawd_name
          ButtonGroup ButtonPressed
            OkButton 145, 45, 50, 15
          Text 5, 5, 185, 10, "Client exempt from ABAWD due to child in the SNAP Unit."
          Text 5, 25, 50, 10, "Client Name:"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If exempt_abawd_name = "" Then err_msg = err_msg & vbNewLine & "* Enter the name of the client that os using child under 18 years exemption."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message(exempt_abawd_name & " is exempt from the Able Bodied Adults Without Dependents (ABAWD) Work Requirements due to a child(ren) under the age of 18 in the SNAP unit.")
    End If

    If fset_fail_to_comply_wcom_checkbox Then           'Fail to comply with FSET
        'code for the dialog for fail to comply with FSET (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 201, 85, "WCOM Details"
          EditBox 5, 40, 190, 15, fset_fail_reason
          ButtonGroup ButtonPressed
            OkButton 145, 65, 50, 15
          Text 5, 5, 115, 10, "Client did not meet SNAP E & T rules"
          Text 5, 25, 95, 10, "Reasons client failed FSET"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If fset_fail_reason = "" Then err_msg = err_msg & vbNewLine & "* Enter the reasons the client failed E&T."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("Reasons for not meeting the rules: " & fset_fail_reason & ". You can keep getting your SNAP benefits if you show you had a good reason for not meeting the SNAP E & T rules. If you had a good reason, tell us right away.;" & "What do you do next:;" &_
        "You must meet the SNAP E & T rules by the end of the month. If you want to meet the rules, contact your county worker at 612-596-1300, or your SNAP E &T provider at 612-596-7411. You can tell us why you did not meet with the rules. If you had a good reason for not meeting the SNAP E & T rules, contact your SNAP E & T provider right away.")
    End If

    If snap_pact_wcom_checkbox Then             'SNAP closed with PACT
        'code for the dialog for PACT closure (this dialog has the same name in each IF to prevent the over 7 dialog error)
        BeginDialog wcom_details_dlg, 0, 0, 301, 85, "WCOM Details"
          DropListBox 65, 5, 45, 45, "Select One..."+chr(9)+"CLOSED"+chr(9)+"DENIED", SNAP_close_or_deny
          EditBox 5, 40, 290, 15, pact_close_reason
          ButtonGroup ButtonPressed
            OkButton 245, 65, 50, 15
          Text 5, 10, 55, 10, "SNAP case was "
          Text 120, 10, 35, 10, "on PACT."
          Text 5, 25, 95, 10, "SNAP case closed reason(s):"
        EndDialog

        Do                          'displaying the dialog and ensuring that all required information is entered
            err_msg = ""

            Dialog wcom_details_dlg

            If SNAP_close_or_deny = "Select One..." Then err_msg = err_msg & vbNewLine & "* Select if the case was closed or denied."
            If pact_close_reason = "" Then err_msg = err_msg & vbNewLine & "* Enter the reasons the SNAP was denied."
            If err_msg <> "" Then MsgBox "Resolve the following to continue:" & vbNewLine & err_msg
        Loop until err_msg = ""
        'Adding the verbiage to the WCOM_TO_WRITE_ARRAY
        CALL add_words_to_message("Your SNAP case was " & SNAP_close_or_deny & " because " & pact_close_reason)
    End If

    'This assesses if the message generated is too long for WCOM. If so then the checklist will reappear along with each selected WCOM dialog so it can be changed
    If end_of_wcom_row > 15 Then big_err_msg = big_err_msg & vbNewLine & "The amount of text/information that is being added to WCOM will exceed the 15 lines available on MAXIS WCOMs. Please reduce the number of WCOMs that have been selected or reduce the amount of text in the selected WCOM."
    MsgBox "End of WCOM ROW is " & end_of_wcom_row
    'Leave this here - testing purposes
    wcom_to_display = ""
    For each msg_line in WCOM_TO_WRITE_ARRAY
        if wcom_to_display = "" Then
            wcom_to_display = msg_line
        else
            wcom_to_display = wcom_to_display & vbNewLine & msg_line
        end if
    Next
    MsgBox wcom_to_display

    If big_err_msg <> "" Then MsgBox "*** Please resolved the following to continue ***" & vbNewLine & big_err_msg
Loop until big_err_msg = ""

'This will cycle through all the notices that are on WCOM
For notices_listed = 0 to UBound(NOTICES_ARRAY, 2)

    If NOTICES_ARRAY(selected, notices_listed) = checked Then   'If the worker selected the notice
        'Navigate to the correct SPEC screen to select the notice
        Call navigate_to_MAXIS_screen ("SPEC", notice_panel)

        EMWriteScreen MAXIS_footer_month, 3, 46
        EMWriteScreen MAXIS_footer_year, 3, 51

        transmit

        'Open the Notice
        EMWriteScreen "X", NOTICES_ARRAY(MAXIS_row, notices_listed), 13
        transmit

        PF9     'Put in to edit mode - the worker comment input screen
        EMSetCursor 03, 15

        For each msg_line in WCOM_TO_WRITE_ARRAY        'each line in this array will be written to the WCOM
            CALL write_variable_in_SPEC_MEMO(msg_line)
        Next

        MsgBox "Look"
        PF4     'Save the WCOM
        PF3     'Exit the WCOM

        back_to_self
    End If
Next

'Now the action will be case noted
CALL navigate_to_MAXIS_screen("CASE", "NOTE")

start_a_blank_case_note

CALL write_variable_in_CASE_NOTE("*** Added WCOM for to Notice to clarify action taken ***")
CALL write_variable_in_CASE_NOTE("Inormation added to the following WCOM notices in " & MAXIS_footer_month & "/" & MAXIS_footer_year & ":")
For notices_listed = 0 to UBound(NOTICES_ARRAY, 2)
    If NOTICES_ARRAY(selected, notices_listed) = checked Then
        CALL write_variable_in_CASE_NOTE("* " & NOTICES_ARRAY(information, notices_listed))
    End If
Next
CALL write_variable_in_CASE_NOTE("---")
CALL write_variable_in_CASE_NOTE("Detail added to each notice:")
If duplicate_assistance_wcom_checkbox = checked Then CALL write_variable_in_CASE_NOTE("* Advised duplicate assistance from state of: " & dup_state & " during the month of " & dup_month & "/" & dup_year & " was received.")
If returned_mail_wcom_checkbox = checked Then CALL write_variable_in_CASE_NOTE("* Explained returned mail was received. Verification request sent: " & rm_sent_date & " and Due: " & rm_due_date & " with no response caused SNAP case closure.")
If pact_fraud_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Explained New Household Member: " & new_hh_memb & " added. Verification needed: " & new_memb_verifs & ". Verification not received causing closure.")
If temp_disa_abawd_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Advised client meets ABAWD exemption of temporary inability to work for " & numb_disa_mos & " months per Doctor statement.")
If client_death_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Advised closure due to client death.")
If mfip_to_snap_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Explained MFIP closure due to: " & MFIP_closing_reason & ".")
If wreg_postponed_verif_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Advised " & abawd_name & " has used their 3 ABAWD months. Postponed WREG verification: " & wreg_verifs_needed & " is due: " & wreg_verifs_due_date & ".")
If banked_mos_avail_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Advised ABAWD months have been used, explained Banked Months may be available.")
If banked_mos_non_coop_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Explained " & banked_abawd_name & " was receiving Banked Months and fail cooperation with E & T. Explained requesting Good Cause, and future banked months ineligibility.")
If banked_mos_used_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Explained Banked Months were being used are are now all used. Advised to review other WREG/ABAWD exemptions.")
If abawd_child_coded_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Explained " & exempt_abawd_name & " is ABAWD and WREG exemptd due to a child(ren) under the age of 18 in the SNAP unit.")
If fset_fail_to_comply_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Advised SNAP is closing due to FSET requirements not being met. Reasons for not meeting the rules: " & fset_fail_reason & ". Advised of good cause and contact information.")
If snap_pact_wcom_checkbox Then CALL write_variable_in_CASE_NOTE("* Explained SNAP case was " & SNAP_close_or_deny & " because " & pact_close_reason)

CALL write_variable_in_CASE_NOTE("---")
CALL write_variable_in_CASE_NOTE(worker_signature)